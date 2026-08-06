# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: KMS (Key Management Service)
# File: main.tf
# Description: Initializes AWS KMS Customer Managed Key (CMK) for At-Rest Encryption.
# Architecture Ref: SEC-003 (KMS CMK Encryption Standard for EBS, RDS, S3, Secrets Manager)
# ==============================================================================

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-KMS-CMK"
    }
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/databue-${lower(var.environment)}-cmk"
  target_key_id = aws_kms_key.this.key_id
}
