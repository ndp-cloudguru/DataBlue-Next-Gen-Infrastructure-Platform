output "amqp_endpoints" {
  value = aws_mq_broker.this.instances[*].endpoints
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}
