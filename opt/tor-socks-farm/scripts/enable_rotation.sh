#!/bin/bash
set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

echo "=== Enabling Tor Identity Rotation ==="

# Source configuration
source /opt/tor-socks-farm/config/torfarm.env

# Update timer configuration with rotation interval
TIMER_FILE="/etc/systemd/system/rotate.timer"

if [ ! -f "$TIMER_FILE" ]; then
  echo "ERROR: Timer file not found at $TIMER_FILE"
  echo "Please run install.sh first"
  exit 1
fi

# Update OnUnitActiveSec in timer file
echo "Setting rotation interval to ${ROTATE_EVERY_MIN} minutes..."
sed -i "s/OnUnitActiveSec=.*m/OnUnitActiveSec=${ROTATE_EVERY_MIN}m/" "$TIMER_FILE"

# Reload systemd
systemctl daemon-reload

# Enable and start the timer
systemctl enable rotate.timer
systemctl restart rotate.timer

echo ""
echo "=== Rotation timer enabled successfully ==="
echo "Rotation interval: ${ROTATE_EVERY_MIN} minutes"
echo "First rotation: 5 minutes after boot"
echo ""
echo "Check timer status with: systemctl status rotate.timer"
echo "Check rotation logs with: journalctl -u rotate.service"
echo ""
echo "To manually trigger rotation now, run:"
echo "  systemctl start rotate.service"
