# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: ElastiCache Redis (In-Memory Cache)
# File: outputs.tf
# Description: Output xuất Redis Primary Endpoint & Auth Token.
# ==============================================================================

output "primary_endpoint_address" {
  description = "Địa chỉ DNS Endpoint của Redis Primary Node"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Địa chỉ DNS Endpoint của Redis Reader Nodes"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "redis_auth_token" {
  description = "Mật khẩu xác thực Redis AUTH (Sensitive)"
  value       = random_password.auth_token.result
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group của Redis"
  value       = aws_security_group.redis_sg.id
}
