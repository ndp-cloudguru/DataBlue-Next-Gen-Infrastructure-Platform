variable "identifier" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type        = string
  description = "RDS MySQL Instance Class (must be specified per environment)"
}

variable "allocated_storage" {
  type        = number
  default     = 100
  description = "Allocated storage in GB"
}

variable "db_name" {
  type    = string
  default = "datablue_db"
}

variable "username" {
  type    = string
  default = "admin_datablue"
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

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
