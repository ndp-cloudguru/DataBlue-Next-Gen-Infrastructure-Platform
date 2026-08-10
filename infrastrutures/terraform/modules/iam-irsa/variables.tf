variable "role_name" {
  type        = string
  description = "IAM Role Name"
}

variable "oidc_provider_arn" {
  type        = string
  description = "EKS OIDC Provider ARN"
}

variable "oidc_issuer_url" {
  type        = string
  description = "EKS OIDC Issuer URL"
}

variable "service_account_namespace" {
  type        = string
  description = "Kubernetes Namespace"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes ServiceAccount Name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags"
}
