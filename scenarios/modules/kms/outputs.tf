# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: KMS (Key Management Service)
# File: outputs.tf
# Description: Output xuất KMS Key ARN & Key ID dùng mã hóa tài nguyên.
# ==============================================================================

output "key_arn" {
  description = "ARN của khóa KMS CMK"
  value       = aws_kms_key.this.arn
}

output "key_id" {
  description = "ID của khóa KMS CMK"
  value       = aws_kms_key.this.key_id
}

output "key_alias_arn" {
  description = "ARN của KMS Alias"
  value       = aws_kms_alias.this.arn
}
