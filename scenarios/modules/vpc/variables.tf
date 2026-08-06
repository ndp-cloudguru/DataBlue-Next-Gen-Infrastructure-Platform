# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: VPC (Networking & Subnet Topology)
# File: variables.tf
# Description: Variable definitions for AWS VPC Module.
# ==============================================================================

variable "environment" {
  description = "Deployment environment name (e.g., Test, Production, DevTest)"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for VPC (e.g., 10.0.0.0/16 or 10.100.0.0/16)"
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones for deployment (minimum 2 AZs for Test, 3 AZs for Prod)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for Public Subnets (hosting ALBs and NAT Gateways)"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDR blocks for Private Application Subnets (hosting EKS Worker Nodes & Pods)"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for Isolated Database Subnets (hosting RDS, Redis, MQ, DocumentDB with ZERO internet egress)"
  type        = list(string)
  default     = []
}

variable "eks_cluster_name" {
  description = "EKS Cluster Name used for Subnet Auto-Discovery tagging (Karpenter & AWS Load Balancer Controller)"
  type        = string
}

variable "tags" {
  description = "Map of resource tags conforming to FinOps Tagging Policy"
  type        = map(string)
  default     = {}
}
