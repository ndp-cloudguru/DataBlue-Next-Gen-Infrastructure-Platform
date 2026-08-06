# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: Amazon MQ RabbitMQ (Message Broker)
# File: outputs.tf
# Description: Output xuất RabbitMQ AMQP Endpoint & Master Credentials.
# ==============================================================================

output "broker_id" {
  description = "ID của RabbitMQ Broker"
  value       = aws_mq_broker.this.id
}

output "amqp_endpoints" {
  description = "Danh sách AMQPS Endpoints để Pods kết nối (cổng 5671)"
  value       = aws_mq_broker.this.instances[*].endpoints
}

output "mq_password" {
  description = "Mật khẩu quản trị RabbitMQ (Sensitive)"
  value       = random_password.mq_password.result
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group của RabbitMQ Broker"
  value       = aws_security_group.mq_sg.id
}
