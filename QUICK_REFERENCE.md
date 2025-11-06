# Quick Reference - Tor-SOCKS Farm

Essential commands and information for day-to-day operations.

## Installation (One-Time)

```bash
# Copy to /opt
sudo cp -r opt/tor-socks-farm /opt/
sudo chmod +x /opt/tor-socks-farm/scripts/*.sh /opt/tor-socks-farm/firewall/*.sh

# Full deployment
sudo bash /opt/tor-socks-farm/scripts/install.sh
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh
sudo bash /opt/tor-socks-farm/firewall/hardening.sh
```

## Service Management

### Check Status
```bash
# All Tor nodes
sudo systemctl list-units 'tor@*'

# All proxy endpoints
sudo systemctl list-units '3proxy@*'

# Rotation timer
sudo systemctl status rotate.timer

# Specific instance
sudo systemctl status tor@001
sudo systemctl status 3proxy@001
```

### Start/Stop/Restart
```bash
# Single instance
sudo systemctl start tor@001
sudo systemctl stop tor@001
sudo systemctl restart tor@001

# Multiple instances
for i in {001..050}; do sudo systemctl restart tor@$i; done
for i in {001..050}; do sudo systemctl restart 3proxy@$i; done
```

### Enable/Disable
```bash
# Enable on boot
sudo systemctl enable tor@001

# Disable
sudo systemctl disable tor@001
```

## Logs

### View Logs
```bash
# Real-time logs
sudo journalctl -u tor@001 -f
sudo journalctl -u 3proxy@001 -f
sudo journalctl -u rotate.service -f

# Last 50 lines
sudo journalctl -u tor@001 -n 50

# Tor file logs
sudo tail -f /var/log/tor/instance001.log

# All Tor errors
sudo journalctl -u 'tor@*' -p err
```

### Log Locations
- Systemd logs: `journalctl -u SERVICE_NAME`
- Tor logs: `/var/log/tor/instanceXXX.log`
- Rotation logs: `journalctl -u rotate.service`

## Configuration Files

### Main Config
```bash
# Edit global parameters
sudo nano /opt/tor-socks-farm/config/torfarm.env

# Edit country mapping
sudo nano /opt/tor-socks-farm/config/countries.map

# Edit user credentials
sudo nano /opt/tor-socks-farm/config/users.csv

# View control password
sudo cat /opt/tor-socks-farm/config/control.password
```

### Instance Configs
- Tor: `/etc/tor/torrc.instanceXXX`
- 3proxy: `/etc/3proxy/instanceXXX.cfg`

## Rotation

### Manual Rotation
```bash
# Rotate all instances
sudo bash /opt/tor-socks-farm/scripts/rotate.sh

# Via systemd
sudo systemctl start rotate.service
```

### Automatic Rotation
```bash
# Check timer status
sudo systemctl status rotate.timer

# Check next rotation time
sudo systemctl list-timers rotate.timer

# Restart timer (after config change)
sudo systemctl restart rotate.timer
```

### Change Rotation Interval
```bash
# Edit config
sudo nano /opt/tor-socks-farm/config/torfarm.env
# Change ROTATE_EVERY_MIN=30 to desired value

# Apply changes
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh
```

## Testing

### Quick Connection Test
```bash
# Test local proxy
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org

# Test remote proxy (from another machine)
curl -x socks5://user001:pass001@SERVER_IP:20001 https://api.ipify.org
```

### Check Current IP
```bash
# Direct IP
curl https://api.ipify.org

# Through proxy 001
curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org

# Through proxy 050
curl -x socks5://user050:pass050@127.0.0.1:20050 https://api.ipify.org
```

### Test Rotation
```bash
# Get current IP
IP1=$(curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org)
echo "Current IP: $IP1"

# Rotate
sudo bash /opt/tor-socks-farm/scripts/rotate.sh

# Wait and check new IP
sleep 30
IP2=$(curl -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org)
echo "New IP: $IP2"
```

### Check Country
```bash
# Get IP location info
curl -x socks5://user001:pass001@127.0.0.1:20001 https://ipapi.co/json/ | jq
```

## Port Information

### Default Ports

| Service | Port Range | Description |
|---------|------------|-------------|
| Tor SOCKS (local) | 9001-9050 | Local SOCKS5 ports |
| Tor Control | 9101-9150 | Control ports |
| Tor DNS | 9201-9250 | DNS ports |
| Tor Trans | 9301-9350 | Transparent proxy ports |
| 3proxy (public) | 20001-20050 | Public SOCKS5 ports |

### Check Port Usage
```bash
# Check if port is listening
sudo netstat -tulpn | grep :20001

# Check all 3proxy ports
sudo netstat -tulpn | grep 3proxy

# Check all tor ports
sudo netstat -tulpn | grep tor
```

## Credentials

### Default Credentials (50 nodes)
```
Port 20001: user001 / pass001
Port 20002: user002 / pass002
...
Port 20050: user050 / pass050
```

### View All Credentials
```bash
cat /opt/tor-socks-farm/config/users.csv
```

### Generate New Credentials
```bash
# Generate 50 random passwords
for i in {1..50}; do
  PASS=$(openssl rand -base64 12)
  printf "%03d,user%03d,%s\n" $i $i "$PASS"
done | sudo tee /opt/tor-socks-farm/config/users.csv.new
```

## Scaling

### Add More Instances
```bash
# Add users (51-100)
for i in {51..100}; do
  printf "%03d,user%03d,pass%03d\n" $i $i $i
done | sudo tee -a /opt/tor-socks-farm/config/users.csv

# Add countries (51-100)
for i in {51..100}; do
  printf "%03d=*\n" $i
done | sudo tee -a /opt/tor-socks-farm/config/countries.map

# Deploy
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 100
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 100
```

### Remove Instances
```bash
# Stop and disable (instances 51-100)
for i in {051..100}; do
  sudo systemctl stop tor@$i 3proxy@$i
  sudo systemctl disable tor@$i 3proxy@$i
done

# Remove configs
for i in {051..100}; do
  sudo rm -f /etc/tor/torrc.instance$i
  sudo rm -f /etc/3proxy/instance$i.cfg
  sudo rm -rf /var/lib/tor/instance$i
done
```

## Monitoring

### Health Check Script
```bash
# Create health check
cat > /tmp/health_check.sh << 'EOF'
#!/bin/bash
TOR=$(systemctl list-units 'tor@*' --no-pager | grep -c "active (running)")
PROXY=$(systemctl list-units '3proxy@*' --no-pager | grep -c "active (running)")
echo "Tor: $TOR active | 3proxy: $PROXY active"
EOF
chmod +x /tmp/health_check.sh

# Run it
bash /tmp/health_check.sh
```

### Watch Service Status
```bash
# Real-time monitoring
watch -n 5 'systemctl list-units "tor@*" "3proxy@*" --no-pager | grep -E "(tor@|3proxy@)"'
```

## Firewall

### Allow Public Access
```bash
# UFW
sudo ufw allow 20001:20050/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 20001:20050 -j ACCEPT
```

### Check Firewall Rules
```bash
# UFW
sudo ufw status

# iptables
sudo iptables -L -n -v
```

### Rollback iptables
```bash
# List backups
ls -lh /root/iptables.backup.*

# Restore
sudo iptables-restore < /root/iptables.backup.TIMESTAMP
```

## Troubleshooting

### Instance Won't Start
```bash
# Check status
sudo systemctl status tor@001

# View logs
sudo journalctl -u tor@001 -n 100

# Verify config
sudo tor -f /etc/tor/torrc.instance001 --verify-config

# Check permissions
ls -la /var/lib/tor/instance001

# Restart
sudo systemctl restart tor@001
```

### Proxy Not Responding
```bash
# Check if Tor is running
sudo systemctl status tor@001

# Check if 3proxy is running
sudo systemctl status 3proxy@001

# Check port
sudo netstat -tulpn | grep :20001

# Test locally
curl -v -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org
```

### Rotation Not Working
```bash
# Check timer
sudo systemctl status rotate.timer
sudo systemctl list-timers rotate.timer

# Check last rotation
sudo journalctl -u rotate.service -n 50

# Manual rotation
sudo bash /opt/tor-socks-farm/scripts/rotate.sh

# Restart timer
sudo systemctl restart rotate.timer
```

### Check for Errors
```bash
# All Tor errors
sudo journalctl -u 'tor@*' -p err -n 100

# All 3proxy errors
sudo journalctl -u '3proxy@*' -p err -n 100

# Recent errors
sudo journalctl -p err --since "1 hour ago"
```

## Performance

### Resource Usage
```bash
# CPU and memory
top -b -n 1 | grep -E "(tor|3proxy)"

# All Tor processes
ps aux | grep tor | wc -l

# Memory per instance
ps aux | grep "tor -f" | awk '{sum+=$6} END {print "Total RSS: " sum/1024 " MB"}'
```

### Connection Count
```bash
# Active connections
sudo netstat -an | grep -E ":(9[0-9]{3}|20[0-9]{3})" | grep ESTABLISHED | wc -l

# Per port
for port in {20001..20010}; do
  COUNT=$(sudo netstat -an | grep ":$port " | grep ESTABLISHED | wc -l)
  echo "Port $port: $COUNT connections"
done
```

## Backup and Restore

### Backup Configuration
```bash
# Create backup
sudo tar czf /root/tor-farm-backup-$(date +%Y%m%d).tar.gz \
  /opt/tor-socks-farm/config/ \
  /etc/tor/torrc.instance* \
  /etc/3proxy/instance*.cfg

# List backups
ls -lh /root/tor-farm-backup-*
```

### Restore Configuration
```bash
# Restore from backup
sudo tar xzf /root/tor-farm-backup-YYYYMMDD.tar.gz -C /
```

## Complete Removal

```bash
# Stop all services
for i in {001..050}; do
  sudo systemctl stop tor@$i 3proxy@$i
  sudo systemctl disable tor@$i 3proxy@$i
done

# Remove systemd units
sudo rm /etc/systemd/system/{tor@,3proxy@,rotate}.{service,timer}
sudo systemctl daemon-reload

# Remove configs and data
sudo rm -rf /etc/tor/torrc.instance*
sudo rm -rf /etc/3proxy/instance*
sudo rm -rf /var/lib/tor/instance*
sudo rm -rf /var/log/tor/instance*

# Restore iptables
sudo iptables-restore < /root/iptables.backup.TIMESTAMP

# Remove project
sudo rm -rf /opt/tor-socks-farm
```

## Useful URLs

- Check Tor: https://check.torproject.org
- Get IP: https://api.ipify.org
- IP Info: https://ipapi.co/json/
- DNS Leak Test: https://dnsleaktest.com
- IPv6 Leak Test: https://ipv6leak.com
- Browser Leaks: https://browserleaks.com

## Support Files

- Full docs: `/opt/tor-socks-farm/README.md`
- Deployment guide: `/opt/tor-socks-farm/DEPLOYMENT_GUIDE.md`
- Testing guide: `/opt/tor-socks-farm/TESTING_GUIDE.md`
- Technical spec: `/opt/tor-socks-farm/TZ`

---

**Pro Tip**: Keep this reference handy! Bookmark or print for quick access.
