variable "project_name" {
  type    = string
}

variable "env" {
  type = string
}

variable "ami" {
  type    = string
}

variable "vpc_id" {
  type    = string
}

variable "ecs_iam_instance_profile" {
  type    = string
}

variable "alb_security_group" {
  type    = string
}

variable "instance_type" {
  type    = string
}

variable "volume_size" {
  type    = number
}

variable "public_subnets" {
  type    = list(string)
}

variable "private_subnets" {
  type    = list(string)
}

variable "target_groups" {
  type = map(object({
    arn = string
  }))
}

variable "max_size" {
  type    = number
}

variable "min_size" {
  type    = number
}

variable "account" {
  type    = string
}

variable "region" {
  type    = string
}

variable "service_config" {
  type = map(object({
    is_fargate          = bool
    is_public           = bool
    name                = string
    container_port      = number
    host_port           = number
    cpu                 = number
    memory              = number
    desired_count       = number
    enable_environments = bool
    environments        = map(string)

    alb_target_group = object({
    port                = number
    protocol            = string
    path_pattern        = list(string)
    health_check_path   = string
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout             = number
    interval            = number
    priority            = number
    })

    auto_scaling = object({
      max_capacity = number
      min_capacity = number
      cpu          = object({
        target_value = number
      })
      memory = object({
        target_value = number
      })
    })
  }))
}

variable "execution_role_arn" {
  type = string
}

variable "ecs_role_policy" {
  type = any
}

variable "maximum_scaling_step_size" {
  type    = number
}

variable "minimum_scaling_step_size" {
  type    = number
}

variable "target_capacity" {
  type    = number
}

