resource "random_password" "auth" {
  length  = 32
  special = false
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = var.name
  description                = "${var.name} redis cache"
  node_type                  = var.node_type
  port                       = 6379
  engine                     = "redis"
  num_cache_clusters         = 1
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = var.security_group_ids
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  kms_key_id                 = var.kms_key_arn
  automatic_failover_enabled = false
  tags                       = var.tags
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    host       = aws_elasticache_replication_group.this.primary_endpoint_address
    port       = 6379
    auth_token = ""
    tls        = false
  })
}
