# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: EKS (Kubernetes Control Plane & Compute Engine)
# File: outputs.tf
# Description: Output definitions for EKS Cluster Endpoint, OIDC Provider, and Karpenter Roles.
# ==============================================================================

output "cluster_name" {
  description = "Name of the initialized EKS Cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API Endpoint for EKS Control Plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded Certificate Authority data for EKS Cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider" {
  description = "OpenID Connect (OIDC) Provider URL for IRSA"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "ARN of the OpenID Connect (OIDC) Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "karpenter_node_role_arn" {
  description = "ARN of the IAM Role for Karpenter JIT Worker Nodes"
  value       = aws_iam_role.karpenter_node.arn
}

output "karpenter_instance_profile_name" {
  description = "Name of the EC2 Instance Profile for Karpenter Nodes"
  value       = aws_iam_instance_profile.karpenter_node.name
}
