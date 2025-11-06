# Changelog

All notable changes to the Tor-SOCKS Farm Automation project will be documented in this file.

## [1.0.0] - 2025-11-05

### Added

#### Core System
- Complete Tor-SOCKS Farm automation system
- Support for 50-500 Tor nodes with SOCKS5 proxies
- Automatic deployment and configuration
- systemd integration for service management

#### Scripts
- `install.sh` - System installation and package setup
- `deploy_tor_instances.sh` - Automated Tor node deployment
- `deploy_3proxy_endpoints.sh` - Proxy endpoint deployment
- `rotate.sh` - Tor identity rotation
- `enable_rotation.sh` - Automatic rotation timer setup
- `tor_iptables_apply.sh` - Firewall rules for DNS isolation
- `hardening.sh` - Security hardening automation

#### Configuration
- `torfarm.env` - Global configuration parameters
- `countries.map` - Country-based exit node selection
- `users.csv` - User credentials for proxy authentication
- `control.password` - Tor ControlPort password
- `instance.cfg.tpl` - 3proxy configuration template

#### systemd Units
- `tor@.service` - Template for Tor instances
- `3proxy@.service` - Template for proxy endpoints
- `rotate.service` - Identity rotation service
- `rotate.timer` - Scheduled rotation timer

#### Security Features
- DNS isolation (only debian-tor user can make DNS queries)
- IPv6 completely disabled to prevent leaks
- Tor bound to localhost only (127.0.0.1)
- Mandatory authentication for all public proxies
- Firewall rules with automatic backup
- Minimal privilege design (unprivileged users for services)

#### Documentation
- `README.md` - Comprehensive Russian documentation
- `README.en.md` - English quick start guide
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `TESTING_GUIDE.md` - Complete testing procedures
- `QUICK_REFERENCE.md` - Quick command reference
- `TZ` - Technical specification (Russian)

#### Features
- Scalable from 50 to 500 nodes
- Per-node country selection for exit IPs
- Automatic IP rotation on schedule (configurable interval)
- Individual SOCKS5 authentication per node
- Health checking and verification
- Comprehensive logging
- Easy rollback procedures

### Technical Details

#### Port Allocation
- Local SOCKS: 9001-9500 (BASE_SOCKS_PORT + instance)
- Control Ports: 9101-9600 (BASE_CTRL_PORT + instance)
- DNS Ports: 9201-9700 (BASE_DNS_PORT + instance)
- Transparent Proxy: 9301-9800 (BASE_TRANS_PORT + instance)
- Public SOCKS: 20001-20500 (BASE_PUBLIC_PORT + instance)

#### System Requirements
- OS: Ubuntu 22.04 LTS / 24.04 LTS
- Packages: tor, 3proxy, netcat-traditional, jq
- Root privileges required for installation

#### Default Configuration
- Minimum instances: 50
- Maximum instances: 500
- Rotation interval: 30 minutes
- Default country: * (any)
- First rotation: 5 minutes after boot

### Architecture

#### Directory Structure
```
/opt/tor-socks-farm/
├── scripts/      # Management scripts
├── systemd/      # systemd unit templates
├── config/       # Configuration files
├── 3proxy/       # Proxy templates
└── firewall/     # Security scripts
```

#### Data Directories
- Tor data: `/var/lib/tor/instanceXXX/`
- Tor logs: `/var/log/tor/instanceXXX.log`
- Tor configs: `/etc/tor/torrc.instanceXXX`
- 3proxy configs: `/etc/3proxy/instanceXXX.cfg`

### Testing
- Service status verification
- Local and remote proxy connection tests
- Authentication requirement tests
- IP rotation verification
- Country selection validation
- DNS and IPv6 leak tests
- Concurrent connection tests
- Performance benchmarking

### Known Limitations
- Maximum 500 instances (configurable limit)
- Requires manual firewall configuration for remote access
- Country selection depends on Tor relay availability
- Initial Tor circuit building takes 2-5 minutes
- Some countries may have limited relay availability

### Compatibility
- Tested on Ubuntu 22.04 LTS
- Compatible with Ubuntu 24.04 LTS
- Bash scripts are POSIX-compatible
- Requires systemd (standard on Ubuntu)

### Security Considerations
- Default passwords are weak (change for production)
- Control password is plain text (secure file permissions required)
- Public proxies exposed to internet (authentication required)
- Regular security updates recommended
- Monitor for abuse
- Comply with local laws regarding Tor usage

## Future Enhancements (Planned)

### Version 1.1.0 (Future)
- [ ] Web-based management interface
- [ ] Prometheus metrics export
- [ ] Grafana dashboard templates
- [ ] Health check API endpoint
- [ ] Automatic failover for failed instances
- [ ] Load balancing across instances
- [ ] Geographic distribution support
- [ ] Docker containerization option
- [ ] Ansible playbooks for automation
- [ ] Database-backed configuration
- [ ] User quota management
- [ ] Traffic statistics and analytics
- [ ] Email alerts for failures

### Version 1.2.0 (Future)
- [ ] IPv6 support (with leak prevention)
- [ ] Multiple proxy protocols (HTTP/HTTPS)
- [ ] Automatic country rotation
- [ ] Time-based country scheduling
- [ ] Bandwidth throttling per instance
- [ ] Connection limiting per user
- [ ] Advanced logging and auditing
- [ ] Integration with fail2ban
- [ ] Automatic Tor version updates
- [ ] High availability clustering

### Version 2.0.0 (Future)
- [ ] Multi-server orchestration
- [ ] Central management server
- [ ] RESTful API
- [ ] User self-service portal
- [ ] Billing integration
- [ ] Advanced traffic shaping
- [ ] Custom exit policies
- [ ] Bridge support
- [ ] Pluggable transport support

## Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

## Upgrade Instructions

### From Future Versions
Instructions will be provided here for upgrading between versions.

## Bug Fixes

### Version 1.0.0
No bug fixes (initial release)

## Contributors

- Project implementation based on TZ technical specification
- Developed for: mrolivershea-cyber/Proxy-Good

## License

This project is provided for educational purposes. Use responsibly and in accordance with local laws.

## Support

For issues, questions, or contributions:
1. Check the documentation in this repository
2. Review the troubleshooting section in README.md
3. Check system logs for error messages
4. Verify configuration files

---

**Note**: This is the initial release (v1.0.0). Future versions will include enhancements, bug fixes, and new features based on user feedback and requirements.
