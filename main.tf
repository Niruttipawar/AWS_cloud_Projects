terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  project_name = var.project_name
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_security_group = module.security_groups.alb_security_group_id
  environment        = var.environment
  project_name       = var.project_name
}

# EC2 Application Tier Module
module "ec2_app_tier" {
  source = "./modules/ec2"

  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.security_groups.app_security_group_id
  instance_type         = var.app_instance_type
  ami_id                = var.app_ami_id
  key_name              = var.key_name
  min_size              = var.app_min_size
  max_size              = var.app_max_size
  desired_capacity      = var.app_desired_capacity
  target_group_arn      = module.alb.target_group_arn
  environment           = var.environment
  project_name          = var.project_name
  tier                  = "app"
}

# RDS Database Module
module "rds" {
  source = "./modules/rds"

  vpc_id                = module.vpc.vpc_id
  db_subnet_ids         = module.vpc.db_subnet_ids
  db_security_group_id  = module.security_groups.db_security_group_id
  db_engine             = var.db_engine
  db_engine_version     = var.db_engine_version
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  allocated_storage     = var.db_allocated_storage
  multi_az              = var.db_multi_az
  environment           = var.environment
  project_name          = var.project_name
}
