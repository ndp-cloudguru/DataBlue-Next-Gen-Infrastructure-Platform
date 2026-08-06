# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: RDS MySQL (Relational Database Service)
# File: variables.tf
# Description: Variable definitions cho Amazon RDS MySQL Multi-AZ.
# ==============================================================================

variable "environment" {
  description = "Tên môi trường (Test, Production, DevTest)"
  type        = string
}

variable "identifier" {
  description = "Identifier duy nhất cho RDS Instance (ví dụ: datablue-prod-mysql)"
  type        = string
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Tên Database Subnet Group (cách ly hoàn toàn khỏi Internet)"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "Danh sách dải CIDR được phép kết nối MySQL (thường là Private App Subnet CIDRs)"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN của khóa KMS CMK dùng mã hóa RDS Storage"
  type        = string
}

variable "instance_class" {
  description = "Loại Instance RDS (ví dụ: db.m6g.large cho Test, db.m6g.xlarge cho Prod)"
  type        = string
  default     = "db.m6g.large"
}

variable "allocated_storage" {
  description = "Dung lượng lưu trữ ban đầu (GB)"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Dung lượng tự động mở rộng tối đa (Autoscaling GB)"
  type        = number
  default     = 500
}

variable "multi_az" {
  description = "Kích hoạt Multi-AZ High Availability (Primary + Standby với tự động failover < 60s)"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Tên cơ sở dữ liệu mặc định ban đầu"
  type        = string
  default     = "datablue_db"
}

variable "admin_username" {
  description = "Tên tài khoản quản trị DB Master"
  type        = string
  default     = "admin_databue"
}

variable "backup_retention_period" {
  description = "Số ngày lưu trữ bản sao lưu PITR (30 ngày chuẩn sản xuất theo ADR-006 / ADR-013)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
