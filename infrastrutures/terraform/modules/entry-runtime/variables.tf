variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "image" {
  type    = string
  default = "nginx:1.27-alpine"
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "container_port" {
  type    = number
  default = 80
}

variable "upstream_host" {
  type    = string
  default = "core.internal"
}

variable "upstream_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type        = number
  description = "Fargate Task CPU units (must be specified per environment)"
}

variable "memory" {
  type        = number
  description = "Fargate Task Memory in MiB (must be specified per environment)"
}

variable "desired_count" {
  type        = number
  description = "Fargate Service desired task count (must be specified per environment)"
}

variable "tags" {
  type    = map(string)
  default = {}
}
