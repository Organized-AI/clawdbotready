# Tailscale Device Management for Business Support

## Overview

This guide covers managing customer Mac Minis via Tailscale for remote support and troubleshooting. It's designed for service providers who need to maintain OpenClaw Gateway installations on customer hardware.

**Use Case:** Your business provides managed AI messaging services. Customers have Mac Minis with OpenClaw Gateway installed. You need to remotely manage, update, and troubleshoot these devices via Tailscale.

---

## Table of Contents

1. [Tailscale Admin Setup](#tailscale-admin-setup)
2. [Adding Customer Devices](#adding-customer-devices)
3. [Device Inventory Management](#device-inventory-management)
4. [Remote Access Patterns](#remote-access-patterns)
5. [Managing OpenClaw Agents Remotely](#managing-openclaw-agents-remotely)
6. [Troubleshooting Remote Updates](#troubleshooting-remote-updates)
7. [Access Control & Security](#access-control--security)
8. [Best Practices](#best-practices)

---

## Tailscale Admin Setup

### Prerequisites

1. **Tailscale Account** (Free or Paid)
   - Free tier: 100 devices, 3 users (sufficient for small operations)
   - Personal Pro: Unlimited devices, better ACLs
   - Team tier: Multi-user management, SSO

2. **Admin Console Access**
   - Visit: https://login.tailscale.com/admin/machines
   - Your account must have admin privileges

### Initial Configuration

```bash
# Install Tailscale on your support machine (if not already)
# Download from: https://tailscale.com/download/mac

# Login and authenticate
tailscale up

# Verify connection
tailscale status
```

**Set a descriptive hostname for your support machine:**
```bash
# Via CLI
tailscale set --hostname "jordan-support-mac"

# Or via admin console
# Machines → Your machine → Settings → Hostname
```

---

## Adding Customer Devices

### Method 1: Customer Self-Enrollment (Recommended)

**Steps for Customer:**

1. **Install Tailscale on Mac Mini**
   ```bash
   # Download standalone installer (not App Store version)
   # Visit: https://tailscale.com/download/mac
   ```

2. **Authenticate with YOUR Tailnet**
   ```bash
   tailscale up
   # This opens browser for authentication
   # Customer logs in with credentials you provide
   ```

3. **Set Descriptive Hostname**
   ```bash
   # Use customer identifier
   tailscale set --hostname "client-sclayton-macmini"
   ```

**You provide the customer:**
- Tailscale login credentials (unique per customer)
- Installation instructions
- Hostname naming convention

### Method 2: Pre-Configured Deployment

**For technical setup before delivery:**

1. **Configure Tailscale on Mac Mini before delivery**
2. **Use Auth Keys for unattended setup**

```bash
# Generate auth key in admin console
# Machines → Settings → Keys → Generate auth key

# Options:
# - Reusable: Yes (if deploying multiple devices)
# - Ephemeral: No (device stays after disconnect)
# - Preauthorized: Yes (skip manual approval)
# - Expiry: 90 days

# Use key for automated setup
tailscale up --authkey="tskey-auth-xxxxx" --hostname="client-name-macmini"
```

### Naming Convention

Use consistent hostnames for easy identification:

```
Format: client-<username>-<device>
Examples:
- client-sclayton-macmini
- client-johndoe-m1mac
- client-acme-server01
```

---

## Device Inventory Management

### View All Devices

**Via Web Console:**
- https://login.tailscale.com/admin/machines
- Shows: hostname, IP, last seen, owner, OS

**Via CLI:**
```bash
# List all devices on your tailnet
tailscale status

# Example output:
# 100.66.145.48   client-sclayton-macmini  sclayton@  macOS   -
# 100.66.22.10    jordan-support-mac       jordan@    macOS   active; direct
```

### Device Tracking Spreadsheet

Maintain a spreadsheet with:

| Customer | Tailscale IP | Hostname | Bot Username | Telegram ID | SSH User | Status | Last Check |
|----------|--------------|----------|--------------|-------------|----------|--------|------------|
| @sclayton567 | 100.66.145.48 | client-sclayton-macmini | @SAMyosin_bot | 337198 | openclaw | Active | 2026-02-05 |

**Template fields:**
- Customer: Telegram handle or name
- Tailscale IP: Fixed IP assigned by Tailscale
- Hostname: Tailscale device name
- Bot Username: Telegram bot handle
- Telegram ID: User's Telegram ID for allowlist
- SSH User: Username for SSH access (usually `openclaw`)
- Status: Active / Suspended / Maintenance
- Last Check: Last health check date

### Automating Device Discovery

```bash
#!/bin/bash
# save as: ~/bin/list-customer-devices.sh

echo "=== Customer Mac Mini Inventory ==="
echo ""

tailscale status --json | jq -r '.Peer[] | select(.HostName | startswith("client-")) |
  "\(.HostName) | \(.TailscaleIPs[0]) | \(.OS) | Last seen: \(.LastSeen)"'
```

---

## Remote Access Patterns

### SSH Access (Primary Method)

**Basic Connection:**
```bash
ssh openclaw@<TAILSCALE_IP>
```

**Quick Commands:**
```bash
# Check if Gateway is running
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"

# View recent logs
ssh openclaw@100.66.145.48 "tail -30 ~/.openclaw/logs/gateway.log"

# Check system uptime
ssh openclaw@100.66.145.48 "uptime"

# Check disk space
ssh openclaw@100.66.145.48 "df -h /"
```

### SSH Config for Easy Access

Edit `~/.ssh/config`:

```
Host client-sclayton
    HostName 100.66.145.48
    User openclaw
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host client-*
    User openclaw
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**Now you can connect with:**
```bash
ssh client-sclayton
```

### Dashboard Access (SSH Tunnel)

**Create tunnel:**
```bash
# Use unique port per customer to avoid conflicts
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48  # Client 1
ssh -f -N -L 18791:127.0.0.1:18789 openclaw@100.66.145.49  # Client 2
```

**Access dashboard:**
```
http://localhost:18790/?token=<GATEWAY_TOKEN>
```

**Port mapping:**
- 18790 → Client 1
- 18791 → Client 2
- 18792 → Client 3
- (etc.)

### File Transfer

**Upload file to customer Mac Mini:**
```bash
scp script.sh openclaw@100.66.145.48:~/
```

**Download logs from customer:**
```bash
scp openclaw@100.66.145.48:~/.openclaw/logs/gateway.log ./client-sclayton-gateway.log
```

**Use Tailscale Taildrop (alternative):**
```bash
tailscale file cp script.sh client-sclayton-macmini:
```

---

## Managing OpenClaw Agents Remotely

### Common Issue: Adding Agent Capabilities

**Problem:** You try to add capabilities (like web browsing, calendar access) but they don't persist or fail to initialize.

### Step 1: Check Current Configuration

```bash
# View current agent config
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq '.agents.defaults'"
```

### Step 2: Backup Configuration

```bash
# Always backup before changes
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-\$(date +%Y%m%d-%H%M%S)"
```

### Step 3: Update Configuration

**Method A: Edit Directly via SSH**

```bash
# Open in editor
ssh openclaw@100.66.145.48 "vim ~/.openclaw/openclaw.json"

# Or use nano
ssh openclaw@100.66.145.48 "nano ~/.openclaw/openclaw.json"
```

**Method B: Use jq for Programmatic Updates**

```bash
# Add web browsing capability
ssh openclaw@100.66.145.48 "jq '.agents.defaults.capabilities += [\"browser-control\"]' ~/.openclaw/openclaw.json > /tmp/updated.json && mv /tmp/updated.json ~/.openclaw/openclaw.json"

# Add calendar access
ssh openclaw@100.66.145.48 "jq '.agents.defaults.capabilities += [\"calendar-read\", \"calendar-write\"]' ~/.openclaw/openclaw.json > /tmp/updated.json && mv /tmp/updated.json ~/.openclaw/openclaw.json"
```

**Method C: Upload New Config**

```bash
# Edit locally, then upload
scp openclaw.json openclaw@100.66.145.48:~/.openclaw/openclaw.json
```

### Step 4: Reload or Restart Gateway

**Reload (preserves running sessions):**
```bash
ssh openclaw@100.66.145.48 "pkill -SIGUSR1 openclaw-gateway"
```

**Restart (clean slate):**
```bash
ssh openclaw@100.66.145.48 "pkill -f openclaw-gateway && sleep 3 && /opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@*/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"
```

### Step 5: Verify Changes

```bash
# Check if Gateway restarted
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"

# Check logs for capability loading
ssh openclaw@100.66.145.48 "tail -30 ~/.openclaw/logs/gateway.log | grep -i capabilit"

# Verify config was applied
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq '.agents.defaults.capabilities'"
```

### Common Agent Configuration Changes

**Adding Browser Control:**
```json
{
  "agents": {
    "defaults": {
      "capabilities": [
        "browser-control"
      ],
      "tools": [
        {
          "name": "browser",
          "config": {
            "headless": false
          }
        }
      ]
    }
  }
}
```

**Adding File System Access:**
```json
{
  "agents": {
    "defaults": {
      "capabilities": [
        "filesystem-read",
        "filesystem-write"
      ],
      "tools": [
        {
          "name": "filesystem",
          "config": {
            "allowedPaths": ["/Users/openclaw/Documents"]
          }
        }
      ]
    }
  }
}
```

**Changing AI Model:**
```bash
# Switch to different model
ssh openclaw@100.66.145.48 'jq ".agents.defaults.model.primary = \"openrouter/anthropic/claude-3-opus\"" ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json'

# Restart Gateway
ssh openclaw@100.66.145.48 "pkill -SIGUSR1 openclaw-gateway"
```

---

## Troubleshooting Remote Updates

### Issue 1: Configuration Changes Don't Persist

**Symptoms:**
- You update config, restart Gateway, but changes revert
- Config looks correct but Gateway doesn't use new settings

**Causes:**
1. **Multiple config files** - Gateway loading from different location
2. **LaunchAgent overriding** - Startup script has hardcoded config
3. **Permissions issue** - Config file owned by wrong user
4. **Syntax error** - Invalid JSON causes fallback to defaults

**Diagnosis:**

```bash
# Find all openclaw config files
ssh openclaw@100.66.145.48 "find ~ -name 'openclaw.json' 2>/dev/null"

# Check which config Gateway is actually using
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway"
# Look for --config flag

# Validate JSON syntax
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq empty"
# No output = valid JSON
# Error = syntax problem

# Check file permissions
ssh openclaw@100.66.145.48 "ls -la ~/.openclaw/openclaw.json"
```

**Solution:**

```bash
# Ensure only one config exists in expected location
ssh openclaw@100.66.145.48 "ls -la ~/.openclaw/openclaw.json"

# Fix permissions if needed
ssh openclaw@100.66.145.48 "chown openclaw:staff ~/.openclaw/openclaw.json"
ssh openclaw@100.66.145.48 "chmod 600 ~/.openclaw/openclaw.json"

# Validate JSON before restart
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq empty && echo 'Valid JSON'"

# Hard restart Gateway
ssh openclaw@100.66.145.48 "pkill -9 -f openclaw-gateway && sleep 3 && /opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@*/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"
```

### Issue 2: New Capabilities Not Available

**Symptoms:**
- Added capability to config
- Gateway restarted successfully
- But agent doesn't have access to new capability

**Causes:**
1. **Capability not installed** - OpenClaw installation missing required plugins
2. **Tool not configured** - Capability exists but tool config missing
3. **Permissions issue** - macOS blocking access (browser, calendar, etc.)

**Diagnosis:**

```bash
# Check Gateway startup logs for capability errors
ssh openclaw@100.66.145.48 "grep -i 'capabilit\|tool\|plugin' ~/.openclaw/logs/gateway.log | tail -20"

# Check for permission errors
ssh openclaw@100.66.145.48 "grep -i 'permission\|denied\|access' ~/.openclaw/logs/gateway.err.log | tail -20"

# Verify OpenClaw installation includes capability
ssh openclaw@100.66.145.48 "openclaw --version && openclaw capabilities list 2>/dev/null || echo 'Command not available'"
```

**Solution:**

```bash
# Update OpenClaw to latest version (may include new capabilities)
ssh openclaw@100.66.145.48 "openclaw update"

# Check if system permissions are needed (macOS prompts)
# Have customer grant permissions via System Settings → Privacy & Security

# Verify capability is now available
ssh openclaw@100.66.145.48 "tail -30 ~/.openclaw/logs/gateway.log | grep 'capability loaded'"
```

### Issue 3: Gateway Won't Start After Config Change

**Symptoms:**
- Updated config
- Gateway process terminates immediately
- No Gateway process running

**Causes:**
1. **Invalid JSON** - Syntax error in config
2. **Invalid config values** - Wrong type, missing required fields
3. **Port conflict** - Port 18789 already in use

**Diagnosis:**

```bash
# Test Gateway startup manually (see error output)
ssh openclaw@100.66.145.48 "openclaw gateway start --port 18789"

# Check for port conflicts
ssh openclaw@100.66.145.48 "lsof -i :18789"

# Validate config JSON
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq empty"
```

**Solution:**

```bash
# Restore from backup
ssh openclaw@100.66.145.48 "ls -la ~/.openclaw/openclaw.json.backup*"
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json.backup-20260205-143000 ~/.openclaw/openclaw.json"

# Kill any process on port 18789
ssh openclaw@100.66.145.48 "lsof -ti :18789 | xargs kill -9"

# Start Gateway
ssh openclaw@100.66.145.48 "openclaw gateway start --port 18789"
```

### Issue 4: Changes Work Locally But Not Remotely

**Symptoms:**
- Changes work when testing on your support Mac
- Same changes don't work on customer Mac Mini

**Causes:**
1. **OpenClaw version mismatch** - Customer has older version
2. **macOS version difference** - Different OS capabilities
3. **Permission differences** - macOS security settings vary

**Solution:**

```bash
# Check versions
echo "Support Mac:"
openclaw --version

echo "Customer Mac:"
ssh openclaw@100.66.145.48 "openclaw --version"

# Update customer's OpenClaw if needed
ssh openclaw@100.66.145.48 "openclaw update"

# Check macOS version
ssh openclaw@100.66.145.48 "sw_vers"
```

---

## Access Control & Security

### Tailscale ACLs (Access Control Lists)

Control which devices can access customer Mac Minis.

**Edit ACLs in Admin Console:**
- https://login.tailscale.com/admin/acls

**Example ACL for Support Access:**

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:support"],
      "dst": ["tag:customer:*"]
    },
    {
      "action": "accept",
      "src": ["tag:customer"],
      "dst": ["tag:customer"]
    }
  ],
  "tagOwners": {
    "tag:support": ["jordan@yourdomain.com"],
    "tag:customer": ["jordan@yourdomain.com"]
  }
}
```

**Assign tags to devices:**
```bash
# Via admin console: Machines → Device → Edit tags
# Add: "tag:customer" to customer Mac Minis
# Add: "tag:support" to your support machines
```

### SSH Key Management

**Use unique SSH keys per customer (recommended):**

```bash
# Generate key pair for customer
ssh-keygen -t ed25519 -f ~/.ssh/client-sclayton -C "support-sclayton"

# Copy public key to customer Mac Mini
ssh-copy-id -i ~/.ssh/client-sclayton.pub openclaw@100.66.145.48

# Update SSH config
cat >> ~/.ssh/config <<EOF
Host client-sclayton
    HostName 100.66.145.48
    User openclaw
    IdentityFile ~/.ssh/client-sclayton
EOF
```

**Key rotation schedule:**
- Rotate keys every 90 days
- Rotate immediately if key may be compromised
- Keep old keys for 30 days during transition

### Audit Logging

**Track support access:**

```bash
# On customer Mac Mini, enable SSH logging
# /etc/ssh/sshd_config
LogLevel VERBOSE

# View SSH access logs
ssh openclaw@100.66.145.48 "sudo log show --predicate 'process == \"sshd\"' --last 1h"

# Gateway access logs
ssh openclaw@100.66.145.48 "grep 'connection' ~/.openclaw/logs/gateway.log | tail -20"
```

**Support session logging:**

```bash
#!/bin/bash
# save as: ~/bin/support-session.sh
# Logs all support activities

SESSION_LOG="$HOME/support-logs/session-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$HOME/support-logs"

echo "=== Support Session Started ===" | tee -a "$SESSION_LOG"
echo "Customer: $1" | tee -a "$SESSION_LOG"
echo "Technician: $(whoami)" | tee -a "$SESSION_LOG"
echo "Timestamp: $(date)" | tee -a "$SESSION_LOG"
echo "" | tee -a "$SESSION_LOG"

# Start recording commands
exec > >(tee -a "$SESSION_LOG") 2>&1

# Your support work happens here
ssh openclaw@$2
```

---

## Best Practices

### 1. Pre-Deployment Checklist

Before delivering Mac Mini to customer:

- [ ] Tailscale installed and authenticated
- [ ] Descriptive hostname set (`client-<name>-macmini`)
- [ ] SSH daemon enabled (System Settings → Sharing → Remote Login)
- [ ] SSH key authentication configured
- [ ] OpenClaw Gateway installed and tested
- [ ] Gateway token documented
- [ ] Sleep settings disabled (`pmset -a sleep 0`)
- [ ] Auto-start configured (LaunchAgent)
- [ ] Health monitor installed
- [ ] Customer added to your device inventory spreadsheet

### 2. Regular Maintenance Schedule

**Weekly:**
- Check device online status via `tailscale status`
- Review Gateway logs for errors
- Verify bot is responding

**Monthly:**
- Update OpenClaw to latest version
- Review and rotate SSH keys (if policy requires)
- Check disk space and system resources
- Review Gateway configuration for optimization

**Quarterly:**
- Full system backup
- Security audit (ACLs, permissions, keys)
- Customer satisfaction check-in

### 3. Configuration Management

**Version control for configs:**

```bash
# Keep master configs in git
~/customer-configs/
├── client-sclayton/
│   ├── openclaw.json
│   ├── ssh-config
│   └── notes.md
├── client-johndoe/
│   ├── openclaw.json
│   ├── ssh-config
│   └── notes.md
```

**Deploy config to customer:**
```bash
scp ~/customer-configs/client-sclayton/openclaw.json openclaw@100.66.145.48:~/.openclaw/openclaw.json
```

### 4. Emergency Procedures

**If customer reports issue:**

1. **Verify connectivity**
   ```bash
   ping -c 3 <TAILSCALE_IP>
   ```

2. **Check Gateway status**
   ```bash
   ssh openclaw@<IP> "ps aux | grep openclaw-gateway | grep -v grep"
   ```

3. **Review recent logs**
   ```bash
   ssh openclaw@<IP> "tail -50 ~/.openclaw/logs/gateway.log"
   ssh openclaw@<IP> "tail -20 ~/.openclaw/logs/gateway.err.log"
   ```

4. **Restart if needed** (see [Managing OpenClaw Agents Remotely](#managing-openclaw-agents-remotely))

5. **Document in support log**

### 5. Communication with Customers

**Set expectations:**
- Explain that Tailscale must stay running
- Mac Mini must not sleep
- You have remote access for support
- When and how you'll access their device
- What logs/data you can see

**Transparency:**
- Notify customer before remote sessions (if possible)
- Keep support session logs
- Document all changes made
- Provide summary after support intervention

---

## Quick Reference: Common Operations

### Device Health Check

```bash
#!/bin/bash
# Quick health check for customer device

CUSTOMER_IP="$1"

echo "=== Device Health Check: $CUSTOMER_IP ==="
echo ""

echo "1. Network connectivity:"
ping -c 3 "$CUSTOMER_IP" | tail -2

echo ""
echo "2. SSH connectivity:"
ssh "openclaw@$CUSTOMER_IP" "echo 'SSH: OK'" 2>&1

echo ""
echo "3. Gateway status:"
ssh "openclaw@$CUSTOMER_IP" "ps aux | grep openclaw-gateway | grep -v grep || echo 'NOT RUNNING'"

echo ""
echo "4. Disk space:"
ssh "openclaw@$CUSTOMER_IP" "df -h / | tail -1"

echo ""
echo "5. System uptime:"
ssh "openclaw@$CUSTOMER_IP" "uptime"

echo ""
echo "6. Recent errors:"
ssh "openclaw@$CUSTOMER_IP" "tail -10 ~/.openclaw/logs/gateway.err.log 2>/dev/null || echo 'No errors'"
```

### Update Gateway Configuration

```bash
#!/bin/bash
# Update specific config value remotely

CUSTOMER_IP="$1"
CONFIG_PATH="$2"  # e.g., ".agents.defaults.model.primary"
NEW_VALUE="$3"    # e.g., "openrouter/anthropic/claude-3-opus"

# Backup
ssh "openclaw@$CUSTOMER_IP" "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup"

# Update
ssh "openclaw@$CUSTOMER_IP" "jq '$CONFIG_PATH = \"$NEW_VALUE\"' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json"

# Reload
ssh "openclaw@$CUSTOMER_IP" "pkill -SIGUSR1 openclaw-gateway"

echo "Updated: $CONFIG_PATH = $NEW_VALUE"
```

### Batch Update All Customers

```bash
#!/bin/bash
# Update all customer devices with same change

# Customer device IPs
CUSTOMERS=(
  "100.66.145.48"
  "100.66.145.49"
  "100.66.145.50"
)

for IP in "${CUSTOMERS[@]}"; do
  echo "Updating: $IP"

  # Run your update command
  ssh "openclaw@$IP" "openclaw update"

  echo "✓ Complete"
  echo ""
done
```

---

## Troubleshooting Flowchart

```
Customer reports issue
    ↓
Can you ping Mac Mini via Tailscale?
├─ NO → Check customer's Tailscale status
│       → Ask to run: tailscale status
│       → Verify Mac Mini isn't asleep
│       → Check Tailscale admin console for device status
└─ YES → Continue
    ↓
Can you SSH into Mac Mini?
├─ NO → Check SSH service running
│       → ssh-copy-id may be needed
│       → Check firewall settings
└─ YES → Continue
    ↓
Is Gateway process running?
├─ NO → Check why (logs, port conflict, config error)
│       → Start Gateway
│       → Verify auto-start (LaunchAgent)
└─ YES → Continue
    ↓
Are there errors in logs?
├─ YES → Review gateway.err.log
│        → Fix specific error
│        → Restart if needed
└─ NO → Continue
    ↓
Test bot functionality
├─ Send test message to Telegram bot
├─ Check logs for message receipt
└─ Verify response sent
```

---

## Related Documentation

- [SSH vs Tailscale Explained](./ssh-vs-tailscale-explained.md) - Understanding the relationship
- [Dashboard Troubleshooting](./dashboard-troubleshooting.md) - Remote dashboard access
- [Remote Support Guide](./REMOTE-SUPPORT-GUIDE.md) - Specific customer support procedures
- [Tailscale Explained](./tailscale-explained.md) - Deep dive into Tailscale functionality

---

*Last Updated: 2026-02-05*
*Applies to: OpenClaw 2026.2.1+, Tailscale 1.x+, macOS Sequoia*
