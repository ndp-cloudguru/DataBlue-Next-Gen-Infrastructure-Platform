variable "repositories" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "keep_last_images" {
  type    = number
  default = 10
}

variable "tags" {
  type    = map(string)
  default = {}
}
