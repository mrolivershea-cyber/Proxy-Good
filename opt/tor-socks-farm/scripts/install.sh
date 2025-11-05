#!/bin/bash
set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

echo "=== Tor-SOCKS Farm Installation Script ==="
echo "Starting installation process..."

# Install required packages
echo "Installing packages: tor, 3proxy, netcat-traditional, jq..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y tor 3proxy netcat-traditional jq

# Create system users
echo "Creating system users..."
useradd -r -s /usr/sbin/nologin debian-tor 2>/dev/null || true
useradd -r -s /usr/sbin/nologin proxy 2>/dev/null || true

# Copy systemd units
echo "Installing systemd units..."
cp /opt/tor-socks-farm/systemd/*.service /etc/systemd/system/
cp /opt/tor-socks-farm/systemd/*.timer /etc/systemd/system/

# Disable IPv6
echo "Disabling IPv6..."
if ! grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
  cat >> /etc/sysctl.conf << EOF

# Disable IPv6 for Tor-SOCKS Farm
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
  sysctl -p
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p /var/lib/tor
mkdir -p /var/log/tor
mkdir -p /etc/tor
mkdir -p /etc/3proxy
chown debian-tor:debian-tor /var/lib/tor
chown debian-tor:debian-tor /var/log/tor

# Reload systemd
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "=== Installation completed successfully ==="
echo "Next steps:"
echo "  1. Run: bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50"
echo "  2. Run: bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50"
echo "  3. Run: bash /opt/tor-socks-farm/scripts/enable_rotation.sh"
echo "  4. Run: bash /opt/tor-socks-farm/firewall/hardening.sh"
