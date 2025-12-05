# Complete Deployment Guide - Student Management System

This guide covers the complete deployment process for the Student Management System including infrastructure provisioning, Jenkins/SonarQube setup, and application deployment.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Accessing Jenkins and SonarQube](#accessing-jenkins-and-sonarqube)
4. [Configuring Jenkins](#configuring-jenkins)
5. [Configuring SonarQube](#configuring-sonarqube)
6. [Running the Pipeline](#running-the-pipeline)
7. [Accessing the Application](#accessing-the-application)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Local Machine Requirements

- **AWS CLI v2** installed and configured
- **Terraform** v1.0+ installed
- **SSH client** (OpenSSH, PuTTY, etc.)
- **Git** installed
- **AWS Account** with appropriate permissions

### AWS Permissions Required

Your AWS IAM user/role needs permissions for:
- EC2 (instances, security groups, key pairs)
- VPC (subnets, route tables, internet gateways, NAT gateways)
- RDS (database instances)
- ELB/ALB (load balancers, target groups)
- IAM (roles, instance profiles)
- Auto Scaling

### Required Files

- SSH key pair (public and private keys)
- This repository cloned locally

---

## Infrastructure Setup

### Step 1: Prepare SSH Key Pair

If you don't have an SSH key pair, create one:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/java-sb-key -N ""

# This creates:
# - ~/.ssh/java-sb-key (private key)
# - ~/.ssh/java-sb-key.pub (public key)
```

### Step 2: Configure Terraform Variables

Edit `infra/envs/dev.tfvars` (or create it if it doesn't exist):

```hcl
# AWS Configuration
aws_region = "us-east-1"
name       = "student-management"

# SSH Configuration
ssh_key_name   = "java-sb-key"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-public-key-here"

# Your public IP for SSH access (find it at https://whatismyip.com)
jenkins_ssh_cidr = "YOUR_PUBLIC_IP/32"

# Instance Sizes (adjust as needed)
bastion_instance_type      = "t3.micro"
jenkins_sonar_instance_type = "t3.large"  # Recommended for Jenkins + SonarQube
frontend_instance_type     = "t3.micro"
backend_instance_type      = "t3.micro"

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_username       = "admin"
rds_password       = "YourSecurePassword123!"  # Change this!

# Auto Scaling
frontend_desired_capacity = 1
frontend_min_size        = 1
frontend_max_size        = 2

backend_desired_capacity = 1
backend_min_size        = 1
backend_max_size        = 2
```

> **IMPORTANT**: Replace `YOUR_PUBLIC_IP` with your actual public IP address and set a strong RDS password.

### Step 3: Initialize and Apply Terraform

```bash
# Navigate to infrastructure directory
cd infra

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan -var-file=envs/dev.tfvars

# Apply infrastructure (this will take 10-15 minutes)
terraform apply -var-file=envs/dev.tfvars
```

Type `yes` when prompted to confirm.

### Step 4: Retrieve Infrastructure Outputs

After successful deployment, get the important outputs:

```bash
# Get all outputs
terraform output

# Get specific outputs
terraform output bastion_public_ip
terraform output jenkins_sonar_private_ip
terraform output alb_dns
terraform output rds_endpoint
```

Save these values - you'll need them for the next steps.

---

## Accessing Jenkins and SonarQube

Since Jenkins and SonarQube are on a private server, you need to access them through the bastion host.

### Method 1: SSH Port Forwarding (Recommended)

Set up SSH port forwarding to access the web interfaces:

```bash
# Get the IPs from Terraform
BASTION_IP=$(terraform output -raw bastion_public_ip)
JENKINS_IP=$(terraform output -raw jenkins_sonar_private_ip)

# Set up port forwarding (keep this terminal open)
ssh -i ~/.ssh/java-sb-key \
    -L 8080:$JENKINS_IP:8080 \
    -L 9000:$JENKINS_IP:9000 \
    ec2-user@$BASTION_IP
```

Now you can access:
- **Jenkins**: http://localhost:8080
- **SonarQube**: http://localhost:9000

### Method 2: Direct SSH to Jenkins/SonarQube Server

To SSH directly to the Jenkins/SonarQube server:

```bash
BASTION_IP=$(terraform output -raw bastion_public_ip)
JENKINS_IP=$(terraform output -raw jenkins_sonar_private_ip)

# SSH through bastion
ssh -i ~/.ssh/java-sb-key \
    -o ProxyCommand="ssh -i ~/.ssh/java-sb-key -W %h:%p ec2-user@$BASTION_IP" \
    ec2-user@$JENKINS_IP
```

### Retrieve Initial Passwords

Once connected to the Jenkins/SonarQube server:

```bash
# Check service status
check-services

# Get Jenkins initial admin password
get-jenkins-password

# Or manually:
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Configuring Jenkins

### Step 1: Initial Setup Wizard

1. Open http://localhost:8080 (with port forwarding active)
2. Enter the initial admin password retrieved above
3. Click **Install suggested plugins**
4. Wait for plugins to install (5-10 minutes)
5. Create your admin user:
   - Username: `admin`
   - Password: Choose a strong password
   - Full name: Your name
   - Email: Your email
6. Keep the default Jenkins URL: `http://localhost:8080/`
7. Click **Start using Jenkins**

### Step 2: Install Additional Plugins

Navigate to **Manage Jenkins → Plugins → Available plugins**

Install these plugins:
- ✅ **Pipeline**
- ✅ **Git plugin**
- ✅ **AWS Credentials Plugin**
- ✅ **SSH Agent Plugin**
- ✅ **SonarQube Scanner**
- ✅ **Docker Pipeline**

Click **Install** and restart Jenkins when done.

### Step 3: Configure AWS Credentials

1. Go to **Manage Jenkins → Credentials → System → Global credentials**
2. Click **Add Credentials**

**AWS Credentials:**
- Kind: `AWS Credentials`
- ID: `aws-creds`
- Access Key ID: Your AWS Access Key
- Secret Access Key: Your AWS Secret Key
- Description: `AWS credentials for deployment`
- Click **Create**

### Step 4: Configure SSH Key

1. Still in **Global credentials**, click **Add Credentials**

**SSH Private Key:**
- Kind: `SSH Username with private key`
- ID: `jenkins-ssh-key`
- Username: `ec2-user`
- Private Key: **Enter directly**
  - Copy and paste your private key content from `~/.ssh/java-sb-key`
- Description: `SSH key for EC2 instances`
- Click **Create**

### Step 5: Configure SonarQube Token (Will do after SonarQube setup)

We'll add this after configuring SonarQube.

---

## Configuring SonarQube

### Step 1: Initial Login

1. Open http://localhost:9000 (with port forwarding active)
2. Default credentials:
   - Username: `admin`
   - Password: `admin`
3. You'll be prompted to change the password - choose a strong password

### Step 2: Create a Project

1. Click **Create Project** → **Manually**
2. Project key: `student-management-backend`
3. Display name: `Student Management Backend`
4. Click **Set Up**

### Step 3: Generate Authentication Token

1. Choose **Locally**
2. Generate a token:
   - Token name: `jenkins-token`
   - Click **Generate**
   - **COPY THE TOKEN** - you won't see it again!
   - Example: `squ_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

### Step 4: Add Token to Jenkins

1. Go back to Jenkins: http://localhost:8080
2. Navigate to **Manage Jenkins → Credentials → System → Global credentials**
3. Click **Add Credentials**

**SonarQube Token:**
- Kind: `Secret text`
- Secret: Paste the SonarQube token
- ID: `sonar-token`
- Description: `SonarQube authentication token`
- Click **Create**

### Step 5: Configure SonarQube Server in Jenkins

1. Go to **Manage Jenkins → System**
2. Scroll to **SonarQube servers**
3. Click **Add SonarQube**
   - Name: `SonarQube`
   - Server URL: `http://<JENKINS_PRIVATE_IP>:9000`
     - Get the IP: `terraform output -raw jenkins_sonar_private_ip`
     - Example: `http://10.0.11.123:9000`
   - Server authentication token: Select `sonar-token`
4. Click **Save**

---

## Running the Pipeline

### Step 1: Create Pipeline Job

1. From Jenkins dashboard, click **New Item**
2. Enter name: `student-management-deployment`
3. Select **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

In the pipeline configuration:

**General:**
- Description: `Student Management System CI/CD Pipeline`

**Build Triggers** (Optional):
- ✅ Poll SCM: `H/5 * * * *` (polls every 5 minutes)

**Pipeline:**
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: Your Git repository URL
  - Example: `https://github.com/yourusername/java-springboot-project.git`
- Credentials: Add if private repository
- Branch Specifier: `*/main` (or your branch)
- Script Path: `infra/Jenkinsfile`

Click **Save**

### Step 3: Trigger First Build

1. Click **Build Now**
2. Click on the build number (e.g., `#1`)
3. Click **Console Output** to watch progress

### Step 4: Monitor Pipeline Execution

The pipeline will execute these stages:

1. ✅ **Checkout** - Clone repository
2. ✅ **Sonar - Frontend** - Analyze frontend code
3. ✅ **Build Frontend artifact** - Package frontend
4. ✅ **Sonar - Backend** - Analyze backend code
5. ✅ **Build Backend artifact** - Build Spring Boot JAR
6. ✅ **Terraform Init & Apply** - Update infrastructure
7. ✅ **Discover Instances & Deploy** - Deploy to EC2 instances

**Expected Duration:** 15-20 minutes for first run

### Step 5: Verify Deployment Success

Check for these success indicators in console output:

```
✓ Frontend deployed successfully to 10.0.11.x
✓ Backend deployed successfully to 10.0.11.y
=== Deployment Complete ===
```

---

## Accessing the Application

### Get Application URL

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns)
echo "Application URL: http://$ALB_DNS"
```

### Test Backend API

```bash
# Health check
curl http://$ALB_DNS/api/actuator/health

# Get all students
curl http://$ALB_DNS/api/students

# Create a student
curl -X POST http://$ALB_DNS/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "course": "Computer Science"
  }'
```

### Test Frontend

Open in browser:
```
http://<ALB_DNS>/
```

You should see the Student Management frontend interface.

---

## Troubleshooting

### Jenkins/SonarQube Not Accessible

**Problem:** Can't access Jenkins or SonarQube web UI

**Solutions:**

1. **Check port forwarding is active:**
   ```bash
   # Make sure SSH tunnel is still running
   # Re-run the port forwarding command if needed
   ```

2. **Verify services are running:**
   ```bash
   # SSH to Jenkins server
   ssh -i ~/.ssh/java-sb-key \
       -o ProxyCommand="ssh -i ~/.ssh/java-sb-key -W %h:%p ec2-user@$BASTION_IP" \
       ec2-user@$JENKINS_IP
   
   # Check service status
   sudo systemctl status jenkins
   sudo systemctl status sonarqube
   
   # Restart if needed
   sudo systemctl restart jenkins
   sudo systemctl restart sonarqube
   ```

3. **Check security groups:**
   ```bash
   # Verify Jenkins/SonarQube security group allows traffic from bastion
   aws ec2 describe-security-groups \
       --filters "Name=tag:Name,Values=*jenkins-sonar-sg*"
   ```

### Pipeline Fails at Terraform Stage

**Problem:** Terraform apply fails in pipeline

**Solutions:**

1. **Check AWS credentials:**
   - Verify `aws-creds` credential is correctly configured in Jenkins
   - Test AWS CLI access from Jenkins server

2. **Check Terraform state:**
   ```bash
   cd infra
   terraform state list
   terraform refresh -var-file=envs/dev.tfvars
   ```

3. **Manual Terraform run:**
   ```bash
   # SSH to Jenkins server and run Terraform manually
   cd /var/lib/jenkins/workspace/student-management-deployment/infra
   terraform plan -var-file=envs/dev.tfvars
   ```

### Pipeline Fails at Deployment Stage

**Problem:** SSH deployment fails

**Solutions:**

1. **Verify SSH key:**
   - Ensure `jenkins-ssh-key` credential matches EC2 key pair
   - Check key permissions

2. **Check bastion connectivity:**
   ```bash
   # Test SSH to bastion from Jenkins server
   ssh -i /path/to/key ec2-user@$BASTION_IP
   ```

3. **Verify instances are running:**
   ```bash
   # Check ASG instances
   aws autoscaling describe-auto-scaling-groups \
       --auto-scaling-group-names student-management-frontend-asg
   ```

### Application Not Accessible

**Problem:** Can't access application via ALB

**Solutions:**

1. **Check ALB health checks:**
   ```bash
   # Get target group ARN from Terraform state
   aws elbv2 describe-target-health \
       --target-group-arn <target-group-arn>
   ```

2. **Verify instances are healthy:**
   - Check AWS Console → EC2 → Target Groups
   - Ensure targets show as "healthy"

3. **Check application logs:**
   ```bash
   # SSH to backend instance
   ssh -i ~/.ssh/java-sb-key \
       -o ProxyCommand="ssh -i ~/.ssh/java-sb-key -W %h:%p ec2-user@$BASTION_IP" \
       ec2-user@<backend-private-ip>
   
   # Check backend logs
   sudo journalctl -u backend.service -f
   
   # Check frontend logs
   sudo journalctl -u frontend.service -f
   ```

### Database Connection Issues

**Problem:** Backend can't connect to RDS

**Solutions:**

1. **Verify RDS endpoint:**
   ```bash
   terraform output rds_endpoint
   ```

2. **Check security group:**
   - Ensure backend security group can access RDS security group on port 3306

3. **Test database connection:**
   ```bash
   # From backend instance
   mysql -h <rds-endpoint> -u admin -p
   ```

4. **Check application properties:**
   ```bash
   # Verify environment variables are set correctly
   sudo systemctl status backend.service
   ```

---

## Quick Reference Commands

### Infrastructure Management

```bash
# Deploy infrastructure
cd infra
terraform apply -var-file=envs/dev.tfvars

# Destroy infrastructure
terraform destroy -var-file=envs/dev.tfvars

# Get outputs
terraform output

# Refresh state
terraform refresh -var-file=envs/dev.tfvars
```

### Access Commands

```bash
# Port forwarding for Jenkins/SonarQube
ssh -i ~/.ssh/java-sb-key -L 8080:$JENKINS_IP:8080 -L 9000:$JENKINS_IP:9000 ec2-user@$BASTION_IP

# SSH to Jenkins/SonarQube server
ssh -i ~/.ssh/java-sb-key -o ProxyCommand="ssh -i ~/.ssh/java-sb-key -W %h:%p ec2-user@$BASTION_IP" ec2-user@$JENKINS_IP

# SSH to application instance
ssh -i ~/.ssh/java-sb-key -o ProxyCommand="ssh -i ~/.ssh/java-sb-key -W %h:%p ec2-user@$BASTION_IP" ec2-user@<instance-private-ip>
```

### Service Management

```bash
# On Jenkins/SonarQube server
sudo systemctl status jenkins
sudo systemctl restart jenkins
sudo systemctl status sonarqube
sudo systemctl restart sonarqube

# On application instances
sudo systemctl status backend.service
sudo systemctl restart backend.service
sudo systemctl status frontend.service
sudo systemctl restart frontend.service
```

### Monitoring

```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check SonarQube logs
sudo journalctl -u sonarqube -f
tail -f /opt/sonarqube/logs/sonar.log

# Check application logs
sudo journalctl -u backend.service -f
sudo journalctl -u frontend.service -f
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────┬────────────────────────────────────────┘
                     │
            ┌────────▼─────────┐
            │  Application     │
            │  Load Balancer   │
            │     (ALB)        │
            └────────┬─────────┘
                     │
     ┌───────────────┴───────────────┐
     │                               │
┌────▼─────┐                   ┌────▼─────┐
│ Frontend │                   │ Backend  │
│   ASG    │                   │   ASG    │
│ (Private)│                   │ (Private)│
└──────────┘                   └────┬─────┘
                                    │
                               ┌────▼─────┐
                               │   RDS    │
                               │  MySQL   │
                               │ (Private)│
                               └──────────┘

┌──────────────┐              ┌──────────────┐
│   Bastion    │              │   Jenkins/   │
│    Host      │◄────────────►│  SonarQube   │
│  (Public)    │              │  (Private)   │
└──────────────┘              └──────────────┘
```

---

## Next Steps

After successful deployment:

1. ✅ Set up GitHub webhooks for automatic builds
2. ✅ Configure backup strategy for Jenkins and SonarQube
3. ✅ Set up CloudWatch monitoring and alarms
4. ✅ Implement SSL/TLS for ALB
5. ✅ Configure RDS automated backups
6. ✅ Set up log aggregation (CloudWatch Logs)
7. ✅ Implement secrets management (AWS Secrets Manager)

---

## Support

For issues or questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review Jenkins console output for detailed error messages
- Check AWS CloudWatch logs
- Verify security group rules and network connectivity
