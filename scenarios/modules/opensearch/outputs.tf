# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: Amazon OpenSearch Service (Log Analytics & Search Engine)
# File: outputs.tf
# Description: Output xuất OpenSearch Endpoint & Dashboard URL.
# ==============================================================================

output "domain_endpoint" {
  description = "Domain Endpoint của OpenSearch Service (HTTPS)"
  value       = aws_opensearch_domain.this.endpoint
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards / Kibana Web Endpoint"
  value       = aws_opensearch_domain.this.dashboard_endpoint
}

output "domain_arn" {
  description = "ARN của OpenSearch Domain"
  value       = aws_opensearch_domain.this.arn
}

output "security_group_id" {
  description = "ID Security Group của OpenSearch"
  value       = aws_security_group.opensearch_sg.id
}
