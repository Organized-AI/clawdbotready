# Alternative Fix: Manual Gateway Health Check

**If SSH access isn't available yet**, the machine owner can run these commands to diagnose and fix the gateway.

---

## Quick Health Check (Run on Mac Mini)

Open **Terminal** on the Mac Mini and run:

```bash
# 1. Check if OpenClaw Gateway is running
ps aux | grep openclaw-gateway | grep -v grep

# Expected: Should show openclaw-gateway process
# If empty: Gateway is NOT running
```

```bash
# 2. Check if gateway port is listening
lsof -i :18789

# Expected: Should show openclaw-gateway on port 18789
# If empty: Gateway is not listening
```

```bash
# 3. Check recent errors
tail -50 ~/.openclaw/logs/gateway.err.log

# Look for any ERROR or FATAL messages
```

```bash
# 4. Check if config file exists
ls -la ~/.openclaw/openclaw.json

# Expected: File should exist
# If not: Gateway never initialized
```

---

## Common Fixes

### Fix 1: Gateway Not Running

```bash
# Start the gateway
launchctl start com.openclaw.gateway

# Wait 5 seconds
sleep 5

# Verify it started
ps aux | grep openclaw-gateway | grep -v grep
```

### Fix 2: Gateway Crashed/Stuck

```bash
# Kill any stuck processes
pkill -9 openclaw-gateway

# Wait a moment
sleep 2

# Restart via LaunchAgent
launchctl stop com.openclaw.gateway
sleep 2
launchctl start com.openclaw.gateway

# Verify it's running
ps aux | grep openclaw-gateway | grep -v grep
```

### Fix 3: Check if LaunchAgent is Loaded

```bash
# List loaded LaunchAgents
launchctl list | grep openclaw

# If not found, load it:
launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist

# Then start it:
launchctl start com.openclaw.gateway
```

### Fix 4: View Live Logs

```bash
# Watch logs in real-time
tail -f ~/.openclaw/logs/gateway.log

# Press Ctrl+C to stop watching
```

---

## Test if Gateway is Working

```bash
# Get your gateway token
GATEWAY_TOKEN=$(cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"' | grep '"token"' | cut -d'"' -f4)

echo "Gateway Token: $GATEWAY_TOKEN"

# Try to access dashboard locally
open "http://localhost:18789/?token=$GATEWAY_TOKEN"

# Should open dashboard in browser
# If "Connected" appears in dashboard: ✅ Gateway is working
# If "Disconnected" or errors: ❌ Gateway has issues
```

---

## Check Telegram Bot Connection

If Telegram bot isn't responding:

```bash
# 1. Check Telegram channel config
cat ~/.openclaw/openclaw.json | grep -A 10 '"telegram"'

# Should show bot token and configuration
```

```bash
# 2. Restart gateway to reconnect bot
launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway

# Wait 10 seconds for reconnection
sleep 10

# 3. Check if bot connected successfully
tail -30 ~/.openclaw/logs/gateway.log | grep -i telegram
```

---

## Collect Diagnostics (If Still Not Working)

Run this to collect all diagnostic info:

```bash
# Create diagnostics report
cat > /tmp/gateway-diagnostics.txt << 'EOF'
=== OpenClaw Gateway Diagnostics ===

TIMESTAMP: $(date)

=== Gateway Process ===
$(ps aux | grep openclaw | grep -v grep)

=== Port Status ===
$(lsof -i :18789)

=== Recent Logs (last 50 lines) ===
$(tail -50 ~/.openclaw/logs/gateway.log)

=== Recent Errors (last 20 lines) ===
$(tail -20 ~/.openclaw/logs/gateway.err.log)

=== LaunchAgent Status ===
$(launchctl list | grep openclaw)

=== Config File ===
$(ls -la ~/.openclaw/openclaw.json)

=== Telegram Config (redacted) ===
$(cat ~/.openclaw/openclaw.json | grep -A 10 '"telegram"' | grep -v '"token"')

EOF

echo "Diagnostics saved to: /tmp/gateway-diagnostics.txt"
cat /tmp/gateway-diagnostics.txt
```

Send the output to your support person.

---

## Quick Reference

**Gateway not running?**
```bash
launchctl start com.openclaw.gateway
```

**Gateway stuck?**
```bash
pkill openclaw-gateway && sleep 3 && launchctl start com.openclaw.gateway
```

**Check logs:**
```bash
tail -f ~/.openclaw/logs/gateway.log
```

**Test locally:**
```bash
curl http://localhost:18789/
# Should return HTTP 200
```

---

*Created: 2026-02-08*
*For: Manual troubleshooting when remote SSH not available*
