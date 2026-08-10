output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}

output "mq_sg_id" {
  value = aws_security_group.mq.id
}
