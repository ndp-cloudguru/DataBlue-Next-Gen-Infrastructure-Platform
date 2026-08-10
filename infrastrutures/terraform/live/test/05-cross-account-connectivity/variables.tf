variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "core_profile" {
  type    = string
  default = "datablue-test-core"
}

variable "entry_profile" {
  type    = string
  default = "datablue-test-entry"
}

variable "core_account_id" {
  type = string
}

variable "entry_account_id" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "core_app_port" {
  type    = number
  default = 8080
}
