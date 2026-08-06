# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: ElastiCache Redis (In-Memory Cache)
# File: main.tf
# Description: Initializes Amazon ElastiCache Redis Multi-AZ with Auth Token & KMS CMK Encryption.
# Architecture Ref: ADR-007 (ElastiCache Redis Multi-AZ), SEC-003 (KMS Encryption At-Rest & TLS In-Transit)
# ==============================================================================

# 1. Generate secure random AUTH Token for Redis
resource "random_password" "auth_token" {
  length  = 32
  special = false
}

# 2. Subnet Group for Redis deployed in Isolated Database Subnets
resource "aws_elasticache_subnet_group" "this" {
  name       = "databue-${lower(var.environment)}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

# 3. Security Group restricting Redis 6379 ingress to Private App Subnets
resource "aws_security_group" "redis_sg" {
  name        = "${var.replication_group_id}-sg"
  description = "Security group for DataBlue ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Redis traffic from Private App Subnets"
    from_port   = 6379
    to_port     = 6379
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

# 4. Parameter Group optimizing Redis 7.0
resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.replication_group_id}-params"
  family      = "redis7"
  description = "Custom Parameter Group for DataBlue Redis 7.0"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }
}

# 5. ElastiCache Redis Replication Group (Multi-AZ Primary + Replica)
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.replication_group_id
  description          = "DataBlue Redis Cache Replication Group (${var.environment})"

  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  port                       = 6379
  automatic_failover_enabled = true # Multi-AZ High Availability (ADR-007)
  multi_az_enabled           = true

  # Encryption In-Transit (TLS) & At-Rest (KMS CMK) per SEC-003
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  auth_token                 = random_password.auth_token.result

  snapshot_retention_limit = 7
  snapshot_window          = "02:00-03:00"

  tags = merge(
    var.tags,
    {
      Name = var.replication_group_id
    }
  )
}
