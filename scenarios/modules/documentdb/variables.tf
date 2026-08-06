# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: DocumentDB (MongoDB API Compatible Document Store)
# File: variables.tf
# Description: Variable definitions cho Amazon DocumentDB.
# ==============================================================================

variable "environment" {
  description = "Tên môi trường (Test, Production)"
  type        = string
}

variable "cluster_identifier" {
  description = "Identifier duy nhất cho DocumentDB Cluster (ví dụ: datablue-prod-docdb)"
  type        = string
}

variable "instance_class" {
  description = "Loại Instance Node (db.t4g.medium cho Test, db.r6g.xlarge cho Prod Baseline)"
  type        = string
  default     = "db.r6g.xlarge"
}

variable "instance_count" {
  description = "Số lượng Instance trong Cluster (tối thiểu 2 cho Test, 3 cho Prod 3-AZ)"
  type        = number
  default     = 3
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Tên Database Subnet Group"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "Danh sách CIDR được phép kết nối MongoDB protocol (cổng 27017)"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN khóa KMS CMK mã hóa dữ liệu DocumentDB At-Rest"
  type        = string
}

variable "admin_username" {
  description = "Tên tài khoản Master Administrator"
  type        = string
  default     = "databue_docdb_admin"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
