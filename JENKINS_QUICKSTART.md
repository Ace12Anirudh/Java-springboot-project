# Quick Fix: Jenkins Pipeline "No Data Available"

## The Problem
Your Jenkins pipeline shows **"No data available. This Pipeline has not yet run"** because the pipeline hasn't been triggered yet.

---

## Quick Solution (5 Steps)

### 1. **Configure Jenkins Credentials**
Go to: **Jenkins → Manage Jenkins → Credentials → Global**

Create these 3 credentials:

| ID | Type | Details |
|---|---|---|
| `aws-creds` | AWS Credentials | Your AWS Access Key + Secret Key |
| `jenkins-ssh-key` | SSH Username with private key | Username: `ec2-user`, Private Key: Your EC2 key pair |
| `sonar-token` | Secret text | SonarQube token (optional) |

### 2. **Create Pipeline Job**
1. Jenkins Dashboard → **New Item**
2. Name: `student-management-deployment`
3. Type: **Pipeline**
4. Click **OK**

### 3. **Configure Pipeline**
In the pipeline configuration:

- **Pipeline Definition:** `Pipeline script from SCM`
- **SCM:** `Git`
- **Repository URL:** Your Git repo URL
- **Branch:** `*/main` (or your branch)
- **Script Path:** `infra/Jenkinsfile` ⚠️ **IMPORTANT**

Click **Save**

### 4. **Click "Build Now"**
This will trigger the first pipeline run!

### 5. **Monitor Progress**
- Click on the build number (e.g., #1)
- View **Console Output** for detailed logs
- Check **Stage View** for visual progress

---

## Common Issues

### ❌ "Jenkinsfile not found"
**Fix:** Ensure Script Path is `infra/Jenkinsfile`

### ❌ "Credentials not found"
**Fix:** Verify credential IDs match exactly:
- `aws-creds`
- `jenkins-ssh-key`
- `sonar-token`

### ❌ "mvn: command not found" or "terraform: command not found"
**Fix:** Install required tools on Jenkins agent:
- Maven 3.6+
- Terraform
- AWS CLI v2
- Java 17+

### ❌ SSH connection fails
**Fix:** Ensure the SSH private key in Jenkins matches the EC2 key pair used in Terraform

---

## What the Pipeline Does

1. ✅ Checks out code from Git
2. ✅ Runs SonarQube analysis (optional)
3. ✅ Builds frontend ZIP artifact
4. ✅ Builds backend JAR artifact
5. ✅ Runs Terraform to provision AWS infrastructure
6. ✅ Deploys artifacts to EC2 instances via bastion host

---

## Need More Help?

See the detailed guide: [JENKINS_SETUP.md](file:///c:/Users/Anirudh/Downloads/AWS/projects/java-springboot%20project/Java-springboot-project/JENKINS_SETUP.md)

---

## Verification

After the pipeline runs successfully:

1. **Check AWS Console** - Verify EC2 instances, ALB, RDS are created
2. **Get ALB DNS** - From Terraform outputs or AWS Console
3. **Access Application** - `http://<ALB-DNS>/api/students`

---

## Pipeline Improvements Made

The Jenkinsfile has been enhanced with:
- ✅ Better error messages
- ✅ Validation checks for Terraform outputs
- ✅ Only deploys to instances in "InService" state
- ✅ Clear deployment progress indicators
- ✅ Proper error handling for SSH operations
- ✅ Service status checks after deployment
