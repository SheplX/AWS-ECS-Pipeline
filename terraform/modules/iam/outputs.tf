output "ecs_iam_instance_profile" {
  value = aws_iam_instance_profile.ecs_iam_instance_profile.name
}

output "ecs_role_policy" {
  value = aws_iam_role_policy_attachment.ecs_role_policy
}

output "execution_role_arn" {
  value = aws_iam_role.ecs_task_manage_role.arn
}