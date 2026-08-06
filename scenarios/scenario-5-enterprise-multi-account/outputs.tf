# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 5: Enterprise Multi-Account Isolation Architecture ($12,000 – $18,500 / month)
# File: outputs.tf
# Description: Comprehensive outputs for Scenario 5 Landing Zone deployment.
# ==============================================================================

output "prod_core_kms_arn" {
  description = "ARN of KMS CMK in Account 1 Prod Core"
  value       = module.kms_prod_core.key_arn
}

output "prod_core_vpc_id" {
  description = "VPC ID of Account 1 Prod Core"
  value       = module.vpc_prod_core.vpc_id
}

output "prod_core_eks_endpoint" {
  description = "Kubernetes API Endpoint for EKS Cluster in Account 1 Prod Core"
  value       = module.eks_prod_core.cluster_endpoint
}

output "prod_core_rds_endpoint" {
  description = "Endpoint for RDS MySQL Multi-AZ Database in Account 1 Prod Core"
  value       = module.rds_prod_core.db_instance_endpoint
}

output "dev_test_kms_arn" {
  description = "ARN of KMS CMK in Account 4 Dev/Test Isolated"
  value       = module.kms_dev_test.key_arn
}

output "dev_test_vpc_id" {
  description = "VPC ID of Account 4 Dev/Test Isolated (100% Standalone)"
  value       = module.vpc_dev_test.vpc_id
}

output "dev_test_eks_endpoint" {
  description = "Kubernetes API Endpoint for EKS Cluster in Account 4 Dev/Test Isolated"
  value       = module.eks_dev_test.cluster_endpoint
}

output "transit_gateway_id" {
  description = "ID of the Central AWS Transit Gateway Hub (Connecting Accounts 1, 2, 3)"
  value       = aws_ec2_transit_gateway.tgw_hub.id
}
