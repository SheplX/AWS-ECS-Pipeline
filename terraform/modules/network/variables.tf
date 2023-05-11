variable "cidr_block" {
  type    = string
}

variable "project_name" {
  type    = string
}

variable "env" {
  type    = string
}

variable "public_subnets" {
  type    = list(string)
}

variable "private_subnets" {
  type    = list(string)
}

variable "subnet_availability_zones" {
  type    = list(string)
}
