# Terraform Apply Error Fix Guide

## Error Summary

Your `terraform apply` is failing due to SSH public key formatting issues in `infra/envs/dev.tfvars`.

---

## The Problem

**Error Message:**
```
Error: Invalid multi-line string
Error: Unterminated template string
Error: InvalidKey.Format: Key is not in valid OpenSSH public key format
```

**Root Cause:** The SSH public key in `dev.tfvars` is split across multiple lines, which is invalid HCL syntax.

---

## Solution

### Step 1: Get Your SSH Public Key (Single Line)

Open your SSH public key file and copy the **entire key as a single line**:

**Windows (PowerShell):**
```powershell
# View your public key
Get-Content ~\.ssh\java-sb-key.pub

# Copy the entire output (should be ONE long line starting with "ssh-rsa")
```

**Linux/Mac:**
```bash
cat ~/.ssh/java-sb-key.pub
```

The key should look like:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...very_long_string...== user@hostname
```

### Step 2: Fix dev.tfvars File

Edit `infra/envs/dev.tfvars` and ensure the SSH key is on **ONE SINGLE LINE**:

**CORRECT FORMAT:**
```hcl
# AWS Configuration
aws_region = "us-east-1"
name       = "student-management"

# SSH Configuration
ssh_key_name   = "java-sb-key"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...entire_key_here...== user@hostname"

# Your public IP for SSH access
jenkins_ssh_cidr = "YOUR_PUBLIC_IP/32"

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

**INCORRECT FORMAT (What you currently have):**
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...
...rest of key on next line...
"
```

### Step 3: Verify the Fix

The key must be:
- ✅ On a **single line**
- ✅ Enclosed in **double quotes**
- ✅ Starting with `ssh-rsa` (or `ssh-ed25519` if using Ed25519)
- ✅ Ending with your username@hostname

---

## Quick Fix Commands

### Option 1: Recreate dev.tfvars

```bash
cd infra/envs

# Backup current file
cp dev.tfvars dev.tfvars.backup

# Create new file with correct format
cat > dev.tfvars << 'EOF'
# AWS Configuration
aws_region = "us-east-1"
name       = "student-management"

# SSH Configuration
ssh_key_name   = "java-sb-key"
ssh_public_key = "PASTE_YOUR_SINGLE_LINE_KEY_HERE"

# Your public IP for SSH access (get from https://whatismyip.com)
jenkins_ssh_cidr = "YOUR_PUBLIC_IP/32"

# Instance Sizes
bastion_instance_type       = "t3.micro"
jenkins_sonar_instance_type = "t3.large"
frontend_instance_type      = "t3.micro"
backend_instance_type       = "t3.micro"

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_username       = "admin"
rds_password       = "ChangeThisPassword123!"

# Auto Scaling
frontend_desired_capacity = 1
frontend_min_size        = 1
frontend_max_size        = 2

backend_desired_capacity = 1
backend_min_size        = 1
backend_max_size        = 2
EOF
```

Then edit the file and replace:
- `PASTE_YOUR_SINGLE_LINE_KEY_HERE` with your actual SSH public key
- `YOUR_PUBLIC_IP` with your public IP address
- `ChangeThisPassword123!` with a secure password

### Option 2: Use Terraform Variable

Instead of putting the key in the file, you can pass it as an environment variable:

```bash
# Set the SSH public key as environment variable
export TF_VAR_ssh_public_key="$(cat ~/.ssh/java-sb-key.pub)"

# Then apply
terraform apply -var-file=envs/dev.tfvars
```

---

## Verification Steps

After fixing the file:

1. **Validate syntax:**
   ```bash
   cd infra
   terraform validate
   ```
   Should show: `Success! The configuration is valid.`

2. **Check the plan:**
   ```bash
   terraform plan -var-file=envs/dev.tfvars
   ```
   Should not show any key format errors

3. **Apply:**
   ```bash
   terraform apply -var-file=envs/dev.tfvars
   ```

---

## Common Mistakes to Avoid

❌ **Multi-line key:**
```hcl
ssh_public_key = "ssh-rsa AAAAB3...
...rest of key...
"
```

❌ **Missing quotes:**
```hcl
ssh_public_key = ssh-rsa AAAAB3...
```

❌ **Extra spaces or newlines:**
```hcl
ssh_public_key = "
ssh-rsa AAAAB3...
"
```

✅ **Correct format:**
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...entire_key_one_line...== user@host"
```

---

## If You Don't Have an SSH Key

Generate one:

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/java-sb-key -N ""

# View the public key (copy this entire line)
cat ~/.ssh/java-sb-key.pub
```

---

## Need Your Public IP?

```bash
# Linux/Mac
curl https://ifconfig.me

# Windows PowerShell
(Invoke-WebRequest -Uri "https://ifconfig.me").Content

# Or visit: https://whatismyip.com
```

Then use it in the format: `YOUR_IP/32`

Example: `203.0.113.45/32`

---

## After Fixing

Once you've corrected the `dev.tfvars` file:

```bash
cd infra
terraform validate
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

The apply should now succeed!
