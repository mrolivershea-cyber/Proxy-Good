# Deployment Guide - Tor-SOCKS Farm Automation

This guide provides detailed step-by-step instructions for deploying the Tor-SOCKS Farm on your Ubuntu server.

## Prerequisites

Before starting, ensure you have:

1. **Ubuntu Server 22.04 LTS or 24.04 LTS**
2. **Root access** (sudo privileges)
3. **Network connectivity** to download packages
4. **Sufficient resources**:
   - For 50 nodes: 2-4 CPU cores, 2-4 GB RAM, 10 GB disk
   - For 100 nodes: 4-8 CPU cores, 4-8 GB RAM, 20 GB disk
   - For 500 nodes: 16+ CPU cores, 32+ GB RAM, 50+ GB disk

## Step 1: Clone/Copy the Repository

### Option A: From Git Repository

```bash
# Clone the repository
git clone https://github.com/mrolivershea-cyber/Proxy-Good.git
cd Proxy-Good
```

### Option B: Manual Copy

If you downloaded the repository as a zip:

```bash
# Extract and navigate
unzip Proxy-Good-main.zip
cd Proxy-Good-main
```

## Step 2: Copy Project to /opt

```bash
# Create /opt directory if needed
sudo mkdir -p /opt

# Copy the project structure
sudo cp -r opt/tor-socks-farm /opt/

# Verify the copy
ls -la /opt/tor-socks-farm/
```

Expected structure:
```
/opt/tor-socks-farm/
├── 3proxy/
├── config/
├── firewall/
├── scripts/
└── systemd/
```

## Step 3: Ensure Scripts are Executable

```bash
sudo chmod +x /opt/tor-socks-farm/scripts/*.sh
sudo chmod +x /opt/tor-socks-farm/firewall/*.sh
```

## Step 4: Review and Customize Configuration (Optional)

### Edit Global Parameters

```bash
sudo nano /opt/tor-socks-farm/config/torfarm.env
```

Key parameters to review:
- `MIN_INSTANCES`: Starting number of nodes (default: 50)
- `ROTATE_EVERY_MIN`: Rotation interval in minutes (default: 30)
- Port ranges (usually don't need to change)

### Customize Country Mapping

```bash
sudo nano /opt/tor-socks-farm/config/countries.map
```

Set exit countries for each node:
- `001=us` - USA
- `002=de` - Germany
- `003=*` - Any country (no restriction)

Available country codes: us, de, gb, fr, nl, ca, se, ch, it, es, jp, au, etc.

### Review/Generate User Credentials

```bash
sudo nano /opt/tor-socks-farm/config/users.csv
```

Default provides 50 users (user001/pass001 through user050/pass050).

**For production use, generate strong passwords:**

```bash
# Generate 50 users with random passwords
for i in {1..50}; do
  PASS=$(openssl rand -base64 12)
  printf "%03d,user%03d,%s\n" $i $i "$PASS"
done | sudo tee /opt/tor-socks-farm/config/users.csv.new

# Backup old and use new
sudo mv /opt/tor-socks-farm/config/users.csv /opt/tor-socks-farm/config/users.csv.default
sudo mv /opt/tor-socks-farm/config/users.csv.new /opt/tor-socks-farm/config/users.csv
```

### Change Tor Control Password

```bash
# Generate strong password
STRONG_PASS=$(openssl rand -base64 16)
echo "$STRONG_PASS" | sudo tee /opt/tor-socks-farm/config/control.password
```

## Step 5: Run Installation Script

This installs required packages and sets up the system:

```bash
sudo bash /opt/tor-socks-farm/scripts/install.sh
```

This script will:
- Install tor, 3proxy, netcat-traditional, jq
- Create system users (debian-tor, proxy)
- Copy systemd units
- Disable IPv6
- Reload systemd daemon

**Expected output:** "Installation completed successfully"

## Step 6: Deploy Tor Instances

Deploy 50 Tor nodes (or specify different number):

```bash
# Deploy 50 nodes (default)
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50

# Or deploy different number (e.g., 100)
# sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 100
```

This will:
- Create data directories for each instance
- Generate torrc configurations
- Start all Tor instances
- Verify they're running

**Expected output:** "All 50 Tor instances deployed successfully"

**Verification:**

```bash
# Check active Tor instances
sudo systemctl list-units 'tor@*' | grep active

# Should show 50 active services (tor@001 through tor@050)
```

**Wait time:** Allow 2-5 minutes for all Tor circuits to establish.

## Step 7: Deploy 3proxy Endpoints

Deploy public SOCKS5 endpoints:

```bash
# Deploy 50 endpoints (must match number of Tor instances)
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50
```

This will:
- Read credentials from users.csv
- Generate 3proxy configurations
- Start all 3proxy instances
- Link each to corresponding Tor instance

**Expected output:** "All 50 3proxy endpoints deployed successfully"

**Verification:**

```bash
# Check active 3proxy instances
sudo systemctl list-units '3proxy@*' | grep active

# Should show 50 active services
```

## Step 8: Enable Automatic Rotation

Enable scheduled IP rotation:

```bash
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh
```

This will:
- Configure rotation timer with interval from torfarm.env
- Enable and start the timer
- Schedule first rotation for 5 minutes after boot

**Verification:**

```bash
# Check timer status
sudo systemctl status rotate.timer

# Should show "Active: active (waiting)"

# Check when next rotation will occur
sudo systemctl list-timers rotate.timer
```

## Step 9: Apply Security Hardening

Apply firewall rules and security measures:

```bash
sudo bash /opt/tor-socks-farm/firewall/hardening.sh
```

This will:
- Apply DNS isolation rules (only debian-tor can make DNS queries)
- Create iptables backup
- Display rollback instructions

**Important:** Note the backup file location in case you need to rollback.

## Step 10: Verify Complete Deployment

### Check All Services

```bash
# Check Tor nodes (should show 50 active)
sudo systemctl list-units 'tor@*' --no-pager | grep -c "active (running)"

# Check 3proxy endpoints (should show 50 active)
sudo systemctl list-units '3proxy@*' --no-pager | grep -c "active (running)"

# Check rotation timer
sudo systemctl is-active rotate.timer
```

### Test a Proxy Connection

```bash
# Test proxy connection (replace SERVER_IP with your server's IP)
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org

# Should return an IP address (Tor exit node IP)
```

### Check Your External IP vs Proxy IP

```bash
# Your direct IP
curl https://api.ipify.org

# Through proxy (should be different)
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org
```

### Test Manual Rotation

```bash
# Get current IP
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org

# Rotate
sudo bash /opt/tor-socks-farm/scripts/rotate.sh

# Wait 30 seconds for new circuit
sleep 30

# Get new IP (should be different)
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org
```

## Post-Deployment Configuration

### Allow Remote Connections

By default, 3proxy listens on all interfaces (0.0.0.0). Ensure your firewall allows connections to ports 20001-20050:

```bash
# Using UFW (Ubuntu firewall)
sudo ufw allow 20001:20050/tcp
sudo ufw reload

# Using iptables
sudo iptables -A INPUT -p tcp --dport 20001:20050 -j ACCEPT
```

### Configure Firewall for SSH

Make sure SSH access remains open:

```bash
# Allow SSH before enabling firewall
sudo ufw allow 22/tcp
sudo ufw enable
```

### Set Up Monitoring (Optional)

Create a simple monitoring script:

```bash
sudo tee /opt/tor-socks-farm/scripts/check_status.sh << 'EOF'
#!/bin/bash
echo "=== Tor-SOCKS Farm Status ==="
TOR_ACTIVE=$(systemctl list-units 'tor@*' --no-pager | grep -c "active (running)")
PROXY_ACTIVE=$(systemctl list-units '3proxy@*' --no-pager | grep -c "active (running)")
echo "Tor instances active: $TOR_ACTIVE"
echo "3proxy instances active: $PROXY_ACTIVE"
echo "Rotation timer: $(systemctl is-active rotate.timer)"
EOF

sudo chmod +x /opt/tor-socks-farm/scripts/check_status.sh

# Run it
sudo bash /opt/tor-socks-farm/scripts/check_status.sh
```

## Troubleshooting Deployment

### Some Tor Instances Failed to Start

```bash
# Check which ones failed
for i in {001..050}; do
  if ! systemctl is-active --quiet tor@$i; then
    echo "tor@$i is NOT running"
    journalctl -u tor@$i -n 20
  fi
done

# Common fixes:
# 1. Wait longer (Tor needs time to bootstrap)
# 2. Restart failed instances:
sudo systemctl restart tor@001
```

### 3proxy Instances Not Starting

```bash
# Check logs
sudo journalctl -u 3proxy@001 -n 50

# Common causes:
# 1. Tor instance not running yet - start Tor first
# 2. Port conflict - check if ports are already in use
sudo netstat -tulpn | grep :20001
```

### Cannot Connect Remotely

```bash
# Check if 3proxy is listening on external IP
sudo netstat -tulpn | grep 3proxy

# Check firewall
sudo ufw status
sudo iptables -L INPUT -n | grep 20000

# Test locally first
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org
```

### Rotation Not Working

```bash
# Check timer
sudo systemctl status rotate.timer

# Check rotation service logs
sudo journalctl -u rotate.service -n 50

# Test manual rotation
sudo bash /opt/tor-socks-farm/scripts/rotate.sh
```

## Scaling to More Instances

### Scaling to 100 Nodes

1. **Generate additional user credentials:**

```bash
for i in {51..100}; do
  PASS=$(openssl rand -base64 12)
  printf "%03d,user%03d,%s\n" $i $i "$PASS"
done | sudo tee -a /opt/tor-socks-farm/config/users.csv
```

2. **Add countries to countries.map:**

```bash
for i in {51..100}; do
  printf "%03d=*\n" $i
done | sudo tee -a /opt/tor-socks-farm/config/countries.map
```

3. **Deploy instances:**

```bash
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 100
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 100
```

### Scaling to 500 Nodes

Same process, but ensure your server has sufficient resources:
- 16+ CPU cores
- 32+ GB RAM
- 50+ GB disk space

## Rollback Procedures

### Remove Everything

```bash
# Stop all services
for i in {001..050}; do
  sudo systemctl stop tor@$i 3proxy@$i
  sudo systemctl disable tor@$i 3proxy@$i
done

# Remove systemd units
sudo rm /etc/systemd/system/tor@.service
sudo rm /etc/systemd/system/3proxy@.service
sudo rm /etc/systemd/system/rotate.*
sudo systemctl daemon-reload

# Remove configurations
sudo rm -rf /etc/tor/torrc.instance*
sudo rm -rf /etc/3proxy/instance*
sudo rm -rf /var/lib/tor/instance*

# Restore iptables
sudo iptables-restore < /root/iptables.backup.TIMESTAMP

# Remove project (optional)
sudo rm -rf /opt/tor-socks-farm
```

## Next Steps

1. **Test all proxies** from remote location
2. **Monitor logs** for first few hours
3. **Set up automated backups** of configuration files
4. **Document your credentials** securely
5. **Test leak prevention** using online tools
6. **Set up automated health checks** (optional)

## Support

For issues during deployment:
1. Check logs: `journalctl -u tor@001 -u 3proxy@001`
2. Verify configuration files
3. Ensure all prerequisites are met
4. Check firewall rules

## Security Reminder

- Keep control.password secure
- Use strong passwords in users.csv for production
- Regularly update system packages
- Monitor for abuse
- Comply with local laws regarding Tor usage

---

**Deployment completed!** You now have a fully functional Tor-SOCKS farm with 50 nodes, automatic rotation, and security hardening.
