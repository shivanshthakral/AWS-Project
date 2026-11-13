provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  tags         = local.common_tags
}

module "ec2" {
  source                = "./modules/ec2"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnet_id
  instance_type         = var.instance_type
  key_pair_name         = var.key_pair_name
  create_jenkins_server = var.create_jenkins_server
  ssh_allowed_cidr      = var.ssh_allowed_cidr
  tags                  = local.common_tags
}

module "rds" {
  source       = "./modules/rds"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  db_password  = var.db_password
  app_sg_id    = module.ec2.security_group_id
  tags         = local.common_tags
}

module "alb" {
  source             = "./modules/alb"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  app_sg_id          = module.ec2.security_group_id
  target_instance_id = module.ec2.instance_id
  certificate_arn    = var.alb_certificate_arn
  tags               = local.common_tags
}
