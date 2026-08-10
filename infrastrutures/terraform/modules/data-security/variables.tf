variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_cidrs" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
