# Tor-SOCKS Farm Automation

Automatic deployment of a pool of Tor nodes on Linux servers (Ubuntu 22.04+). Each node provides a SOCKS5 proxy with authentication, IP rotation, and exit country selection.

## Features

- ✅ Automatic deployment of 50 to 500 Tor nodes
- ✅ SOCKS5 proxy with authentication for each node
- ✅ Automatic IP address rotation on schedule
- ✅ Exit country selection for each node
- ✅ Complete DNS isolation (no leaks)
- ✅ IPv6 disabled (no leaks)
- ✅ Management via systemd
- ✅ CLI scripts for management

## Requirements

- **OS**: Ubuntu 22.04 LTS / 24.04 LTS
- **Privileges**: root
- **Packages**: tor, 3proxy, netcat-traditional, jq (installed automatically)

## Quick Start

### 1. Install on server

```bash
# Copy project to /opt
sudo mkdir -p /opt
sudo cp -r opt/tor-socks-farm /opt/

# Ensure scripts are executable
sudo chmod +x /opt/tor-socks-farm/scripts/*.sh
sudo chmod +x /opt/tor-socks-farm/firewall/*.sh
```

### 2. Full deployment (50 nodes)

```bash
# System installation
sudo bash /opt/tor-socks-farm/scripts/install.sh

# Deploy Tor nodes
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50

# Deploy proxy endpoints
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50

# Enable automatic rotation
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh

# Apply security hardening
sudo bash /opt/tor-socks-farm/firewall/hardening.sh
```

### 3. Verify operation

```bash
# Check Tor nodes status
sudo systemctl list-units | grep tor@

# Check proxy endpoints status
sudo systemctl list-units | grep 3proxy@

# Check rotation timer status
sudo systemctl status rotate.timer
```

## Usage

### Connecting to proxy

After deployment, SOCKS5 proxies are available on ports 20001-20050:

```bash
# Example with curl
curl -x socks5://user001:pass001@SERVER_IP:20001 https://api.ipify.org

# Browser configuration example
# Proxy server: SERVER_IP
# Port: 20001
# Username: user001
# Password: pass001
```

### Credentials

Credentials are located in `/opt/tor-socks-farm/config/users.csv`:

```csv
instance,user,password
001,user001,pass001
002,user002,pass002
...
```

### Configure exit countries

Edit `/opt/tor-socks-farm/config/countries.map`:

```
001=us    # USA
002=de    # Germany
003=gb    # United Kingdom
004=*     # Any country
```

After changes, trigger rotation:

```bash
sudo systemctl start rotate.service
```

### Change rotation interval

Edit `/opt/tor-socks-farm/config/torfarm.env`:

```bash
ROTATE_EVERY_MIN=30  # Rotate every 30 minutes
```

Then apply changes:

```bash
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh
```

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| MIN_INSTANCES | 50 | Initial count |
| MAX_INSTANCES | 500 | Maximum limit |
| BASE_SOCKS_PORT | 9000 | Local SOCKS (9001..) |
| BASE_CTRL_PORT | 9100 | ControlPort (9101..) |
| BASE_DNS_PORT | 9200 | DNSPort (9201..) |
| BASE_TRANS_PORT | 9300 | TransPort (9301..) |
| BASE_PUBLIC_PORT | 20000 | Public SOCKS (20001..) |
| ROTATE_EVERY_MIN | 30 | Rotation interval (min) |

## Security

### Implemented measures

1. **DNS isolation**: All DNS queries allowed only from `debian-tor` user
2. **IPv6 disabled**: Prevents IPv6 leaks
3. **Local bindings**: Tor listens only on 127.0.0.1
4. **Authentication**: Required for all public proxies
5. **Minimal privileges**: Services run as unprivileged users

## Documentation

Full technical specification available in [TZ](TZ) file (Russian).

For detailed Russian documentation, see [README.md](README.md).

## License

This project is for educational purposes. Use responsibly and in accordance with your country's laws.

---

**Important**: Using Tor to bypass blocks may be illegal in some jurisdictions. Ensure you comply with local laws.
