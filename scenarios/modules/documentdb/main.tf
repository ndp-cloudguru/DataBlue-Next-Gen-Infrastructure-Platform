# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: DocumentDB (MongoDB API Compatible Document Store)
# File: main.tf
# Description: Production Amazon DocumentDB 3-Node Cluster with KMS CMK Encryption & 30-day Continuous PITR.
# Architecture Ref: ADR-009 (Amazon DocumentDB Audit), SEC-002 (Isolated DB Subnet), ADR-013 (Backup Policy)
# ==============================================================================

# 1. Random password for Master Administrator
resource "random_password" "docdb_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Security Group restricting MongoDB 27017 ingress to Private App Subnets
resource "aws_security_group" "docdb_sg" {
  name        = "${var.cluster_identifier}-sg"
  description = "Security group for DataBlue DocumentDB Cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MongoDB protocol from Private App Subnets"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 3. Amazon DocumentDB Cluster
resource "aws_docdb_cluster" "this" {
  cluster_identifier     = var.cluster_identifier
  engine                 = "docdb"
  master_username        = var.admin_username
  master_password        = random_password.docdb_password.result
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.docdb_sg.id]

  # KMS CMK Encryption at rest (SEC-003)
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Continuous 30-day Backup Retention (ADR-013)
  backup_retention_period   = 30
  preferred_backup_window   = "02:00-03:00"
  skip_final_snapshot       = var.environment == "Production" ? false : true
  final_snapshot_identifier = "${var.cluster_identifier}-final-snapshot"

  tags = merge(
    var.tags,
    {
      Name = var.cluster_identifier
    }
  )
}

# 4. DocumentDB Cluster Instances (Multi-AZ Allocation)
resource "aws_docdb_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-${count.index + 1}"
    }
  )
}
