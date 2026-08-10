import boto3
import json
import pymysql

def check_nacos_users():
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

    # Check existing users
    cur.execute("SELECT username, password FROM users;")
    rows = cur.fetchall()
    print(f"\nExisting users in nacos_config.users ({len(rows)}):")
    for r in rows:
        print(f"  username={r[0]}, password_hash={r[1][:20]}...")

    if not rows:
        print("\nNo users found! Creating default nacos user...")
        # Nacos default password hash for 'nacos': $2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu
        cur.execute("""
            INSERT INTO users (username, password, enabled)
            VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', 1)
        """)
        # Also insert roles
        cur.execute("""
            INSERT INTO roles (username, role)
            VALUES ('nacos', 'ROLE_ADMIN')
        """)
        print("Created user 'nacos' with password 'nacos' and ROLE_ADMIN")
    else:
        print("\nUpdating password for 'nacos' user to default 'nacos'...")
        cur.execute("""
            UPDATE users SET password='$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu'
            WHERE username='nacos'
        """)
        print("Password reset to 'nacos'")

    # Verify
    cur.execute("SELECT username, enabled FROM users;")
    print("\nFinal user list:")
    for r in cur.fetchall():
        print(f"  {r}")

if __name__ == '__main__':
    check_nacos_users()
