import boto3
import json
import pymysql

def init_nacos_db():
    print("Fetching RDS secrets from AWS Secrets Manager...")
    secrets_client = boto3.client('secretsmanager', region_name='ap-southeast-1')
    secret_value = secrets_client.get_secret_value(SecretId='datablue/test/rds-mysql')
    credentials = json.loads(secret_value['SecretString'])

    host = credentials['host']
    user = credentials['username']
    password = credentials['password']
    port = int(credentials['port'])

    print(f"Connecting to RDS MySQL host: {host}:{port}...")
    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    cur = conn.cursor()

    print("Creating database nacos_config if not exists...")
    cur.execute("CREATE DATABASE IF NOT EXISTS `nacos_config` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
    cur.execute("USE `nacos_config`;")

    sqls = [
        """
        CREATE TABLE IF NOT EXISTS `config_info` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
          `data_id` varchar(255) NOT NULL COMMENT 'data_id',
          `group_id` varchar(128) DEFAULT NULL,
          `content` longtext NOT NULL COMMENT 'content',
          `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
          `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_create',
          `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_modified',
          `src_user` text COMMENT 'source user',
          `src_ip` varchar(50) DEFAULT NULL COMMENT 'source ip',
          `app_name` varchar(128) DEFAULT NULL,
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          `c_schema` text,
          `c_line` text,
          `c_desc` text,
          `config_tags` varchar(128) DEFAULT NULL,
          `type` varchar(64) DEFAULT NULL,
          `encrypted_data_key` text COMMENT 'key',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_configinfo_datagrouptenant` (`data_id`,`group_id`,`tenant_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info';
        """,
        """
        CREATE TABLE IF NOT EXISTS `config_info_aggr` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
          `data_id` varchar(255) NOT NULL COMMENT 'data_id',
          `group_id` varchar(128) NOT NULL COMMENT 'group_id',
          `datum_id` varchar(255) NOT NULL COMMENT 'datum_id',
          `content` longtext NOT NULL COMMENT 'content',
          `gmt_modified` datetime NOT NULL COMMENT 'gmt_modified',
          `app_name` varchar(128) DEFAULT NULL,
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_configinfoaggr_datagrouptenantdatum` (`data_id`,`group_id`,`tenant_id`,`datum_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_aggr';
        """,
        """
        CREATE TABLE IF NOT EXISTS `config_info_beta` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
          `data_id` varchar(255) NOT NULL COMMENT 'data_id',
          `group_id` varchar(128) NOT NULL COMMENT 'group_id',
          `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
          `content` longtext NOT NULL COMMENT 'content',
          `beta_ips` varchar(1024) DEFAULT NULL COMMENT 'betaIps',
          `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
          `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_create',
          `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_modified',
          `src_user` text COMMENT 'src_user',
          `src_ip` varchar(50) DEFAULT NULL COMMENT 'src_ip',
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          `encrypted_data_key` text COMMENT 'key',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_configinfobeta_datagrouptenant` (`data_id`,`group_id`,`tenant_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_beta';
        """,
        """
        CREATE TABLE IF NOT EXISTS `config_info_tag` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
          `data_id` varchar(255) NOT NULL COMMENT 'data_id',
          `group_id` varchar(128) NOT NULL COMMENT 'group_id',
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          `tag_id` varchar(128) NOT NULL COMMENT 'tag_id',
          `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
          `content` longtext NOT NULL COMMENT 'content',
          `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
          `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_create',
          `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_modified',
          `src_user` text COMMENT 'src_user',
          `src_ip` varchar(50) DEFAULT NULL COMMENT 'src_ip',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_configinfotag_datagrouptenanttag` (`data_id`,`group_id`,`tenant_id`,`tag_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_tag';
        """,
        """
        CREATE TABLE IF NOT EXISTS `config_tags_relation` (
          `id` bigint(20) NOT NULL COMMENT 'id',
          `tag_name` varchar(128) NOT NULL COMMENT 'tag_name',
          `tag_type` varchar(64) DEFAULT NULL COMMENT 'tag_type',
          `data_id` varchar(255) NOT NULL COMMENT 'data_id',
          `group_id` varchar(128) NOT NULL COMMENT 'group_id',
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          `nid` bigint(20) NOT NULL AUTO_INCREMENT,
          PRIMARY KEY (`nid`),
          UNIQUE KEY `uk_configtagrelation_configidtag` (`id`,`tag_name`,`tag_type`),
          KEY `idx_tenant_id` (`tenant_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_tags_relation';
        """,
        """
        CREATE TABLE IF NOT EXISTS `group_capacity` (
          `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
          `group_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'Group ID',
          `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Quota',
          `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Usage',
          `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max Size',
          `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max Aggr Count',
          `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max Aggr Size',
          `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max History Count',
          `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_create',
          `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_modified',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_group_id` (`group_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='group_capacity';
        """,
        """
        CREATE TABLE IF NOT EXISTS `his_config_info` (
          `id` bigint(20) unsigned NOT NULL COMMENT 'id',
          `nid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
          `data_id` varchar(255) NOT NULL COMMENT 'data_id',
          `group_id` varchar(128) NOT NULL COMMENT 'group_id',
          `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
          `content` longtext NOT NULL COMMENT 'content',
          `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
          `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_create',
          `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_modified',
          `src_user` text COMMENT 'src_user',
          `src_ip` varchar(50) DEFAULT NULL COMMENT 'src_ip',
          `op_type` char(10) DEFAULT NULL COMMENT 'op_type',
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          `encrypted_data_key` text COMMENT 'key',
          PRIMARY KEY (`nid`),
          KEY `idx_gmt_create` (`gmt_create`),
          KEY `idx_gmt_modified` (`gmt_modified`),
          KEY `idx_did` (`data_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='his_config_info';
        """,
        """
        CREATE TABLE IF NOT EXISTS `tenant_capacity` (
          `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
          `tenant_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'Tenant ID',
          `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Quota',
          `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Usage',
          `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max Size',
          `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max Aggr Count',
          `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max Aggr Size',
          `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Max History Count',
          `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_create',
          `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'gmt_modified',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_tenant_id` (`tenant_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='tenant_capacity';
        """,
        """
        CREATE TABLE IF NOT EXISTS `tenant_info` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
          `kp` varchar(128) NOT NULL COMMENT 'kp',
          `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
          `tenant_name` varchar(128) DEFAULT '' COMMENT 'tenant_name',
          `tenant_desc` varchar(256) DEFAULT NULL COMMENT 'tenant_desc',
          `create_source` varchar(32) DEFAULT NULL COMMENT 'create_source',
          `gmt_create` bigint(20) NOT NULL COMMENT 'gmt_create',
          `gmt_modified` bigint(20) NOT NULL COMMENT 'gmt_modified',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uk_tenant_info_kptenant` (`kp`,`tenant_id`),
          KEY `idx_tenant_id` (`tenant_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='tenant_info';
        """,
        """
        CREATE TABLE IF NOT EXISTS `users` (
          `username` varchar(50) NOT NULL PRIMARY KEY,
          `password` varchar(500) NOT NULL,
          `enabled` boolean NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS `roles` (
          `username` varchar(50) NOT NULL,
          `role` varchar(50) NOT NULL,
          UNIQUE KEY `idx_user_role` (`username`, `role`)
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS `permissions` (
          `role` varchar(50) NOT NULL,
          `resource` varchar(255) NOT NULL,
          `action` varchar(8) NOT NULL,
          UNIQUE KEY `uk_role_permission` (`role`,`resource`,`action`)
        );
        """,
        """
        INSERT INTO users (username, password, enabled) VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jOW/58G.Wn66bE.x9u.k/Oa.xK7f8z0.Gg8s', TRUE) ON DUPLICATE KEY UPDATE username=username;
        """,
        """
        INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN') ON DUPLICATE KEY UPDATE username=username;
        """
    ]

    for sql in sqls:
        cur.execute(sql)

    print("All Nacos MySQL tables created successfully!")

if __name__ == '__main__':
    init_nacos_db()
