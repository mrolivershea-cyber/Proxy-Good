#!/bin/bash
set -e

echo "=== Tor Identity Rotation Started at $(date) ==="

# Source configuration
source /opt/tor-socks-farm/config/torfarm.env

# Read control password
CONTROL_PASSWORD=$(cat /opt/tor-socks-farm/config/control.password | tr -d '\n')

# Find all active Tor instances
INSTANCES=$(ls /etc/tor/torrc.instance* 2>/dev/null | sed 's/.*instance//' || true)

if [ -z "$INSTANCES" ]; then
  echo "No Tor instances found"
  exit 0
fi

ROTATED=0
FAILED=0

for INSTANCE_NUM in $INSTANCES; do
  CTRL_PORT=$((BASE_CTRL_PORT + 10#$INSTANCE_NUM))
  
  # Get country from countries.map
  COUNTRY=$(grep "^$INSTANCE_NUM=" /opt/tor-socks-farm/config/countries.map 2>/dev/null | cut -d'=' -f2 || echo "*")
  
  echo "Rotating instance $INSTANCE_NUM (port $CTRL_PORT, country: $COUNTRY)..."
  
  # Prepare control commands
  if [ "$COUNTRY" = "*" ]; then
    # No country restriction - clear ExitNodes
    COMMANDS="AUTHENTICATE \"$CONTROL_PASSWORD\"
SETCONF ExitNodes=
SIGNAL NEWNYM
QUIT"
  else
    # Set specific country
    COUNTRY_UPPER=$(echo "$COUNTRY" | tr '[:lower:]' '[:upper:]')
    COMMANDS="AUTHENTICATE \"$CONTROL_PASSWORD\"
SETCONF ExitNodes={$COUNTRY_UPPER} StrictNodes=1
SIGNAL NEWNYM
QUIT"
  fi
  
  # Send commands via netcat
  RESPONSE=$(echo -e "$COMMANDS" | nc 127.0.0.1 $CTRL_PORT 2>&1 || true)
  
  if echo "$RESPONSE" | grep -q "250 OK"; then
    echo "  ✓ Instance $INSTANCE_NUM rotated successfully"
    ROTATED=$((ROTATED + 1))
  else
    echo "  ✗ Instance $INSTANCE_NUM rotation failed"
    echo "  Response: $RESPONSE"
    FAILED=$((FAILED + 1))
  fi
  
  # Small delay between rotations
  sleep 0.1
done

echo ""
echo "=== Rotation completed at $(date) ==="
echo "Rotated: $ROTATED instances"
echo "Failed: $FAILED instances"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
