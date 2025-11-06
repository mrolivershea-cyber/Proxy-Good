# Testing Guide - Tor-SOCKS Farm

This guide provides comprehensive tests to verify your Tor-SOCKS Farm deployment is working correctly.

## Prerequisites

Before testing, ensure:
- All deployment steps completed successfully
- Services are running (check with `systemctl list-units | grep -E '(tor@|3proxy@)'`)
- You have credentials from `/opt/tor-socks-farm/config/users.csv`

## Test Suite

### Test 1: Service Status Verification

Verify all services are running:

```bash
#!/bin/bash
echo "=== Service Status Test ==="

# Count active Tor instances
TOR_COUNT=$(systemctl list-units 'tor@*' --no-pager | grep -c "active (running)")
echo "Active Tor instances: $TOR_COUNT"

# Count active 3proxy instances
PROXY_COUNT=$(systemctl list-units '3proxy@*' --no-pager | grep -c "active (running)")
echo "Active 3proxy instances: $PROXY_COUNT"

# Check rotation timer
TIMER_STATUS=$(systemctl is-active rotate.timer)
echo "Rotation timer: $TIMER_STATUS"

# Results
if [ "$TOR_COUNT" -ge 50 ] && [ "$PROXY_COUNT" -ge 50 ] && [ "$TIMER_STATUS" = "active" ]; then
  echo "✓ PASSED: All services are running"
  exit 0
else
  echo "✗ FAILED: Some services are not running"
  exit 1
fi
```

**Expected result:** At least 50 Tor and 3proxy instances running, timer active

### Test 2: Local Proxy Connection

Test connecting through proxy locally:

```bash
#!/bin/bash
echo "=== Local Proxy Connection Test ==="

# Test first proxy
RESULT=$(curl -s -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org 2>&1)

if [ $? -eq 0 ]; then
  echo "✓ PASSED: Proxy connection successful"
  echo "  Exit IP: $RESULT"
  exit 0
else
  echo "✗ FAILED: Cannot connect through proxy"
  echo "  Error: $RESULT"
  exit 1
fi
```

**Expected result:** Successfully retrieves IP address different from server's direct IP

### Test 3: Multiple Proxies

Test multiple proxy endpoints:

```bash
#!/bin/bash
echo "=== Multiple Proxies Test ==="

FAILED=0
for i in 001 002 003 004 005; do
  USER="user$i"
  PASS="pass$i"
  PORT=$((20000 + 10#$i))
  
  echo -n "Testing proxy $i (port $PORT)... "
  IP=$(curl -s --max-time 30 -x socks5://$USER:$PASS@127.0.0.1:$PORT https://api.ipify.org 2>&1)
  
  if [ $? -eq 0 ]; then
    echo "✓ OK (IP: $IP)"
  else
    echo "✗ FAILED"
    FAILED=$((FAILED + 1))
  fi
done

if [ $FAILED -eq 0 ]; then
  echo "✓ PASSED: All tested proxies working"
  exit 0
else
  echo "✗ FAILED: $FAILED proxies failed"
  exit 1
fi
```

**Expected result:** All 5 tested proxies return valid IP addresses

### Test 4: Proxy Authentication

Test authentication requirement:

```bash
#!/bin/bash
echo "=== Proxy Authentication Test ==="

# Try without authentication (should fail)
echo -n "Testing without credentials... "
RESULT=$(curl -s --max-time 10 -x socks5://127.0.0.1:20001 https://api.ipify.org 2>&1)

if [ $? -ne 0 ]; then
  echo "✓ OK (correctly rejected)"
else
  echo "✗ FAILED (should require authentication)"
  exit 1
fi

# Try with wrong credentials (should fail)
echo -n "Testing with wrong credentials... "
RESULT=$(curl -s --max-time 10 -x socks5://wrong:wrong@127.0.0.1:20001 https://api.ipify.org 2>&1)

if [ $? -ne 0 ]; then
  echo "✓ OK (correctly rejected)"
else
  echo "✗ FAILED (should reject wrong credentials)"
  exit 1
fi

# Try with correct credentials (should work)
echo -n "Testing with correct credentials... "
RESULT=$(curl -s --max-time 30 -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org 2>&1)

if [ $? -eq 0 ]; then
  echo "✓ OK (accepted)"
  echo "✓ PASSED: Authentication working correctly"
  exit 0
else
  echo "✗ FAILED (should accept correct credentials)"
  exit 1
fi
```

**Expected result:** Connection without/wrong credentials fails, correct credentials work

### Test 5: IP Rotation

Test that IP rotation changes exit IP:

```bash
#!/bin/bash
echo "=== IP Rotation Test ==="

# Get initial IP
echo "Getting initial IP..."
IP1=$(curl -s --max-time 30 -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org)
echo "Initial IP: $IP1"

# Trigger rotation
echo "Triggering rotation..."
sudo bash /opt/tor-socks-farm/scripts/rotate.sh > /dev/null 2>&1

# Wait for new circuit
echo "Waiting 30 seconds for new circuit..."
sleep 30

# Get new IP
echo "Getting new IP..."
IP2=$(curl -s --max-time 30 -x socks5://user001:pass001@127.0.0.1:20001 https://api.ipify.org)
echo "New IP: $IP2"

# Compare
if [ "$IP1" != "$IP2" ] && [ -n "$IP1" ] && [ -n "$IP2" ]; then
  echo "✓ PASSED: IP changed after rotation ($IP1 -> $IP2)"
  exit 0
else
  echo "✗ FAILED: IP did not change (may need to wait longer)"
  exit 1
fi
```

**Expected result:** IP address changes after rotation

### Test 6: Country Selection

Test exit node country selection:

```bash
#!/bin/bash
echo "=== Country Selection Test ==="

# Check if instance 001 has country set in countries.map
COUNTRY=$(grep "^001=" /opt/tor-socks-farm/config/countries.map | cut -d'=' -f2)
echo "Instance 001 configured for country: $COUNTRY"

if [ "$COUNTRY" = "*" ]; then
  echo "⚠ SKIPPED: Instance 001 has no country restriction"
  exit 0
fi

# Get IP info
IP_INFO=$(curl -s --max-time 30 -x socks5://user001:pass001@127.0.0.1:20001 https://ipapi.co/json/)
DETECTED_COUNTRY=$(echo "$IP_INFO" | jq -r '.country_code' | tr '[:upper:]' '[:lower:]')

echo "Detected country: $DETECTED_COUNTRY"
echo "Expected country: $COUNTRY"

if [ "$DETECTED_COUNTRY" = "$COUNTRY" ]; then
  echo "✓ PASSED: Exit node country matches configuration"
  exit 0
else
  echo "⚠ WARNING: Country mismatch (Tor may need more time or relays unavailable)"
  exit 1
fi
```

**Expected result:** Exit IP matches configured country (may take time)

### Test 7: DNS Leak Test

Test for DNS leaks:

```bash
#!/bin/bash
echo "=== DNS Leak Test ==="

# Test DNS through proxy
echo "Testing DNS resolution through proxy..."
DNS_RESULT=$(curl -s --max-time 30 -x socks5://user001:pass001@127.0.0.1:20001 https://www.dnsleaktest.com/dns-leak-test.json 2>&1)

if [ $? -eq 0 ]; then
  # Parse DNS servers (if any)
  DNS_COUNT=$(echo "$DNS_RESULT" | jq 'length' 2>/dev/null || echo "unknown")
  echo "DNS servers detected: $DNS_COUNT"
  
  # Check if DNS servers are not local
  if echo "$DNS_RESULT" | grep -qv "$(curl -s https://api.ipify.org)"; then
    echo "✓ PASSED: DNS requests appear to be routed through Tor"
  else
    echo "⚠ WARNING: Possible DNS leak detected"
  fi
else
  echo "⚠ Test inconclusive (could not reach test server)"
fi
```

**Expected result:** DNS queries go through Tor network

### Test 8: IPv6 Leak Test

Test that IPv6 is disabled:

```bash
#!/bin/bash
echo "=== IPv6 Leak Test ==="

# Check system IPv6 status
IPV6_DISABLED=$(sysctl net.ipv6.conf.all.disable_ipv6 | awk '{print $3}')
echo "IPv6 disabled in sysctl: $IPV6_DISABLED"

if [ "$IPV6_DISABLED" = "1" ]; then
  echo "✓ System IPv6 is disabled"
else
  echo "✗ System IPv6 is NOT disabled"
  exit 1
fi

# Try to get IPv6 address through proxy
echo "Checking for IPv6 through proxy..."
IPV6_TEST=$(curl -6 -s --max-time 10 -x socks5://user001:pass001@127.0.0.1:20001 https://api6.ipify.org 2>&1 || echo "failed")

if echo "$IPV6_TEST" | grep -q "failed\|Network is unreachable\|Connection refused"; then
  echo "✓ PASSED: No IPv6 connectivity (as expected)"
  exit 0
else
  echo "✗ FAILED: IPv6 might be leaking"
  echo "  Response: $IPV6_TEST"
  exit 1
fi
```

**Expected result:** IPv6 is completely disabled

### Test 9: Concurrent Connections

Test multiple simultaneous connections:

```bash
#!/bin/bash
echo "=== Concurrent Connections Test ==="

CONCURRENT=10
SUCCESS=0

echo "Starting $CONCURRENT concurrent connections..."

# Start multiple connections in background
for i in $(seq 1 $CONCURRENT); do
  (
    PROXY_NUM=$(printf "%03d" $i)
    curl -s --max-time 30 -x socks5://user$PROXY_NUM:pass$PROXY_NUM@127.0.0.1:20${PROXY_NUM} https://api.ipify.org > /tmp/test_$i.txt 2>&1
  ) &
done

# Wait for all to complete
wait

# Count successful connections
for i in $(seq 1 $CONCURRENT); do
  if [ -s /tmp/test_$i.txt ] && ! grep -q "error\|failed" /tmp/test_$i.txt; then
    SUCCESS=$((SUCCESS + 1))
  fi
  rm -f /tmp/test_$i.txt
done

echo "Successful connections: $SUCCESS/$CONCURRENT"

if [ $SUCCESS -ge $((CONCURRENT * 8 / 10)) ]; then
  echo "✓ PASSED: Most concurrent connections successful"
  exit 0
else
  echo "✗ FAILED: Too many concurrent connections failed"
  exit 1
fi
```

**Expected result:** Most (80%+) concurrent connections succeed

### Test 10: Remote Connection

Test connecting from remote location:

```bash
#!/bin/bash
echo "=== Remote Connection Test ==="
echo "NOTE: This test must be run from a REMOTE machine, not the server itself"
echo ""

# Get server IP (you need to set this)
read -p "Enter your server's public IP: " SERVER_IP

if [ -z "$SERVER_IP" ]; then
  echo "✗ Server IP required"
  exit 1
fi

echo "Testing connection to $SERVER_IP:20001..."
RESULT=$(curl -s --max-time 30 -x socks5://user001:pass001@$SERVER_IP:20001 https://api.ipify.org 2>&1)

if [ $? -eq 0 ]; then
  echo "✓ PASSED: Remote connection successful"
  echo "  Exit IP: $RESULT"
  exit 0
else
  echo "✗ FAILED: Cannot connect remotely"
  echo "  Error: $RESULT"
  echo ""
  echo "Possible causes:"
  echo "  - Firewall blocking ports 20001-20050"
  echo "  - 3proxy not listening on public interface"
  echo "  - Network/routing issue"
  exit 1
fi
```

**Expected result:** Can connect from remote location

## Complete Test Suite Script

Save this as `/opt/tor-socks-farm/scripts/run_tests.sh`:

```bash
#!/bin/bash

echo "================================================"
echo "Tor-SOCKS Farm - Complete Test Suite"
echo "================================================"
echo ""

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

run_test() {
  TEST_NAME="$1"
  TEST_CMD="$2"
  
  TOTAL=$((TOTAL + 1))
  echo "[$TOTAL] Running: $TEST_NAME"
  echo "----------------------------------------"
  
  if eval "$TEST_CMD"; then
    PASSED=$((PASSED + 1))
  else
    RESULT=$?
    if [ $RESULT -eq 2 ]; then
      SKIPPED=$((SKIPPED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  fi
  echo ""
}

# Run all tests
run_test "Service Status" "bash test1_services.sh"
run_test "Local Proxy Connection" "bash test2_local.sh"
run_test "Multiple Proxies" "bash test3_multiple.sh"
run_test "Proxy Authentication" "bash test4_auth.sh"
run_test "IP Rotation" "bash test5_rotation.sh"
run_test "Country Selection" "bash test6_country.sh"
run_test "DNS Leak" "bash test7_dns.sh"
run_test "IPv6 Leak" "bash test8_ipv6.sh"
run_test "Concurrent Connections" "bash test9_concurrent.sh"

echo "================================================"
echo "Test Summary"
echo "================================================"
echo "Total tests: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Skipped: $SKIPPED"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "✓ ALL TESTS PASSED"
  exit 0
else
  echo "✗ SOME TESTS FAILED"
  exit 1
fi
```

## Manual Verification Steps

### Check Tor Circuits

```bash
# View Tor logs for a specific instance
sudo tail -f /var/log/tor/instance001.log

# Look for "Bootstrapped 100%" - indicates ready
# Look for "SIGNAL NEWNYM" - indicates rotation happened
```

### Check 3proxy Status

```bash
# View 3proxy logs
sudo journalctl -u 3proxy@001 -f

# Check listening ports
sudo netstat -tulpn | grep 3proxy
```

### Test in Browser

1. Configure browser to use SOCKS5 proxy:
   - Server: YOUR_SERVER_IP
   - Port: 20001
   - Username: user001
   - Password: pass001

2. Visit: https://check.torproject.org
   - Should say "Congratulations. This browser is configured to use Tor."

3. Visit: https://browserleaks.com/ip
   - Check for DNS leaks
   - Check for IPv6 leaks
   - Verify exit IP location

### Performance Test

```bash
# Test download speed through proxy
curl -x socks5://user001:pass001@127.0.0.1:20001 -o /dev/null \
  https://speed.cloudflare.com/__down?bytes=10000000 -w "Speed: %{speed_download} bytes/sec\n"
```

## Common Test Failures and Solutions

| Test | Failure | Solution |
|------|---------|----------|
| Service Status | Services not running | Check logs with `journalctl -u tor@001` |
| Local Connection | Connection timeout | Wait for Tor bootstrap (2-5 min) |
| Authentication | Accepts without auth | Check 3proxy config |
| IP Rotation | IP doesn't change | Increase wait time, check ControlPort |
| Country Selection | Wrong country | Wait longer, check relay availability |
| DNS Leak | DNS leak detected | Verify iptables rules |
| IPv6 Leak | IPv6 working | Check sysctl settings |
| Remote Connection | Can't connect | Check firewall rules |

## Continuous Monitoring

Set up a cron job for regular testing:

```bash
# Add to crontab
sudo crontab -e

# Test every hour
0 * * * * /opt/tor-socks-farm/scripts/test_basic.sh >> /var/log/tor-farm-tests.log 2>&1
```

## Security Verification

After all tests pass, verify security:

1. **No DNS leaks**: Use https://dnsleaktest.com through proxy
2. **No IPv6 leaks**: Use https://ipv6leak.com through proxy
3. **Proper country**: Use https://ipapi.co through proxy
4. **Tor detection**: Use https://check.torproject.org

---

**Testing completed!** If all tests pass, your Tor-SOCKS Farm is fully functional and secure.
