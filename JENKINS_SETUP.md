# Jenkins Pipeline Setup Guide

## Issue: "No data available. This Pipeline has not yet run"

This message appears when Jenkins hasn't executed the pipeline yet. Follow the steps below to configure and run your pipeline.

---

## Prerequisites

### 1. Jenkins Installation
Ensure Jenkins is installed and running. You need Jenkins with the following plugins:
- **Pipeline Plugin**
- **Git Plugin**
- **AWS Credentials Plugin**
- **SSH Agent Plugin**
- **Credentials Binding Plugin**

### 2. Required Tools on Jenkins Agent
The following tools must be installed on the Jenkins agent/node:
- **Java 17+** (for Maven builds)
- **Maven 3.6+**
- **Terraform** (latest version)
- **AWS CLI v2**
- **SonarQube Scanner** (optional, for code quality)
- **zip/unzip utilities**
- **SSH client**

---

## Step-by-Step Configuration

### Step 1: Configure Jenkins Credentials

Navigate to **Jenkins Dashboard → Manage Jenkins → Credentials → System → Global credentials**

#### A. AWS Credentials (`aws-creds`)
1. Click **Add Credentials**
2. Kind: **AWS Credentials**
3. ID: `aws-creds`
4. Access Key ID: Your AWS Access Key
5. Secret Access Key: Your AWS Secret Key
6. Description: AWS credentials for Terraform and deployment

#### B. SSH Private Key (`jenkins-ssh-key`)
1. Click **Add Credentials**
2. Kind: **SSH Username with private key**
3. ID: `jenkins-ssh-key`
4. Username: `ec2-user`
5. Private Key: **Enter directly** (paste your EC2 key pair private key)
6. Description: SSH key for EC2 instances

#### C. SonarQube Token (`sonar-token`)
1. Click **Add Credentials**
2. Kind: **Secret text**
3. Secret: Your SonarQube authentication token
4. ID: `sonar-token`
5. Description: SonarQube authentication token

> **Note:** If you don't have SonarQube, you can skip this and the pipeline will continue (stages have `|| true` to prevent failures)

---

### Step 2: Create Jenkins Pipeline Job

1. **Go to Jenkins Dashboard**
2. Click **New Item**
3. Enter name: `student-management-deployment` (or your preferred name)
4. Select **Pipeline**
5. Click **OK**

---

### Step 3: Configure Pipeline

In the pipeline configuration page:

#### General Settings
- ✅ Check **GitHub project** (optional)
  - Project url: Your GitHub repository URL

#### Build Triggers (Optional)
- ✅ **Poll SCM** or **GitHub hook trigger for GITScm polling**
  - Schedule: `H/5 * * * *` (polls every 5 minutes)

#### Pipeline Definition
1. **Definition:** Pipeline script from SCM
2. **SCM:** Git
3. **Repository URL:** Your Git repository URL
   - Example: `https://github.com/yourusername/Java-springboot-project.git`
4. **Credentials:** Add your Git credentials if private repo
5. **Branch Specifier:** `*/main` (or your branch name)
6. **Script Path:** `infra/Jenkinsfile`

> **IMPORTANT:** The Script Path must be `infra/Jenkinsfile` since your Jenkinsfile is located in the `infra` directory.

7. Click **Save**

---

### Step 4: Run the Pipeline

1. Go to your pipeline job page
2. Click **Build Now**
3. The pipeline should start executing

---

## Common Issues and Solutions

### Issue 1: "No data available"
**Cause:** Pipeline hasn't been triggered yet  
**Solution:** Click "Build Now" to trigger the first build

### Issue 2: Jenkinsfile not found
**Cause:** Incorrect Script Path  
**Solution:** Ensure Script Path is set to `infra/Jenkinsfile`

### Issue 3: Credentials not found
**Cause:** Missing or incorrectly named credentials  
**Solution:** 
- Verify credential IDs match exactly:
  - `aws-creds`
  - `jenkins-ssh-key`
  - `sonar-token`

### Issue 4: Tool not found (mvn, terraform, etc.)
**Cause:** Tools not installed on Jenkins agent  
**Solution:** 
- Install required tools on the Jenkins agent
- Or configure tools in **Manage Jenkins → Global Tool Configuration**

### Issue 5: Permission denied (SSH)
**Cause:** SSH key doesn't have correct permissions or doesn't match EC2 key pair  
**Solution:**
- Ensure the SSH private key in Jenkins matches the key pair used in Terraform
- The key pair name in `infra/envs/dev.tfvars` should match

### Issue 6: Terraform state issues
**Cause:** Terraform state file conflicts or missing  
**Solution:**
- Consider using remote state (S3 backend)
- Or ensure workspace is clean between runs

### Issue 7: SonarQube scanner not found
**Cause:** SonarQube scanner not installed  
**Solution:**
- Install SonarQube scanner on Jenkins agent
- Or remove/comment out SonarQube stages if not needed

---

## Pipeline Stages Explained

1. **Checkout** - Clones the Git repository
2. **Sonar - Frontend** - Runs SonarQube analysis on frontend code
3. **Build Frontend artifact** - Packages frontend as ZIP
4. **Sonar - Backend** - Runs SonarQube analysis on backend code
5. **Build Backend artifact** - Builds Spring Boot JAR and packages it
6. **Terraform Init & Apply** - Provisions AWS infrastructure
7. **Discover Instances & Deploy via SSH** - Deploys artifacts to EC2 instances via bastion host

---

## Verifying Pipeline Execution

After running the pipeline:

1. **Check Console Output**
   - Click on the build number (e.g., #1)
   - Click **Console Output**
   - Review logs for errors

2. **Check Stage View**
   - Should show all stages with status (green = success, red = failure)

3. **Verify AWS Resources**
   - Check AWS Console for created resources
   - Verify EC2 instances are running
   - Check ALB health checks

---

## Quick Start Checklist

- [ ] Jenkins installed with required plugins
- [ ] Tools installed on Jenkins agent (Maven, Terraform, AWS CLI)
- [ ] AWS credentials configured in Jenkins (`aws-creds`)
- [ ] SSH key configured in Jenkins (`jenkins-ssh-key`)
- [ ] SonarQube token configured (optional, `sonar-token`)
- [ ] Pipeline job created
- [ ] Pipeline configured with correct Git repository
- [ ] Script Path set to `infra/Jenkinsfile`
- [ ] First build triggered with "Build Now"

---

## Alternative: Run Pipeline Without SonarQube

If you don't have SonarQube set up, the pipeline will still work because all SonarQube commands have `|| true` which prevents failures. However, you can also:

1. Remove the SonarQube stages from the Jenkinsfile, or
2. Set up a local SonarQube instance, or
3. Use SonarCloud (cloud-based SonarQube)

---

## Next Steps

Once the pipeline runs successfully:

1. Check the **Stage View** - all stages should be green
2. Verify infrastructure in AWS Console
3. Access your application via the ALB DNS name
4. Monitor application logs on EC2 instances

---

## Support

If you encounter issues:
1. Check the **Console Output** for detailed error messages
2. Verify all credentials are correctly configured
3. Ensure all required tools are installed
4. Check AWS permissions for the IAM user/role
5. Verify network connectivity from Jenkins to AWS
