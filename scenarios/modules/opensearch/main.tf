# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: Amazon OpenSearch Service (Log Analytics & Search Engine)
# File: main.tf
# Description: Initializes Amazon OpenSearch Service Domain with KMS CMK Encryption & Private VPC Access.
# Architecture Ref: ADR-012 (Observability Stack), OPS-001 (OpenSearch Central Logging)
# ==============================================================================

# 1. Security Group restricting HTTPS 443 ingress to Private App Subnets
resource "aws_security_group" "opensearch_sg" {
  name        = "${var.domain_name}-sg"
  description = "Security group for DataBlue Amazon OpenSearch Service"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS 443 from Private App Subnets (Fluent Bit & Grafana)"
    from_port   = 443
    to_port     = 443
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

# 2. Amazon OpenSearch Domain
resource "aws_opensearch_domain" "this" {
  domain_name    = var.domain_name
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.instance_count > 1 ? true : false

    dynamic "zone_awareness_config" {
      for_each = var.instance_count > 1 ? [1] : []
      content {
        availability_zone_count = min(var.instance_count, 3)
      }
    }
  }

  vpc_options {
    subnet_ids         = slice(var.subnet_ids, 0, min(length(var.subnet_ids), var.instance_count))
    security_group_ids = [aws_security_group.opensearch_sg.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.ebs_volume_size
    iops        = 3000
    throughput  = 125
  }

  # KMS CMK Encryption at rest & TLS node-to-node (SEC-003)
  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = false
    internal_user_database_enabled = false
  }

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}
