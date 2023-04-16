resource "aws_lb" "ecs_alb" {
  name               = lower("${var.project_name}-alb")
  subnets            = var.subnets
  security_groups    = var.security_groups
}

resource "aws_lb_target_group" "alb_target_group" {
  for_each    = var.target_groups
  name        = "${lower(each.key)}-tg"
  port        = each.value.alb_target_group.port
  protocol    = each.value.alb_target_group.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.is_fargate == true ? "ip" : "instance"

  health_check {
    path                = each.value.alb_target_group.health_check_path
    healthy_threshold   = each.value.alb_target_group.healthy_threshold
    unhealthy_threshold = each.value.alb_target_group.unhealthy_threshold
    timeout             = each.value.alb_target_group.timeout
    interval            = each.value.alb_target_group.interval
    matcher             = "200"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No routes defined"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  for_each     = var.target_groups
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = each.value.alb_target_group.priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.alb_target_group.path_pattern
    }
  }
}