#!/bin/bash
set -ex
yum update -y

# Install Java 17
yum install -y java-17-amazon-corretto-devel unzip

# Create appuser
useradd -m -s /bin/bash appuser || true
mkdir -p /opt/backend
chown -R appuser:appuser /opt/backend

# Get RDS endpoint from Terraform output or use placeholder
# This will be set by Terraform via templatefile
DB_URL="${db_url}"
DB_USERNAME="${db_username}"
DB_PASSWORD="${db_password}"

# Create systemd service for Spring Boot backend
cat >/etc/systemd/system/backend.service <<'EOF'
[Unit]
Description=Spring Boot Backend - Student Management System
After=network.target

[Service]
User=appuser
Group=appuser
WorkingDirectory=/opt/backend
Environment="DB_URL=${db_url}"
Environment="DB_USERNAME=${db_username}"
Environment="DB_PASSWORD=${db_password}"
ExecStart=/usr/bin/java -jar /opt/backend/backend.jar
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable backend.service

# Note: Jenkins will SCP backend.jar to /tmp/backend-artifact.zip,
# then unzip to /opt/backend and restart the service
