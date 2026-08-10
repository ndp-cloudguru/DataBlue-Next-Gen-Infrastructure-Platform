output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_address" {
  value = module.rds.address
}

output "rds_secret_arn" {
  value = module.rds.secret_arn
}

output "redis_primary_endpoint" {
  value = module.redis.primary_endpoint
}

output "redis_secret_arn" {
  value = module.redis.secret_arn
}

output "rabbitmq_amqp_endpoints" {
  value = module.mq.amqp_endpoints
}

output "rabbitmq_secret_arn" {
  value = module.mq.secret_arn
}
