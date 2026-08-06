# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: Amazon MQ RabbitMQ (Message Broker)
# File: variables.tf
# Description: Variable definitions cho Amazon MQ RabbitMQ.
# ==============================================================================

variable "environment" {
  description = "Tên môi trường (Test, Production)"
  type        = string
}

variable "broker_name" {
  description = "Tên nhận diện của RabbitMQ Broker (ví dụ: datablue-prod-rabbitmq)"
  type        = string
}

variable "host_instance_type" {
  description = "Loại EC2 Instance Host (mq.t3.micro cho Test, mq.m6g.large cho Prod Baseline)"
  type        = string
  default     = "mq.m6g.large"
}

variable "deployment_mode" {
  description = "Chế độ triển khai (SINGLE_INSTANCE hoặc CLUSTER_MULTI_AZ)"
  type        = string
  default     = "CLUSTER_MULTI_AZ"
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Danh sách Database Subnet IDs cách ly (tối thiểu 2 hoặc 3 subnet cho Multi-AZ Broker)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "Danh sách CIDRs truy cập cổng 5671 (AMQP TLS) và 15671 (RabbitMQ Management)"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN khóa KMS CMK mã hóa dữ liệu RabbitMQ At-Rest"
  type        = string
}

variable "admin_username" {
  description = "Tên tài khoản quản trị RabbitMQ Master"
  type        = string
  default     = "databue_mq_admin"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
