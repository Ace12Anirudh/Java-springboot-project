# Terraform + Jenkins Deployment for Java Spring Boot (backend) + Python Frontend

This repo contains a complete Terraform infra layout and Jenkins pipeline for deploying:
- Python frontend (Gunicorn + systemd)
- Java Spring Boot backend (systemd)
- ALB (routes `/` → frontend, `/api/*` → backend)
- ASG for frontend & backend (private subnets)
- Bastion host in public subnet (SSH jump)
- RDS MySQL 8.0 (private)
- Private subnets + NAT gateways (2 AZs)
- Jenkins pipeline that does Sonar scans, builds artifacts and deploys via SSH (through bastion)

---

## Architecture (2 AZs)
Internet
└─> ALB (public subnets)
├─> Target Group (frontend ASG in private subnets)
└─> Target Group (backend ASG in private subnets)
Bastion (public subnet) <-- Jenkins SSH -> Bastion -> Private Instances
Private Instances (ASG) -> Access RDS MySQL in private subnet


---

## Files & folders
- `infra/` - All Terraform code
- `Jenkinsfile` - Pipeline: Sonar, build, terraform apply, SSH deploy via bastion
- `README.md` - This document

---

## Pre-requisites
- AWS account with access keys
- Create S3 bucket & DynamoDB table for remote state before `terraform init` (or adapt backend.tf)
- Jenkins server with:
  - `aws` CLI
  - `ssh`, `scp`, `unzip`, `zip`, `mvn`, `sonar-scanner`
  - Credentials stored:
    - `aws-creds` (AWS access key)
    - `jenkins-ssh-key` (private key for SSH to bastion)
    - `sonar-token` (Sonar API token)
- Your SSH public key (for creating EC2 key pair)

---

## Quickstart (high-level)

1. Edit `infra/backend/backend.tf` and set `<YOUR_S3_BUCKET_NAME>` & `<YOUR_DYNAMODB_TABLE_NAME>` or bootstrap state manually.
2. Update `infra/envs/dev.tfvars` with your region, SSH public key, Jenkins public IP and RDS password.
3. From `infra/`:
   ```bash
   terraform init
   terraform apply -var-file=envs/dev.tfvars
(Or let Jenkins run Terraform in pipeline.)
4. After apply, note alb_dns output. Test ALB HTTP access.
5. Configure Jenkins pipeline:

Create credentials: aws-creds, jenkins-ssh-key (private key), sonar-token.

Ensure Jenkins agent has necessary tools.

Run pipeline — it will build artifacts and deploy via bastion to private instances.

## How deployment works (Jenkins)

Checkout repo.

Sonar scan for frontend (python) & backend (maven).

Package frontend as frontend-artifact.zip and backend as backend-artifact.zip.

Run Terraform (init → plan → apply).

Query Terraform output for ASG names & bastion IP.

Use aws autoscaling describe-auto-scaling-groups and aws ec2 describe-instances to fetch private IPs of instances in ASG.

Use scp + ssh with ProxyCommand over bastion to copy artifacts to private instances and restart systemd services.

## Files to look at (important)

infra/modules/launch_template/user_data_frontend.sh.tpl

infra/modules/launch_template/user_data_backend.sh.tpl

infra/modules/bastion/user_data_bastion.sh.tpl

Jenkinsfile

## Security notes & recommendations

Restrict jenkins_ssh_cidr to Jenkins public IP (/32) — do NOT leave SSH open to the world.

Consider replacing SSH-based deploy with:

S3 artifacts + instance pull + instance profile, or

AWS SSM Session Manager to run commands (no SSH port open).

Use AWS Secrets Manager or SSM Parameter Store for RDS password in production.

Use ACM + HTTPS on ALB for production encryption.

## Troubleshooting

If Terraform can't find AMI: data.aws_ami filter is region-specific. Change filters or use a pinned AMI.

If ALB health checks fail:

Ensure app listens on expected port (80 for frontend, 8080 for backend).

Check systemctl status frontend.service / backend.service.

If SSH via bastion fails:

Confirm private key in Jenkins matches public key in infra/envs/dev.tfvars.

Confirm jenkins_ssh_cidr contains Jenkins public IP.

Confirm bastion has public IP (output bastion_public_ip).
