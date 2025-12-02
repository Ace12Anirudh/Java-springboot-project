terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Credentials are provided via environment, Jenkins, or AWS provider chain
}

# Lookup latest Amazon Linux 2 AMI for region
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "vpc" {
  source   = "./modules/vpc"
  name     = var.name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
  tags     = var.tags
}

module "subnets" {
  source       = "./modules/subnets"
  vpc_id       = module.vpc.vpc_id
  azs          = var.azs
  public_cidrs = var.public_subnet_cidrs
  private_cidrs = var.private_subnet_cidrs
  tags         = var.tags
}

module "nat" {
  source    = "./modules/nat"
  vpc_id    = module.vpc.vpc_id
  public_subnet_ids = module.subnets.public_subnet_ids
  tags      = var.tags
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
  allowed_ssh_cidr = var.jenkins_ssh_cidr
  alb_allowed_cidr = ["0.0.0.0/0"]
  name_prefix = var.name
  tags = var.tags
}

module "keypair" {
  source = "./modules/keypair"
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

module "iam" {
  source = "./modules/iam"
  name = var.name
}

module "bastion" {
  source = "./modules/bastion"
  name = "${var.name}-bastion"
  ami_id = data.aws_ami.amzn2.id
  instance_type = var.bastion_instance_type
  key_name = module.keypair.key_name
  subnet_id = element(module.subnets.public_subnet_ids, 0)
  security_group_id = module.security_groups.bastion_sg
  user_data_template = file("${path.module}/modules/bastion/user_data_bastion.sh.tpl")
  tags = var.tags
}

module "alb" {
  source = "./modules/alb"
  name = var.name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.subnets.public_subnet_ids
  tags = var.tags
}

module "rds" {
  source = "./modules/rds"
  name = var.name
  engine = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class
  username = var.rds_username
  password = var.rds_password
  subnet_ids = module.subnets.private_subnet_ids_db
  vpc_security_group_ids = [module.security_groups.rds_sg]
  tags = var.tags
}

module "launch_template_frontend" {
  source = "./modules/launch_template"
  name = "${var.name}-frontend"
  instance_type = var.frontend_instance_type
  ami_id = data.aws_ami.amzn2.id
  key_name = module.keypair.key_name
  iam_instance_profile = module.iam.instance_profile_name
  security_group_ids = [module.security_groups.frontend_sg]
  user_data_template = templatefile("${path.module}/modules/launch_template/user_data_frontend.sh.tpl", {
    backend_url = "http://${module.alb.alb_dns}"
  })
  tags = var.tags
}

module "launch_template_backend" {
  source = "./modules/launch_template"
  name = "${var.name}-backend"
  instance_type = var.backend_instance_type
  ami_id = data.aws_ami.amzn2.id
  key_name = module.keypair.key_name
  iam_instance_profile = module.iam.instance_profile_name
  security_group_ids = [module.security_groups.backend_sg]
  user_data_template = templatefile("${path.module}/modules/launch_template/user_data_backend.sh.tpl", {
    db_url = "jdbc:mysql://${module.rds.endpoint}/studentdb?createDatabaseIfNotExist=true"
    db_username = var.rds_username
    db_password = var.rds_password
  })
  tags = var.tags
}

module "asg_frontend" {
  source = "./modules/asg_frontend"
  name = "${var.name}-frontend-asg"
  launch_template_id = module.launch_template_frontend.launch_template_id
  subnet_ids = module.subnets.private_subnet_ids_app
  desired_capacity = var.frontend_desired_capacity
  min_size = var.frontend_min_size
  max_size = var.frontend_max_size
  alb_target_group_arn = module.alb.frontend_tg_arn
  tags = var.tags
}

module "asg_backend" {
  source = "./modules/asg_backend"
  name = "${var.name}-backend-asg"
  launch_template_id = module.launch_template_backend.launch_template_id
  subnet_ids = module.subnets.private_subnet_ids_app
  desired_capacity = var.backend_desired_capacity
  min_size = var.backend_min_size
  max_size = var.backend_max_size
  alb_target_group_arn = module.alb.backend_tg_arn
  tags = var.tags
}
