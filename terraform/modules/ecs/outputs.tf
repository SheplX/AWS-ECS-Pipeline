output "auto_scaling_group_arn" {
  value       = aws_autoscaling_group.ecs_autoscaling_group.arn
}

output "cluster_name" {
  value       = aws_ecs_cluster.ecs_cluster.name
}
