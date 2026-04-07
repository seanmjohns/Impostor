#!/bin/bash
set -e


# Update system
yum update -y


# Install required packages
yum install -y aws-cli unzip


# Create application directory
mkdir -p /opt/impostor
cd /opt/impostor


# Download artifacts from S3
echo "Downloading application artifacts from S3..."
aws s3 cp s3://${s3_bucket}/impostor /opt/impostor/impostor
aws s3 cp s3://${s3_bucket}/index.html /opt/impostor/index.html
aws s3 cp s3://${s3_bucket}/wordlists/ /opt/impostor/wordlists/ --recursive


# Make binary executable
chmod +x /opt/impostor/impostor


# Create a systemd service file for the Go app
cat > /etc/systemd/system/impostor.service << 'EOF'
[Unit]
Description=Impostor Game Server
After=network.target


[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/impostor
ExecStart=/opt/impostor/impostor -port ${port}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal


[Install]
WantedBy=multi-user.target
EOF


# Set proper ownership
chown -R ec2-user:ec2-user /opt/impostor


# Enable and start the service
systemctl daemon-reload
systemctl enable impostor
systemctl start impostor


# Wait for service to start
sleep 3


# Install Caddy if domain is provided
%{ if domain != "" }
echo "Installing Caddy for HTTPS..."


# Install Caddy using official binary
CADDY_VERSION="2.7.6"
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
   CADDY_ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
   CADDY_ARCH="amd64"
fi


# Download and install Caddy
curl -L "https://github.com/caddyserver/caddy/releases/download/v$${CADDY_VERSION}/caddy_$${CADDY_VERSION}_linux_$${CADDY_ARCH}.tar.gz" -o /tmp/caddy.tar.gz
tar -xzf /tmp/caddy.tar.gz -C /tmp
mv /tmp/caddy /usr/bin/caddy
chmod +x /usr/bin/caddy
rm /tmp/caddy.tar.gz


# Create caddy user
groupadd --system caddy
useradd --system --gid caddy --create-home --home-dir /var/lib/caddy --shell /usr/sbin/nologin caddy


# Create directories
mkdir -p /etc/caddy
mkdir -p /var/lib/caddy/.local/share/caddy


# Create Caddyfile
cat > /etc/caddy/Caddyfile << 'CADDYEOF'
${domain} {
   reverse_proxy localhost:${port}
   encode gzip
}
CADDYEOF


# Set permissions
chown -R caddy:caddy /etc/caddy
chown -R caddy:caddy /var/lib/caddy


# Create systemd service
cat > /etc/systemd/system/caddy.service << 'SERVICEEOF'
[Unit]
Description=Caddy Web Server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target


[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE


[Install]
WantedBy=multi-user.target
SERVICEEOF


# Enable and start Caddy
systemctl daemon-reload
systemctl enable caddy
systemctl start caddy


echo "Caddy installed and configured for ${domain}"
echo "Make sure your DNS points ${domain} to this server's IP!"
echo "Access the game at https://${domain}"
%{ else }
echo "No domain configured. Access the game at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):${port}"
%{ endif }


# Check service status
systemctl status impostor --no-pager


echo "Impostor game server installation complete!"


