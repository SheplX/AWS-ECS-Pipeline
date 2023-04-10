resource "aws_lb" "ecs_alb" {
  name               = lower("${var.project_name}-alb")
  subnets            = var.subnets
  security_groups    = var.security_groups
}

resource "aws_lb_target_group" "alb_target_group" {
  for_each  = var.target_groups
  name      = "${lower(each.key)}-tg"
  port      = each.value.port
  protocol  = each.value.protocol
  vpc_id    = var.vpc_id

  health_check {
    path                = each.value.health_check_path
    healthy_threshold   = each.value.healthy_threshold
    unhealthy_threshold = each.value.unhealthy_threshold
    timeout             = each.value.timeout
    interval            = each.value.interval
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
  priority     = each.value.priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path_pattern
    }
  }
}