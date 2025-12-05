variable "vpc_id" {}
variable "allowed_ssh_cidr" { type = string }
variable "alb_allowed_cidr" { 
    type = list(string) 
    default = ["0.0.0.0/0"] 
    }
variable "name_prefix" { 
    type = string 
    default = "app" 
    }
variable "tags" { 
    type = map(string) 
    default = {} 
    }

# ALB SG
resource "aws_security_group" "alb_sg" {
  name = "${var.name_prefix}-alb-sg"
  vpc_id = var.vpc_id
  description = "Allow HTTP to ALB"
  ingress {
    from_port = 80 
    to_port = 80
    protocol = "tcp" 
    cidr_blocks = var.alb_allowed_cidr
  }
  egress { 
    from_port = 0 
    to_port = 0
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

# Bastion SG: allow SSH from Jenkins only
resource "aws_security_group" "bastion_sg" {
  name = "${var.name_prefix}-bastion-sg"
  vpc_id = var.vpc_id
  ingress { 
    from_port = 22 
    to_port = 22
    protocol = "tcp" 
    cidr_blocks = [var.allowed_ssh_cidr] 
    }
  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  tags = merge(var.tags, { Name = "${var.name_prefix}-bastion-sg" })
}

# Frontend SG: allow HTTP from ALB; SSH from Jenkins (for deployment)
resource "aws_security_group" "frontend_sg" {
  name = "${var.name_prefix}-frontend-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port = 80
    to_port = 80 
    protocol = "tcp"
    # ALB will send traffic from its IPs; allow from ALB SG
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress { 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = [var.allowed_ssh_cidr] 
    }
  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  tags = merge(var.tags, { Name = "${var.name_prefix}-frontend-sg" })
}

# Backend SG: allow HTTP from ALB SG (target), SSH from Jenkins, access to RDS SG
resource "aws_security_group" "backend_sg" {
  name = "${var.name_prefix}-backend-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port = 8080 
    to_port = 8080 
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress { 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = [var.allowed_ssh_cidr] 
    }
  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  tags = merge(var.tags, { Name = "${var.name_prefix}-backend-sg" })
}

# RDS SG
resource "aws_security_group" "rds_sg" {
  name = "${var.name_prefix}-rds-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port = 3306 
    to_port = 3306 
    protocol = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-sg" })
}

# Jenkins/SonarQube SG: allow SSH, Jenkins (8080), SonarQube (9000) from bastion and app servers
resource "aws_security_group" "jenkins_sonar_sg" {
  name = "${var.name_prefix}-jenkins-sonar-sg"
  vpc_id = var.vpc_id
  description = "Security group for Jenkins and SonarQube server"
  
  # SSH from bastion
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  # Jenkins web UI from bastion
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  # SonarQube web UI from bastion
  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  # Jenkins access from frontend instances (for pipeline execution)
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  
  # Jenkins access from backend instances (for pipeline execution)
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  
  # SonarQube access from frontend instances (for code analysis)
  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  
  # SonarQube access from backend instances (for code analysis)
  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  
  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, { Name = "${var.name_prefix}-jenkins-sonar-sg" })
}

