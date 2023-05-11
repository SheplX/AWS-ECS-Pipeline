variable "project_name" {
  type = string
}

variable "env" {
  type    = string
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
    alb_target_group = object({
      port                 = number
      protocol             = string
      health_check_path    = string
      healthy_threshold    = optional(number)
      unhealthy_threshold  = optional(number)
      timeout              = optional(number)
      interval             = optional(number)
      priority             = number
      path_pattern         = list(string)
    })
    is_fargate = bool
  }))
}
