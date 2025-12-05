#!/bin/bash
# Manual installation script for Maven and SonarQube
# Run this on the Jenkins server to complete the installation

set -e

echo "=== Installing Maven and SonarQube ==="

############################
# Maven Installation
############################
echo "Installing Maven..."
cd /opt
wget --tries=3 --timeout=30 https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz || \
wget --tries=3 --timeout=30 https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.6/apache-maven-3.9.6-bin.tar.gz

if [ -f apache-maven-3.9.6-bin.tar.gz ]; then
    sudo tar xzf apache-maven-3.9.6-bin.tar.gz
    sudo ln -s /opt/apache-maven-3.9.6 /opt/maven
    
    sudo tee /etc/profile.d/maven.sh > /dev/null <<EOF
export M2_HOME=/opt/maven
export PATH=\$M2_HOME/bin:\$PATH
EOF
    source /etc/profile.d/maven.sh
    echo "✅ Maven installed successfully"
    mvn --version
else
    echo "❌ Maven download failed"
    exit 1
fi

############################
# SonarQube Scanner
############################
echo "Installing SonarQube Scanner..."
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
sudo unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip
sudo ln -s /opt/sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner

sudo tee /etc/profile.d/sonar.sh > /dev/null <<EOF
export SONAR_SCANNER_HOME=/opt/sonar-scanner
export PATH=\$SONAR_SCANNER_HOME/bin:\$PATH
EOF
source /etc/profile.d/sonar.sh
echo "✅ SonarQube Scanner installed"

############################
# SonarQube Server
############################
echo "Installing SonarQube Server..."
sudo useradd -r -s /bin/bash sonarqube || echo "User sonarqube already exists"

cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
sudo unzip -q sonarqube-10.3.0.82913.zip
sudo mv sonarqube-10.3.0.82913 sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Configure SonarQube
sudo tee /opt/sonarqube/conf/sonar.properties > /dev/null <<EOF
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.jdbc.username=
sonar.jdbc.password=
sonar.log.level=INFO
EOF

# Kernel tuning
echo "Configuring kernel parameters..."
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
sonarqube soft nofile 131072
sonarqube hard nofile 131072
sonarqube soft nproc 8192
sonarqube hard nproc 8192
EOF

# Create systemd service
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
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

# Start SonarQube
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "✅ SonarQube installed and started"
echo ""
echo "=== Installation Complete ==="
echo "Maven: $(mvn --version | head -1)"
echo "SonarQube: Starting (may take 2-3 minutes)"
echo ""
echo "Check status with: sudo systemctl status sonarqube"
