resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${var.env}-ecs-cluster"

  tags = {
    Name        = "${var.project_name}-cluster"
    Env         = var.env
  }
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
  name   = "${var.project_name}-${var.env}-ecs-service-security-group"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
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
  name              = "${var.project_name}-${var.env}-ecs-tg"
  port              = 80
  protocol          = "HTTP"
  vpc_id            = var.vpc_id
}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = "${var.project_name}-${var.env}-ecs-capacity-provider"
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

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "${var.project_name}-${var.env}-ecs-launch-configuration"
  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp2"
  }

}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name                      = "${var.project_name}-${var.env}-ecs-asg"
  vpc_zone_identifier       = var.private_subnets
  target_group_arns         = [aws_lb_target_group.ecs_asg_tg.arn]
  max_size                  = var.max_size
  min_size                  = var.min_size
  launch_configuration      = aws_launch_configuration.ecs_launch_configuration.name
  health_check_grace_period = 60

  termination_policies = ["NewestInstance", "Default"]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.env}-ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs_group" {
  for_each = toset(keys(var.service_config))
  name     = lower("${each.key}-logs")
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  for_each                 = var.service_config
  family                   = "${var.project_name}-${each.key}"
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
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-group         = "${lower(each.value["name"])}-logs"
          awslogs-region        = var.region
          awslogs-stream-prefix = var.project_name
        }
      }
    }
  ])
}

data "aws_ecs_task_definition" "task_definitions" {
  for_each        = var.service_config
  task_definition = aws_ecs_task_definition.ecs_task_definition[each.key].arn
}

resource "aws_ecs_service" "ecs_services" {
  for_each                = var.service_config
  name                    = "${each.value.name}"
  cluster                 = aws_ecs_cluster.ecs_cluster.id
  depends_on              = [var.ecs_role_policy]
  task_definition         = "${data.aws_ecs_task_definition.task_definitions[each.key].family}:${data.aws_ecs_task_definition.task_definitions[each.key].revision}"
  desired_count           = each.value.desired_count
  launch_type             = each.value.is_fargate ? "FARGATE" : null
  force_new_deployment    = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

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
      subnets          = each.value.is_public == true ? var.public_subnets : var.private_subnets
      assign_public_ip = each.value.is_public == true ? true : false
    }
  }

  load_balancer {
    target_group_arn = var.target_groups[each.key].arn
    container_name   = each.value.name
    container_port   = each.value.container_port
  }
}

resource "aws_appautoscaling_target" "service_autoscaling" {
  for_each           = var.service_config
  max_capacity       = each.value.auto_scaling.max_capacity
  min_capacity       = each.value.auto_scaling.min_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  for_each           = var.service_config
  name               = "${var.project_name}-${var.env}-ecs-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service_autoscaling[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service_autoscaling[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_autoscaling[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = each.value.auto_scaling.memory.target_value
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  for_each           = var.service_config
  name               = "${var.project_name}-${var.env}-ecs-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service_autoscaling[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service_autoscaling[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_autoscaling[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = each.value.auto_scaling.cpu.target_value
  }
}
