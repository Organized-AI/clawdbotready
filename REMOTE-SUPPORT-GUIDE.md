# Remote Support Guide - OpenClaw Mac Mini

**For: Support Technician (@jordaaanh)**
**Client**: OpenClaw User (Telegram ID: 337198)
**Mac Mini**: Apple Silicon M1 at `100.66.145.48` (Tailscale)
**Bot**: `@SAMyosin_bot`

---

## Quick Access

### SSH Connection

```bash
ssh openclaw@100.66.145.48
```

**Key Location**: `~/.ssh/id_ed25519`

### Dashboard Access

**Get Gateway Token:**
```bash
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | grep -A 3 '\"auth\"' | grep '\"token\"' | cut -d'\"' -f4"
```

**Create SSH Tunnel (for dashboard access):**
```bash
# Port 18790 to avoid conflict with local Gateway
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48
```

**Access Dashboard:**
```
http://localhost:18790/?token=<GATEWAY_TOKEN>
```

See [Dashboard Troubleshooting Guide](DOCUMENTATION/dashboard-troubleshooting.md) for detailed instructions.

### Emergency Quick Commands

```bash
# Is it running?
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"

# Restart it
ssh openclaw@100.66.145.48 "launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway"

# View last 30 log lines
ssh openclaw@100.66.145.48 "tail -30 ~/.openclaw/logs/gateway.log"

# Check for errors
ssh openclaw@100.66.145.48 "tail -30 ~/.openclaw/logs/gateway.err.log"
```

---

## Common Support Scenarios

### Scenario 1: "The bot isn't responding"

**Diagnosis workflow:**

1. **Check if gateway is running:**
```bash
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"
```

**If no output** → Gateway is not running → Go to "Start Gateway"

**If running** → Continue to step 2

2. **Check recent logs for Telegram connection:**
```bash
ssh openclaw@100.66.145.48 "tail -50 ~/.openclaw/logs/gateway.log | grep -i telegram"
```

**Look for:**
- `[telegram] [default] starting provider (@SAMyosin_bot)` - Good!
- `[telegram] autoSelectFamily=false` - Connection established
- Any error messages about `401 Unauthorized` - Bad token
- `getUpdates conflict` - Multiple instances running

3. **Test Telegram API directly:**
```bash
ssh openclaw@100.66.145.48 "curl -s 'https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe' | python3 -m json.tool"
```

**Expected:** `"ok": true` with bot details

4. **Check for recent errors:**
```bash
ssh openclaw@100.66.145.48 "grep -i 'telegram' ~/.openclaw/logs/gateway.err.log | tail -10"
```

**Common issues:**
- `401: Unauthorized` - Wrong bot token
- `Unknown model` - Model configuration issue
- `Invalid config` - Configuration validation failed

5. **Restart gateway if needed:**
```bash
ssh openclaw@100.66.145.48 "launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway"
```

Wait 5 seconds, then verify:
```bash
ssh openclaw@100.66.145.48 "tail -20 ~/.openclaw/logs/gateway.log"
```

Should see:
```
[gateway] listening on ws://127.0.0.1:18789
[telegram] [default] starting provider (@SAMyosin_bot)
```

### Scenario 2: "Mac Mini went to sleep / Can't connect"

**Problem**: The Mac Mini becomes unreachable (ping fails, SSH times out)

**Diagnosis:**

1. **Try to ping the Mac Mini:**
```bash
ping -c 3 100.66.145.48
```

**If 100% packet loss** → Mac Mini is either:
- Asleep (most common)
- Powered off
- Tailscale disconnected
- Network issue

2. **Ask client to wake the Mac Mini:**
   - Move the mouse or press any key
   - Check if Tailscale is running (menu bar icon)

3. **Once awake, verify sleep settings:**
```bash
ssh openclaw@100.66.145.48 "pmset -g | grep sleep"
```

**Expected output:**
```
 sleep                0
 disksleep            0
 displaysleep         10
```

**If sleep is NOT 0**, the settings need to be fixed.

4. **Fix sleep settings (requires client's password):**

The client must run this on the Mac Mini:
```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10 womp 0 powernap 0
```

Or use the script already on the machine:
```bash
~/mac-mini-power-setup.sh
```

5. **Verify settings were applied:**
```bash
ssh openclaw@100.66.145.48 "pmset -g | grep sleep"
```

**Why this happens:**
- macOS defaults allow sleep after inactivity
- Power settings may not persist across macOS updates
- System preferences can override pmset settings

**Prevention:**
- Client should run `mac-mini-power-setup.sh` after any macOS updates
- Consider creating a LaunchDaemon to enforce power settings on boot

### Scenario 3: "I restarted the Mac Mini and it's not working"

**Diagnosis:**

1. **Verify Mac Mini is online:**
```bash
ping 100.66.145.48
```

2. **Check if gateway auto-started:**
```bash
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"
```

**If not running:**

3. **Check if LaunchAgent is loaded:**
```bash
ssh openclaw@100.66.145.48 "launchctl list | grep openclaw"
```

**If not listed:**
```bash
ssh openclaw@100.66.145.48 "launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist"
```

4. **Start the gateway:**
```bash
ssh openclaw@100.66.145.48 "launchctl start com.openclaw.gateway"
```

5. **Verify it started:**
```bash
ssh openclaw@100.66.145.48 "sleep 3 && ps aux | grep openclaw-gateway | grep -v grep"
```

### Scenario 3: "Error messages in Telegram"

**Common errors and fixes:**

#### Error: "Unknown model: openrouter/auto"

**Fix the model configuration:**
```bash
ssh openclaw@100.66.145.48 "jq '.agents.defaults.model.primary = \"openrouter/anthropic/claude-3.5-sonnet\" | .agents.defaults.models = {\"openrouter/anthropic/claude-3.5-sonnet\": {\"alias\": \"Claude 3.5 Sonnet\"}}' ~/.openclaw/openclaw.json > /tmp/fix.json && cat /tmp/fix.json > ~/.openclaw/openclaw.json"
```

**Restart gateway:**
```bash
ssh openclaw@100.66.145.48 "pkill -9 openclaw-gateway && sleep 2 && /opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"
```

#### Error: "Invalid config: channels.telegram.dmPolicy..."

**This means dmPolicy and allowFrom don't match.**

**For open access (testing):**
```bash
ssh openclaw@100.66.145.48 "jq '.channels.telegram.dmPolicy = \"open\" | .channels.telegram.allowFrom = [\"*\"]' ~/.openclaw/openclaw.json > /tmp/fix.json && cat /tmp/fix.json > ~/.openclaw/openclaw.json"
```

**For client-only access (production):**
```bash
ssh openclaw@100.66.145.48 "jq '.channels.telegram.dmPolicy = \"allowlist\" | .channels.telegram.allowFrom = [\"337198\"]' ~/.openclaw/openclaw.json > /tmp/fix.json && cat /tmp/fix.json > ~/.openclaw/openclaw.json"
```

**Reload gateway:**
```bash
ssh openclaw@100.66.145.48 "pkill -SIGUSR1 openclaw-gateway"
```

### Scenario 4: "Telegram Provider Crashed" (Auto-Detected)

**Problem**: Telegram provider times out or crashes (common after 500s of inactivity)

**Symptoms:**
- Bot receives messages but doesn't respond
- Error logs show: `[telegram] [default] channel exited: Request to 'getUpdates' timed out after 500 seconds`
- Gateway process is running but Telegram isn't working

**Automatic Recovery (if health monitor is installed):**

The health monitor detects this automatically and restarts the gateway within 5 minutes.

**Manual Fix:**

1. **Check for crash:**
```bash
ssh openclaw@100.66.145.48 "grep 'telegram.*exited\|getUpdates.*timed out' ~/.openclaw/logs/gateway.err.log | tail -5"
```

2. **Restart gateway:**
```bash
ssh openclaw@100.66.145.48 "pkill -f openclaw-gateway && sleep 2 && /opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"
```

3. **Verify restart:**
```bash
ssh openclaw@100.66.145.48 "sleep 5 && ps aux | grep openclaw-gateway | grep -v grep"
```

4. **Test bot:**
Send message to `@SAMyosin_bot` and verify response

**Prevention:**

Install the automated health monitor to detect and recover from this automatically:

```bash
ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh --install"
```

### Scenario 5: Testing the Bot (Pre-Delivery)

**Before delivering to client, always test:**

1. **Enable open access temporarily:**
```bash
ssh openclaw@100.66.145.48 "jq '.channels.telegram.dmPolicy = \"open\" | .channels.telegram.allowFrom = [\"*\"]' ~/.openclaw/openclaw.json > /tmp/test.json && cat /tmp/test.json > ~/.openclaw/openclaw.json"
```

2. **Reload gateway:**
```bash
ssh openclaw@100.66.145.48 "pkill -SIGUSR1 openclaw-gateway"
```

3. **Wait 5 seconds, then test:**
   - Open Telegram
   - Message `@SAMyosin_bot`
   - Send "Hello test"
   - Verify response

4. **Monitor logs during test:**
```bash
ssh openclaw@100.66.145.48 "tail -f ~/.openclaw/logs/gateway.log"
```

5. **Restore client-only access:**
```bash
ssh openclaw@100.66.145.48 "jq '.channels.telegram.dmPolicy = \"allowlist\" | .channels.telegram.allowFrom = [\"337198\"]' ~/.openclaw/openclaw.json > /tmp/restore.json && cat /tmp/restore.json > ~/.openclaw/openclaw.json"
```

6. **Reload again:**
```bash
ssh openclaw@100.66.145.48 "pkill -SIGUSR1 openclaw-gateway"
```

---

## Configuration Management

### View Current Config

```bash
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | python3 -m json.tool"
```

### Backup Config

```bash
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)"
```

### Restore from Backup

```bash
# List backups
ssh openclaw@100.66.145.48 "ls -la ~/.openclaw/*.bak*"

# Restore
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json"
```

### Key Configuration Values

| Setting | Value | Purpose |
|---------|-------|---------|
| `channels.telegram.botToken` | `8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4` | Bot authentication |
| `channels.telegram.dmPolicy` | `"allowlist"` | Restrict to specific users |
| `channels.telegram.allowFrom` | `["337198"]` | Client's Telegram user ID |
| `agents.defaults.model.primary` | `"openrouter/anthropic/claude-3.5-sonnet"` | AI model to use |
| `gateway.port` | `18789` | Local gateway port |
| `gateway.bind` | `"loopback"` | Localhost only (secure) |

---

## Monitoring & Logs

### Log Locations

```
~/.openclaw/logs/
├── gateway.log          # Main activity log
├── gateway.err.log      # Errors only
├── gateway.stdout.log   # LaunchAgent stdout
└── gateway.stderr.log   # LaunchAgent stderr
```

### Live Log Monitoring

**Main log:**
```bash
ssh openclaw@100.66.145.48 "tail -f ~/.openclaw/logs/gateway.log"
```

**Errors only:**
```bash
ssh openclaw@100.66.145.48 "tail -f ~/.openclaw/logs/gateway.err.log"
```

**Filter for Telegram events:**
```bash
ssh openclaw@100.66.145.48 "tail -f ~/.openclaw/logs/gateway.log | grep -i telegram"
```

### Log Analysis Commands

**Find recent errors:**
```bash
ssh openclaw@100.66.145.48 "grep -i error ~/.openclaw/logs/gateway.err.log | tail -20"
```

**Check Telegram connectivity history:**
```bash
ssh openclaw@100.66.145.48 "grep 'starting provider' ~/.openclaw/logs/gateway.log | tail -10"
```

**See when gateway last restarted:**
```bash
ssh openclaw@100.66.145.48 "grep 'listening on ws' ~/.openclaw/logs/gateway.log | tail -5"
```

**Check for config reloads:**
```bash
ssh openclaw@100.66.145.48 "grep 'reload' ~/.openclaw/logs/gateway.log | tail -10"
```

---

## Gateway Control

### Start/Stop/Restart

**Using LaunchAgent (preferred):**
```bash
# Start
ssh openclaw@100.66.145.48 "launchctl start com.openclaw.gateway"

# Stop
ssh openclaw@100.66.145.48 "launchctl stop com.openclaw.gateway"

# Restart
ssh openclaw@100.66.145.48 "launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway"

# Reload config (SIGUSR1)
ssh openclaw@100.66.145.48 "pkill -SIGUSR1 openclaw-gateway"
```

**Manual (if LaunchAgent not configured):**
```bash
# Stop
ssh openclaw@100.66.145.48 "pkill -f openclaw-gateway"

# Start
ssh openclaw@100.66.145.48 "/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"

# Verify
ssh openclaw@100.66.145.48 "sleep 3 && ps aux | grep openclaw-gateway | grep -v grep"
```

### Check Status

```bash
# Is it running?
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep && echo '✓ Running' || echo '✗ Not running'"

# Check process details
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"

# Check LaunchAgent status
ssh openclaw@100.66.145.48 "launchctl list | grep openclaw"
```

---

## Health Checks

### Automated Health Monitor (NEW - Proactive Crash Detection)

The Mac Mini now has an automated health monitor that detects and recovers from crashes automatically.

**What it monitors:**
- Gateway process running
- Telegram provider crashes/timeouts
- Recent errors in logs
- Sleep settings (warns if Mac can sleep)

**Run manual check:**
```bash
ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh"
```

**Install as background service (recommended):**
```bash
ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh --install"
```

This will:
- Check health every 5 minutes
- Automatically restart gateway if Telegram provider crashes
- Log all actions to `/tmp/openclaw-monitor.log`
- Warn about sleep settings

**View monitor logs:**
```bash
ssh openclaw@100.66.145.48 "tail -50 /tmp/openclaw-monitor.log"
```

**Why this is needed:**
- Telegram provider can timeout after 500 seconds of inactivity
- Gateway may crash silently
- Proactive monitoring prevents extended downtime
- Auto-recovery means less manual intervention needed

### Quick Health Check Script

```bash
#!/bin/bash
# Run this locally to check Mac Mini health

echo "=== OpenClaw Mac Mini Health Check ==="
echo ""

echo "1. Ping test:"
ping -c 3 100.66.145.48

echo ""
echo "2. SSH connectivity:"
ssh openclaw@100.66.145.48 "echo 'SSH: OK'"

echo ""
echo "3. Gateway process:"
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep || echo 'NOT RUNNING'"

echo ""
echo "4. Recent logs:"
ssh openclaw@100.66.145.48 "tail -10 ~/.openclaw/logs/gateway.log"

echo ""
echo "5. Telegram bot API test:"
ssh openclaw@100.66.145.48 "curl -s 'https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe' | python3 -m json.tool | head -5"

echo ""
echo "6. Health monitor status (if installed):"
ssh openclaw@100.66.145.48 "launchctl list | grep openclaw.healthmonitor"

echo ""
echo "=== Health Check Complete ==="
```

### System Resource Check

```bash
# CPU and Memory
ssh openclaw@100.66.145.48 "top -l 1 | head -10"

# Disk space
ssh openclaw@100.66.145.48 "df -h /"

# Uptime
ssh openclaw@100.66.145.48 "uptime"

# Network connectivity
ssh openclaw@100.66.145.48 "ping -c 3 8.8.8.8"
```

---

## Troubleshooting Reference

### Common Issues Quick Reference

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| Bot not responding | Gateway not running | `launchctl start com.openclaw.gateway` |
| Bot receives but doesn't respond | Telegram provider crashed | Run: `~/openclaw-health-monitor.sh` or wait for auto-recovery |
| "Unknown model" error | Wrong model config | Fix model to `openrouter/anthropic/claude-3.5-sonnet` |
| "Invalid config" error | dmPolicy/allowFrom mismatch | Set `dmPolicy="allowlist"` and `allowFrom=["337198"]` |
| "401 Unauthorized" | Wrong bot token | Verify token: `8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4` |
| Gateway keeps restarting | Config invalid | Check `gateway.err.log` for validation errors |
| Can't SSH in / Mac unreachable | Mac Mini asleep or Tailscale off | Have client wake Mac & check Tailscale app |
| Mac Mini keeps going to sleep | Power settings not applied | Client must run: `sudo pmset -a sleep 0 disksleep 0` |
| No logs appearing | Wrong log location | Check `/tmp/openclaw/` or `~/.openclaw/logs/` |

### Emergency Recovery

**If everything is broken:**

1. **Backup current config:**
```bash
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.emergency-backup"
```

2. **Restore from last good backup:**
```bash
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json"
```

3. **Kill all gateway processes:**
```bash
ssh openclaw@100.66.145.48 "pkill -9 -f openclaw"
```

4. **Start fresh:**
```bash
ssh openclaw@100.66.145.48 "/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"
```

5. **Verify:**
```bash
ssh openclaw@100.66.145.48 "sleep 5 && tail -30 ~/.openclaw/logs/gateway.log"
```

---

## Pre-Delivery Checklist

Before delivering Mac Mini to client:

- [ ] SSH access tested and working
- [ ] OpenClaw Gateway running
- [ ] Dashboard accessible via SSH tunnel (see Dashboard Access section)
- [ ] Gateway token documented for dashboard access
- [ ] Bot tested (temporarily allowed your user ID)
- [ ] Bot restricted to client's user ID only (`337198`)
- [ ] LaunchAgent configured for auto-start
- [ ] Power settings configured (no sleep)
- [ ] All setup scripts present on Mac Mini:
  - [ ] `CLIENT-SETUP-GUIDE.md`
  - [ ] `setup-openclaw-autostart.sh`
  - [ ] `mac-mini-power-setup.sh`
- [ ] Client credentials documented
- [ ] Tailscale installed and logged in
- [ ] SSH daemon enabled
- [ ] Test message sent to bot and response received
- [ ] Logs reviewed for any errors

---

## Contact Information

**Client Telegram Bot**: `@SAMyosin_bot`
**Client Telegram User ID**: `337198`
**Mac Mini Tailscale IP**: `100.66.145.48`
**Mac Mini Username**: `openclaw`
**Gateway Port**: `18789`
**Support Technician**: @jordaaanh

---

## Related Documentation

- [Dashboard Troubleshooting Guide](DOCUMENTATION/dashboard-troubleshooting.md) - Comprehensive dashboard access and troubleshooting
- [Tailscale Explained](DOCUMENTATION/tailscale-explained.md) - Network connectivity setup
- [Client Setup Guide](CLIENT-SETUP-GUIDE.md) - Initial OpenClaw configuration for clients

---

*Last Updated: 2026-02-03*
*OpenClaw Version: 2026.2.1*
*macOS: Sequoia on Apple Silicon M1*
