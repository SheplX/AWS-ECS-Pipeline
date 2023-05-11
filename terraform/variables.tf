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

variable "ecr_repositories" {
  type = list(string)
}


variable "alb_security_group" {
  type = object({
    name          = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  })
}

variable "hosted_zone" {
  type = string
}

variable "record_name" {
  type = string
}

variable "ami" {
  type    = string
}

variable "instance_type" {
  type    = string
}

variable "volume_size" {
  type    = number
}

variable "autoscaling_max_size" {
  type    = number
}

variable "autoscaling_min_size" {
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
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      timeout             = optional(number)
      interval            = optional(number)
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

variable "capacity_provider_maximum_scaling_step" {
  type    = number
}

variable "capacity_provider_minimum_scaling_step" {
  type    = number
}

variable "capacity_provider_target_capacity" {
  type    = number
}
