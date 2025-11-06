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
echo "Installing packages: tor, netcat-traditional, jq, build-essential..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y tor netcat-traditional jq build-essential

# Install 3proxy from source if not already installed
if ! command -v 3proxy &> /dev/null; then
  echo "Installing 3proxy from source..."
  cd /tmp
  wget -q https://github.com/3proxy/3proxy/archive/refs/tags/0.9.4.tar.gz
  tar xzf 0.9.4.tar.gz
  cd 3proxy-0.9.4
  make -f Makefile.Linux
  cp bin/3proxy /usr/bin/
  chmod +x /usr/bin/3proxy
  cd /tmp
  rm -rf 3proxy-0.9.4 0.9.4.tar.gz
  echo "3proxy installed successfully"
else
  echo "3proxy already installed"
fi

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
echo ""
echo "⚠️  SECURITY WARNING ⚠️"
echo "Default passwords in config/users.csv and config/control.password are WEAK!"
echo "For production use, generate strong passwords:"
echo "  openssl rand -base64 32 > /opt/tor-socks-farm/config/control.password"
echo "  for i in {1..50}; do PASS=\$(openssl rand -base64 16); printf \"%03d,user%03d,%s\n\" \$i \$i \"\$PASS\"; done > /opt/tor-socks-farm/config/users.csv.new"
echo ""
echo "Next steps:"
echo "  1. Run: bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50"
echo "  2. Run: bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50"
echo "  3. Run: bash /opt/tor-socks-farm/scripts/enable_rotation.sh"
echo "  4. Run: bash /opt/tor-socks-farm/firewall/hardening.sh"
