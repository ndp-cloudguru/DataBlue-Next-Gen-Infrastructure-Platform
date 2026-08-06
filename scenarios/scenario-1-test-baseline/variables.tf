# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 1: Test Environment Baseline (Singapore Region ap-southeast-1)
# File: variables.tf
# Description: Input variables for Scenario 1 Test Environment.
# ==============================================================================

variable "aws_region" {
  description = "AWS region for Test Environment deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile_core" {
  description = "AWS CLI Profile for Account 1 Test Core"
  type        = string
  default     = "datablue-test-core"
}

variable "aws_profile_entry" {
  description = "AWS CLI Profile for Account 4 Test Entry"
  type        = string
  default     = "datablue-test-entry"
}


variable "test_core_vpc_cidr" {
  description = "IPv4 CIDR block for Account 1 Test Core VPC"
  type        = string
  default     = "10.50.0.0/16"
}

variable "test_entry_vpc_cidr" {
  description = "IPv4 CIDR block for Account 4 Test Entry VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones for 2-AZ Test Layout in Singapore"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "eks_cluster_name" {
  description = "EKS Cluster Name for Test Environment"
  type        = string
  default     = "DataBlue-Test-EKS"
}

variable "db_name" {
  description = "Initial default database name for RDS MySQL Test"
  type        = string
  default     = "datablue_test_db"
}

variable "admin_username" {
  description = "Master administrator username for RDS MySQL Test"
  type        = string
  default     = "admin_test"
}

variable "tags" {
  description = "Map of resource tags conforming to FinOps Tagging Policy"
  type        = map(string)
  default = {
    Environment    = "Test"
    BusinessSystem = "DataBlue-Platform"
    CostCenter     = "CC-101-TEST"
    Owner          = "SRE-DevSecOps-Team"
    ManagedBy      = "Terraform"
    Scenario       = "Scenario-1-Test-Baseline"
  }
}

# Subnet CIDR Block Definitions for Test Core VPC (10.50.0.0/16)
variable "test_core_public_subnet_cidrs" {
  description = "Public Subnet CIDRs for Account 1 Test Core VPC"
  type        = list(string)
  default     = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "test_core_private_app_subnet_cidrs" {
  description = "Private App Subnet CIDRs for Account 1 Test Core VPC"
  type        = list(string)
  default     = ["10.50.10.0/24", "10.50.20.0/24"]
}

variable "test_core_database_subnet_cidrs" {
  description = "Isolated Database Subnet CIDRs for Account 1 Test Core VPC"
  type        = list(string)
  default     = ["10.50.100.0/24", "10.50.200.0/24"]
}

# Subnet CIDR Block Definitions for Test Entry VPC (10.40.0.0/16)
variable "test_entry_public_subnet_cidrs" {
  description = "Public Subnet CIDRs for Account 4 Test Entry VPC"
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "test_entry_private_app_subnet_cidrs" {
  description = "Private App Subnet CIDRs for Account 4 Test Entry VPC"
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.20.0/24"]
}

variable "test_entry_database_subnet_cidrs" {
  description = "Isolated Database Subnet CIDRs for Account 4 Test Entry VPC"
  type        = list(string)
  default     = ["10.40.100.0/24", "10.40.200.0/24"]
}

# ECS Fargate Entry Proxy Task Specifications
variable "fargate_cpu" {
  description = "vCPU units allocated for ECS Fargate Test Entry Proxy Task (1024 = 1 vCPU per TERRAFORM_TEST_PLANNING.md)"
  type        = number
  default     = 1024
}

variable "fargate_memory" {
  description = "Memory allocated for ECS Fargate Test Entry Proxy Task (2048 MB = 2 GB per TERRAFORM_TEST_PLANNING.md)"
  type        = number
  default     = 2048
}

# ECR Repositories for Test Environment
variable "ecr_repository_names" {
  description = "List of ECR repositories for Test microservices"
  type        = list(string)
  default = [
    "datablue-test/backend-api",
    "datablue-test/frontend",
    "datablue-test/envoy-proxy"
  ]
}


