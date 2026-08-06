# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 4: Production Cross-Region Disaster Recovery ($10,000 – $14,800 / month)
# File: outputs.tf
# Description: Comprehensive outputs for Scenario 4 deployment.
# ==============================================================================

output "primary_kms_key_arn" {
  description = "ARN of Primary Region KMS Customer Managed Key"
  value       = module.kms_primary.key_arn
}

output "secondary_kms_key_arn" {
  description = "ARN of Secondary DR Region KMS Customer Managed Key"
  value       = module.kms_dr.key_arn
}

output "primary_vpc_id" {
  description = "VPC ID of Primary Active Production Environment"
  value       = module.vpc_primary.vpc_id
}

output "secondary_vpc_id" {
  description = "VPC ID of Secondary Pilot Light DR Environment"
  value       = module.vpc_dr.vpc_id
}

output "primary_eks_endpoint" {
  description = "Kubernetes API Endpoint for Primary EKS Cluster (us-east-1)"
  value       = module.eks_primary.cluster_endpoint
}

output "secondary_eks_endpoint" {
  description = "Kubernetes API Endpoint for Standby DR EKS Cluster (us-west-2)"
  value       = module.eks_dr.cluster_endpoint
}

output "primary_rds_endpoint" {
  description = "Endpoint for Primary RDS MySQL Multi-AZ Database"
  value       = module.rds_primary.db_instance_endpoint
}

output "primary_backup_bucket_arn" {
  description = "ARN of Primary S3 Backup Vault"
  value       = aws_s3_bucket.primary_backup.arn
}

output "dr_backup_bucket_arn" {
  description = "ARN of Secondary DR S3 Backup Vault"
  value       = aws_s3_bucket.dr_backup.arn
}
