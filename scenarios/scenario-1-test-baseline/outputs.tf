# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 1: Test Environment Baseline (Singapore Region ap-southeast-1)
# File: outputs.tf
# Description: Output definitions for Test Environment scenario.
# ==============================================================================

output "kms_key_arn" {
  description = "ARN of the KMS Customer Managed Key"
  value       = module.kms.key_arn
}

output "test_core_vpc_id" {
  description = "VPC ID of Account 1 Test Core VPC (10.50.0.0/16)"
  value       = module.test_core_vpc.vpc_id
}

output "test_entry_vpc_id" {
  description = "VPC ID of Account 4 Test Entry VPC (10.40.0.0/16)"
  value       = module.test_entry_vpc.vpc_id
}

output "vpc_peering_connection_id" {
  description = "Direct VPC Peering Connection ID connecting Test Entry and Test Core"
  value       = aws_vpc_peering_connection.test_peering.id
}

output "eks_cluster_name" {
  description = "Name of the EKS Test Cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API Endpoint for EKS Test Control Plane"
  value       = module.eks.cluster_endpoint
}

output "rds_mysql_endpoint" {
  description = "Endpoint for RDS MySQL Single-AZ Test Database (db.t4g.medium)"
  value       = module.rds_mysql.db_instance_endpoint
}

output "rds_mysql_master_password" {
  description = "Randomly generated Master Password for RDS MySQL (Sensitive)"
  value       = module.rds_mysql.db_master_password
  sensitive   = true
}

output "rds_mysql_secret_arn" {
  description = "ARN of the AWS Secrets Manager Secret storing RDS MySQL Master Credentials"
  value       = module.rds_mysql.secretsmanager_secret_arn
}

output "rds_mysql_secret_name" {
  description = "Name of the AWS Secrets Manager Secret storing RDS MySQL Master Credentials"
  value       = module.rds_mysql.secretsmanager_secret_name
}



output "redis_primary_endpoint" {
  description = "Endpoint for ElastiCache Redis Test Cache (cache.t4g.small)"
  value       = module.elasticache_redis.primary_endpoint_address
}

output "redis_auth_token" {
  description = "Randomly generated AUTH Token (Password) for ElastiCache Redis (Sensitive)"
  value       = module.elasticache_redis.redis_auth_token
  sensitive   = true
}


output "rabbitmq_amqp_endpoints" {
  description = "Endpoints for Amazon MQ RabbitMQ Test Broker (mq.t3.micro)"
  value       = module.amazon_mq_rabbitmq.amqp_endpoints
}

output "test_nlb_dns_name" {
  description = "DNS Name of the Public NLB for Account 4 Test Entry"
  value       = aws_lb.test_entry_nlb.dns_name
}

output "ecs_fargate_proxy_cluster_name" {
  description = "Name of the ECS Cluster hosting Fargate Test Entry Proxy"
  value       = aws_ecs_cluster.test_entry.name
}

output "ecs_fargate_proxy_service_name" {
  description = "Name of the ECS Fargate Test Entry Proxy Service"
  value       = aws_ecs_service.fargate_proxy.name
}

output "ecs_fargate_proxy_task_definition" {
  description = "ARN of the ECS Fargate Test Proxy Task Definition"
  value       = aws_ecs_task_definition.fargate_proxy.arn
}

output "ecr_repository_urls" {
  description = "Map of ECR repository names and their URLs for Test environment"
  value       = module.ecr.repository_urls
}

# ─── NETWORK SUBNET LAYERS OUTPUTS ───────────────────────────────────────────
output "test_core_public_subnet_ids" {
  description = "List of Public Subnet IDs in Account 1 Test Core VPC (10.50.1.0/24, 10.50.2.0/24)"
  value       = module.test_core_vpc.public_subnet_ids
}

output "test_core_private_app_subnet_ids" {
  description = "List of Private App Subnet IDs in Account 1 Test Core VPC (10.50.10.0/24, 10.50.20.0/24)"
  value       = module.test_core_vpc.private_app_subnet_ids
}

output "test_core_database_subnet_ids" {
  description = "List of Isolated DB Subnet IDs in Account 1 Test Core VPC (10.50.100.0/24, 10.50.200.0/24)"
  value       = module.test_core_vpc.database_subnet_ids
}

output "test_entry_public_subnet_ids" {
  description = "List of Public Subnet IDs in Account 4 Test Entry VPC (10.40.1.0/24, 10.40.2.0/24)"
  value       = module.test_entry_vpc.public_subnet_ids
}

output "test_entry_private_app_subnet_ids" {
  description = "List of Private App Subnet IDs in Account 4 Test Entry VPC (10.40.10.0/24, 10.40.20.0/24)"
  value       = module.test_entry_vpc.private_app_subnet_ids
}



