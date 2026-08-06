# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: DocumentDB (MongoDB API Compatible Document Store)
# File: outputs.tf
# Description: Output xuất DocumentDB Cluster Endpoint & Credentials.
# ==============================================================================

output "endpoint" {
  description = "Endpoint kết nối DocumentDB Cluster (cổng 27017)"
  value       = aws_docdb_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Endpoint đọc Read-Only của DocumentDB Cluster"
  value       = aws_docdb_cluster.this.reader_endpoint
}

output "master_password" {
  description = "Mật khẩu Master quản trị DocumentDB (Sensitive)"
  value       = random_password.docdb_password.result
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group quản lý truy cập DocumentDB"
  value       = aws_security_group.docdb_sg.id
}
