#!/bin/bash
#
# Automated Jenkins + SonarQube Installation for Amazon Linux 2
# Fixed version for AL2 compatibility
# Safe, idempotent, logged install
set -e
# Log everything
exec > >(tee /var/log/user-data-fixed.log | logger -t user-data -s 2> /dev/console)
exec 2>&1
echo "=== Starting Jenkins + SonarQube Installation (AL2 Fixed) ==="
############################
# System Update
############################
echo "Updating system..."
yum update -y
yum install -y wget curl unzip zip git
############################
# Install Java (Required for Jenkins & SonarQube)
############################
echo "Installing Java 17..."
# Import Amazon Corretto public key
rpm --import https://yum.corretto.aws/corretto.key
# Add Corretto yum repository
wget -O /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
# Install Corretto 17
yum install -y java-17-amazon-corretto-devel
cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
source /etc/profile.d/java.sh
############################
# Install Docker
############################
echo "Installing Docker..."
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
############################
# Jenkins Installation
############################
echo "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum clean all
yum makecache
yum install -y fontconfig jenkins
systemctl enable jenkins
systemctl start jenkins
############################
# Maven Installation
############################
echo "=== Installing Maven 3.9.6 ==="
cd /opt
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
sudo tar -xzf apache-maven-3.9.6-bin.tar.gz
sudo ln -s /opt/apache-maven-3.9.6 /opt/maven
sudo tee /etc/profile.d/maven.sh <<EOF
export M2_HOME=/opt/maven
export PATH=\$M2_HOME/bin:\$PATH
EOF
sudo chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
echo "=== Maven Installed Successfully ==="
mvn -version
echo "Maven installed successfully"
############################
# Terraform Installation
############################
echo "Installing Terraform..."
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y terraform
############################
# AWS CLI v2
############################
echo "Installing AWS CLI v2..."
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip
############################
# SonarQube Scanner (CLI)
############################
echo "Installing SonarQube Scanner..."
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip
ln -s /opt/sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner
cat > /etc/profile.d/sonar.sh <<EOF
export SONAR_SCANNER_HOME=/opt/sonar-scanner
export PATH=\$SONAR_SCANNER_HOME/bin:\$PATH
EOF
source /etc/profile.d/sonar.sh
############################
# SonarQube Server Installation
############################
echo "Installing SonarQube Server..."
useradd -r -s /bin/bash sonarqube
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
unzip -q sonarqube-10.3.0.82913.zip
mv sonarqube-10.3.0.82913 sonarqube
chown -R sonarqube:sonarqube /opt/sonarqube
############################
# SonarQube Config
############################
cat > /opt/sonarqube/conf/sonar.properties <<EOF
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.jdbc.username=
sonar.jdbc.password=
sonar.log.level=INFO
EOF
############################
# Kernel Tuning for SonarQube
############################
echo "Configuring kernel parameters..."
echo "vm.max_map_count=524288" >> /etc/sysctl.conf
echo "fs.file-max=131072" >> /etc/sysctl.conf
sysctl -p
cat >> /etc/security/limits.conf <<EOF
sonarqube soft nofile 131072
sonarqube hard nofile 131072
sonarqube soft nproc 8192
sonarqube hard nproc 8192
EOF
############################
# SonarQube Systemd
############################
cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube Service
After=syslog.target network.target
[Service]
Type=forking
User=sonarqube
Group=sonarqube
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=131072
LimitNPROC=8192
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube
############################
# Helper scripts
############################
cat > /usr/local/bin/get-jenkins-password <<'EOF'
#!/bin/bash
echo "Jenkins Initial Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Password not ready yet"
EOF
chmod +x /usr/local/bin/get-jenkins-password
cat > /usr/local/bin/check-services <<'EOF'
#!/bin/bash
echo "=== Jenkins ==="
systemctl status jenkins --no-pager
echo ""
echo "=== SonarQube ==="
systemctl status sonarqube --no-pager
echo ""
echo "Jenkins: http://$(hostname -I | awk '{print $1}'):8080"
echo "SonarQube: http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "Initial Jenkins Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Not available yet"
EOF
chmod +x /usr/local/bin/check-services
echo "Installation complete!"
echo "Run: check-services"
echo "Run: get-jenkins-password"