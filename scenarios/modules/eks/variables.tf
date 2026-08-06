# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: EKS (Kubernetes Control Plane & Compute Engine)
# File: variables.tf
# Description: Variable definitions for EKS Cluster & Karpenter Nodes.
# ==============================================================================

variable "environment" {
  description = "Environment name (e.g., Test, Production, DevTest)"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name (e.g., DataBlue-Prod-EKS)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes Version (standard v1.30+ per ADR-003)"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "ID of the VPC hosting the EKS Cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of Private App Subnet IDs for EKS Control Plane & Initial NodeGroup"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of the KMS CMK used to encrypt Kubernetes Secrets & EBS volumes"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 Instance types for Initial Managed NodeGroup (e.g., m6g.large, m6g.xlarge)"
  type        = list(string)
  default     = ["m6g.large"]
}

variable "desired_size" {
  description = "Desired number of worker nodes initially"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes for Initial Managed NodeGroup"
  type        = number
  default     = 6
}

variable "capacity_type" {
  description = "EC2 Capacity Type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "tags" {
  description = "Resource tags map conforming to FinOps policy"
  type        = map(string)
  default     = {}
}
