# Google Ads API Setup - Complete Guide

**Client**: OpenClaw Mac Mini (100.66.145.48)
**Status**: ✅ Credentials Generated | 📤 Setup Script Sent
**Date**: 2026-02-07

---

## ✅ What's Been Completed

### 1. OAuth Credentials Generated
- **Client ID**: `(stored in ~/.google-ads-cli/config.json on Mac Mini)`
- **Client Secret**: `(stored in ~/.google-ads-cli/config.json on Mac Mini)`
- **Refresh Token**: `(stored in ~/.google-ads-cli/config.json on Mac Mini)`
- **Developer Token**: `(stored in ~/.google-ads-cli/config.json on Mac Mini)`
- **Customer ID**: `4761832056`

### 2. Setup Script Sent to Mac Mini
Via Tailscale file transfer: `setup-google-ads-on-macmini.sh`

### 3. Local Configuration Files Created
- `~/.google-ads/google-ads.yaml` (on your local machine)
- `.claude/settings.env` (updated with all credentials)

---

## 📋 Next Steps for Client (On Mac Mini)

### Step 1: Locate the Script
The script was sent via Tailscale and should be in one of these locations:
- `~/Downloads/`
- `~/Taildrop/`
- Check Tailscale menu bar icon → "Files"

### Step 2: Run the Setup Script
```bash
# Navigate to where the file was received
cd ~/Downloads  # or ~/Taildrop

# Make it executable
chmod +x setup-google-ads-on-macmini.sh

# Run it
./setup-google-ads-on-macmini.sh
```

The script will:
1. Create directories (`~/.google-ads-cli/` and `~/.google-ads/`)
2. Install credentials in both JSON and YAML formats
3. Test the Google Ads CLI connection
4. Show success or error messages

### Step 3: Verify It Works
```bash
# Test listing campaigns
google-ads-cli campaigns --limit 1

# Test getting CPA metrics
google-ads-cli cpa

# Check help for all commands
google-ads-cli --help
```

---

## 🔧 Troubleshooting

### "google-ads-cli: command not found"
The CLI may not be in PATH. Try:
```bash
# Find where it's installed
find ~ -name "google-ads-cli" -type f 2>/dev/null

# Or check if it's in the project directory
~/google-ads-cli/dist/index.js
```

### "Unknown error" or "Authentication failed"
Possible causes:
1. **Developer Token not approved**: Check Google Ads API Center
2. **API not enabled**: Enable Google Ads API in Google Cloud Console
3. **Wrong Customer ID**: Verify `4761832056` is correct

### "Quota exceeded" or "Rate limit"
You've hit the Google Ads API daily limit. Wait 24 hours or request quota increase.

---

## 📊 Monitoring & Alerting

### Remote Monitoring (From Your Machine)
Use Tailscale to monitor the Mac Mini without SSH:

```bash
# Check if Google Ads CLI is working
./scripts/monitor-google-ads-cli.sh --local
```

This will:
- ✅ Test Mac Mini connectivity
- ✅ Check if google-ads-cli is installed
- ✅ Test Google Ads API connection
- 🚨 Send alerts if something fails

### Configure Alerts
Edit `scripts/monitor-google-ads-cli.sh` and set:

```bash
# Telegram notifications
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"

# Email notifications
export GOOGLE_ADS_ALERT_EMAIL="your@email.com"
```

### Set Up Automated Monitoring
Run this every 15 minutes:

```bash
# Add to your local crontab
crontab -e

# Add this line:
*/15 * * * * cd "/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready" && ./scripts/monitor-google-ads-cli.sh --local >> /tmp/google-ads-monitor.log 2>&1
```

Or use a LaunchAgent for better macOS integration.

---

## 🧪 Testing via Telegram (OpenClaw)

Once the credentials are installed on the Mac Mini, test via Telegram:

1. **Message the bot**: `@SAMyosin_bot`
2. **Ask for campaign data**: "Show me my Google Ads campaigns"
3. **Ask for CPA metrics**: "What's my current CPA?"

The bot should now be able to:
- ✅ List campaigns
- ✅ Get CPA/performance metrics
- ✅ Generate reports
- ✅ Update budgets (if permissions allow)

---

## 📁 File Locations

### On Mac Mini (100.66.145.48)
```
~/.google-ads-cli/
├── config.json          # CLI configuration (JSON format)

~/.google-ads/
├── google-ads.yaml      # Standard library config (YAML format)

~/google-ads-cli/        # Source code (if exists)
├── dist/
│   └── index.js         # Compiled CLI tool
```

### On Your Local Machine
```
~/.google-ads/
├── google-ads.yaml      # Your local config

.claude/
├── settings.env         # All credentials stored here

scripts/
├── deploy-google-ads-credentials.sh  # SSH deployment (backup method)
├── deploy-via-tailscale.sh          # Tailscale deployment
├── setup-google-ads-on-macmini.sh   # Mac Mini setup script (sent to client)
├── monitor-google-ads-cli.sh        # Health monitoring
└── generate-google-ads-token-web.sh # OAuth token generator
```

---

## 🔐 Security Considerations

### Why Tailscale Over SSH?
- ✅ **End-to-end encrypted** - Zero trust network
- ✅ **No port forwarding** - No exposed attack surface
- ✅ **Automatic key rotation** - Better than static SSH keys
- ✅ **Access logging** - See who accessed what
- ✅ **Easy revocation** - Disable devices instantly

### Credential Security
- ✅ Stored in home directory (not world-readable)
- ✅ File permissions: `600` (owner read/write only)
- ✅ Not committed to git
- ✅ Refresh token can be revoked in Google Cloud Console

---

## 🚀 What This Enables

Your client (via OpenClaw Telegram bot) can now:

1. **Campaign Management**
   - List all campaigns
   - Get campaign performance
   - Pause/resume campaigns

2. **Performance Tracking**
   - Real-time CPA metrics
   - Conversion tracking
   - ROI analysis

3. **Budget Control**
   - View current budgets
   - Update campaign budgets
   - Monitor spend

4. **Reporting**
   - Custom date ranges
   - Performance reports
   - Export data

All via natural language commands to the Telegram bot! 🤖

---

## 📞 Support

If the client has issues:

1. **Check Monitoring**:
   ```bash
   ./scripts/monitor-google-ads-cli.sh --local
   ```

2. **View Logs** (on Mac Mini):
   ```bash
   tail -f ~/.openclaw/logs/gateway.log | grep google-ads
   ```

3. **Test Manually**:
   ```bash
   google-ads-cli campaigns --limit 1
   ```

4. **Check Google Cloud Console**:
   - Developer token approval status
   - API quotas/limits
   - OAuth consent screen

---

**Setup Date**: 2026-02-07
**Next Review**: 2026-03-07 (30 days)
**Credential Expiry**: Refresh tokens don't expire unless revoked
