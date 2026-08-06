# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: Amazon MQ RabbitMQ (Message Broker)
# File: main.tf
# Description: Initializes Amazon MQ for RabbitMQ Multi-AZ Quorum Broker.
# Architecture Ref: ADR-008 (Amazon MQ RabbitMQ Multi-AZ), SEC-002 (Isolated DB Subnet), SEC-003 (KMS CMK Encryption)
# ==============================================================================

# 1. Random password for RabbitMQ Master Account
resource "random_password" "mq_password" {
  length           = 24
  special          = true
  override_special = "!#$&*()_+-=[]{}|<>?"
}

# 2. Security Group for RabbitMQ (Ports 5671 AMQPS & 15671 HTTPS Web UI)
resource "aws_security_group" "mq_sg" {
  name        = "${var.broker_name}-sg"
  description = "Security group for DataBlue Amazon MQ RabbitMQ Broker"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow AMQP TLS 5671 from Private App Subnets"
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "Allow RabbitMQ Web Console 15671 from Private App Subnets"
    from_port   = 15671
    to_port     = 15671
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

# 3. Amazon MQ RabbitMQ Broker
resource "aws_mq_broker" "this" {
  broker_name = var.broker_name

  engine_type                 = "RabbitMQ"
  engine_version              = "3.13"
  auto_minor_version_upgrade  = true
  host_instance_type          = var.host_instance_type
  deployment_mode    = var.deployment_mode

  publicly_accessible = false # Zero public accessibility
  subnet_ids          = var.subnet_ids
  security_groups     = [aws_security_group.mq_sg.id]

  # KMS CMK Encryption at rest (SEC-003)
  encryption_options {
    use_aws_owned_key = false
    kms_key_id        = var.kms_key_arn
  }

  user {
    username = var.admin_username
    password = random_password.mq_password.result
  }

  logs {
    general = true
  }

  tags = merge(
    var.tags,
    {
      Name = var.broker_name
    }
  )
}
