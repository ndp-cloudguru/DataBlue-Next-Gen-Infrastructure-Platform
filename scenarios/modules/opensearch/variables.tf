# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: Amazon OpenSearch Service (Log Analytics & Search Engine)
# File: variables.tf
# Description: Variable definitions cho Amazon OpenSearch Service.
# ==============================================================================

variable "environment" {
  description = "Tên môi trường (Test, Production)"
  type        = string
}

variable "domain_name" {
  description = "Tên OpenSearch Domain (ví dụ: datablue-prod-opensearch)"
  type        = string
}

variable "instance_type" {
  description = "Loại Instance Node (search.m6g.large cho Test, r6g.large.search cho Prod)"
  type        = string
  default     = "r6g.large.search"
}

variable "instance_count" {
  description = "Số lượng Data Nodes (1 cho Test, 2 cho Prod 2-AZ, 4 cho High-Scale)"
  type        = number
  default     = 2
}

variable "ebs_volume_size" {
  description = "Dung lượng EBS gp3 per node (GB)"
  type        = number
  default     = 100
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Danh sách Private App Subnet IDs cho OpenSearch Nodes"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "Danh sách CIDR truy cập OpenSearch (Fluent Bit & Grafana)"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN khóa KMS CMK mã hóa OpenSearch Storage At-Rest"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
