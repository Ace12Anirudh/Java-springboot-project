#!/bin/bash
# Manual installation script for Jenkins and SonarQube on Amazon Linux 2
# Run this on the Jenkins/SonarQube server to fix the installation

set -e

echo "=== Starting Manual Jenkins and SonarQube Installation ==="

# Update system
sudo yum update -y

# Install Java 17
echo "Installing Java 17..."
sudo amazon-linux-extras enable java-openjdk17
sudo yum install -y java-17-openjdk java-17-openjdk-devel

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk" | sudo tee /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/java.sh
source /etc/profile.d/java.sh

# Install Jenkins
echo "Installing Jenkins..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Git
sudo yum install -y git

# Install Docker
echo "Installing Docker..."
sudo amazon-linux-extras install docker -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user

# Install Maven
echo "Installing Maven..."
cd /opt
sudo wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
sudo tar xzf apache-maven-3.9.6-bin.tar.gz
sudo ln -s apache-maven-3.9.6 maven
echo "export M2_HOME=/opt/maven" | sudo tee /etc/profile.d/maven.sh
echo "export PATH=\$M2_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/maven.sh

# Install Terraform
echo "Installing Terraform..."
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install zip/unzip
sudo yum install -y zip unzip

# Install SonarQube Scanner
echo "Installing SonarQube Scanner..."
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
sudo unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip
sudo ln -s sonar-scanner-5.0.1.3006-linux sonar-scanner
echo "export SONAR_SCANNER_HOME=/opt/sonar-scanner" | sudo tee /etc/profile.d/sonar.sh
echo "export PATH=\$SONAR_SCANNER_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/sonar.sh

# Create SonarQube user
echo "Setting up SonarQube..."
sudo useradd -r -s /bin/bash sonarqube

# Download and install SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
sudo unzip -q sonarqube-10.3.0.82913.zip
sudo mv sonarqube-10.3.0.82913 sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Configure SonarQube
sudo tee /opt/sonarqube/conf/sonar.properties > /dev/null <<EOF
sonar.jdbc.username=
sonar.jdbc.password=
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.log.level=INFO
sonar.path.logs=logs
EOF

# Set system limits
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF
sudo sysctl -p

sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF

# Create SonarQube systemd service
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
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
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

# Install Node.js
echo "Installing Node.js..."
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install Python 3
sudo yum install -y python3 python3-pip

# Create helper scripts
sudo tee /usr/local/bin/get-jenkins-password > /dev/null <<'EOF'
#!/bin/bash
echo "Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Password file not found yet. Wait a few moments and try again."
EOF
sudo chmod +x /usr/local/bin/get-jenkins-password

sudo tee /usr/local/bin/check-services > /dev/null <<'EOF'
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
sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Not available yet"
EOF
sudo chmod +x /usr/local/bin/check-services

# Restart Jenkins
sudo systemctl restart jenkins

echo "=== Installation Complete ==="
echo "Jenkins is running on port 8080"
echo "SonarQube is running on port 9000"
echo "Run 'get-jenkins-password' to retrieve Jenkins initial admin password"
echo "Run 'check-services' to check service status"
