# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 4: Production Cross-Region Disaster Recovery ($10,000 – $14,800 / month)
# File: variables.tf
# Description: Complete variable definitions for Scenario 4 Cross-Region DR.
# ==============================================================================

variable "primary_region" {
  description = "Primary AWS region for Active Production (us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary DR AWS region for Pilot Light Standby (us-west-2)"
  type        = string
  default     = "us-west-2"
}

variable "primary_vpc_cidr" {
  description = "IPv4 CIDR block for Primary Active Production VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "IPv4 CIDR block for Secondary Pilot Light DR VPC"
  type        = string
  default     = "10.200.0.0/16"
}

variable "tags" {
  description = "Map of resource tags conforming to FinOps Tagging Policy"
  type        = map(string)
  default = {
    BusinessSystem = "DataBlue-Platform"
    CostCenter     = "CC-401-PROD-DR"
    Owner          = "SRE-DevSecOps-Team"
    ManagedBy      = "Terraform"
    Scenario       = "Scenario-4-Prod-Cross-Region-DR"
  }
}
