variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type    = string
  default = "datablue-test-core"
}

variable "aws_account_id" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "eks_node_instance_type" {
  type        = string
  default     = "t4g.large"
  description = "EKS Node Group Instance Type per environment"
}

variable "eks_min_size" {
  type        = number
  default     = 2
  description = "EKS Node Group minimum size"
}

variable "eks_max_size" {
  type        = number
  default     = 4
  description = "EKS Node Group maximum size"
}

variable "eks_desired_size" {
  type        = number
  default     = 4
  description = "EKS Node Group desired size"
}
