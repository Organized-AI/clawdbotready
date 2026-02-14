# Enable Tailscale SSH - One-Time Setup for Client

**For**: Client's Mac Mini (100.66.145.48)
**Purpose**: Allow you to remotely manage the Mac Mini via Tailscale (no SSH keys needed)
**Time**: 2 minutes

---

## Why This is Better Than Regular SSH

- ✅ **No password needed** - Tailscale handles authentication
- ✅ **No SSH keys to manage** - Tailscale uses the existing Tailscale connection
- ✅ **More secure** - Uses Tailscale's encrypted network
- ✅ **You can help remotely** - Run scripts and updates without asking client to do anything

---

## Simple Instructions for Client

Send this to your client (via Telegram or other method):

---

### 📝 Quick Setup (2 minutes)

**Step 1: Open Tailscale Preferences**
1. Click the **Tailscale icon** in your menu bar (top-right)
2. Click **Preferences...**

**Step 2: Enable Tailscale SSH**
1. In the Preferences window, find the **SSH** section
2. Check the box: **"Allow SSH connections to this device"**
3. That's it! You can close the window.

**Visual Guide**:
```
Tailscale Menu Bar → Preferences → SSH → ✓ Allow SSH connections
```

---

## After Client Enables This

Once the client enables Tailscale SSH, you can:

### Connect and Run the Setup Script
```bash
# From your machine
tailscale ssh openclaw@openclaws-mac-mini 'bash -s' < ./scripts/setup-google-ads-on-macmini.sh
```

### Run Any Command Remotely
```bash
# Check Google Ads CLI status
tailscale ssh openclaw@openclaws-mac-mini 'google-ads-cli --version'

# Check if OpenClaw is running
tailscale ssh openclaw@openclaws-mac-mini 'ps aux | grep openclaw-gateway'

# View logs
tailscale ssh openclaw@openclaws-mac-mini 'tail -20 ~/.openclaw/logs/gateway.log'
```

### Run Monitoring
```bash
# Check health remotely
tailscale ssh openclaw@openclaws-mac-mini 'google-ads-cli campaigns --limit 1'
```

---

## Alternative: Client Runs One Command

If the client prefers to just run one command instead of changing settings, they can enable it via Terminal:

```bash
sudo tailscale up --ssh
```

This does the same thing but via command line.

---

## For Your Reference

### What Gets Enabled
- **Tailscale SSH server** on the Mac Mini
- **Automatic authentication** via Tailscale network
- **No additional ports opened** (uses Tailscale's encrypted tunnel)

### Security
- Only devices on the same Tailscale network can connect
- You can revoke access anytime by removing the device from Tailscale admin
- All connections are logged in Tailscale admin console

---

## Message Template for Client

Copy and send this to your client:

---

**Subject**: Quick Setup for Remote Support

Hi!

To make it easier for me to help you with updates and maintenance (without bothering you each time), could you enable Tailscale SSH on your Mac Mini?

**It's super simple:**
1. Click the Tailscale icon in your menu bar
2. Click "Preferences"
3. Check "Allow SSH connections to this device"

This lets me:
- ✅ Install updates remotely
- ✅ Fix issues without asking you to run commands
- ✅ Monitor your Google Ads integration
- ✅ Keep everything running smoothly

It's completely secure (uses your existing Tailscale connection) and I can only access it while I'm connected to your Tailscale network.

Takes 30 seconds to enable - let me know once it's done!

---

Thanks!

---

