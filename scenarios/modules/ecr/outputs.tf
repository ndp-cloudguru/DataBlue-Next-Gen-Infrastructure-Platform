# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: ECR (Elastic Container Registry)
# File: outputs.tf
# Description: Module output exports for ECR Repositories.
# ==============================================================================

output "repository_urls" {
  description = "Map of ECR repository names to their repository URLs"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of ECR repository names to their ARNs"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}
