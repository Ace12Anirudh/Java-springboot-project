# Deployment Guide - Student Management System

## 📋 Overview

This guide covers two deployment scenarios:
1. **Local Development** - Test on your machine
2. **AWS Production** - Deploy to AWS with Jenkins automation

---

## 🏠 Option 1: Local Development (Start Here)

### Prerequisites
- Java 17 installed
- Maven installed
- Python 3.8+ installed
- MySQL 8.0 installed and running
- Git

### Step 1: Setup MySQL Database

```bash
# Login to MySQL
mysql -u root -p

# Create database
CREATE DATABASE studentdb;

# Create user (optional)
CREATE USER 'studentapp'@'localhost' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON studentdb.* TO 'studentapp'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Step 2: Start Backend

```bash
# Navigate to backend directory
cd backend

# Set environment variables (Windows PowerShell)
$env:DB_URL="jdbc:mysql://localhost:3306/studentdb"
$env:DB_USERNAME="root"
$env:DB_PASSWORD="ace12mysql"

# Or for Linux/Mac
export DB_URL="jdbc:mysql://localhost:3306/studentdb"
export DB_USERNAME="root"
export DB_PASSWORD="ace12mysql"

# Build and run
mvn spring-boot:run
```

**Backend will start on:** `http://localhost:8080`

**Test it:**
```bash
curl http://localhost:8080/student/health
```

Expected response:
```json
{"status":"UP","service":"Student Management Backend"}
```

### Step 3: Start Frontend

Open a **new terminal** (keep backend running):

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
pip install -r requirements.txt

# Set backend URL (Windows PowerShell)
$env:API_URL="http://localhost:8080"

# Or for Linux/Mac
export API_URL="http://localhost:8080"

# Run Streamlit
streamlit run src/app.py
```

**Frontend will start on:** `http://localhost:8501`

### Step 4: Test the Application

1. Open browser: `http://localhost:8501`
2. You should see the beautiful purple gradient UI
3. Try adding a student in the "Add Student" tab
4. Search for the student
5. View all students in the "All Students" tab

---

## ☁️ Option 2: AWS Production Deployment

### Architecture Overview

```
Your Machine (Jenkins)
    ↓
Terraform creates AWS Infrastructure:
    - VPC with public/private subnets
    - ALB (Application Load Balancer)
    - RDS MySQL database
    - Bastion host (public subnet)
    - Frontend ASG (private subnet) - Streamlit
    - Backend ASG (private subnet) - Spring Boot
    ↓
Jenkins deploys code via SSH through Bastion
```

### Prerequisites

#### 1. Jenkins Server Setup

You need a Jenkins server (can be local or on EC2) with:

```bash
# Install required tools on Jenkins server
# Java 17
sudo yum install -y java-17-amazon-corretto-devel

# Maven
sudo yum install -y maven

# Python and SonarQube Scanner
sudo yum install -y python3 python3-pip
# Download and install sonar-scanner from SonarQube website

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Git
sudo yum install -y git
```

#### 2. SonarQube Server Setup

Option A: Use SonarCloud (cloud-based, easier)
- Sign up at https://sonarcloud.io
- Get your token

Option B: Self-hosted SonarQube
- Install SonarQube on a separate EC2 instance
- Configure and get authentication token

#### 3. AWS Account Setup

- AWS account with admin access
- Create IAM user for Jenkins with permissions for EC2, VPC, RDS, ALB
- Note down Access Key ID and Secret Access Key

---

### AWS Deployment Steps

#### Step 1: Prepare Configuration Files

**1.1 Configure Terraform Variables**

Edit `infra/envs/dev.tfvars`:

```hcl
aws_region = "us-east-1"  # Your preferred region

# Your SSH public key (generate with: ssh-keygen -t rsa -b 4096)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD..."

# Jenkins server public IP (for SSH access to bastion)
jenkins_ssh_cidr = ["1.2.3.4/32"]  # Replace with your Jenkins IP

# RDS MySQL password (use a strong password)
rds_password = "YourSecurePassword123!"

# Other settings (optional, defaults are fine)
vpc_cidr = "10.0.0.0/16"
frontend_desired_capacity = 2
backend_desired_capacity = 2
```

**1.2 Configure Terraform Backend (Optional but Recommended)**

Edit `infra/backend/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Create this S3 bucket first
    key            = "student-management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"  # Create this DynamoDB table first
    encrypt        = true
  }
}
```

**Create S3 bucket and DynamoDB table:**
```bash
# Create S3 bucket
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### Step 2: Configure Jenkins

**2.1 Install Jenkins Plugins**
- Pipeline
- Git
- AWS Credentials
- SSH Agent
- SonarQube Scanner

**2.2 Add Credentials in Jenkins**

Go to Jenkins → Manage Jenkins → Credentials → Global → Add Credentials

1. **AWS Credentials** (ID: `aws-creds`)
   - Kind: AWS Credentials
   - Access Key ID: Your AWS access key
   - Secret Access Key: Your AWS secret key

2. **SSH Private Key** (ID: `jenkins-ssh-key`)
   - Kind: SSH Username with private key
   - Username: ec2-user
   - Private Key: Paste your SSH private key (pair of the public key in tfvars)

3. **SonarQube Token** (ID: `sonar-token`)
   - Kind: Secret text
   - Secret: Your SonarQube token

**2.3 Configure SonarQube in Jenkins**

Go to Jenkins → Manage Jenkins → Configure System → SonarQube servers

- Name: SonarQube
- Server URL: https://sonarcloud.io (or your SonarQube URL)
- Server authentication token: Select `sonar-token` credential

#### Step 3: Create Jenkins Pipeline

**3.1 Create New Pipeline Job**
- New Item → Pipeline
- Name: student-management-deployment

**3.2 Configure Pipeline**
- Pipeline Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: Your Git repository URL
- Script Path: `infra/Jenkinsfile`

#### Step 4: Run Deployment

**4.1 First Time - Manual Terraform (Optional)**

You can run Terraform manually first to verify infrastructure:

```bash
cd infra

# Initialize Terraform
terraform init

# Plan (review what will be created)
terraform plan -var-file=envs/dev.tfvars

# Apply (create infrastructure)
terraform apply -var-file=envs/dev.tfvars
```

**4.2 Run Jenkins Pipeline**

1. Go to Jenkins → student-management-deployment
2. Click "Build Now"

The pipeline will:
- ✅ Checkout code from Git
- ✅ Run SonarQube analysis on frontend
- ✅ Run SonarQube analysis on backend
- ✅ Build backend JAR file
- ✅ Package frontend Python files
- ✅ Run Terraform (create/update infrastructure)
- ✅ Deploy backend to EC2 instances via SSH
- ✅ Deploy frontend to EC2 instances via SSH
- ✅ Restart systemd services

**4.3 Monitor Deployment**

Watch Jenkins console output for:
- Build status
- Terraform outputs (ALB DNS, Bastion IP, RDS endpoint)
- Deployment status

#### Step 5: Access Your Application

**5.1 Get ALB DNS Name**

From Jenkins console output or run:
```bash
cd infra
terraform output alb_dns_name
```

**5.2 Access Application**

- **Frontend**: `http://<alb-dns-name>/`
- **Backend API**: `http://<alb-dns-name>/student/health`

Example:
```
http://student-alb-123456789.us-east-1.elb.amazonaws.com/
```

---

## 🔍 Verification Steps

### After AWS Deployment

**1. Check Infrastructure**
```bash
cd infra

# Get all outputs
terraform output

# Should show:
# - alb_dns_name
# - bastion_public_ip
# - rds_endpoint
# - frontend_asg_name
# - backend_asg_name
```

**2. Check EC2 Instances**
```bash
# List frontend instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <frontend_asg_name> \
  --query "AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus]"

# List backend instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <backend_asg_name> \
  --query "AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus]"
```

**3. Check Application Logs (via Bastion)**

```bash
# SSH to bastion
ssh -i your-key.pem ec2-user@<bastion-public-ip>

# From bastion, SSH to backend instance
ssh ec2-user@<backend-private-ip>

# Check backend service
sudo systemctl status backend.service
sudo journalctl -u backend.service -f

# Check frontend service (on frontend instance)
sudo systemctl status frontend.service
sudo journalctl -u frontend.service -f
```

**4. Test Application**

```bash
# Test backend health
curl http://<alb-dns>/student/health

# Test creating a student
curl -X POST http://<alb-dns>/student/post \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Student","age":20,"email":"test@example.com","course":"CS"}'

# Test getting all students
curl http://<alb-dns>/student/all
```

**5. Access Frontend**

Open browser: `http://<alb-dns>/`

You should see the beautiful purple gradient Streamlit UI!

---

## 🔧 Troubleshooting

### Issue: Backend won't start

**Check logs:**
```bash
ssh to backend instance via bastion
sudo journalctl -u backend.service -n 50
```

**Common causes:**
- Database connection failed → Check RDS endpoint and credentials
- Port 8080 already in use
- JAR file not found → Check deployment

### Issue: Frontend can't connect to backend

**Check:**
1. Backend is running: `curl http://<backend-alb>/student/health`
2. API_URL environment variable is set correctly in frontend systemd service
3. Security groups allow traffic between ALB and instances

### Issue: Can't access via ALB

**Check:**
1. ALB is active: AWS Console → EC2 → Load Balancers
2. Target groups are healthy: Check target group health status
3. Security groups allow HTTP traffic on port 80

### Issue: Jenkins deployment fails

**Check:**
1. Jenkins has correct AWS credentials
2. SSH key matches the public key in Terraform
3. Jenkins can reach bastion IP (check jenkins_ssh_cidr)
4. Review Jenkins console output for specific error

---

## 📊 Infrastructure Components

### What Terraform Creates

| Component | Purpose | Location |
|-----------|---------|----------|
| VPC | Network isolation | AWS Region |
| Public Subnets (2) | ALB, Bastion | 2 Availability Zones |
| Private Subnets (4) | App servers, RDS | 2 AZs (2 for app, 2 for DB) |
| ALB | Load balancer | Public subnets |
| Frontend ASG | Streamlit instances | Private app subnets |
| Backend ASG | Spring Boot instances | Private app subnets |
| RDS MySQL | Database | Private DB subnets |
| Bastion | SSH jump host | Public subnet |
| NAT Gateways (2) | Internet for private instances | Public subnets |

### Cost Estimate (us-east-1)

- EC2 instances (4 x t3.small): ~$60/month
- RDS MySQL (db.t3.micro): ~$15/month
- ALB: ~$20/month
- NAT Gateways (2): ~$65/month
- **Total: ~$160/month**

---

## 🎯 Recommended Workflow

### For Development
1. ✅ Test locally first (Option 1)
2. ✅ Make code changes
3. ✅ Test locally again
4. ✅ Commit to Git
5. ✅ Deploy to AWS via Jenkins

### For Production
1. ✅ Use separate Terraform workspace for prod
2. ✅ Enable HTTPS on ALB with ACM certificate
3. ✅ Use AWS Secrets Manager for RDS password
4. ✅ Implement authentication in application
5. ✅ Set up CloudWatch monitoring and alarms

---

## 🚀 Quick Reference

### Local Testing
```bash
# Terminal 1 - Backend
cd backend
mvn spring-boot:run

# Terminal 2 - Frontend
cd frontend
streamlit run src/app.py
```

### AWS Deployment
```bash
# Option 1: Via Jenkins
# Just click "Build Now" in Jenkins

# Option 2: Manual Terraform
cd infra
terraform apply -var-file=envs/dev.tfvars
# Then deploy code manually via Jenkins or SSH
```

### Access Application
- **Local**: http://localhost:8501
- **AWS**: http://<alb-dns>/

---

## ✅ Success Checklist

- [ ] MySQL database created and running
- [ ] Backend starts successfully on port 8080
- [ ] Frontend starts successfully on port 8501
- [ ] Can add/search/update/delete students locally
- [ ] Jenkins configured with all credentials
- [ ] Terraform variables configured
- [ ] Jenkins pipeline runs successfully
- [ ] Infrastructure created in AWS
- [ ] Application accessible via ALB DNS
- [ ] All CRUD operations work on AWS deployment

---

**Need Help?** Check the troubleshooting section or review application logs!
