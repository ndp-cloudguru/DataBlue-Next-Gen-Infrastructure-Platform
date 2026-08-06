# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: ECR (Elastic Container Registry)
# File: variables.tf
# Description: Variable definitions for AWS ECR Repository Management.
# ==============================================================================

variable "environment" {
  description = "Environment name (e.g., Test, Production, DevTest)"
  type        = string
}

variable "repository_names" {
  description = "List of ECR repository names to create (e.g., ['datablue-test/backend', 'datablue-test/frontend'])"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable automatic vulnerability scanning upon image push"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS CMK used for ECR image encryption at-rest"
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "Maximum number of untagged/tagged images to retain in lifecycle policy"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
