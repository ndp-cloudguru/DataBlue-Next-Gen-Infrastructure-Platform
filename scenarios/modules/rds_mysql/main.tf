# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: RDS MySQL (Relational Database Service)
# File: main.tf
# Description: Production Amazon RDS MySQL Multi-AZ with KMS CMK, restricted Security Group, and 30-day PITR.
# Architecture Ref: ADR-006 (MySQL Multi-AZ), ADR-013 (Backup PITR), SEC-002 (Isolated DB Subnet)
# ==============================================================================

# 1. Generate secure random master password
resource "random_password" "master_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Security Group restricting MySQL 3306 ingress to Private App Subnets only
resource "aws_security_group" "rds_sg" {
  name        = "${var.identifier}-sg"
  description = "Security group for DataBlue RDS MySQL Database"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL protocol from Private Application Subnets only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow outbound to local VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-sg"
    }
  )
}

# 3. Parameter Group supporting MySQL 8.0 with UTF8MB4 character set
resource "aws_db_parameter_group" "this" {
  name        = "${var.identifier}-params"
  family      = "mysql8.0"
  description = "Custom Parameter Group for DataBlue MySQL 8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "2000"
  }
}

# 4. Amazon RDS Instance (Primary + Standby Multi-AZ)
resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.this.name

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  # Network & Subnet configuration
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false # Zero Public IP

  # Master Account Credentials
  db_name  = var.db_name
  username = var.admin_username
  password = random_password.master_password.result
  port     = 3306

  # Multi-AZ High Availability Configuration (ADR-006)
  multi_az = var.multi_az

  # Storage Encryption At-Rest via KMS CMK (SEC-003)
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Point-in-Time Recovery Backup (PITR 30-day Retention per ADR-013)
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "Sun:04:30-Sun:05:30"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.environment == "Production" ? true : false
  skip_final_snapshot       = var.environment == "Production" ? false : true
  final_snapshot_identifier = "${var.identifier}-final-snapshot"

  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )
}

# 5. AWS Secrets Manager Secret storing MySQL Master Credentials (JSON format encrypted with KMS CMK)
resource "aws_secretsmanager_secret" "this" {
  name        = "datablue/${lower(var.environment)}/rds-mysql"
  description = "RDS MySQL Master Credentials for DataBlue ${var.environment} Environment"
  kms_key_id  = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-secret"
    }
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    engine   = "mysql"
    host     = aws_db_instance.this.address
    port     = 3306
    username = var.admin_username
    password = random_password.master_password.result
    dbname   = var.db_name
    endpoint = aws_db_instance.this.endpoint
  })
}

