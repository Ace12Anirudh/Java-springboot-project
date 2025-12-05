$sshKey = (Get-Content ~\.ssh\java-sb-key.pub) -join ''

$content = @"
# AWS Configuration
aws_region = "us-east-1"
name       = "student-management"

# SSH Configuration
ssh_key_name   = "java-sb-key"
ssh_public_key = "$sshKey"

# Your public IP for SSH access
jenkins_ssh_cidr = "0.0.0.0/0"

# Instance Sizes
bastion_instance_type       = "t3.micro"
jenkins_sonar_instance_type = "t3.large"
frontend_instance_type      = "t3.micro"
backend_instance_type       = "t3.micro"

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_username       = "admin"
rds_password       = "SecurePassword123!"

# Auto Scaling
frontend_desired_capacity = 1
frontend_min_size        = 1
frontend_max_size        = 2

backend_desired_capacity = 1
backend_min_size        = 1
backend_max_size        = 2
"@

Set-Content -Path "envs\dev.tfvars" -Value $content
Write-Host "dev.tfvars file has been updated successfully!"
