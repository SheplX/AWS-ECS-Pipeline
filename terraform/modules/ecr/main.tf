resource "aws_ecr_repository" "ecr_repository" {
  for_each = toset(var.ecr_repositories)
  name     = "${var.project_name}-${each.key}"

  tags = {
    Name        = "${var.project_name}-ecr"
    Environment =  var.env
  }
}