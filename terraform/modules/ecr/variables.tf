variable "project_name" {
  type = string
}

variable "ecr_repositories" {
  type = list(string)
}

variable "env" {
  type = string
}