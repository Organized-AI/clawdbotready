# Telegram Channel Connection - Monitoring & Troubleshooting Guide

**For: Client & Support Technician**
**Bot**: `@SAMyosin_bot`
**Mac Mini**: `100.66.145.48`

---

## Understanding Telegram Channel Connections

### How It Works

Your bot connects to Telegram using the OpenClaw Gateway:

```
Telegram App → Telegram Servers → OpenClaw Gateway → Claude AI
                                        ↑
                                   Your Mac Mini
```

The gateway uses Telegram's "getUpdates" API to check for new messages every few seconds.

### Common Connection Issues

| Issue | Symptom | Cause |
|-------|---------|-------|
| **EMFILE Error** | "Agent failed before reply" with file error | Too many open files (file descriptor limit) |
| **Provider Timeout** | Bot stops responding after being idle | Telegram API timeout after 500s |
| **Gateway Crash** | Bot completely offline | Process crashed or stopped |
| **Network Issue** | Intermittent responses | Mac Mini network/internet problem |
| **Mac Asleep** | Can't reach bot remotely | Power settings allow sleep |

**⚠️ NEW: If you see EMFILE errors**, see the dedicated guide: [EMFILE Troubleshooting](../troubleshooting/OPENCLAW-EMFILE-TROUBLESHOOTING.md)

---

## Monitoring Channel Health

### Quick Status Check

**From Mac Mini Terminal:**

```bash
# 1. Is gateway running?
ps aux | grep openclaw-gateway | grep -v grep

# 2. When did Telegram last connect?
grep "telegram.*starting provider" ~/.openclaw/logs/gateway.log | tail -1

# 3. Any recent errors?
tail -20 ~/.openclaw/logs/gateway.err.log
```

**Expected Healthy Output:**

```
# Process running:
openclaw  13540  0.5  3.8  openclaw-gateway

# Recent Telegram connection:
2026-02-03T20:42:53.422Z [telegram] [default] starting provider (@SAMyosin_bot)

# No recent errors in error log
```

### Remote Monitoring (Support Technician)

```bash
# Quick health check
ssh openclaw@100.66.145.48 "
  echo '=== Gateway Status ===' && \
  ps aux | grep openclaw-gateway | grep -v grep && \
  echo && echo '=== Last Telegram Activity ===' && \
  grep 'telegram.*starting provider' ~/.openclaw/logs/gateway.log | tail -1 && \
  echo && echo '=== Recent Errors ===' && \
  tail -5 ~/.openclaw/logs/gateway.err.log
"
```

---

## Troubleshooting Common Issues

### Issue 1: Telegram Provider Timeout

**Symptoms:**
- Bot was working fine
- Now messages go unanswered
- Gateway process is still running
- Error log shows: `[telegram] [default] channel exited: Request to 'getUpdates' timed out after 500 seconds`

**Why This Happens:**

The Telegram API "getUpdates" call times out after 500 seconds (8.3 minutes) of no activity. This is a known limitation of long-polling.

**Fix (Client):**

1. Open Terminal
2. Restart the gateway:
```bash
launchctl stop com.openclaw.gateway
sleep 3
launchctl start com.openclaw.gateway
```
3. Wait 10 seconds
4. Test bot on Telegram

**Fix (Support - Remote):**

```bash
ssh openclaw@100.66.145.48 "launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway"

# Verify restart
ssh openclaw@100.66.145.48 "sleep 5 && tail -10 ~/.openclaw/logs/gateway.log"
```

**Prevention:**

Install the automated health monitor:
```bash
~/openclaw-health-monitor.sh --install
```

This detects timeouts automatically and restarts the gateway within 5 minutes.

---

### Issue 2: Bot Not Receiving Messages

**Symptoms:**
- You send messages to bot
- Bot doesn't respond at all
- No errors visible

**Diagnosis:**

1. **Check if Telegram is getting the messages:**

```bash
# Client:
curl -s "https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getUpdates?limit=5" | python3 -m json.tool

# Remote:
ssh openclaw@100.66.145.48 "curl -s 'https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getUpdates?limit=5' | python3 -m json.tool"
```

**If you see your messages** → Telegram API is working, gateway isn't processing them

**If no messages** → Check bot token or Telegram server issues

2. **Check gateway logs for message processing:**

```bash
# Client:
tail -50 ~/.openclaw/logs/gateway.log | grep -i message

# Remote:
ssh openclaw@100.66.145.48 "tail -50 ~/.openclaw/logs/gateway.log | grep -i message"
```

3. **Verify bot token:**

```bash
# Client:
grep "botToken" ~/.openclaw/openclaw.json

# Remote:
ssh openclaw@100.66.145.48 "grep 'botToken' ~/.openclaw/openclaw.json"
```

Should show: `"botToken": "8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4"`

**Fix:**

If gateway isn't processing messages, restart it:

```bash
# Client:
launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway

# Remote:
ssh openclaw@100.66.145.48 "launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway"
```

---

### Issue 3: "401 Unauthorized" Error

**Symptoms:**
- Bot won't start
- Error log shows: `401: Unauthorized`
- Telegram API test fails

**Cause:** Wrong bot token in configuration

**Fix:**

1. **Verify correct token:**

The correct token is: `8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4`

2. **Update configuration:**

```bash
# Client:
nano ~/.openclaw/openclaw.json
# Find "botToken" and verify it matches above
# Save: Ctrl+O, Enter, Ctrl+X

# Remote:
ssh openclaw@100.66.145.48 "jq '.channels.telegram.botToken = \"8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4\"' ~/.openclaw/openclaw.json > /tmp/fix.json && cat /tmp/fix.json > ~/.openclaw/openclaw.json"
```

3. **Restart gateway:**

```bash
launchctl stop com.openclaw.gateway && sleep 3 && launchctl start com.openclaw.gateway
```

---

### Issue 4: Multiple Bot Instances (Conflict)

**Symptoms:**
- Error: `getUpdates conflict`
- Bot responds twice to same message
- Unstable behavior

**Cause:** Multiple gateway processes running with same bot token

**Fix:**

1. **Kill all gateway processes:**

```bash
# Client:
pkill -9 -f openclaw-gateway

# Remote:
ssh openclaw@100.66.145.48 "pkill -9 -f openclaw-gateway"
```

2. **Wait 5 seconds:**

```bash
sleep 5
```

3. **Start ONE instance:**

```bash
# Client:
launchctl start com.openclaw.gateway

# Remote:
ssh openclaw@100.66.145.48 "launchctl start com.openclaw.gateway"
```

4. **Verify only ONE process:**

```bash
# Client:
ps aux | grep openclaw-gateway | grep -v grep | wc -l
# Should show: 1

# Remote:
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep | wc -l"
```

---

### Issue 5: EMFILE Error - "Too Many Open Files"

**Symptoms:**
- Error message in Telegram: `Agent failed before reply: EMFILE: process.cwd failed with error too many open files`
- Gateway is running but can't process messages
- Gateway log shows file opening failures

**Why This Happens:**

macOS has a default limit of only 256 file descriptors per process. OpenClaw Gateway uses file descriptors for:
- WebSocket connections
- Database files
- Log files
- Configuration files
- Telegram connections

When this limit is reached, the gateway can't open any more files - including critical config files.

**Diagnosis:**

```bash
# Check open file descriptors
lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l
# If > 200, you're approaching the limit

# Check for EMFILE errors
grep 'EMFILE' ~/.openclaw/logs/gateway.err.log | tail -5
```

**Immediate Fix (Temporary):**

```bash
# Client:
launchctl stop ai.openclaw.gateway && sleep 3 && launchctl start ai.openclaw.gateway

# Remote:
ssh openclaw@100.66.145.48 "launchctl stop ai.openclaw.gateway && sleep 3 && launchctl start ai.openclaw.gateway"
```

**Permanent Fix:**

See the comprehensive guide: **[EMFILE Troubleshooting Guide](../troubleshooting/OPENCLAW-EMFILE-TROUBLESHOOTING.md)**

The fix involves updating the LaunchAgent plist to increase file descriptor limits from 256 to 65,536.

**Prevention:**

Monitor file descriptor usage and restart gateway if it exceeds 10,000:

```bash
# Add to health monitor
FD_COUNT=$(lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l)
if [ $FD_COUNT -gt 10000 ]; then
    launchctl stop ai.openclaw.gateway
    sleep 3
    launchctl start ai.openclaw.gateway
fi
```

---

### Issue 6: Intermittent Connection Drops

**Symptoms:**
- Bot works sometimes, not others
- Connections drop randomly
- No consistent pattern

**Diagnosis:**

1. **Check network stability:**

```bash
# Client:
ping -c 10 8.8.8.8

# Remote:
ssh openclaw@100.66.145.48 "ping -c 10 8.8.8.8"
```

2. **Check for sleep events:**

```bash
# Client:
pmset -g log | grep -i "sleep\|wake" | tail -20

# Remote:
ssh openclaw@100.66.145.48 "pmset -g log | grep -i 'sleep\|wake' | tail -20"
```

3. **Check gateway uptime:**

```bash
# Client:
ps -p $(pgrep openclaw-gateway) -o etime=

# Remote:
ssh openclaw@100.66.145.48 "ps -p \$(pgrep openclaw-gateway) -o etime="
```

**If uptime is low** → Gateway is restarting frequently

**If sleep events found** → Fix power settings (see below)

**Fixes:**

1. **Disable Mac sleep (CRITICAL):**

```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10 womp 0 powernap 0
```

2. **Install health monitor for auto-recovery:**

```bash
~/openclaw-health-monitor.sh --install
```

3. **Check WiFi/Ethernet stability:**
   - Use Ethernet if possible (more stable)
   - Move Mac Mini closer to router if on WiFi
   - Check router logs for connection drops

---

## Automated Monitoring Setup

### Install Health Monitor (Recommended)

The health monitor automatically detects and fixes Telegram connection issues.

**Installation:**

```bash
# Client:
~/openclaw-health-monitor.sh --install

# Remote:
ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh --install"
```

**What it does:**
- Checks every 5 minutes
- Detects Telegram provider timeouts
- Automatically restarts gateway when issues found
- Logs all actions for review
- Warns about sleep settings

**View monitor logs:**

```bash
# Client:
tail -50 /tmp/openclaw-monitor.log

# Remote:
ssh openclaw@100.66.145.48 "tail -50 /tmp/openclaw-monitor.log"
```

**Check if monitor is running:**

```bash
# Client:
launchctl list | grep healthmonitor

# Remote:
ssh openclaw@100.66.145.48 "launchctl list | grep healthmonitor"
```

---

## Testing Telegram Connectivity

### Test 1: Bot API Connectivity

```bash
# Client:
curl -s "https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe" | python3 -m json.tool

# Remote:
ssh openclaw@100.66.145.48 "curl -s 'https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe' | python3 -m json.tool"
```

**Expected output:**
```json
{
    "ok": true,
    "result": {
        "id": 8055366403,
        "is_bot": true,
        "username": "SAMyosin_bot",
        ...
    }
}
```

### Test 2: Send Test Message

```bash
# Replace 7062607114 with your Telegram user ID
curl -s -X POST 'https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/sendMessage' \
  -d 'chat_id=7062607114' \
  -d 'text=Test message from gateway' | python3 -m json.tool
```

### Test 3: Check Recent Updates

```bash
# See last 5 messages received
curl -s "https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getUpdates?limit=5" | python3 -m json.tool
```

### Test 4: End-to-End Test

1. Send message to `@SAMyosin_bot`: "Hello test"
2. Watch gateway logs:
```bash
tail -f ~/.openclaw/logs/gateway.log
```
3. Look for:
   - Message received log entry
   - Claude API call
   - Response sent log entry
4. Verify bot responds in Telegram

---

## Log Analysis

### Reading Gateway Logs

**Good signs:**
```
[gateway] listening on ws://127.0.0.1:18789
[telegram] [default] starting provider (@SAMyosin_bot)
[telegram] autoSelectFamily=false
```

**Warning signs:**
```
[telegram] [default] channel exited
Request to 'getUpdates' timed out after 500 seconds
[openclaw] Suppressed AbortError
```

**Bad signs:**
```
401: Unauthorized
Unknown model
Invalid config
getUpdates conflict
```

### Finding Specific Issues

**Check for timeouts:**
```bash
grep "timed out" ~/.openclaw/logs/gateway.err.log
```

**Check for Telegram errors:**
```bash
grep -i "telegram.*error\|telegram.*exited" ~/.openclaw/logs/gateway.err.log
```

**Find when gateway last started:**
```bash
grep "listening on ws" ~/.openclaw/logs/gateway.log | tail -5
```

**See recent Telegram activity:**
```bash
grep "telegram.*starting provider" ~/.openclaw/logs/gateway.log | tail -10
```

---

## Emergency Recovery

### When Nothing Works

1. **Backup configuration:**
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.emergency
```

2. **Kill everything:**
```bash
pkill -9 -f openclaw
launchctl unload ~/Library/LaunchAgents/com.openclaw.gateway.plist 2>/dev/null || true
```

3. **Wait:**
```bash
sleep 10
```

4. **Start fresh:**
```bash
launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist
launchctl start com.openclaw.gateway
```

5. **Verify:**
```bash
sleep 5
ps aux | grep openclaw-gateway | grep -v grep
tail -20 ~/.openclaw/logs/gateway.log
```

6. **Test bot:**
Send message to `@SAMyosin_bot`

---

## Quick Reference

### Common Commands

| Task | Command (Client) | Command (Remote) |
|------|------------------|------------------|
| Check Telegram connection | `grep "telegram.*starting" ~/.openclaw/logs/gateway.log \| tail -1` | `ssh openclaw@100.66.145.48 "grep 'telegram.*starting' ~/.openclaw/logs/gateway.log \| tail -1"` |
| Check for timeouts | `grep "timed out" ~/.openclaw/logs/gateway.err.log` | `ssh openclaw@100.66.145.48 "grep 'timed out' ~/.openclaw/logs/gateway.err.log"` |
| Test bot API | `curl -s "https://api.telegram.org/bot.../getMe"` | `ssh openclaw@100.66.145.48 "curl -s 'https://api.telegram.org/bot.../getMe'"` |
| Restart gateway | `launchctl stop/start com.openclaw.gateway` | `ssh openclaw@100.66.145.48 "launchctl stop/start com.openclaw.gateway"` |
| Run health check | `~/openclaw-health-monitor.sh` | `ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh"` |

---

**Last Updated**: 2026-02-03
**OpenClaw Version**: 2026.2.1
**Telegram Bot**: @SAMyosin_bot
