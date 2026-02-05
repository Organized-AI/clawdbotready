# Quick Start Guide - Your AI Telegram Bot

**For: Mac Mini Owner**
**Bot Name**: `@SAMyosin_bot`

---

## When You First Plug In Your Mac Mini

### 1. Power On

1. Connect power cable to wall outlet
2. Connect Ethernet cable (or make sure WiFi is set up)
3. Press the **power button** on the back of the Mac Mini
4. Wait 30-60 seconds for it to boot

### 2. Login

- **Username**: `openclaw`
- **Password**: [Your password]

### 3. Wait for Auto-Start

After logging in, wait **10-15 seconds**. The bot starts automatically!

### 4. Test Your Bot

1. Open **Telegram** on your phone
2. Search for `@SAMyosin_bot`
3. Send a message like "Hello"
4. You should get a response within 5-10 seconds

**✓ If it responds** → Everything is working! You're done.

**✗ If it doesn't respond** → See [Troubleshooting](#troubleshooting) below

---

## Daily Use

### Normal Operation

Once set up, you don't need to do anything. Just:

1. Make sure Mac Mini is powered on and connected to internet
2. Message `@SAMyosin_bot` on Telegram
3. Chat with your AI assistant!

### Is Everything Working?

**Quick check** (open Terminal):

```bash
ps aux | grep openclaw-gateway | grep -v grep
```

If you see output → Bot is running ✓

If no output → Bot is not running → [Start the Bot](#starting-the-bot)

---

## Troubleshooting

### Problem 1: Bot Doesn't Respond After Plugging In

**Fix:**

1. Open **Terminal** (Applications → Utilities → Terminal)

2. Check if it's running:
```bash
ps aux | grep openclaw-gateway | grep -v grep
```

3. If nothing shows up, start it:
```bash
launchctl start com.openclaw.gateway
```

4. Wait 10 seconds and test again on Telegram

### Problem 2: Bot Was Working, Now It's Not

**Quick Fix:**

1. Open **Terminal**

2. Restart the bot:
```bash
launchctl stop com.openclaw.gateway
launchctl start com.openclaw.gateway
```

3. Wait 10 seconds and test on Telegram

### Problem 3: Mac Mini Becomes Unreachable Remotely

**This means your Mac went to sleep!**

**Fix (IMPORTANT - Do This Once):**

1. Open **Terminal**

2. Run this command:
```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10 womp 0 powernap 0
```

3. Enter your password when asked

4. This prevents your Mac from going to sleep

**Check it worked:**
```bash
pmset -g | grep sleep
```

Should show:
```
 sleep                0
 disksleep            0
```

### Problem 4: "Unknown Model" Error in Telegram

**Fix:**

1. Open **Terminal**

2. Edit the configuration:
```bash
nano ~/.openclaw/openclaw.json
```

3. Find the line with `"model"` and make sure it says:
```json
"model": "openrouter/anthropic/claude-3.5-sonnet"
```

4. Save: Press `Ctrl+O`, then `Enter`, then `Ctrl+X`

5. Restart the bot:
```bash
launchctl stop com.openclaw.gateway
launchctl start com.openclaw.gateway
```

---

## Starting the Bot Manually

If auto-start isn't working, you can start it manually:

```bash
launchctl start com.openclaw.gateway
```

**Check if it started:**
```bash
ps aux | grep openclaw-gateway | grep -v grep
```

You should see a line with `openclaw-gateway`

---

## Viewing Logs (For Troubleshooting)

### See What the Bot is Doing

```bash
tail -50 ~/.openclaw/logs/gateway.log
```

**Good signs:**
- `[gateway] listening on ws://127.0.0.1:18789`
- `[telegram] [default] starting provider (@SAMyosin_bot)`

**Bad signs:**
- Error messages
- No recent entries

### See Only Errors

```bash
tail -50 ~/.openclaw/logs/gateway.err.log
```

If this file has recent entries, something went wrong.

### Live Monitoring

Watch logs in real-time as they happen:

```bash
tail -f ~/.openclaw/logs/gateway.log
```

Press `Ctrl+C` to stop watching.

---

## Automated Health Monitor (Optional but Recommended)

### What It Does

Automatically checks if your bot is healthy every 5 minutes and restarts it if there's a problem.

**Benefits:**
- Bot recovers automatically from crashes
- Less downtime
- You don't have to manually restart

### Install It

1. Open **Terminal**

2. Run:
```bash
~/openclaw-health-monitor.sh --install
```

3. Follow the prompts and say "yes" when asked

### Check if Monitor is Running

```bash
launchctl list | grep healthmonitor
```

If you see output → Monitor is active ✓

### View Monitor Logs

```bash
tail -50 /tmp/openclaw-monitor.log
```

This shows what the monitor has been doing.

---

## Shutting Down Properly

### Before Unplugging

**Option 1: Using GUI**
1. Click Apple menu (🍎) in top-left
2. Select "Shut Down..."
3. Click "Shut Down"
4. Wait for screen to go black
5. Then you can unplug

**Option 2: Using Terminal**
```bash
sudo shutdown -h now
```
Enter your password when asked.

### When You Plug It Back In

1. Press power button
2. Login as `openclaw`
3. Wait 10-15 seconds for bot to auto-start
4. Test on Telegram

---

## Getting Remote Support

Your support technician can help remotely via SSH.

### What They Can Do

✅ Restart your bot
✅ View logs to diagnose issues
✅ Update configuration
✅ Check system health

### What They CANNOT Do

❌ See your screen
❌ Control your mouse/keyboard
❌ Access your personal files
❌ See your Telegram messages

### How to Enable Remote Support

**Check SSH is on:**
```bash
sudo systemsetup -getremotelogin
```

Should say: `Remote Login: On`

**If it's off, turn it on:**
```bash
sudo systemsetup -setremotelogin on
```

**Check Tailscale is connected:**

Open the **Tailscale** app from Applications and make sure it shows "Connected"

---

## Quick Reference Commands

| What You Want to Do | Command |
|---------------------|---------|
| Check if bot is running | `ps aux \| grep openclaw-gateway \| grep -v grep` |
| Start bot | `launchctl start com.openclaw.gateway` |
| Stop bot | `launchctl stop com.openclaw.gateway` |
| Restart bot | `launchctl stop com.openclaw.gateway && launchctl start com.openclaw.gateway` |
| View recent logs | `tail -50 ~/.openclaw/logs/gateway.log` |
| View errors | `tail -50 ~/.openclaw/logs/gateway.err.log` |
| Watch logs live | `tail -f ~/.openclaw/logs/gateway.log` |
| Prevent sleep | `sudo pmset -a sleep 0 disksleep 0` |
| Check sleep settings | `pmset -g \| grep sleep` |
| Enable SSH | `sudo systemsetup -setremotelogin on` |
| Run health check | `~/openclaw-health-monitor.sh` |
| Install health monitor | `~/openclaw-health-monitor.sh --install` |

---

## When to Contact Support

Contact your support technician if:

- Bot doesn't respond after following troubleshooting steps
- You see constant errors in logs
- Bot keeps restarting on its own
- You can't login to your Mac Mini
- You need to change configuration settings
- You have questions about how it works

**Support Contact**: [Your support contact info]
**Your Bot**: `@SAMyosin_bot`
**Your Mac Mini IP**: `100.66.145.48` (Tailscale)

---

## Important Notes

### Don't Do This

❌ Don't unplug Mac Mini while it's running (always shut down first)
❌ Don't change configuration files unless you know what you're doing
❌ Don't delete files in `~/.openclaw/` directory
❌ Don't disable auto-start (or bot won't restart after reboot)

### Do This

✅ Keep Mac Mini plugged in and powered on
✅ Run the health monitor (it auto-fixes problems)
✅ Disable sleep settings so remote support can access
✅ Test the bot after any Mac Mini restarts
✅ Contact support if you're unsure about something

---

**Last Updated**: 2026-02-03
**OpenClaw Version**: 2026.2.1
**macOS**: Sequoia on Apple Silicon M1
