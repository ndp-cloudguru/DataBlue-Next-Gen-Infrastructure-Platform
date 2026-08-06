# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 5: Enterprise Multi-Account Isolation Architecture ($12,000 – $18,500 / month)
# File: variables.tf
# Description: Complete variable definitions for Scenario 5 Landing Zone.
# ==============================================================================

variable "aws_region" {
  description = "AWS region for Multi-Account Landing Zone"
  type        = string
  default     = "us-east-1"
}

variable "prod_core_vpc_cidr" {
  description = "IPv4 CIDR block for Account 1 Prod Core VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dev_test_vpc_cidr" {
  description = "IPv4 CIDR block for Account 4 Dev/Test Isolated VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "tags" {
  description = "Map of resource tags conforming to FinOps Tagging Policy"
  type        = map(string)
  default = {
    BusinessSystem = "DataBlue-Platform"
    CostCenter     = "CC-501-ENTERPRISE-LANDINGZONE"
    Owner          = "SRE-DevSecOps-Team"
    ManagedBy      = "Terraform"
    Scenario       = "Scenario-5-Enterprise-Multi-Account"
  }
}
