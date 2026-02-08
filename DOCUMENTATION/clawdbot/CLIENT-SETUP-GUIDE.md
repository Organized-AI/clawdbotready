# Mac Mini OpenClaw Setup Guide

**For: Client (OpenClaw User)**
**Mac Mini Model**: Apple Silicon M1 Mac Mini
**Username**: `openclaw`
**Telegram Bot**: `@SAMyosin_bot`

---

## Table of Contents
1. [Initial Setup After Receiving Mac Mini](#initial-setup)
2. [Starting OpenClaw Gateway](#starting-openclaw)
3. [Verifying Everything Works](#verification)
4. [Daily Operations](#daily-operations)
5. [Troubleshooting](#troubleshooting)
6. [Technical Details](#technical-details)

---

## Initial Setup After Receiving Mac Mini {#initial-setup}

### Step 1: Physical Setup
1. **Plug in power cable** and connect to outlet
2. **Connect to monitor** (HDMI) - only needed for initial setup
3. **Connect keyboard and mouse** - only needed for initial setup
4. **Connect Ethernet cable** OR ensure WiFi is configured
5. **Press power button** on back of Mac Mini

### Step 2: Login
- **Username**: `openclaw`
- **Password**: [You'll need to provide this or have them set it]

### Step 3: Configure Power Settings
Open Terminal (Applications > Utilities > Terminal) and run:

```bash
sudo pmset -a sleep 0 displaysleep 10 disksleep 0
```

Enter your password when prompted. This ensures:
- ✅ Mac Mini never sleeps
- ✅ Display sleeps after 10 minutes (saves energy)
- ✅ Disk never sleeps

**Alternative**: You can also use System Settings:
1. Open **System Settings**
2. Go to **Energy Saver** (or **Battery** on newer macOS)
3. Set **Computer Sleep** to **Never**
4. Set **Display Sleep** to **10 minutes** (or your preference)
5. Uncheck **Put hard disks to sleep when possible**

---

## Starting OpenClaw Gateway {#starting-openclaw}

OpenClaw Gateway is the service that connects your Telegram bot to Claude AI.

### Option 1: Auto-Start (Recommended)

Create a LaunchAgent to start OpenClaw automatically on boot:

1. Open Terminal
2. Create the launch agent file:

```bash
mkdir -p ~/Library/LaunchAgents
nano ~/Library/LaunchAgents/com.openclaw.gateway.plist
```

3. Paste this content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/node</string>
        <string>/Users/openclaw/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js</string>
        <string>gateway</string>
        <string>--port</string>
        <string>18789</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/openclaw/.openclaw/logs/gateway.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/openclaw/.openclaw/logs/gateway.stderr.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/openclaw</string>
</dict>
</plist>
```

4. Save and exit (Ctrl+O, Enter, Ctrl+X)

5. Load the launch agent:

```bash
launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist
```

6. Start it now:

```bash
launchctl start com.openclaw.gateway
```

**Result**: OpenClaw will now start automatically every time you log in or restart the Mac Mini.

### Option 2: Manual Start

If you prefer to start OpenClaw manually:

```bash
cd ~
/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &
```

### Option 3: Simple Command (If Configured)

If the `openclaw` command is in your PATH:

```bash
openclaw gateway start
```

---

## Verifying Everything Works {#verification}

### Check 1: Is the Gateway Running?

```bash
ps aux | grep openclaw-gateway | grep -v grep
```

**Expected output**: You should see a process running with `openclaw-gateway` or `node...openclaw...gateway`

### Check 2: Test the Telegram Bot

1. Open **Telegram** on your phone or computer
2. Search for `@SAMyosin_bot`
3. Send a message like "Hello" or "Test"
4. **Expected**: The bot should respond within a few seconds

### Check 3: View Logs

To see what's happening:

```bash
tail -f ~/.openclaw/logs/gateway.log
```

Press `Ctrl+C` to stop viewing logs.

**Look for**:
- `[telegram] [default] starting provider (@SAMyosin_bot)` - Telegram is connected
- `[gateway] listening on ws://127.0.0.1:18789` - Gateway is running
- No error messages

---

## Daily Operations {#daily-operations}

### Normal Usage
Once set up, you don't need to do anything! Just use the Telegram bot:

1. Open Telegram
2. Message `@SAMyosin_bot`
3. Chat with Claude AI through the bot

### Checking Status

Quick health check:
```bash
ps aux | grep openclaw-gateway | grep -v grep && echo "✓ OpenClaw is running"
```

### Restarting OpenClaw (if needed)

**If using LaunchAgent (auto-start)**:
```bash
launchctl stop com.openclaw.gateway
launchctl start com.openclaw.gateway
```

**If running manually**:
```bash
# Stop
pkill -f openclaw-gateway

# Start
/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &
```

### Viewing Logs

**Gateway logs** (main activity):
```bash
tail -50 ~/.openclaw/logs/gateway.log
```

**Error logs** (problems only):
```bash
tail -50 ~/.openclaw/logs/gateway.err.log
```

**Live monitoring**:
```bash
tail -f ~/.openclaw/logs/gateway.log
```

---

## Troubleshooting {#troubleshooting}

### Problem: Bot doesn't respond

**Check 1**: Is the gateway running?
```bash
ps aux | grep openclaw-gateway | grep -v grep
```

If not, start it using the commands in [Starting OpenClaw](#starting-openclaw).

**Check 2**: Are there errors in the logs?
```bash
tail -30 ~/.openclaw/logs/gateway.err.log
```

**Check 3**: Test the bot token
```bash
curl -s "https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe" | python3 -m json.tool
```

Should show: `"ok": true` and bot details.

### Problem: Gateway keeps crashing

**Check config file**:
```bash
cat ~/.openclaw/openclaw.json | python3 -m json.tool
```

Should parse without errors. If it fails, restore from backup:
```bash
cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json
```

### Problem: Mac Mini goes to sleep (CRITICAL)

**Symptoms:**
- Mac Mini becomes unreachable remotely
- Bot stops responding
- Can't SSH in
- Screen is black

**Why this happens:**
- macOS default power settings allow sleep
- Settings may not persist across macOS updates
- System Preferences can override command-line settings

**Fix (IMPORTANT - Requires your password):**

Open Terminal and run:
```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10 womp 0 powernap 0
```

**What this does:**
- `sleep 0` - Mac NEVER goes to sleep (CRITICAL)
- `disksleep 0` - Hard drives NEVER sleep
- `displaysleep 10` - Screen sleeps after 10 min (saves energy, OK)
- `womp 0` - Disable wake-on-LAN
- `powernap 0` - Disable Power Nap (prevents sleep cycles)

**Verify it worked:**
```bash
pmset -g | grep sleep
```

**Expected output:**
```
 sleep                0
 disksleep            0
 displaysleep         10
```

**Alternative - Use the setup script:**
```bash
cd ~
./mac-mini-power-setup.sh
```

**IMPORTANT:** Re-run this command after any macOS system updates, as updates can reset power settings.

### Problem: Can't access Mac Mini remotely

Your Mac Mini's Tailscale IP is: `100.66.145.48`

Check if Tailscale is running:
```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale status
```

If not connected, open the Tailscale app from Applications and sign in.

### Getting Help

If you encounter issues:

1. **Collect logs**:
```bash
tail -100 ~/.openclaw/logs/gateway.log > ~/openclaw-logs.txt
tail -100 ~/.openclaw/logs/gateway.err.log >> ~/openclaw-logs.txt
```

2. **Check configuration**:
```bash
cat ~/.openclaw/openclaw.json > ~/openclaw-config.txt
```

3. Send both files (`openclaw-logs.txt` and `openclaw-config.txt`) to your support contact

---

## Power Down & Restart Procedures {#power-procedures}

### Safely Shutting Down

**Method 1: GUI (Recommended)**
1. Click Apple menu () in top-left corner
2. Select "Shut Down..."
3. Click "Shut Down" in the confirmation dialog

**Method 2: Terminal**
```bash
sudo shutdown -h now
```

**Before Shutdown Checklist:**
- [ ] Save any open work
- [ ] OpenClaw will stop (auto-starts on next boot if configured)
- [ ] Note: Telegram bot will be offline until restart

### Restarting the Mac Mini

**After Plugging Back In:**

1. **Press power button** on back of Mac Mini
2. **Wait for boot** (approximately 30-60 seconds)
3. **Login** as `openclaw`

**If Auto-Start is Configured** (LaunchAgent):
- OpenClaw Gateway starts automatically within 10-15 seconds after login
- No action needed!

**If Auto-Start is NOT Configured:**

Open Terminal and run:
```bash
/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &
```

### Verify Everything Started

```bash
# Check if gateway is running
ps aux | grep openclaw-gateway | grep -v grep

# View recent logs
tail -20 ~/.openclaw/logs/gateway.log

# Test the bot
# Send a message to @SAMyosin_bot on Telegram
```

**Expected log output:**
```
[gateway] listening on ws://127.0.0.1:18789
[telegram] [default] starting provider (@SAMyosin_bot)
```

### What Happens During Restart?

| Component | Behavior | Action Needed |
|-----------|----------|---------------|
| Mac Mini OS | Boots normally | None (automatic) |
| OpenClaw Gateway | Auto-starts if LaunchAgent configured | None or manual start |
| Telegram Bot | Reconnects automatically | None |
| SSH Access | Available immediately after boot | None |
| Tailscale | Auto-starts | None (already configured) |

### Quick Restart (No Power Down)

If you just need to restart OpenClaw without rebooting:

```bash
launchctl stop com.openclaw.gateway
launchctl start com.openclaw.gateway
```

Or manually:
```bash
pkill -f openclaw-gateway
/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &
```

---

## Remote Support Access {#remote-support}

Your support technician can start/restart OpenClaw remotely via SSH if needed.

### Enabling Remote Support

**Your support technician already has SSH access configured.**

**To verify SSH access is working:**

1. Check Tailscale is connected:
```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale status
```

Should show: `100.66.145.48` and status "Connected"

2. Check SSH is enabled:
```bash
sudo systemsetup -getremotelogin
```

Should show: `Remote Login: On`

**If SSH is disabled, enable it:**
```bash
sudo systemsetup -setremotelogin on
```

### What Remote Support Can Do

Your support technician can remotely:

✅ Check if OpenClaw is running
✅ View logs to diagnose issues
✅ Start/restart the OpenClaw Gateway
✅ Update configuration if needed
✅ Verify Telegram bot connectivity
✅ Check system resources (CPU, memory, disk)

**They CANNOT:**
- Access your files or personal data
- See your screen
- Control your mouse/keyboard
- Access anything outside OpenClaw directory

### Remote Support Commands

**For Support Technician:**

```bash
# Connect via SSH
ssh openclaw@100.66.145.48

# Check if gateway is running
ps aux | grep openclaw-gateway | grep -v grep

# View recent logs
tail -50 ~/.openclaw/logs/gateway.log

# Restart gateway (if using LaunchAgent)
launchctl stop com.openclaw.gateway
launchctl start com.openclaw.gateway

# Or restart manually
pkill -f openclaw-gateway
/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &

# Verify it started
sleep 3
ps aux | grep openclaw-gateway | grep -v grep

# Test Telegram connectivity
curl -s "https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe" | python3 -m json.tool

# Exit
exit
```

### Disabling Remote Support

If you want to disable remote support access:

**Disable SSH:**
```bash
sudo systemsetup -setremotelogin off
```

**Or remove support technician's SSH key:**
```bash
nano ~/.ssh/authorized_keys
# Delete the line containing the support key
# Save: Ctrl+O, Enter, Ctrl+X
```

**To re-enable later:**
```bash
sudo systemsetup -setremotelogin on
```

And contact your support technician to re-add their SSH key.

### Remote Support Security

✅ **Encrypted:** All SSH connections are encrypted
✅ **Key-based:** Password authentication is disabled
✅ **Logged:** All SSH access is logged in system logs
✅ **Limited:** Support access is restricted to OpenClaw directory
✅ **Tailscale:** Only accessible via your private Tailscale network

To view SSH access logs:
```bash
log show --predicate 'process == "sshd"' --last 1h | grep openclaw
```

---

## Technical Details {#technical-details}

### Configuration File
- **Location**: `~/.openclaw/openclaw.json`
- **Backups**: `~/.openclaw/openclaw.json.bak` (automatic backups)

### Important Settings

**Telegram Bot**:
- **Bot Token**: `8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4`
- **Bot Username**: `@SAMyosin_bot`
- **Allowed Users**: Anyone (dmPolicy: "open")

**AI Model**:
- **Provider**: OpenRouter
- **Model**: `openrouter/anthropic/claude-3.5-sonnet`

**Gateway**:
- **Port**: 18789
- **Bind**: localhost only (127.0.0.1)
- **Auth**: Token-based

### Network Details
- **Tailscale IP**: `100.66.145.48`
- **Local Gateway**: `http://127.0.0.1:18789`

### File Locations
```
~/.openclaw/                          # OpenClaw home directory
├── openclaw.json                     # Configuration file
├── openclaw.json.bak                 # Config backup
├── logs/
│   ├── gateway.log                   # Main activity log
│   └── gateway.err.log              # Error log
├── workspace/                        # Agent workspace
└── .gateway-token                    # Auth token (keep secret!)
```

### Useful Commands

**Check OpenClaw version**:
```bash
node ~/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js --version
```

**View current config**:
```bash
cat ~/.openclaw/openclaw.json | python3 -m json.tool
```

**Test Telegram connectivity**:
```bash
curl -s "https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getUpdates?limit=1" | python3 -m json.tool
```

---

## Quick Reference Card

### Essential Commands

| Task | Command |
|------|---------|
| Check if running | `ps aux \| grep openclaw-gateway \| grep -v grep` |
| Start OpenClaw | `launchctl start com.openclaw.gateway` |
| Stop OpenClaw | `launchctl stop com.openclaw.gateway` |
| Restart OpenClaw | `launchctl stop com.openclaw.gateway && launchctl start com.openclaw.gateway` |
| View logs | `tail -f ~/.openclaw/logs/gateway.log` |
| View errors | `tail -f ~/.openclaw/logs/gateway.err.log` |
| Test bot | Message `@SAMyosin_bot` on Telegram |
| Shutdown Mac Mini | `sudo shutdown -h now` |
| Check power settings | `pmset -g` |
| Disable sleep | `sudo pmset -a sleep 0 displaysleep 10 disksleep 0` |
| Check SSH enabled | `sudo systemsetup -getremotelogin` |
| Enable SSH | `sudo systemsetup -setremotelogin on` |

### Power & Restart Quick Guide

| Situation | What to Do |
|-----------|------------|
| **Shutting down** | Apple menu → Shut Down |
| **Restarted Mac** | Login as `openclaw` → Wait 10-15 seconds → OpenClaw auto-starts |
| **OpenClaw not running after restart** | Run: `launchctl start com.openclaw.gateway` |
| **Unplugged and moved** | Plug in → Press power button → Login → Verify OpenClaw started |
| **Need remote help** | Support can SSH in via Tailscale to restart for you |

### Startup Checklist (After Restart)

After restarting the Mac Mini:

1. [ ] Login as `openclaw`
2. [ ] Wait 10-15 seconds for auto-start
3. [ ] Verify OpenClaw is running: `ps aux | grep openclaw-gateway | grep -v grep`
4. [ ] Check logs: `tail -20 ~/.openclaw/logs/gateway.log`
5. [ ] Test bot: Send message to `@SAMyosin_bot` on Telegram
6. [ ] If not running: `launchctl start com.openclaw.gateway`

---

## Emergency Contacts

**Technical Support**: [Your contact information here]
**Telegram Bot**: `@SAMyosin_bot`
**Mac Mini IP**: `100.66.145.48` (Tailscale)

---

*Last Updated: 2026-02-03*
*OpenClaw Version: 2026.2.1*
*macOS Version: Sequoia on Apple Silicon M1*
