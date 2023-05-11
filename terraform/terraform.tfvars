# project

project_name = "pipeline"
env          = "dev"
account      = 123456789
region       = "eu-central-1"

# network module

cidr_block                 = "10.0.0.0/16"
public_subnets             = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets            = ["10.0.20.0/24", "10.0.21.0/24"]
subnet_availability_zones  = ["eu-central-1a", "eu-central-1b"]

# ecr module

ecr_repositories          = ["service-a", "service-b"]

# alb security group module

alb_security_group = {
  name      = "alb-security-group"
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# alb & ECS module

service_config = {
  "service-a" = {
    is_fargate          = false
    is_public           = true
    name                = "service-a"
    container_port      = 5000
    host_port           = 5000
    cpu                 = 256
    memory              = 512
    desired_count       = 2
    enable_environments = true
    environments      = {
      NODE_ENV         = "dev"
      PORT             = 5000 
      MEDICAL_SERVICE  = "Medical"
      SECURITY_SERVICE = "Security"
      LAUNCH_TYPE      = "EC2"
    }
    alb_target_group = {
      port                  = 80
      protocol              = "HTTP"
      health_check_path     = "/healthcheck"
      # healthy_threshold     = 2
      # unhealthy_threshold   = 4
      # timeout               = 120
      # interval              = 130
      path_pattern          = ["/medical*", "/security*"]
      priority              = 1
    }
    auto_scaling = {
      max_capacity = 2
      min_capacity = 1
      cpu          = {
        target_value = 75
      }
      memory = {
        target_value = 75
      }
    }
  },
  "service-b" = {
    is_fargate          = true
    is_public           = false
    name                = "service-b"
    container_port      = 5001
    host_port           = 5001
    cpu                 = 256
    memory              = 512
    desired_count       = 2
    enable_environments = true
    environments      = {
      NODE_ENV         = "dev"
      PORT             = 5001 
      FINANCE_SERVICE  = "Finance"
      PAYMENT_SERVICE  = "Payment"
      LAUNCH_TYPE      = "Fargate"
    }
    alb_target_group = {
      port                  = 80
      protocol              = "HTTP"
      health_check_path     = "/healthcheck"
      # healthy_threshold     = 2
      # unhealthy_threshold   = 4
      # timeout               = 120
      # interval              = 130
      path_pattern          = ["/payment*", "/finance*"]
      priority              = 2
    }
    auto_scaling = {
      max_capacity = 2
      min_capacity = 1
      cpu          = {
        target_value = 75
      }
      memory = {
        target_value = 75
      }
    }
  }
}

ami                                         = "amzn2-ami-ecs-hvm-2.0.202*-x86_64-ebs"
instance_type                               = "t3.micro"
volume_size                                 = 30
autoscaling_max_size                        = 40
autoscaling_min_size                        = 0
capacity_provider_maximum_scaling_step      = 5
capacity_provider_minimum_scaling_step      = 1
capacity_provider_target_capacity           = 100

# route53 module
hosted_zone = "example.com"
record_name = "microservices"
