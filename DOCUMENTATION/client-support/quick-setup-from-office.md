# Quick Setup - When You're at the Office (SSH Access)

**When you have SSH access to the Mac Mini, run these commands:**

---

## One-Line Setup

```bash
# From your office machine with SSH access
ssh openclaw@100.66.145.48 'bash -s' < "/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready/scripts/setup-google-ads-on-macmini.sh"
```

Or if you prefer to copy the script first:

```bash
# Copy script to Mac Mini
scp "/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready/scripts/setup-google-ads-on-macmini.sh" openclaw@100.66.145.48:~/

# SSH in and run it
ssh openclaw@100.66.145.48
chmod +x ~/setup-google-ads-on-macmini.sh
./setup-google-ads-on-macmini.sh
```

---

## Verify It Works

```bash
# Test Google Ads CLI
ssh openclaw@100.66.145.48 'google-ads-cli campaigns --limit 1'

# Test via Telegram
# Message @SAMyosin_bot: "Show me my Google Ads campaigns"
```

---

## Set Up Monitoring (From Your Machine)

Once the credentials are working, enable monitoring:

```bash
crontab -e

# Add this line:
*/15 * * * * cd "/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready" && ./scripts/monitor-google-ads-cli.sh --local >> /tmp/google-ads-monitor.log 2>&1
```

---

## Done! ✅

After this:
- ✅ Google Ads credentials installed on Mac Mini
- ✅ Client can ask bot about campaigns via Telegram
- ✅ Automated monitoring alerts you if anything breaks
- ✅ Zero client involvement needed

---

## Optional: Enable Tailscale SSH for Future

Later, you can ask client to enable Tailscale SSH so you don't need to go to the office for updates.

See: `DOCUMENTATION/client-message-enable-tailscale-ssh.md`
