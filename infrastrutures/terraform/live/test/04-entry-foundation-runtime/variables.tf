variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type    = string
  default = "datablue-test-entry"
}

variable "aws_account_id" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "proxy_image" {
  type    = string
  default = "nginx:1.27-alpine"
}

variable "ecs_cpu" {
  type        = number
  default     = 1024
  description = "Fargate task CPU units per environment"
}

variable "ecs_memory" {
  type        = number
  default     = 2048
  description = "Fargate task Memory in MiB per environment"
}

variable "ecs_desired_count" {
  type        = number
  default     = 1
  description = "Fargate task desired count per environment"
}
