variable "aws_region" { 
    description = "AWS region" 
    default = "us-east-1" 
    }
variable "name" { default = "java-springboot-project" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "azs" { 
    type = list(string) 
    default = ["us-east-1a","us-east-1b"] 
    }
variable "tags" { 
    type = map(string) 
    default = { Owner = "devops" } 
    }

# Subnet CIDRs: 2 AZs
variable "public_subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24","10.0.2.0/24"]
}
variable "private_subnet_cidrs_app" {
  type = list(string)
  default = ["10.0.11.0/24","10.0.12.0/24"]
}
variable "private_subnet_cidrs_db" {
  type = list(string)
  default = ["10.0.21.0/24","10.0.22.0/24"]
}

# combined private cidrs argument for subnets module
variable "private_subnet_cidrs" {
  type = map(list(string))
  default = {
    app = ["10.0.11.0/24","10.0.12.0/24"]
    db  = ["10.0.21.0/24","10.0.22.0/24"]
  }
}

variable "ssh_key_name" { 
    default = "java-sb-key" 
    }
variable "ssh_public_key" { 
    description = "Public key content (ssh-rsa ...)" 
    default = "" 
    }
variable "jenkins_ssh_cidr" { 
    description = "CIDR allowed to SSH (Jenkins server IP), e.g. 1.2.3.4/32" 
    default = ""
    }

# Instance sizes
variable "bastion_instance_type" { default = "t3.micro" }
variable "jenkins_sonar_instance_type" { default = "t3.large" }
variable "frontend_instance_type" { default = "t3.micro" }
variable "backend_instance_type" { default = "t3.micro" }

# ASG sizing
variable "frontend_desired_capacity" { default = 1 }
variable "frontend_min_size" { default = 1 }
variable "frontend_max_size" { default = 2 }

variable "backend_desired_capacity" { default = 1 }
variable "backend_min_size" { default = 1 }
variable "backend_max_size" { default = 2 }

# RDS
variable "rds_instance_class" { default = "db.t3.micro" }
variable "rds_username" { default = "admin" }
variable "rds_password" { 
    description = "RDS password - set via tfvars or secret manager" 
    default = "" 
    }

# Extra computed
variable "public_subnet_cidrs_count" { default = 2 }
