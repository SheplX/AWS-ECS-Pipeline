output "alb" {
  value = aws_lb.ecs_alb
}

output "target_groups" {
  value = aws_lb_target_group.alb_target_group
}