# OpenClaw Dashboard Troubleshooting Guide

## Common Dashboard Issues

### Issue 1: "Disconnected (1008): unauthorized: gateway token missing"

**Symptoms:**
- Dashboard loads but shows disconnected status
- Error message: "unauthorized: gateway token missing (open a tokenized dashboard URL or paste token in Control UI settings)"
- WebSocket connection fails with 1008 error code

**Root Cause:**
OpenClaw Gateway requires authentication via a token. The dashboard needs this token to establish a WebSocket connection.

---

## Solution 1: Use Tokenized URL (Recommended)

### Step 1: Retrieve Gateway Token

**For Remote Mac Mini (via SSH):**
```bash
ssh openclaw@<TAILSCALE_IP> "cat ~/.openclaw/openclaw.json | grep -A 5 '\"gateway\"' | grep -A 3 '\"auth\"'"
```

Example:
```bash
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | grep -A 5 '\"gateway\"' | grep -A 3 '\"auth\"'"
```

**For Local Machine:**
```bash
cat ~/.openclaw/openclaw.json | grep -A 5 '"gateway"' | grep -A 3 '"auth"'
```

**Expected Output:**
```json
"auth": {
  "token": "96e234ec9a175f394df0b5b4345b652a4617b992ce1bd41db5dea36eb572fed9",
  "mode": "token"
}
```

### Step 2: Create Tokenized URL

**Format:**
```
http://localhost:<PORT>/?token=<YOUR_TOKEN_HERE>
```

**Examples:**

Mac Mini (via SSH tunnel on port 18790):
```
http://localhost:18790/?token=96e234ec9a175f394df0b5b4345b652a4617b992ce1bd41db5dea36eb572fed9
```

Local Gateway (default port 18789):
```
http://localhost:18789/?token=6ab72a8937d83589a29fea9cf7c4dd1901226fa28c6cbc4bedccc6ea105d2f55
```

### Step 3: Open Tokenized URL

Copy the full tokenized URL and paste it into your browser. The dashboard should connect immediately.

---

## Solution 2: Paste Token in Control UI Settings

If you prefer not to use URL parameters:

1. Open the dashboard at `http://localhost:<PORT>/`
2. You'll see "disconnected" status - this is expected
3. Click the **Settings** icon in the Control UI (gear icon or settings menu)
4. Find the **Gateway Token** field
5. Paste your token (retrieved from Step 1 above)
6. Click **Save**
7. Refresh the page or wait for auto-reconnect

---

## Issue 2: Multiple Gateways Running (Port Conflicts)

**Symptoms:**
- Confused about which dashboard connects to which Gateway
- Port 18789 already in use
- Local dashboard connects but it's the wrong Gateway

**Diagnosis:**

Check what's running locally:
```bash
lsof -i :18789
```

Check Mac Mini Gateway:
```bash
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"
```

**Solution: Use SSH Tunnel on Alternate Port**

To access a remote Gateway when you have a local one running:

```bash
# Create SSH tunnel to Mac Mini on alternate port
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48
```

Now you have:
- **Local Gateway**: `http://localhost:18789`
- **Mac Mini Gateway**: `http://localhost:18790` (via tunnel)

Verify tunnel is working:
```bash
curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:18790/
```

Expected: `HTTP 200`

---

## Issue 3: SSH Tunnel Not Working

**Symptoms:**
- `curl http://localhost:18790/` returns connection refused
- Dashboard won't load even with correct token
- Tunnel process exists but connection fails

**Diagnosis:**

Check if tunnel is running:
```bash
ps aux | grep "ssh.*18790" | grep -v grep
```

Check if port is listening:
```bash
lsof -i :18790
```

**Solutions:**

### Kill and Recreate Tunnel
```bash
# Kill existing tunnel
pkill -f "ssh.*18790.*100.66.145.48"

# Verify it's gone
ps aux | grep "ssh.*18790" | grep -v grep

# Recreate tunnel
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48

# Test connection
curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:18790/
```

### Verbose SSH Tunnel (for debugging)
```bash
# Run tunnel in foreground with verbose output
ssh -v -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48
```

Look for errors in output. Common issues:
- `Permission denied (publickey)` - SSH key not configured
- `Address already in use` - Port 18790 taken by another process
- Connection timeout - Mac Mini may be asleep or Tailscale disconnected

---

## Issue 4: Token Not Found in Config

**Symptoms:**
- `openclaw.json` doesn't have `gateway.auth.token`
- Token retrieval commands return empty or "Not found"

**Solution: Generate New Token**

```bash
# On the machine running Gateway
openclaw config set gateway.auth.token "$(openssl rand -hex 32)"

# Verify it was set
openclaw config get gateway.auth.token
```

Or manually edit `~/.openclaw/openclaw.json`:
```json
{
  "gateway": {
    "auth": {
      "token": "YOUR_GENERATED_TOKEN_HERE",
      "mode": "token"
    }
  }
}
```

Generate a token:
```bash
openssl rand -hex 32
```

Restart Gateway after changing config:
```bash
# Via LaunchAgent
launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway

# Or via openclaw CLI
openclaw gateway stop && openclaw gateway start --port 18789
```

---

## Issue 5: Dashboard Loads but Shows Empty/No Channels

**Symptoms:**
- Dashboard connects successfully (no 1008 error)
- No Telegram, iMessage, or other channels visible
- Gateway logs show channels loaded but UI doesn't display them

**Diagnosis:**

Check Gateway logs:
```bash
# Local
tail -50 ~/.openclaw/logs/gateway.log

# Remote (Mac Mini)
ssh openclaw@100.66.145.48 "tail -50 ~/.openclaw/logs/gateway.log"
```

Look for channel initialization:
```
[telegram] [default] starting provider (@YourBot)
```

**Solution:**

1. **Verify channels in config:**
```bash
cat ~/.openclaw/openclaw.json | grep -A 20 '"channels"'
```

2. **Reload Gateway config:**
```bash
# Send SIGUSR1 to reload without restarting
pkill -SIGUSR1 openclaw-gateway
```

3. **Hard restart Gateway:**
```bash
launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway
```

4. **Clear browser cache and refresh dashboard**

---

## Quick Reference: Token Retrieval Commands

### Mac Mini (Remote)
```bash
# Via SSH
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | grep -A 5 '\"gateway\"' | grep -A 3 '\"auth\"'"

# Shorthand (if .gateway-token file exists)
ssh openclaw@100.66.145.48 "cat ~/.openclaw/.gateway-token"
```

### Local Machine
```bash
# From config
cat ~/.openclaw/openclaw.json | grep -A 5 '"gateway"' | grep -A 3 '"auth"'

# Using openclaw CLI
openclaw config get gateway.auth.token

# Shorthand (if .gateway-token file exists)
cat ~/.openclaw/.gateway-token
```

---

## Quick Reference: SSH Tunnel Management

### Create Tunnel
```bash
# Port 18790 for Mac Mini dashboard
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48
```

### Check Tunnel Status
```bash
# List SSH tunnels
ps aux | grep "ssh.*-L.*18789" | grep -v grep

# Check port listening
lsof -i :18790
```

### Kill Tunnel
```bash
# Kill specific tunnel
pkill -f "ssh.*18790.*100.66.145.48"

# Kill all SSH tunnels to Mac Mini
pkill -f "ssh.*100.66.145.48"
```

### Test Tunnel
```bash
# Quick health check
curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:18790/

# Should return: HTTP 200
```

---

## Common Scenarios

### Scenario: "I have two Macs and want to access both dashboards"

**Setup:**
1. Local Mac: Gateway on default port 18789
2. Remote Mac Mini: Gateway tunneled to port 18790

**Access:**
```bash
# Get local token
LOCAL_TOKEN=$(cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"' | grep '"token"' | cut -d'"' -f4)

# Get remote token
REMOTE_TOKEN=$(ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | grep -A 3 '\"auth\"' | grep '\"token\"' | cut -d'\"' -f4")

# Create tunnel
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48

# Open dashboards
open "http://localhost:18789/?token=${LOCAL_TOKEN}"
open "http://localhost:18790/?token=${REMOTE_TOKEN}"
```

---

### Scenario: "Dashboard was working, now it's not"

**Checklist:**

1. **Is Gateway running?**
```bash
ps aux | grep openclaw-gateway | grep -v grep
```

2. **Is SSH tunnel alive? (if remote)**
```bash
ps aux | grep "ssh.*18790" | grep -v grep
```

3. **Can you reach the Gateway?**
```bash
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:18789/
```

4. **Check Gateway logs for errors:**
```bash
tail -50 ~/.openclaw/logs/gateway.log
grep -i error ~/.openclaw/logs/gateway.err.log | tail -20
```

5. **Restart Gateway:**
```bash
launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway
```

6. **Get fresh token and reconnect:**
```bash
TOKEN=$(cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"' | grep '"token"' | cut -d'"' -f4)
open "http://localhost:18789/?token=${TOKEN}"
```

---

## Security Best Practices

### Token Management

1. **Never commit tokens to git**
```bash
# Add to .gitignore
echo "*.openclaw.json" >> .gitignore
echo ".gateway-token" >> .gitignore
```

2. **Use environment variables for automation**
```bash
export OPENCLAW_GATEWAY_TOKEN="your-token-here"
```

3. **Rotate tokens periodically**
```bash
# Generate new token
NEW_TOKEN=$(openssl rand -hex 32)

# Update config
openclaw config set gateway.auth.token "$NEW_TOKEN"

# Restart Gateway
openclaw gateway stop && openclaw gateway start
```

4. **Restrict token access**
```bash
chmod 600 ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/.gateway-token
```

---

## Troubleshooting Checklist

Before asking for help, verify:

- [ ] Gateway is running (`ps aux | grep openclaw-gateway`)
- [ ] Gateway is listening on correct port (`lsof -i :18789`)
- [ ] Token exists in config (`openclaw config get gateway.auth.token`)
- [ ] Dashboard URL includes `?token=...` parameter
- [ ] SSH tunnel is active (if accessing remote Gateway)
- [ ] No errors in Gateway logs (`tail ~/.openclaw/logs/gateway.err.log`)
- [ ] Browser isn't blocking WebSocket connections (check console)
- [ ] Firewall isn't blocking localhost connections

---

## Related Documentation

- [Remote Support Guide](../REMOTE-SUPPORT-GUIDE.md) - SSH access and Mac Mini management
- [Tailscale Explained](./tailscale-explained.md) - Network connectivity setup
- [Client Setup Guide](../CLIENT-SETUP-GUIDE.md) - Initial OpenClaw configuration

---

*Last Updated: 2026-02-03*
*OpenClaw Version: 2026.2.1+*
