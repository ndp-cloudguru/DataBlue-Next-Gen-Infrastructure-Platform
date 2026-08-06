# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: ECR (Elastic Container Registry)
# File: main.tf
# Description: ECR Repositories with KMS Encryption, Image Scanning & Lifecycle Policies.
# Architecture Ref: SEC-001 (KMS Encryption), SEC-005 (Image Vulnerability Scanning)
# ==============================================================================

# 1. ECR Repositories
resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repository_names)
  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  tags = merge(
    var.tags,
    {
      Name        = each.value
      Environment = var.environment
    }
  )
}

# 2. Lifecycle Policy to clean up old images and control storage costs
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = toset(var.repository_names)
  repository = aws_ecr_repository.this[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
