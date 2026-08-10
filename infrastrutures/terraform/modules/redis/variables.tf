variable "name" {
  type = string
}

variable "node_type" {
  type        = string
  description = "ElastiCache Redis Node Type (must be specified per environment)"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
