# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 2: Production Early-Start Environment ($2,096.49 / month)
# File: variables.tf
# Description: Input variables for Scenario 2 Production Early-Start Environment.
# Governance Ref: TERRAFORM_PROD_EARLYSTART_PLANNING.md
# ==============================================================================

variable "aws_region" {
  description = "AWS region for Production deployment (Singapore)"
  type        = string
  default     = "ap-southeast-1"
}

# AWS CLI Profiles for Multi-Account Setup
variable "aws_profile_core" {
  description = "AWS CLI Profile for Account 1 (Prod Core)"
  type        = string
  default     = "datablue-prod-core"
}

variable "aws_profile_entry_a" {
  description = "AWS CLI Profile for Account 2 (Prod Entry A)"
  type        = string
  default     = "datablue-prod-entry-a"
}

variable "aws_profile_entry_b" {
  description = "AWS CLI Profile for Account 3 (Prod Entry B)"
  type        = string
  default     = "datablue-prod-entry-b"
}

# VPC Network CIDRs per TERRAFORM_PROD_EARLYSTART_PLANNING.md
variable "prod_core_vpc_cidr" {
  description = "IPv4 CIDR block for Account 1 Production Core VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "prod_entry_a_vpc_cidr" {
  description = "IPv4 CIDR block for Account 2 Production Entry VPC A"
  type        = string
  default     = "10.20.0.0/16"
}

variable "prod_entry_b_vpc_cidr" {
  description = "IPv4 CIDR block for Account 3 Production Entry VPC B"
  type        = string
  default     = "10.30.0.0/16"
}

variable "availability_zones" {
  description = "List of 3 Availability Zones for Production Layout in Singapore"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

# Account 1 Prod Core Subnet CIDRs (3-AZ Layout)
variable "prod_core_public_subnet_cidrs" {
  description = "Public Subnet CIDRs for Account 1 Prod Core"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "prod_core_private_app_subnet_cidrs" {
  description = "Private App Subnet CIDRs for Account 1 Prod Core (EKS Nodes & Pods)"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.20.0/24", "10.10.30.0/24"]
}

variable "prod_core_database_subnet_cidrs" {
  description = "Isolated DB Subnet CIDRs for Account 1 Prod Core (RDS, Redis, MQ)"
  type        = list(string)
  default     = ["10.10.100.0/24", "10.10.200.0/24", "10.10.300.0/24"]
}

# Account 2 Prod Entry A Subnet CIDRs
variable "prod_entry_a_public_subnet_cidrs" {
  description = "Public Subnet CIDRs for Account 2 Entry A (Public NLB A)"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "prod_entry_a_private_app_subnet_cidrs" {
  description = "Private App Subnet CIDRs for Account 2 Entry A (Fargate Proxy Task A)"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.20.0/24", "10.20.30.0/24"]
}

# Account 3 Prod Entry B Subnet CIDRs
variable "prod_entry_b_public_subnet_cidrs" {
  description = "Public Subnet CIDRs for Account 3 Entry B (Public NLB B)"
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
}

variable "prod_entry_b_private_app_subnet_cidrs" {
  description = "Private App Subnet CIDRs for Account 3 Entry B (Fargate Proxy Task B)"
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.20.0/24", "10.30.30.0/24"]
}

# Compute Specs
variable "eks_cluster_name" {
  description = "EKS Cluster Name for Production Early-Start"
  type        = string
  default     = "DataBlue-Prod-EKS"
}

variable "eks_node_instance_types" {
  description = "Instance type for Production EKS Nodes (Graviton3 m7g.large per TERRAFORM_PROD_EARLYSTART_PLANNING.md)"
  type        = list(string)
  default     = ["m7g.large"]
}

variable "fargate_cpu" {
  description = "vCPU units allocated for ECS Fargate Prod Entry Proxy Tasks (2048 = 2 vCPU per TERRAFORM_PROD_EARLYSTART_PLANNING.md)"
  type        = number
  default     = 2048
}

variable "fargate_memory" {
  description = "Memory allocated for ECS Fargate Prod Entry Proxy Tasks (4096 MB = 4 GB per TERRAFORM_PROD_EARLYSTART_PLANNING.md)"
  type        = number
  default     = 4096
}

# ECR Repositories for Production
variable "ecr_repository_names" {
  description = "List of ECR repositories for Production microservices"
  type        = list(string)
  default = [
    "datablue-prod/backend-api",
    "datablue-prod/frontend",
    "datablue-prod/envoy-proxy"
  ]
}

variable "db_name" {
  description = "Initial default database name for Production RDS MySQL"
  type        = string
  default     = "datablue_prod_db"
}

variable "admin_username" {
  description = "Master administrator username for Production RDS MySQL"
  type        = string
  default     = "admin_databue_prod"
}

variable "tags" {
  description = "Map of resource tags conforming to FinOps Tagging Policy"
  type        = map(string)
  default = {
    Environment    = "Production"
    BusinessSystem = "DataBlue-Platform"
    CostCenter     = "CC-201-PROD-EARLYSTART"
    Owner          = "SRE-DevSecOps-Team"
    ManagedBy      = "Terraform"
    Scenario       = "Scenario-2-Prod-EarlyStart"
  }
}
