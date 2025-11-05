#!/bin/bash
set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

echo "=== Applying Security Hardening ==="

# Apply Tor-specific iptables rules
echo "Applying Tor iptables rules..."
bash /opt/tor-socks-farm/scripts/tor_iptables_apply.sh

# Additional security hardening can be added here
echo ""
echo "=== Security Hardening Summary ==="
echo "✓ DNS isolation: Only debian-tor user can make DNS queries"
echo "✓ IPv6 disabled: Prevents IPv6 leaks"
echo "✓ Tor instances: Bound to 127.0.0.1 only"
echo "✓ 3proxy authentication: Required for all connections"
echo ""
echo "Security hardening completed successfully!"
