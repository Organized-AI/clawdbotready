# Google Ads Remote Management Workflow via Tailscale

**Your Complete Remote Management System**

---

## 🎯 The Setup (Client Does This Once)

**Send client this simple message:**

> "Hey! For me to keep your Google Ads integration running smoothly, can you enable remote access? Just:
> 1. Click Tailscale icon → Preferences
> 2. Check 'Allow SSH connections'
>
> Takes 30 seconds, then I can handle all updates/fixes without bothering you!"

**Reference**: See `enable-tailscale-ssh-for-client.md` for full client instructions.

---

## 🚀 Once Enabled - You Can Do Everything Remotely

### 1. Initial Google Ads Setup (Run Once)

```bash
# Navigate to project directory
cd "/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready"

# Run the setup script on Mac Mini remotely
tailscale ssh openclaw@openclaws-mac-mini 'bash -s' < ./scripts/setup-google-ads-on-macmini.sh
```

This will:
- ✅ Create `~/.google-ads-cli/config.json`
- ✅ Create `~/.google-ads/google-ads.yaml`
- ✅ Test the Google Ads CLI
- ✅ Show you success/error messages

### 2. Verify It Works

```bash
# Test Google Ads CLI
tailscale ssh openclaw@openclaws-mac-mini 'google-ads-cli campaigns --limit 1'

# Check OpenClaw Gateway is running
tailscale ssh openclaw@openclaws-mac-mini 'ps aux | grep openclaw-gateway | grep -v grep'

# View recent logs
tailscale ssh openclaw@openclaws-mac-mini 'tail -30 ~/.openclaw/logs/gateway.log'
```

### 3. Test via Telegram

Message `@SAMyosin_bot`:
```
Show me my Google Ads campaigns
```

Should now work! 🎉

---

## 📊 Ongoing Monitoring (Automated)

### Option A: Manual Health Check (Anytime)

```bash
# Quick health check
./scripts/monitor-google-ads-cli.sh --local
```

### Option B: Automated Monitoring (Set and Forget)

Add to your crontab:

```bash
crontab -e

# Add this line (checks every 15 minutes):
*/15 * * * * cd "/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready" && ./scripts/monitor-google-ads-cli.sh --local >> /tmp/google-ads-monitor.log 2>&1
```

### Configure Alerts

Edit `scripts/monitor-google-ads-cli.sh` and add:

```bash
# Telegram alerts (recommended)
export TELEGRAM_BOT_TOKEN="your_telegram_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"

# Email alerts (optional)
export GOOGLE_ADS_ALERT_EMAIL="your@email.com"
```

Now you'll get notified automatically if:
- ❌ Mac Mini goes offline
- ❌ Google Ads CLI stops working
- ❌ API authentication fails
- ❌ Rate limits exceeded

---

## 🔧 Common Remote Management Tasks

### Update Credentials

```bash
# If you regenerate OAuth tokens
tailscale ssh openclaw@openclaws-mac-mini 'bash -s' < ./scripts/setup-google-ads-on-macmini.sh
```

### Check Logs

```bash
# OpenClaw Gateway logs
tailscale ssh openclaw@openclaws-mac-mini 'tail -f ~/.openclaw/logs/gateway.log'

# Error logs
tailscale ssh openclaw@openclaws-mac-mini 'tail -50 ~/.openclaw/logs/gateway.err.log | grep google-ads'
```

### Restart OpenClaw Gateway

```bash
# If something needs a restart
tailscale ssh openclaw@openclaws-mac-mini 'pkill -f openclaw-gateway && sleep 3 && launchctl start com.openclaw.gateway'
```

### View Configuration

```bash
# Check current Google Ads config
tailscale ssh openclaw@openclaws-mac-mini 'cat ~/.google-ads-cli/config.json | jq .'
```

### Test API Connection

```bash
# Quick API test
tailscale ssh openclaw@openclaws-mac-mini 'google-ads-cli campaigns --limit 1 && echo "✅ API Working"'
```

---

## 🎛️ Your Control Panel (Quick Commands)

Save these as aliases in your `~/.zshrc` or `~/.bashrc`:

```bash
# Add to ~/.zshrc
alias mac-mini="tailscale ssh openclaw@openclaws-mac-mini"
alias mac-mini-logs="tailscale ssh openclaw@openclaws-mac-mini 'tail -f ~/.openclaw/logs/gateway.log'"
alias mac-mini-status="tailscale ssh openclaw@openclaws-mac-mini 'ps aux | grep openclaw-gateway | grep -v grep && google-ads-cli campaigns --limit 1'"
alias mac-mini-health="cd '/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready' && ./scripts/monitor-google-ads-cli.sh --local"
```

Then you can just run:
```bash
mac-mini-health      # Check everything
mac-mini-status      # Quick status
mac-mini-logs        # Watch logs
mac-mini             # Connect directly
```

---

## 📱 Client Experience (Zero Effort)

From the client's perspective:
1. ✅ Enabled Tailscale SSH once (30 seconds)
2. ✅ Everything else happens automatically
3. ✅ Receives Telegram notifications: "Your Google Ads API is working!" or "Issue detected and resolved"
4. ✅ Uses `@SAMyosin_bot` to ask questions about campaigns
5. ✅ Never touches Terminal or runs commands

**Perfect white-glove service!**

---

## 🔐 Security Benefits

### Why This is More Secure Than Traditional SSH

1. **No SSH Keys to Manage**
   - No risk of keys being stolen/leaked
   - No need to rotate keys
   - Tailscale handles all authentication

2. **Zero Attack Surface**
   - No SSH port exposed to internet
   - No port forwarding needed
   - Encrypted Tailscale tunnel only

3. **Granular Access Control**
   - Revoke access instantly from Tailscale admin
   - See connection logs
   - Client can disable anytime

4. **Automatic Security**
   - Tailscale handles key rotation
   - Always uses latest encryption
   - MagicDNS prevents DNS hijacking

---

## 📈 Success Metrics

Track these to show value to client:

```bash
# Uptime tracking
tailscale ssh openclaw@openclaws-mac-mini 'uptime'

# API call success rate (from logs)
tailscale ssh openclaw@openclaws-mac-mini 'grep google-ads ~/.openclaw/logs/gateway.log | tail -100 | grep -c "success"'

# Last successful API call
tailscale ssh openclaw@openclaws-mac-mini 'grep "google-ads.*success" ~/.openclaw/logs/gateway.log | tail -1'
```

---

## 🚨 Troubleshooting

### "Permission denied" when using Tailscale SSH

**Cause**: Client hasn't enabled Tailscale SSH yet

**Fix**: Send them the guide (see `enable-tailscale-ssh-for-client.md`)

### "google-ads-cli: command not found"

**Cause**: CLI not in PATH

**Fix**:
```bash
# Find where it is
tailscale ssh openclaw@openclaws-mac-mini 'find ~ -name google-ads-cli -type f 2>/dev/null'

# Check if it needs to be linked
tailscale ssh openclaw@openclaws-mac-mini 'which node && node --version'
```

### "Unknown error" from Google Ads API

**Possible causes**:
1. Developer token not approved → Check Google Ads API Center
2. API not enabled → Enable in Google Cloud Console
3. Credentials expired → Re-run setup script

**Debug**:
```bash
tailscale ssh openclaw@openclaws-mac-mini 'google-ads-cli campaigns --limit 1 2>&1 | head -20'
```

---

## 📋 Complete Workflow Checklist

- [ ] Client enables Tailscale SSH (one-time, 30 seconds)
- [ ] You run setup script remotely via Tailscale
- [ ] Test Google Ads CLI works
- [ ] Test Telegram bot commands work
- [ ] Set up automated monitoring (15-minute cron)
- [ ] Configure Telegram/email alerts
- [ ] Document for client what they can now do via bot
- [ ] Optional: Create dashboard/reporting

**Total setup time after Tailscale SSH enabled**: ~5 minutes

**Client effort**: ~30 seconds (enable Tailscale SSH)

**Result**: Fully managed Google Ads integration via Telegram 🚀

---

## 🎯 Your Value Proposition to Client

> "I've set up a fully automated Google Ads management system for you. You can:
>
> - Ask your bot about campaigns, CPA, budgets (via Telegram)
> - Get automatic alerts if anything breaks
> - I handle all maintenance remotely
> - Zero technical work on your end
>
> All you needed to do was click one checkbox in Tailscale. Everything else is automated!"

---

**Last Updated**: 2026-02-07
**Status**: Ready to deploy once Tailscale SSH is enabled
