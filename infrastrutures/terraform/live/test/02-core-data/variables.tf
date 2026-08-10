variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type    = string
  default = "datablue-test-core"
}

variable "aws_account_id" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "mysql_instance_class" {
  type        = string
  default     = "db.t4g.medium"
  description = "RDS MySQL Instance Class per environment"
}

variable "redis_node_type" {
  type        = string
  default     = "cache.t4g.small"
  description = "ElastiCache Redis Node Type per environment"
}

variable "mq_instance_type" {
  type        = string
  default     = "mq.m7g.medium"
  description = "Amazon MQ Instance Type per environment"
}
