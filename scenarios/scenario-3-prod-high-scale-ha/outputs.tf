# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 3: Production Enhanced High Availability ($7,200 – $10,500 / month)
# File: outputs.tf
# Description: Comprehensive outputs for Scenario 3 deployment.
# ==============================================================================

output "kms_key_arn" {
  description = "ARN of the KMS Customer Managed Key for High-Scale Production HA"
  value       = module.kms.key_arn
}

output "vpc_id" {
  description = "VPC ID of the High-Scale Production VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API Endpoint for EKS Production HA Control Plane"
  value       = module.eks.cluster_endpoint
}

output "aurora_endpoint" {
  description = "Writer Endpoint for Amazon Aurora MySQL Cluster (3 Replicas)"
  value       = module.aurora_mysql.cluster_endpoint
}

output "redis_primary_endpoint" {
  description = "Endpoint for ElastiCache Redis Sharded Cluster"
  value       = module.elasticache_redis.primary_endpoint_address
}

output "rabbitmq_amqp_endpoints" {
  description = "Endpoints for Amazon MQ RabbitMQ Broker"
  value       = module.amazon_mq_rabbitmq.amqp_endpoints
}

output "documentdb_endpoint" {
  description = "Endpoint for DocumentDB 3-Node Cluster"
  value       = module.documentdb.endpoint
}

output "opensearch_endpoint" {
  description = "Domain Endpoint for OpenSearch 4-Node Cluster"
  value       = module.opensearch.domain_endpoint
}
