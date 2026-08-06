# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: VPC (Networking & Subnet Topology)
# File: outputs.tf
# Description: Module output exports for downstream dependencies (EKS, RDS, Redis, OpenSearch).
# ==============================================================================

output "vpc_id" {
  description = "ID of the initialized VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of Public Subnet IDs (ALB & NAT Gateways)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of Private App Subnet IDs (EKS Nodes & Pods)"
  value       = aws_subnet.private_app[*].id
}

output "database_subnet_ids" {
  description = "List of Isolated Database Subnet IDs (RDS, Redis, MQ, DocumentDB)"
  value       = aws_subnet.database[*].id
}

output "db_subnet_group_name" {
  description = "Database Subnet Group name for RDS MySQL & DocumentDB"
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "nat_public_ips" {
  description = "List of Elastic Public IPs assigned to NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the Public Subnets Route Table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "List of Route Table IDs for Private App Subnets"
  value       = aws_route_table.private_app[*].id
}

output "database_route_table_id" {
  description = "ID of the Isolated Database Subnets Route Table"
  value       = aws_route_table.database.id
}

