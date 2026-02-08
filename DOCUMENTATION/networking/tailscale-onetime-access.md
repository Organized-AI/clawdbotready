# Tailscale One-Time Access for M1 Mac Mini Onboarding

## Overview
This guide explains how to grant temporary Tailscale access to your M1 Mac Mini using a one-time authentication key. Perfect for onboarding team members or providing temporary access without sharing permanent credentials.

## Prerequisites
- Active Tailscale account (tailscale.com)
- M1 Mac Mini with macOS
- Admin access to Tailscale admin console
- Tailscale installed on Mac Mini (or will install during setup)

---

## Step 1: Generate One-Time Auth Key

### Via Tailscale Admin Console (Recommended)
1. Log in to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Navigate to **Settings** → **Keys**
3. Click **Generate auth key**
4. Configure the key:
   - **Description**: "M1 Mac Mini Onboarding - [Date/Person]"
   - **Reusable**: ❌ **Disable** (one-time use only)
   - **Ephemeral**: ✅ **Enable** (device removed when disconnected)
   - **Pre-approved**: ✅ **Enable** (skip manual approval)
   - **Expiration**: Set to 1-7 days (default 90 days)
   - **Tags**: Optional - add `tag:onboarding` or `tag:temporary`

5. Click **Generate key**
6. **Copy the key immediately** - it won't be shown again
   - Format: `tskey-auth-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx`

### Via Tailscale CLI (Alternative)
```bash
# Generate ephemeral, non-reusable key that expires in 1 hour
tailscale up --authkey=$(tailscale auth generate --ephemeral --preapproved --expires=1h)
```

---

## Step 2: Install Tailscale on M1 Mac Mini

### If Not Already Installed
```bash
# Download and install Tailscale
brew install tailscale

# Or download directly from:
# https://tailscale.com/download/mac
```

### Verify Installation
```bash
# Check if Tailscale is installed
which tailscale
# Expected: /opt/homebrew/bin/tailscale (Apple Silicon)

# Check version
tailscale version
```

---

## Step 3: Authenticate with One-Time Key

### Connect Using Auth Key
```bash
# Authenticate with the one-time key
sudo tailscale up --authkey=tskey-auth-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx

# For ephemeral node (recommended for onboarding)
sudo tailscale up --authkey=tskey-auth-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx --accept-routes

# Optional: Set hostname for easy identification
sudo tailscale up --authkey=tskey-auth-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx --hostname=macmini-onboarding
```

### Verify Connection
```bash
# Check Tailscale status
tailscale status

# Get Tailscale IP address
tailscale ip -4

# Test connectivity
tailscale ping <another-tailscale-device>
```

---

## Step 4: Grant Necessary Access

### Option A: SSH Access (Recommended)
```bash
# On Mac Mini: Enable SSH if not already enabled
sudo systemsetup -setremotelogin on

# Verify SSH is running
sudo systemsetup -getremotelogin
# Expected: Remote Login: On

# Get Tailscale IP
tailscale ip -4
# Example output: 100.x.y.z
```

**Share with onboarding person:**
```bash
# They can now SSH via Tailscale
ssh username@100.x.y.z

# Or using hostname if set
ssh username@macmini-onboarding
```

### Option B: Screen Sharing (GUI Access)
```bash
# Enable Screen Sharing
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -access -on -restart -agent -privs -all

# Or via System Preferences:
# System Settings → General → Sharing → Screen Sharing → On
```

**Access via:**
- VNC client: `vnc://100.x.y.z:5900`
- macOS Screen Sharing: `screen-share://100.x.y.z`

---

## Step 5: Security Best Practices

### ACL Rules (Access Control Lists)
Add to your Tailscale ACL policy for fine-grained control:

```json
{
  "tagOwners": {
    "tag:onboarding": ["your-email@example.com"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:onboarding"],
      "dst": ["macmini-onboarding:22"],
      "proto": "tcp"
    }
  ]
}
```

### Monitoring
```bash
# On Mac Mini: Monitor active connections
sudo lsof -i -P | grep ESTABLISHED

# Check Tailscale logs
sudo log show --predicate 'process == "tailscaled"' --last 1h

# View SSH login attempts
sudo log show --predicate 'process == "sshd"' --last 1h
```

### Temporary User Account (Recommended)
```bash
# Create temporary user for onboarding
sudo sysadminctl -addUser onboarding-temp -fullName "Temporary Onboarding" -password -admin

# After onboarding is complete, delete the account
sudo sysadminctl -deleteUser onboarding-temp
```

---

## Step 6: Revoking Access

### Automatic Revocation (Ephemeral Keys)
If you enabled "Ephemeral" when generating the key:
- Device is automatically removed when it disconnects
- Simply restart Tailscale on Mac Mini:
  ```bash
  sudo tailscale down
  ```

### Manual Revocation
1. Go to [Tailscale Admin Console → Machines](https://login.tailscale.com/admin/machines)
2. Find the Mac Mini device
3. Click **⋯** → **Delete machine**
4. Confirm deletion

### Via CLI
```bash
# On Mac Mini: Disconnect from Tailscale
sudo tailscale down

# On your admin machine: Remove device
tailscale logout --self-hosted <device-id>
```

---

## Complete Onboarding Workflow

### Before Sharing Access
```bash
# 1. Generate ephemeral auth key (see Step 1)
# 2. Create temporary user account
sudo sysadminctl -addUser onboarding-temp -fullName "Temporary Onboarding" -password

# 3. Enable SSH
sudo systemsetup -setremotelogin on

# 4. Connect with auth key
sudo tailscale up --authkey=tskey-auth-xxxxx --hostname=macmini-onboarding --ephemeral

# 5. Get Tailscale IP
tailscale ip -4
```

### Share With Onboarding Person
Send them:
```
Tailscale IP: 100.x.y.z
Username: onboarding-temp
Password: [provide securely]
SSH Command: ssh onboarding-temp@100.x.y.z

This access will expire in 24 hours.
```

### After Onboarding Complete
```bash
# 1. Remove temporary user
sudo sysadminctl -deleteUser onboarding-temp

# 2. Disconnect Tailscale (if ephemeral, device auto-removes)
sudo tailscale down

# 3. Disable SSH if not normally needed
sudo systemsetup -setremotelogin off

# 4. Verify device removed in admin console
```

---

## Troubleshooting

### Auth Key Not Working
```bash
# Check key expiration
# Keys expire after configured time (default 90 days)

# Verify key format
# Should be: tskey-auth-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx

# Check Tailscale is running
sudo tailscale status

# Try with verbose logging
sudo tailscale up --authkey=tskey-xxx --verbose
```

### Cannot Connect to Mac Mini
```bash
# Verify Tailscale is connected
tailscale status
# Should show "100.x.y.z" and "active"

# Test network connectivity
tailscale ping macmini-onboarding

# Check firewall settings
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Verify SSH is enabled
sudo systemsetup -getremotelogin
```

### Device Shows Offline
```bash
# Restart Tailscale
sudo tailscale down
sudo tailscale up --authkey=tskey-xxx

# Check system logs
sudo log show --predicate 'process == "tailscaled"' --last 5m --style syslog
```

---

## Security Considerations

### ✅ Best Practices
- Use **ephemeral** keys for temporary access
- Set short **expiration times** (1-7 days)
- Disable **reusable** option (one-time use only)
- Create **temporary user accounts** (not admin)
- Enable **ACL rules** to limit access scope
- **Monitor** active connections during onboarding
- **Revoke immediately** after onboarding complete

### ⚠️ Avoid
- Never commit auth keys to git
- Don't share keys via insecure channels (Slack/email)
- Don't reuse keys for multiple devices
- Don't grant admin access unless required
- Don't leave devices connected indefinitely

### 🔒 Key Storage
If you need to save the key temporarily:
```bash
# Store securely in macOS Keychain
security add-generic-password \
  -a "$USER" \
  -s "tailscale-onboarding-key" \
  -w "tskey-auth-xxxxx"

# Retrieve later
security find-generic-password \
  -a "$USER" \
  -s "tailscale-onboarding-key" \
  -w

# Delete after use
security delete-generic-password \
  -a "$USER" \
  -s "tailscale-onboarding-key"
```

---

## Integration with OpenClaw Deployment

If this Mac Mini is for OpenClaw Gateway deployment:

### 1. Connect Before Running Setup
```bash
# Connect to Tailscale first
sudo tailscale up --authkey=tskey-xxx --hostname=openclaw-gateway

# Verify connection
tailscale ip -4

# Then proceed with openclaw-vm-setup
cd openclaw-vm-setup
./setup.sh all
```

### 2. Update openclaw-vm-setup Config
Edit `openclaw-vm-setup/config/settings.env`:
```bash
# Enable Tailscale integration
USE_TAILSCALE=true
TAILSCALE_HOSTNAME="openclaw-gateway"

# Optional: Restrict SSH to Tailscale network only
SSH_ALLOWED_NETWORKS="100.0.0.0/8"  # Tailscale CGNAT range
```

### 3. SSH via Tailscale After Setup
```bash
# Connect to VM through Tailscale
ssh -i ~/.ssh/openclaw_vm_ed25519 admin@$(tailscale ip -4)

# Or add to ~/.ssh/config
cat >> ~/.ssh/config <<EOF
Host openclaw-gateway
    HostName $(tailscale ip -4)
    User admin
    IdentityFile ~/.ssh/openclaw_vm_ed25519
    StrictHostKeyChecking yes
EOF

# Then simply:
ssh openclaw-gateway
```

---

## Quick Reference

### Generate Ephemeral Key
```bash
# Via admin console: login.tailscale.com/admin/settings/keys
# Settings: Ephemeral ✅, Reusable ❌, Pre-approved ✅, Expires: 24h
```

### Connect Mac Mini
```bash
sudo tailscale up --authkey=tskey-auth-xxxxx --hostname=macmini-onboarding --ephemeral
tailscale ip -4  # Get IP to share
```

### Revoke Access
```bash
sudo tailscale down  # Auto-removes ephemeral device
```

### Monitor
```bash
tailscale status
sudo log show --predicate 'process == "tailscaled"' --last 1h
```

---

## Additional Resources

- [Tailscale Auth Keys Documentation](https://tailscale.com/kb/1085/auth-keys/)
- [Tailscale ACL Documentation](https://tailscale.com/kb/1018/acls/)
- [Tailscale macOS Installation](https://tailscale.com/download/mac)
- [Tailscale SSH Documentation](https://tailscale.com/kb/1193/tailscale-ssh/)

---

*Created: 2026-02-02*
*Target: M1 Mac Mini onboarding via Tailscale*
*Security Level: Ephemeral, time-limited access*
