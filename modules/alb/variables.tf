variable "project_name" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "target_groups" {
  type = map(object({
    port                = number
    protocol            = string
    path_pattern        = list(string)
    health_check_path   = string
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout             = number
    interval            = number
    priority            = number
  }))
}
