import os
import json
import ssl
import logging
from flask import Flask, jsonify
import pymysql
import redis
import pika
import boto3

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

app = Flask(__name__)

REGION = os.getenv("AWS_REGION", "ap-southeast-1")

def get_boto3_session():
    # If running in EKS with IRSA, AWS_ROLE_ARN is injected automatically by EKS
    if os.getenv("AWS_ROLE_ARN"):
        return boto3.Session(region_name=REGION)
    
    profile = os.getenv("AWS_PROFILE")
    if profile:
        try:
            return boto3.Session(profile_name=profile, region_name=REGION)
        except Exception:
            pass
    return boto3.Session(region_name=REGION)

def get_secret(secret_name):
    """Retrieve secret string directly from AWS Secrets Manager."""
    if not secret_name:
        return {}
    try:
        session = get_boto3_session()
        client = session.client("secretsmanager")
        res = client.get_secret_value(SecretId=secret_name)
        if "SecretString" in res:
            return json.loads(res["SecretString"])
    except Exception as e:
        logger.error(f"Failed to fetch secret '{secret_name}': {e}")
    return {}

def check_mysql():
    secret_name = os.getenv("RDS_SECRET_NAME", "datablue/test/rds-mysql")
    secret = get_secret(secret_name)
    host = os.getenv("MYSQL_HOST") or secret.get("host")
    port = int(os.getenv("MYSQL_PORT") or secret.get("port") or 3306)
    user = os.getenv("MYSQL_USER") or secret.get("username") or "admin_datablue"
    password = os.getenv("MYSQL_PASSWORD") or secret.get("password")
    dbname = os.getenv("MYSQL_DB") or secret.get("dbname") or "datablue_test_db"

    if not host or not password:
        return {"status": "SKIPPED", "details": "MySQL host or password not configured"}

    try:
        conn = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=dbname,
            connect_timeout=5
        )
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1;")
            result = cursor.fetchone()
        conn.close()
        return {"status": "CONNECTED", "host": host, "port": port, "query_result": result[0]}
    except Exception as e:
        logger.error(f"MySQL connection error: {e}")
        return {"status": "FAILED", "host": host, "port": port, "error": str(e)}

def check_redis():
    secret_name = os.getenv("REDIS_SECRET_NAME", "datablue/test/redis")
    secret = get_secret(secret_name)
    host = os.getenv("REDIS_HOST") or secret.get("host")
    port = int(os.getenv("REDIS_PORT") or secret.get("port") or 6379)
    auth_token = os.getenv("REDIS_AUTH_TOKEN") or secret.get("auth_token")

    if not host:
        return {"status": "SKIPPED", "details": "Redis host not configured"}

    try:
        r = redis.Redis(
            host=host,
            port=port,
            password=auth_token,
            ssl=True,
            ssl_cert_reqs=None,
            socket_timeout=5
        )
        ping_ok = r.ping()
        return {"status": "CONNECTED", "host": host, "port": port, "ping": ping_ok}
    except Exception as e:
        logger.error(f"Redis connection error: {e}")
        return {"status": "FAILED", "host": host, "port": port, "error": str(e)}

def check_rabbitmq():
    secret_name = os.getenv("MQ_SECRET_NAME", "datablue/test/rabbitmq")
    secret = get_secret(secret_name)
    host = os.getenv("RABBITMQ_HOST") or secret.get("host")
    port = int(os.getenv("RABBITMQ_PORT") or secret.get("port") or 5671)
    username = os.getenv("RABBITMQ_USER") or secret.get("username")
    password = os.getenv("RABBITMQ_PASSWORD") or secret.get("password")

    if not host or not password:
        return {"status": "SKIPPED", "details": "RabbitMQ host or password not configured"}

    try:
        credentials = pika.PlainCredentials(username, password)
        if port == 5671:
            ssl_context = ssl.create_default_context()
            ssl_options = pika.SSLOptions(ssl_context)
        else:
            ssl_options = None

        parameters = pika.ConnectionParameters(
            host=host,
            port=port,
            credentials=credentials,
            ssl_options=ssl_options,
            connection_attempts=1,
            retry_delay=1,
            socket_timeout=5
        )
        connection = pika.BlockingConnection(parameters)
        connection.close()
        return {"status": "CONNECTED", "host": host, "port": port}
    except Exception as e:
        logger.error(f"RabbitMQ connection error: {e}")
        return {"status": "FAILED", "host": host, "port": port, "error": str(e)}

@app.route("/", methods=["GET"])
def health():
    return jsonify({"service": "datablue-data-checker", "status": "UP", "port": 6969})

@app.route("/check-db-connected", methods=["GET"])
def check_db_connected():
    mysql_res = check_mysql()
    redis_res = check_redis()
    rabbitmq_res = check_rabbitmq()

    all_connected = all(
        res["status"] in ["CONNECTED", "SKIPPED"]
        for res in [mysql_res, redis_res, rabbitmq_res]
    )

    response = {
        "overall_status": "SUCCESS" if all_connected else "FAILED",
        "data_tier": {
            "mysql": mysql_res,
            "redis": redis_res,
            "rabbitmq": rabbitmq_res
        }
    }
    status_code = 200 if all_connected else 500
    return jsonify(response), status_code

if __name__ == "__main__":
    port = int(os.getenv("PORT", 6969))
    logger.info(f"Starting Data Checker App on port {port}...")
    app.run(host="0.0.0.0", port=port)
