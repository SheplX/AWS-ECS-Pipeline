terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "state/terraform_state.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

module "network" {
  source = "./modules/network"
  project_name                = "${lower(var.project_name)}"
  env                         = "${lower(var.env)}"
  cidr_block                  = var.cidr_block
  public_subnets              = var.public_subnets
  private_subnets             = var.private_subnets
  subnet_availability_zones   = var.subnet_availability_zones
}

module "ecr" {
  source                   = "./modules/ecr"
  ecr_repositories         = var.ecr_repositories
  project_name             = "${lower(var.project_name)}"
  env                      = "${lower(var.env)}"
}

module "iam" {
  source                   = "./modules/iam"
  project_name             = "${lower(var.project_name)}"
  env                      = "${lower(var.env)}"
}

module "alb-security-group" {
  source                   = "./modules/security-group"
  name                     = "${lower(var.project_name)}-alb-security-group"
  env                      = "${lower(var.env)}"
  vpc_id                   = module.network.vpc_id
  ingress_rules            = var.alb_security_group.ingress_rules
  egress_rules             = var.alb_security_group.egress_rules
}

module "alb" {
  source                   = "./modules/alb"
  project_name             = "${lower(var.project_name)}"
  env                      = "${lower(var.env)}"
  subnets                  = module.network.public_subnets
  security_groups          = [module.alb-security-group.security_group_id]
  vpc_id                   = module.network.vpc_id
  target_groups            = var.service_config
}

module "route53" {
  source                   = "./modules/route53"
  hosted_zone              = var.hosted_zone
  alb                      = module.alb.alb
  record_name              = var.record_name
}

module "ecs" {
  source                                  = "./modules/ecs"
  project_name                            = "${lower(var.project_name)}"
  env                                     = "${lower(var.env)}"
  ami                                     = var.ami
  vpc_id                                  = module.network.vpc_id
  ecs_iam_instance_profile                = module.iam.ecs_iam_instance_profile
  alb_security_group                      = module.alb-security-group.security_group_id
  instance_type                           = var.instance_type
  volume_size                             = var.volume_size
  public_subnets                          = module.network.public_subnets
  private_subnets                         = module.network.private_subnets
  max_size                                = var.autoscaling_max_size
  min_size                                = var.autoscaling_min_size
  service_config                          = var.service_config
  execution_role_arn                      = module.iam.execution_role_arn
  account                                 = var.account
  region                                  = var.region
  ecs_role_policy                         = module.iam.ecs_role_policy
  target_groups                           = module.alb.target_groups
  maximum_scaling_step_size               = var.capacity_provider_maximum_scaling_step
  minimum_scaling_step_size               = var.capacity_provider_minimum_scaling_step
  target_capacity                         = var.capacity_provider_target_capacity
}