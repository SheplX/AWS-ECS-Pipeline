resource "aws_ecs_cluster" "ecs_cluster" {
  name = lower("${var.project_name}-cluster")
}

data "aws_ami" "ecs_cluster_ami" {
  filter {
    name   = "name"
    values = [var.ami]
  }

  most_recent = true
  owners      = ["amazon"]
}

resource "aws_security_group" "service_security_group" {
  name   = lower("${var.project_name}-service-security-group")
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [var.alb_security_group]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "ecs_asg_tg" {
  name              = lower("${var.project_name}-autoscaling-tg")
  port              = 80
  protocol          = "HTTP"
  vpc_id            = var.vpc_id

}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = lower("${var.project_name}-capacity-provider")
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling_group.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = var.maximum_scaling_step_size
      minimum_scaling_step_size = var.minimum_scaling_step_size
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_association" {
  cluster_name         = aws_ecs_cluster.ecs_cluster.name
  capacity_providers   = [aws_ecs_capacity_provider.capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider  = aws_ecs_capacity_provider.capacity_provider.name
    weight             = 0
    base               = 0
  }
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  associate_public_ip_address = true
  image_id                    = data.aws_ami.ecs_cluster_ami.id
  iam_instance_profile        = var.ecs_iam_instance_profile
  security_groups             = [aws_security_group.service_security_group.id]
  user_data                   = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config"
  instance_type               = var.instance_type
  key_name                    = var.key_name

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = lower("${var.project_name}-launch-configuration")
  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp2"
  }

}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name                      = lower("${var.project_name}-autoscaling-group")
  vpc_zone_identifier       = var.vpc_zone_identifier
  target_group_arns         = [aws_lb_target_group.ecs_asg_tg.arn]
  max_size                  = var.max_size
  min_size                  = var.min_size
  launch_configuration      = aws_launch_configuration.ecs_launch_configuration.name
  health_check_grace_period = 60

  termination_policies = ["NewestInstance", "Default"]

  tag {
    key                 = "Name"
    value               = lower("${var.project_name}-instance")
    propagate_at_launch = true
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  for_each                 = var.service_config
  family                   = "${lower(var.project_name)}-${each.key}"
  requires_compatibilities = each.value.is_fargate == true ? ["FARGATE"] : ["EC2"]
  network_mode             = each.value.is_fargate == true ? "awsvpc" : "bridge"
  execution_role_arn       = each.value.is_fargate == true ? var.execution_role_arn : null
  memory                   = each.value.memory
  cpu                      = each.value.cpu

  container_definitions = jsonencode([
    {
      name         = each.value.name
      image        = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${lower(var.project_name)}-${lower(each.value.name)}:latest"
      cpu          = each.value.cpu
      memory       = each.value.memory
      essential    = true
      portMappings = [
        {
          containerPort: each.value.container_port
          hostPort: each.value.host_port
        }
      ]
      environment = each.value.enable_environments ? [ for k, v in each.value.environments : { name = k, value = v } ] : []
    }
  ])
}

data "aws_ecs_task_definition" "task_definitions" {
  for_each        = var.service_config
  task_definition = aws_ecs_task_definition.ecs_task_definition[each.key].arn
}

resource "aws_ecs_service" "ecs_services" {
  for_each        = var.service_config
  name            = "${each.value.name}-Service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  depends_on      = [var.ecs_role_policy]
  task_definition = "${data.aws_ecs_task_definition.task_definitions[each.key].family}:${data.aws_ecs_task_definition.task_definitions[each.key].revision}"
  desired_count   = each.value.desired_count
  launch_type     = each.value.is_fargate == true ? "FARGATE" : "EC2"

  dynamic "capacity_provider_strategy" {
    for_each = each.value.is_fargate == true ? [] : [1]
    content {
      capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
      weight            = 1
    }
  }

  dynamic "network_configuration" {
    for_each = each.value.is_fargate == true ? [1] : []
    content {
      security_groups  = [aws_security_group.service_security_group.id]
      subnets          = var.vpc_zone_identifier
    }
  }

  load_balancer {
    target_group_arn = var.target_groups[each.key].arn
    container_name   = each.value.name
    container_port   = each.value.container_port
  }
}