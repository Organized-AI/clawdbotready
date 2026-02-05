# OpenClaw Health Monitor

**Automated crash detection and recovery for OpenClaw Gateway**

## What It Does

The health monitor runs in the background and automatically detects and recovers from common issues:

✅ **Detects Telegram provider crashes** (e.g., "getUpdates timed out after 500 seconds")
✅ **Restarts gateway automatically** when crashes are detected
✅ **Monitors process health** (ensures gateway is running)
✅ **Checks for recent errors** in logs
✅ **Warns about sleep settings** that could cause connectivity issues
✅ **Logs all actions** for troubleshooting

## Why You Need This

Common issues that this prevents:

1. **Telegram Provider Timeout**: After ~500 seconds of inactivity, the Telegram provider can crash silently
2. **Gateway Crashes**: Process can exit unexpectedly
3. **Mac Sleep**: If Mac goes to sleep, remote access is lost
4. **Silent Failures**: Errors that don't cause obvious symptoms

**Without monitoring**: These issues can go undetected for hours/days
**With monitoring**: Auto-recovery within 5 minutes

## Installation

### Quick Start (One-Time Check)

```bash
~/openclaw-health-monitor.sh
```

### Install as Background Service (Recommended)

```bash
~/openclaw-health-monitor.sh --install
```

This will:
- Create a LaunchAgent that runs at startup
- Check health every 5 minutes
- Automatically restart gateway when issues are detected
- Run continuously in the background

### Run Continuously (Manual)

```bash
~/openclaw-health-monitor.sh --daemon
```

## How It Works

### Checks Performed (Every 5 Minutes)

1. **Gateway Process Check**
   - Verifies `openclaw-gateway` process is running
   - If not running → restarts immediately

2. **Telegram Provider Check**
   - Looks for recent Telegram activity in logs
   - If no activity for 8+ minutes → triggers restart
   - Detects "channel exited" errors

3. **Crash Detection**
   - Scans error logs for Telegram crashes
   - Looks for "getUpdates timed out" messages
   - If found → restarts gateway

4. **Sleep Settings Check**
   - Verifies Mac sleep is disabled
   - Warns if sleep is enabled (doesn't auto-fix, requires sudo)

5. **Auto-Recovery**
   - Stops existing gateway gracefully (SIGTERM)
   - Force-kills if needed (SIGKILL)
   - Starts fresh gateway process
   - Verifies successful startup

## Monitoring Logs

### View Recent Activity

```bash
tail -50 /tmp/openclaw-monitor.log
```

### Live Monitoring

```bash
tail -f /tmp/openclaw-monitor.log
```

### Log Format

```
2026-02-03 14:46:24 [INFO] === Starting health check ===
2026-02-03 14:46:24 [INFO] Telegram provider active (last activity: 120s ago)
2026-02-03 14:46:24 [INFO] ✓ All health checks passed
2026-02-03 14:46:24 [INFO] === Health check complete ===
```

### When Issues Are Detected

```
2026-02-03 14:46:24 [ERROR] Telegram provider inactive for 540s (threshold: 480s)
2026-02-03 14:46:24 [ERROR] Found 3 Telegram errors in last 10 minutes
2026-02-03 14:46:24 [WARN] Health check failed (2 issue(s) detected)
2026-02-03 14:46:24 [INFO] Attempting to restart gateway...
2026-02-03 14:46:34 [INFO] ✓ Gateway restarted successfully
```

## Configuration

Edit the script to customize settings:

```bash
nano ~/openclaw-health-monitor.sh
```

**Key settings:**

| Variable | Default | Description |
|----------|---------|-------------|
| `CHECK_INTERVAL` | 300 | Seconds between health checks |
| `TELEGRAM_TIMEOUT_THRESHOLD` | 480 | Seconds before considering Telegram inactive |
| `MONITOR_LOG` | `/tmp/openclaw-monitor.log` | Where to write logs |

## Troubleshooting

### Health Monitor Not Running

**Check if installed:**
```bash
launchctl list | grep openclaw.healthmonitor
```

**Load manually:**
```bash
launchctl load ~/Library/LaunchAgents/com.openclaw.healthmonitor.plist
```

### Gateway Keeps Restarting

If the monitor is restarting the gateway too frequently:

1. **Check the root cause:**
```bash
tail -100 ~/.openclaw/logs/gateway.err.log
```

2. **Review monitor logs:**
```bash
tail -100 /tmp/openclaw-monitor.log
```

3. **Common causes:**
   - Invalid configuration in `~/.openclaw/openclaw.json`
   - Missing OpenRouter API key
   - Wrong Telegram bot token
   - Network connectivity issues

### False Positives

If health checks are failing incorrectly:

1. **Increase timeout threshold** (edit script):
```bash
TELEGRAM_TIMEOUT_THRESHOLD=600  # 10 minutes instead of 8
```

2. **Check log timestamps** are being parsed correctly
3. **Verify gateway logs** are in expected location

## Uninstallation

### Stop and Remove LaunchAgent

```bash
launchctl unload ~/Library/LaunchAgents/com.openclaw.healthmonitor.plist
rm ~/Library/LaunchAgents/com.openclaw.healthmonitor.plist
```

### Remove Script

```bash
rm ~/openclaw-health-monitor.sh
```

### Remove Logs

```bash
rm /tmp/openclaw-monitor.log
rm /tmp/openclaw-monitor.stdout.log
rm /tmp/openclaw-monitor.stderr.log
```

## Integration with Remote Support

For remote support technicians:

### Check Monitor Status Remotely

```bash
ssh openclaw@100.66.145.48 "launchctl list | grep healthmonitor"
```

### View Recent Monitor Activity

```bash
ssh openclaw@100.66.145.48 "tail -50 /tmp/openclaw-monitor.log"
```

### Trigger Manual Health Check

```bash
ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh"
```

### Install Remotely

```bash
ssh openclaw@100.66.145.48 "~/openclaw-health-monitor.sh --install"
```

## Best Practices

1. **Always install as LaunchAgent** for production deployments
2. **Monitor the monitor logs** periodically to ensure it's working
3. **Fix root causes** instead of relying solely on auto-recovery
4. **Set up sleep prevention** to avoid Mac going to sleep (monitor will warn)
5. **Keep logs rotated** to prevent disk space issues

## Common Issues Prevented

### Issue 1: Telegram Provider Timeout
**Symptom**: Bot receives messages but doesn't respond
**Root Cause**: `getUpdates` API call times out after 500s
**Auto-Recovery**: Detects timeout in logs, restarts gateway

### Issue 2: Gateway Silent Crash
**Symptom**: Bot completely unresponsive
**Root Cause**: Process crashed due to uncaught exception
**Auto-Recovery**: Detects missing process, starts new instance

### Issue 3: Mac Goes to Sleep
**Symptom**: SSH connection fails, bot offline
**Root Cause**: Power settings allow sleep
**Warning Only**: Alerts in logs (client must fix with `sudo pmset`)

## Performance Impact

- **CPU**: Negligible (<0.1% when not restarting)
- **Memory**: ~10MB for script process
- **Disk**: Logs grow ~1MB per day (rotated automatically)
- **Network**: No external calls (only local log parsing)

## Security Considerations

✅ **No sudo required** for normal operation
✅ **Read-only access** to logs
✅ **No network exposure** (localhost only)
✅ **Runs as openclaw user** (not root)
❌ **Cannot fix sleep settings** (requires sudo)

---

**Version**: 1.0.0
**Last Updated**: 2026-02-03
**Tested On**: macOS Sequoia, OpenClaw 2026.2.1
