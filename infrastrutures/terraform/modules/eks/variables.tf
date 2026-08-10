variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "instance_type" {
  type        = string
  description = "EKS Node Group Instance Type (must be specified per environment)"
}

variable "min_size" {
  type        = number
  description = "Minimum size of EKS node group (must be specified per environment)"
}

variable "max_size" {
  type        = number
  description = "Maximum size of EKS node group (must be specified per environment)"
}

variable "desired_size" {
  type        = number
  description = "Desired size of EKS node group (must be specified per environment)"
}

variable "cluster_service_ipv4_cidr" {
  type        = string
  default     = "172.20.0.0/16"
  description = "The CIDR block to assign Kubernetes service IP addresses from"
}

variable "tags" {
  type    = map(string)
  default = {}
}

