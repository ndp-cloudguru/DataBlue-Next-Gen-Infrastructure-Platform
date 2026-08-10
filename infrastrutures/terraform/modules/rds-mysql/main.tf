resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-=?^_"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier                = var.identifier
  engine                    = "mysql"
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  storage_type              = "gp3"
  db_name                   = var.db_name
  username                  = var.username
  password                  = random_password.master.result
  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = var.security_group_ids
  multi_az                  = var.multi_az
  publicly_accessible       = false
  storage_encrypted         = true
  kms_key_id                = var.kms_key_arn
  backup_retention_period   = var.backup_retention_days
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final"
  apply_immediately         = true
  tags                      = var.tags
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
    engine   = "mysql"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    username = var.username
    password = random_password.master.result
    dbname   = var.db_name
  })
}
