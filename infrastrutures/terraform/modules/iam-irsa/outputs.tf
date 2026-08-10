output "role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN of created IRSA IAM Role"
}

output "role_name" {
  value       = aws_iam_role.this.name
  description = "Name of created IRSA IAM Role"
}
