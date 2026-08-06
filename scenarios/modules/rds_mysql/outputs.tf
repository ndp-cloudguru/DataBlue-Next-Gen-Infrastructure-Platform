# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: RDS MySQL (Relational Database Service)
# File: outputs.tf
# Description: Output xuất RDS Endpoint, Master Credentials, và Security Group ID.
# ==============================================================================

output "db_instance_endpoint" {
  description = "Endpoint kết nối MySQL Primary Instance (ví dụ: host:3306)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "Địa chỉ DNS Hostname của RDS MySQL Database"
  value       = aws_db_instance.this.address
}

output "db_instance_id" {
  description = "ID Resource của RDS Instance"
  value       = aws_db_instance.this.id
}

output "db_master_password" {
  description = "Mật khẩu Master ngẫu nhiên được sinh ra (Sensitive)"
  value       = random_password.master_password.result
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group quản lý truy cập RDS MySQL"
  value       = aws_security_group.rds_sg.id
}

output "secretsmanager_secret_arn" {
  description = "ARN của AWS Secrets Manager Secret lưu trữ RDS Master Credentials"
  value       = aws_secretsmanager_secret.this.arn
}

output "secretsmanager_secret_name" {
  description = "Tên của AWS Secrets Manager Secret lưu trữ RDS Master Credentials"
  value       = aws_secretsmanager_secret.this.name
}

