# Quick Fix for dev.tfvars

## The Error

```
Error: Invalid CIDR block: "<JENKINS_PUBLIC_IP>/32"
```

This means your `dev.tfvars` file still has the placeholder text instead of your actual public IP address.

---

## Fix Steps

### Step 1: Get Your Public IP Address

**Option A - Using curl:**
```bash
curl https://ifconfig.me
```

**Option B - Using PowerShell:**
```powershell
(Invoke-WebRequest -Uri "https://ifconfig.me").Content
```

**Option C - Visit a website:**
Go to: https://whatismyip.com

Copy your IP address (example: `203.0.113.45`)

### Step 2: Edit dev.tfvars

Open `infra/envs/dev.tfvars` and find this line:
```hcl
jenkins_ssh_cidr = "<JENKINS_PUBLIC_IP>/32"
```

Replace it with your actual IP:
```hcl
jenkins_ssh_cidr = "YOUR_ACTUAL_IP/32"
```

**Example:**
```hcl
jenkins_ssh_cidr = "203.0.113.45/32"
```

**Or use 0.0.0.0/0 to allow from anywhere (less secure):**
```hcl
jenkins_ssh_cidr = "0.0.0.0/0"
```

### Step 3: Also Check SSH Public Key

Make sure your SSH public key is on ONE SINGLE LINE:

```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCz93b3N59Hq0kIMLo2oMCcJ7jX2dtg1vS2c264e9Z3UJ0impYvrkt+L1EkRX5R9CvF96ViGJleMfBpra6dXa2gQssFNU2HUh2ChCtJ62gB2BBMESe7OBhC5i2SiGIgziany0Q== Anirudh@Ace"
```

### Step 4: Complete dev.tfvars Example

Here's what your `dev.tfvars` should look like:

```hcl
# AWS Configuration
aws_region = "us-east-1"
name       = "student-management"

# SSH Configuration
ssh_key_name   = "java-sb-key"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCz93b3N59Hq0kIMLo2oMCcJ7jX2dtg1vS2c264e9Z3UJ0impYvrkt+L1EkRX5R9CvF96ViGJleMfBpra6dXa2gQssFNU2HUh2ChCtJ62gB2BBMESe7OBhC5i2SiGIgziany0Q== Anirudh@Ace"

# Your public IP for SSH access
jenkins_ssh_cidr = "YOUR_IP_HERE/32"  # Replace with your actual IP

# Instance Sizes
bastion_instance_type       = "t3.micro"
jenkins_sonar_instance_type = "t3.large"
frontend_instance_type      = "t3.micro"
backend_instance_type       = "t3.micro"

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_username       = "admin"
rds_password       = "YourSecurePassword123!"

# Auto Scaling
frontend_desired_capacity = 1
frontend_min_size        = 1
frontend_max_size        = 2

backend_desired_capacity = 1
backend_min_size        = 1
backend_max_size        = 2
```

### Step 5: Validate and Apply

```bash
cd infra
terraform validate
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

---

## Important Notes

⚠️ **AWS Permissions Issue**: Remember, you still have the AWS SCP (Service Control Policy) restriction that prevents creating EC2 instances. Even after fixing the dev.tfvars file, you'll need to:

1. Contact your AWS administrator to grant EC2 permissions, OR
2. Use a different AWS account, OR
3. Comment out the Jenkins/SonarQube module temporarily

---

## If You Want to Deploy Without Jenkins/SonarQube

Since you're getting AWS permission errors for EC2 instances, you can temporarily disable the Jenkins/SonarQube module:

**Edit `infra/main.tf` and comment out:**
```hcl
# module "jenkins_sonar" {
#   source = "./modules/jenkins_sonar_server"
#   ...
# }
```

**Edit `infra/outputs.tf` and comment out:**
```hcl
# output "jenkins_sonar_instance_id" { value = module.jenkins_sonar.instance_id }
# output "jenkins_sonar_private_ip" { value = module.jenkins_sonar.private_ip }
```

Then deploy:
```bash
terraform apply -var-file=envs/dev.tfvars
```
