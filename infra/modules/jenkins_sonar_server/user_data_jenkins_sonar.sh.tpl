#!/bin/bash
# User data script to install Jenkins and SonarQube on Amazon Linux 2

set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting Jenkins and SonarQube Installation ==="

# Update system
yum update -y

# Install Java 17 (required for both Jenkins and SonarQube)
echo "Installing Java 17..."
amazon-linux-extras enable java-openjdk17
yum install -y java-17-openjdk java-17-openjdk-devel
java -version

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk" >> /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile.d/java.sh
source /etc/profile.d/java.sh

# Install Jenkins
echo "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to generate initial password
echo "Waiting for Jenkins to start..."
sleep 30

# Install Git (required for Jenkins)
yum install -y git

# Install Docker (for Jenkins agents)
echo "Installing Docker..."
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins
usermod -aG docker ec2-user

# Install Maven
echo "Installing Maven..."
cd /opt
wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
tar xzf apache-maven-3.9.6-bin.tar.gz
ln -s apache-maven-3.9.6 maven
echo "export M2_HOME=/opt/maven" >> /etc/profile.d/maven.sh
echo "export PATH=\$M2_HOME/bin:\$PATH" >> /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

# Install Terraform
echo "Installing Terraform..."
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y terraform

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install zip/unzip utilities
yum install -y zip unzip

# Install SonarQube Scanner
echo "Installing SonarQube Scanner..."
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip
ln -s sonar-scanner-5.0.1.3006-linux sonar-scanner
echo "export SONAR_SCANNER_HOME=/opt/sonar-scanner" >> /etc/profile.d/sonar.sh
echo "export PATH=\$SONAR_SCANNER_HOME/bin:\$PATH" >> /etc/profile.d/sonar.sh
source /etc/profile.d/sonar.sh

# Create SonarQube user
echo "Setting up SonarQube..."
useradd -r -s /bin/bash sonarqube

# Download and install SonarQube
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
unzip -q sonarqube-10.3.0.82913.zip
mv sonarqube-10.3.0.82913 sonarqube
chown -R sonarqube:sonarqube /opt/sonarqube

# Configure SonarQube
cat > /opt/sonarqube/conf/sonar.properties <<EOF
sonar.jdbc.username=
sonar.jdbc.password=
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.log.level=INFO
sonar.path.logs=logs
EOF

# Set system limits for SonarQube
cat >> /etc/sysctl.conf <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF
sysctl -p

cat >> /etc/security/limits.conf <<EOF
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF

# Create SonarQube systemd service
cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=on-failure
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

# Start SonarQube
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

# Install Node.js (for frontend builds if needed)
echo "Installing Node.js..."
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Python 3 and pip (for Python projects)
yum install -y python3 python3-pip

# Create a helper script for accessing Jenkins initial password
cat > /usr/local/bin/get-jenkins-password <<'EOF'
#!/bin/bash
echo "Jenkins Initial Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Password file not found yet. Wait a few moments and try again."
EOF
chmod +x /usr/local/bin/get-jenkins-password

# Create a helper script for checking service status
cat > /usr/local/bin/check-services <<'EOF'
#!/bin/bash
echo "=== Jenkins Status ==="
systemctl status jenkins --no-pager
echo ""
echo "=== SonarQube Status ==="
systemctl status sonarqube --no-pager
echo ""
echo "=== Jenkins URL ==="
echo "http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "=== SonarQube URL ==="
echo "http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "=== Jenkins Initial Password ==="
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Not available yet"
EOF
chmod +x /usr/local/bin/check-services

# Restart Jenkins to pick up Docker group membership
systemctl restart jenkins

echo "=== Installation Complete ==="
echo "Jenkins is running on port 8080"
echo "SonarQube is running on port 9000"
echo "Run 'get-jenkins-password' to retrieve Jenkins initial admin password"
echo "Run 'check-services' to check service status"
