# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: ElastiCache Redis (In-Memory Cache)
# File: variables.tf
# Description: Variable definitions cho Amazon ElastiCache Redis.
# ==============================================================================

variable "environment" {
  description = "Tên môi trường (Test, Production)"
  type        = string
}

variable "replication_group_id" {
  description = "Identifier duy nhất cho Replication Group (ví dụ: datablue-prod-redis)"
  type        = string
}

variable "node_type" {
  description = "Loại Instance Node (ví dụ: cache.t4g.medium cho Test, cache.m6g.large cho Prod)"
  type        = string
  default     = "cache.m6g.large"
}

variable "num_cache_clusters" {
  description = "Số lượng node trong Replication Group (tối thiểu 2 node cho Multi-AZ Failover)"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Danh sách Database Subnet IDs cách ly"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "Danh sách dải CIDR được phép truy cập cổng 6379 (Private App Subnets)"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN của khóa KMS CMK mã hóa dữ liệu Redis At-Rest"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
