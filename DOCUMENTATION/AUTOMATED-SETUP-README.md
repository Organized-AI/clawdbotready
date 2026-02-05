# Automated OpenClaw Setup

**Created**: 2026-02-02
**Status**: Ready to Use
**Target**: Non-Technical Users

---

## What This Does

The automated setup script (`auto-deploy-openclaw.sh`) installs and configures your entire OpenClaw Gateway with **zero technical knowledge required**.

### What Gets Installed

✅ **Shell Environment** - Automatic PATH configuration
✅ **Homebrew** - macOS package manager
✅ **Node.js** - JavaScript runtime
✅ **pnpm** - Fast package manager
✅ **OpenClaw Gateway** - AI bot platform
✅ **iMessage Channel** - Automatic configuration
✅ **Dashboard** - Web interface for monitoring

---

## Quick Start (3 Steps)

### Step 1: Download the Script

The script is already in this folder: `auto-deploy-openclaw.sh`

### Step 2: Run the Script

Open Terminal and run:

```bash
cd "/Users/jordaaan/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready"
./auto-deploy-openclaw.sh
```

### Step 3: Grant Full Disk Access

When prompted:
1. Open **System Settings**
2. Go to **Privacy & Security** > **Full Disk Access**
3. Enable for **node** or **openclaw**

**Done!** Your bot is ready to use.

---

## What Happens During Installation

The script will:

1. **Check Prerequisites** (5 seconds)
   - Verifies macOS version
   - Checks Apple Silicon
   - Confirms disk space

2. **Configure Shell** (10 seconds)
   - Sets up PATH for all tools
   - Prevents "command not found" errors

3. **Install Dependencies** (3-5 minutes)
   - Homebrew (if needed)
   - Node.js (if needed)
   - pnpm (if needed)

4. **Install OpenClaw** (2 minutes)
   - Downloads OpenClaw CLI
   - Configures Gateway
   - Generates secure token

5. **Setup Channels** (1 minute)
   - Enables iMessage plugin
   - Configures iMessage channel
   - Starts Gateway service

6. **Create Dashboard** (5 seconds)
   - Generates access page
   - Opens in browser

**Total Time**: 10-15 minutes

---

## Using Your Bot

### Test iMessage

Send a message from your iPhone or another Mac to this Mac's iMessage account. The bot will respond automatically!

**Example:**
```
You: Hey bot, what's the weather today?
Bot: I'd be happy to help! To provide weather information...
```

### View Dashboard

Open the dashboard file that was created:
```bash
open ~/openclaw-dashboard.html
```

Or visit: http://localhost:18789/

### Check Status

```bash
openclaw gateway status
openclaw channels status
```

### View Logs

```bash
tail -f ~/.openclaw/logs/gateway.log
```

---

## Optional: Add More Channels

### Telegram Bot

**Before running the script**, set your Telegram bot token:

```bash
export TELEGRAM_BOT_TOKEN="your-bot-token-from-botfather"
./auto-deploy-openclaw.sh
```

**How to get a Telegram bot token:**
1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot`
3. Follow prompts to create your bot
4. Copy the token

### Slack Bot

**Before running the script**, set your Slack tokens:

```bash
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_APP_TOKEN="xapp-your-app-token"
./auto-deploy-openclaw.sh
```

**How to get Slack tokens:**
1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Create a new app
3. Get your bot token (starts with `xoxb-`)
4. Get your app token (starts with `xapp-`)

---

## Troubleshooting

### Script Fails with "Permission Denied"

Make the script executable:
```bash
chmod +x auto-deploy-openclaw.sh
```

### "command not found: openclaw" After Installation

Run this:
```bash
source ~/.zprofile
openclaw --version
```

### Bot Not Responding to iMessages

1. **Check Gateway Status**
   ```bash
   openclaw gateway status
   ```
   Should show "Runtime: running"

2. **Verify Full Disk Access**
   - System Settings > Privacy & Security > Full Disk Access
   - Enable for 'node' or 'openclaw'

3. **Restart Gateway**
   ```bash
   openclaw gateway restart
   ```

### Dashboard Won't Load

1. **Check if Gateway is running**
   ```bash
   openclaw gateway status
   ```

2. **Verify port**
   ```bash
   lsof -i :18789
   ```

3. **Check logs**
   ```bash
   tail -50 ~/.openclaw/logs/gateway.log
   ```

---

## Advanced: Manual Installation

If you prefer manual control, see:
- **iMessage Guide**: [IMESSAGE-BOT-GUIDE.md](IMESSAGE-BOT-GUIDE.md)
- **Deployment Lessons**: [DEPLOYMENT-LESSONS-LEARNED.md](DEPLOYMENT-LESSONS-LEARNED.md)
- **OpenClaw Onboarding Skill**: `.claude/skills/openclaw-onboarding/skill.md`

---

## What's Different from Manual Setup

### Automated Script:
✅ No command typing
✅ No PATH configuration needed
✅ All channels set up automatically
✅ Dashboard created automatically
✅ Takes 10-15 minutes

### Manual Setup:
❌ Must type commands
❌ Must configure PATH manually
❌ Must set up each channel
❌ Must create dashboard
❌ Takes 30-60 minutes

**Recommendation**: Use the automated script unless you have specific customization needs.

---

## Security Notes

### What Gets Stored

- **Gateway Token**: `~/.openclaw/.gateway-token` (chmod 600)
- **Configuration**: `~/.openclaw/openclaw.json`
- **Logs**: `~/.openclaw/logs/`
- **Sessions**: `~/.openclaw/agents/main/sessions/`

### Keeping It Secure

1. **Don't share your token** - Anyone with it can access your Gateway
2. **Use Full Disk Access carefully** - Only grant to trusted processes
3. **Monitor logs** - Check for suspicious activity
4. **Keep OpenClaw updated** - Run `pnpm add -g openclaw@latest`

---

## Uninstalling

To completely remove OpenClaw:

```bash
# Stop Gateway
openclaw gateway stop

# Uninstall service
openclaw gateway uninstall

# Remove OpenClaw
pnpm remove -g openclaw

# Remove configuration (optional)
rm -rf ~/.openclaw
```

---

## Getting Help

### Documentation
- **OpenClaw Docs**: https://docs.openclaw.ai
- **iMessage Setup**: [IMESSAGE-BOT-GUIDE.md](IMESSAGE-BOT-GUIDE.md)
- **Troubleshooting**: [DEPLOYMENT-LESSONS-LEARNED.md](DEPLOYMENT-LESSONS-LEARNED.md)

### Commands
```bash
# System health check
openclaw doctor

# Gateway status
openclaw gateway status

# Channel status
openclaw channels status

# View logs
tail -f ~/.openclaw/logs/gateway.log
```

---

## Success! What Now?

Your bot is ready! Here's what you can do:

1. **Test it** - Send an iMessage and get a response
2. **Customize it** - Edit `~/.openclaw/openclaw.json`
3. **Add channels** - Set up Telegram, Slack, etc.
4. **Monitor it** - Watch logs and dashboard
5. **Share it** - Let others message your bot

**Enjoy your AI bot!** 🤖

---

**Version**: 1.0
**Last Updated**: 2026-02-02
**Part of**: Clawdbot Ready - OpenClaw Gateway Deployment
