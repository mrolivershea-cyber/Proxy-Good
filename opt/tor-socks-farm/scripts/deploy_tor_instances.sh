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

echo "=== Deploying $COUNT Tor instances ==="

# Read control password and generate hash
CONTROL_PASSWORD=$(cat /opt/tor-socks-farm/config/control.password | tr -d '\n')
HASHED_PASSWORD=$(tor --hash-password "$CONTROL_PASSWORD" | tail -n1)

# Deploy each instance
for i in $(seq 1 $COUNT); do
  INSTANCE_NUM=$(printf "%03d" $i)
  SOCKS_PORT=$((BASE_SOCKS_PORT + i))
  CTRL_PORT=$((BASE_CTRL_PORT + i))
  DNS_PORT=$((BASE_DNS_PORT + i))
  TRANS_PORT=$((BASE_TRANS_PORT + i))
  
  echo "Deploying instance $INSTANCE_NUM (SOCKS: $SOCKS_PORT, Control: $CTRL_PORT)..."
  
  # Create data directory
  DATA_DIR="/var/lib/tor/instance$INSTANCE_NUM"
  mkdir -p "$DATA_DIR"
  chown debian-tor:debian-tor "$DATA_DIR"
  chmod 700 "$DATA_DIR"
  
  # Generate torrc configuration
  cat > /etc/tor/torrc.instance$INSTANCE_NUM << EOF
# Tor configuration for instance $INSTANCE_NUM
DataDirectory $DATA_DIR
SocksPort 127.0.0.1:$SOCKS_PORT
ControlPort 127.0.0.1:$CTRL_PORT
HashedControlPassword $HASHED_PASSWORD
DNSPort 127.0.0.1:$DNS_PORT
TransPort 127.0.0.1:$TRANS_PORT
Log notice file /var/log/tor/instance$INSTANCE_NUM.log
ClientOnly 1
AvoidDiskWrites 1
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
EOF
  
  # Set permissions
  chown debian-tor:debian-tor /etc/tor/torrc.instance$INSTANCE_NUM
  chmod 644 /etc/tor/torrc.instance$INSTANCE_NUM
  
  # Enable and start the service
  systemctl enable tor@$INSTANCE_NUM 2>/dev/null || true
  systemctl restart tor@$INSTANCE_NUM
  
  # Wait a bit for the service to start
  sleep 0.5
done

echo ""
echo "=== Verifying instances ==="

# Check status of all instances
FAILED=0
for i in $(seq -f "%03g" 1 $COUNT); do
  INSTANCE_NUM=$(printf "%03d" $i)
  if systemctl is-active --quiet tor@$INSTANCE_NUM; then
    echo "✓ Instance $INSTANCE_NUM is active"
  else
    echo "✗ Instance $INSTANCE_NUM failed to start"
    FAILED=$((FAILED + 1))
  fi
done

if [ $FAILED -eq 0 ]; then
  echo ""
  echo "=== All $COUNT Tor instances deployed successfully ==="
  echo "SOCKS ports: $((BASE_SOCKS_PORT + 1)) - $((BASE_SOCKS_PORT + COUNT))"
  echo "Control ports: $((BASE_CTRL_PORT + 1)) - $((BASE_CTRL_PORT + COUNT))"
else
  echo ""
  echo "WARNING: $FAILED instances failed to start"
  echo "Check logs with: journalctl -u tor@NNN"
  exit 1
fi
