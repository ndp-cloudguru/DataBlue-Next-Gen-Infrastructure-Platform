# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: KMS (Key Management Service)
# File: variables.tf
# Description: Variable definitions cho AWS KMS CMK Encryption.
# ==============================================================================

variable "environment" {
  description = "Tên môi trường (Test, Production, v.v.)"
  type        = string
}

variable "description" {
  description = "Mô tả khóa KMS CMK"
  type        = string
  default     = "DataBlue Customer Managed Key (CMK) for encryption at rest"
}

variable "deletion_window_in_days" {
  description = "Thời gian chờ trước khi xóa vĩnh viễn khóa KMS (mặc định 30 ngày)"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Tự động xoay vòng khóa KMS định kỳ hàng năm (AWS Managed Rotation)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
