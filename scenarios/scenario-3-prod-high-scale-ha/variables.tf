# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 3: Production Enhanced High Availability ($7,200 – $10,500 / month)
# File: variables.tf
# Description: Complete variable definitions for Scenario 3.
# ==============================================================================

variable "aws_region" {
  description = "AWS region for High-Scale Production HA deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for High-Scale Production VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of 3 Availability Zones for High-Scale HA Layout"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "eks_cluster_name" {
  description = "EKS Cluster Name for High-Scale Production"
  type        = string
  default     = "DataBlue-Prod-HA-EKS"
}

variable "tags" {
  description = "Map of resource tags conforming to FinOps Tagging Policy"
  type        = map(string)
  default = {
    Environment    = "Production-HA"
    BusinessSystem = "DataBlue-Platform"
    CostCenter     = "CC-301-PROD-HA"
    Owner          = "SRE-DevSecOps-Team"
    ManagedBy      = "Terraform"
    Scenario       = "Scenario-3-Prod-High-Scale-HA"
  }
}
