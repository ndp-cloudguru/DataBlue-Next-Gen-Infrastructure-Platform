resource "random_password" "password" {
  length  = 24
  special = false
}

resource "aws_mq_broker" "this" {
  broker_name                = var.name
  engine_type                = "RABBITMQ"
  engine_version             = var.engine_version
  host_instance_type         = var.instance_type
  deployment_mode            = "SINGLE_INSTANCE"
  publicly_accessible        = false
  subnet_ids                 = [var.subnet_ids[0]]
  security_groups            = var.security_group_ids
  auto_minor_version_upgrade = true

  user {
    username = var.username
    password = random_password.password.result
  }

  logs {
    general = true
  }

  tags = var.tags
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
    username = var.username
    password = random_password.password.result
  })
}
