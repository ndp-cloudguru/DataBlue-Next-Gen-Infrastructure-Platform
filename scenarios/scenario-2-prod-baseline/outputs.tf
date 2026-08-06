# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 2: Production Early-Start Environment ($2,096.49 / month)
# File: outputs.tf
# Description: Output definitions for Production Early-Start scenario.
# Governance Ref: TERRAFORM_PROD_EARLYSTART_PLANNING.md
# ==============================================================================

output "kms_key_arn" {
  description = "ARN of the KMS Customer Managed Key for Production"
  value       = module.kms.key_arn
}

output "prod_core_vpc_id" {
  description = "VPC ID of Account 1 Production Core VPC (10.10.0.0/16)"
  value       = module.prod_core_vpc.vpc_id
}

output "prod_entry_a_vpc_id" {
  description = "VPC ID of Account 2 Production Entry A VPC (10.20.0.0/16)"
  value       = module.prod_entry_a_vpc.vpc_id
}

output "prod_entry_b_vpc_id" {
  description = "VPC ID of Account 3 Production Entry B VPC (10.30.0.0/16)"
  value       = module.prod_entry_b_vpc.vpc_id
}

output "transit_gateway_id" {
  description = "ID of AWS Transit Gateway Hub connecting Prod Core and Entry A & B"
  value       = aws_ec2_transit_gateway.prod_tgw.id
}

output "transit_gateway_arn" {
  description = "ARN of AWS Transit Gateway Hub"
  value       = aws_ec2_transit_gateway.prod_tgw.arn
}

output "transit_gateway_attachment_core_id" {
  description = "Transit Gateway VPC Attachment ID for Account 1 Prod Core VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.core_tgw_attachment.id
}

output "transit_gateway_attachment_entry_a_id" {
  description = "Transit Gateway VPC Attachment ID for Account 2 Prod Entry A VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.entry_a_tgw_attachment.id
}

output "transit_gateway_attachment_entry_b_id" {
  description = "Transit Gateway VPC Attachment ID for Account 3 Prod Entry B VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.entry_b_tgw_attachment.id
}


output "eks_cluster_name" {
  description = "Name of the Production EKS Cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API Endpoint for Production EKS Control Plane"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "Map of Production ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "rds_mysql_endpoint" {
  description = "Endpoint for RDS MySQL Multi-AZ Production Database (db.t4g.xlarge 200GB GP3)"
  value       = module.rds_mysql.db_instance_endpoint
}

output "rds_mysql_master_password" {
  description = "Randomly generated Master Password for Production RDS MySQL (Sensitive)"
  value       = module.rds_mysql.db_master_password
  sensitive   = true
}

output "rds_mysql_secret_arn" {
  description = "ARN of the AWS Secrets Manager Secret storing Production RDS MySQL Credentials"
  value       = module.rds_mysql.secretsmanager_secret_arn
}

output "rds_mysql_secret_name" {
  description = "Name of the AWS Secrets Manager Secret storing Production RDS MySQL Credentials"
  value       = module.rds_mysql.secretsmanager_secret_name
}


output "redis_primary_endpoint" {
  description = "Primary Endpoint for ElastiCache Redis Production Cluster (cache.t4g.large 2-Node)"
  value       = module.elasticache_redis.primary_endpoint_address
}

output "redis_auth_token" {
  description = "Randomly generated AUTH Token (Password) for ElastiCache Redis (Sensitive)"
  value       = module.elasticache_redis.redis_auth_token
  sensitive   = true
}

output "rabbitmq_amqp_endpoints" {
  description = "Endpoints for Amazon MQ RabbitMQ Production Active/Standby Broker (mq.m5.small)"
  value       = module.amazon_mq_rabbitmq.amqp_endpoints
}

output "prod_entry_a_nlb_dns_name" {
  description = "DNS Name of Public NLB A for Account 2 Prod Entry A"
  value       = aws_lb.prod_entry_a_nlb.dns_name
}

output "prod_entry_b_nlb_dns_name" {
  description = "DNS Name of Public NLB B for Account 3 Prod Entry B (Standby)"
  value       = aws_lb.prod_entry_b_nlb.dns_name
}

# ─── NETWORK SUBNET LAYERS OUTPUTS ───────────────────────────────────────────
output "prod_core_public_subnet_ids" {
  description = "List of Public Subnet IDs in Account 1 Prod Core VPC (10.10.1.0/24, 10.10.2.0/24, 10.10.3.0/24)"
  value       = module.prod_core_vpc.public_subnet_ids
}

output "prod_core_private_app_subnet_ids" {
  description = "List of Private App Subnet IDs in Account 1 Prod Core VPC (10.10.10.0/24, 10.10.20.0/24, 10.10.30.0/24)"
  value       = module.prod_core_vpc.private_app_subnet_ids
}

output "prod_core_database_subnet_ids" {
  description = "List of Isolated DB Subnet IDs in Account 1 Prod Core VPC (10.10.100.0/24, 10.10.200.0/24, 10.10.300.0/24)"
  value       = module.prod_core_vpc.database_subnet_ids
}

output "prod_entry_a_public_subnet_ids" {
  description = "List of Public Subnet IDs in Account 2 Prod Entry A VPC (10.20.1.0/24, 10.20.2.0/24, 10.20.3.0/24)"
  value       = module.prod_entry_a_vpc.public_subnet_ids
}

output "prod_entry_a_private_app_subnet_ids" {
  description = "List of Private App Subnet IDs in Account 2 Prod Entry A VPC (10.20.10.0/24, 10.20.20.0/24, 10.20.30.0/24)"
  value       = module.prod_entry_a_vpc.private_app_subnet_ids
}

output "prod_entry_b_public_subnet_ids" {
  description = "List of Public Subnet IDs in Account 3 Prod Entry B VPC (10.30.1.0/24, 10.30.2.0/24, 10.30.3.0/24)"
  value       = module.prod_entry_b_vpc.public_subnet_ids
}

output "prod_entry_b_private_app_subnet_ids" {
  description = "List of Private App Subnet IDs in Account 3 Prod Entry B VPC (10.30.10.0/24, 10.30.20.0/24, 10.30.30.0/24)"
  value       = module.prod_entry_b_vpc.private_app_subnet_ids
}
