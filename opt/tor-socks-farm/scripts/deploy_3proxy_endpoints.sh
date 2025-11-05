#!/bin/bash
set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

# Source configuration
source /opt/tor-socks-farm/config/torfarm.env

# Get number of instances from argument or use default
COUNT=${1:-$MIN_INSTANCES}

# Validate count
if [ "$COUNT" -gt "$MAX_INSTANCES" ]; then
  echo "ERROR: Instance count ($COUNT) exceeds MAX_INSTANCES ($MAX_INSTANCES)"
  exit 1
fi

echo "=== Deploying $COUNT 3proxy endpoints ==="

# Read template
TEMPLATE=$(cat /opt/tor-socks-farm/3proxy/instance.cfg.tpl)

# Deploy each endpoint
DEPLOYED=0
while IFS=, read -r instance user password; do
  # Skip header line
  if [ "$instance" = "instance" ]; then
    continue
  fi
  
  # Stop if we've deployed enough
  if [ "$DEPLOYED" -ge "$COUNT" ]; then
    break
  fi
  
  INSTANCE_NUM=$instance
  LOCAL_SOCKS=$((BASE_SOCKS_PORT + 10#$INSTANCE_NUM))
  PUBLIC_PORT=$((BASE_PUBLIC_PORT + 10#$INSTANCE_NUM))
  
  echo "Deploying 3proxy for instance $INSTANCE_NUM (Public port: $PUBLIC_PORT)..."
  
  # Generate config from template
  CONFIG="$TEMPLATE"
  CONFIG="${CONFIG//__INSTANCE__/$INSTANCE_NUM}"
  CONFIG="${CONFIG//__USER__/$user}"
  CONFIG="${CONFIG//__PASSWORD__/$password}"
  CONFIG="${CONFIG//__PUBLIC_PORT__/$PUBLIC_PORT}"
  CONFIG="${CONFIG//__LOCAL_SOCKS__/$LOCAL_SOCKS}"
  
  # Write configuration
  echo "$CONFIG" > /etc/3proxy/instance$INSTANCE_NUM.cfg
  chown proxy:proxy /etc/3proxy/instance$INSTANCE_NUM.cfg
  chmod 640 /etc/3proxy/instance$INSTANCE_NUM.cfg
  
  # Enable and start the service
  systemctl enable 3proxy@$INSTANCE_NUM 2>/dev/null || true
  systemctl restart 3proxy@$INSTANCE_NUM
  
  DEPLOYED=$((DEPLOYED + 1))
  sleep 0.2
done < /opt/tor-socks-farm/config/users.csv

echo ""
echo "=== Verifying endpoints ==="

# Check status of all instances
FAILED=0
for i in $(seq -f "%03g" 1 $COUNT); do
  INSTANCE_NUM=$(printf "%03d" $i)
  if systemctl is-active --quiet 3proxy@$INSTANCE_NUM; then
    echo "✓ Endpoint $INSTANCE_NUM is active"
  else
    echo "✗ Endpoint $INSTANCE_NUM failed to start"
    FAILED=$((FAILED + 1))
  fi
done

if [ $FAILED -eq 0 ]; then
  echo ""
  echo "=== All $COUNT 3proxy endpoints deployed successfully ==="
  echo "Public SOCKS5 ports: $((BASE_PUBLIC_PORT + 1)) - $((BASE_PUBLIC_PORT + COUNT))"
  echo "Access with: SERVER_IP:PORT username password"
else
  echo ""
  echo "WARNING: $FAILED endpoints failed to start"
  echo "Check logs with: journalctl -u 3proxy@NNN"
  exit 1
fi
