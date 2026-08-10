variable "name" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "3.13"
}

variable "instance_type" {
  type        = string
  description = "Amazon MQ Instance Type (must be specified per environment)"
}

variable "username" {
  type    = string
  default = "datablue"
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
