#!/bin/bash
set -ex
yum update -y

# Install Python 3.11 (or latest available)
amazon-linux-extras enable python3.8 || true
yum install -y python3 python3-pip git unzip

# Upgrade pip
python3 -m pip install --upgrade pip

# Create appuser
useradd -m -s /bin/bash appuser || true
mkdir -p /opt/frontend/src
chown -R appuser:appuser /opt/frontend

# Create virtual environment
sudo -u appuser python3 -m venv /opt/frontend/.venv

# Install Streamlit and dependencies (will be updated by Jenkins deployment)
sudo -u appuser /opt/frontend/.venv/bin/pip install streamlit requests pandas

# Get backend URL from Terraform
BACKEND_URL="${backend_url}"

# Create systemd service for Streamlit
cat >/etc/systemd/system/frontend.service <<EOF
[Unit]
Description=Streamlit Frontend - Student Management System
After=network.target

[Service]
User=appuser
Group=appuser
WorkingDirectory=/opt/frontend
Environment="PATH=/opt/frontend/.venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="API_URL=${backend_url}"
ExecStart=/opt/frontend/.venv/bin/streamlit run src/app.py --server.port=80 --server.address=0.0.0.0 --server.headless=true
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable frontend.service

# Note: Jenkins will SCP frontend-artifact.zip to /tmp/,
# then unzip to /opt/frontend and restart the service
