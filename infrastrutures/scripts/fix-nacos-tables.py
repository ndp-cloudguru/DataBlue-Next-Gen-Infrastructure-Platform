import boto3
import json
import pymysql

def fix_nacos_tables():
    print("Fetching RDS secrets...")
    secrets_client = boto3.client('secretsmanager', region_name='ap-southeast-1')
    secret_value = secrets_client.get_secret_value(SecretId='datablue/test/rds-mysql')
    credentials = json.loads(secret_value['SecretString'])

    conn = pymysql.connect(
        host=credentials['host'],
        user=credentials['username'],
        password=credentials['password'],
        port=int(credentials['port']),
        database='nacos_config',
        autocommit=True
    )
    cur = conn.cursor()

    alters = [
        "ALTER TABLE config_info ADD COLUMN effect varchar(64) DEFAULT NULL;",
        "ALTER TABLE his_config_info ADD COLUMN effect varchar(64) DEFAULT NULL;",
        "ALTER TABLE config_info ADD COLUMN schema text;",
        "ALTER TABLE his_config_info ADD COLUMN schema text;"
    ]

    for alt in alters:
        try:
            cur.execute(alt)
            print(f"Executed: {alt}")
        except Exception as e:
            print(f"Result for {alt}: {e}")

    print("Nacos tables fixed successfully!")

if __name__ == '__main__':
    fix_nacos_tables()
