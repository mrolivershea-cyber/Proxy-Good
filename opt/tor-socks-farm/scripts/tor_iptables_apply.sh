#!/bin/bash
set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

echo "=== Applying Tor-specific iptables rules ==="

# Create backup of current rules
BACKUP_FILE="/root/iptables.backup.$(date +%s)"
echo "Creating backup: $BACKUP_FILE"
iptables-save > "$BACKUP_FILE"

# Get UID of debian-tor user
TOR_UID=$(id -u debian-tor)
echo "Tor UID: $TOR_UID"

# Block all DNS queries except from debian-tor user
echo "Blocking DNS queries from non-Tor processes..."
iptables -I OUTPUT -p udp --dport 53 -m owner ! --uid-owner $TOR_UID -j REJECT
iptables -I OUTPUT -p tcp --dport 53 -m owner ! --uid-owner $TOR_UID -j REJECT

echo "✓ DNS isolation rules applied"

echo ""
echo "=== iptables rules applied successfully ==="
echo ""
echo "Backup saved to: $BACKUP_FILE"
echo ""
echo "To rollback these changes, run:"
echo "  iptables-restore < $BACKUP_FILE"
echo ""
echo "Current OUTPUT rules:"
iptables -L OUTPUT -n -v --line-numbers | head -n 20
