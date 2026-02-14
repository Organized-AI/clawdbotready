# Remote Agent Capability Troubleshooting

## Problem Statement

**Issue:** You're trying to add capabilities to OpenClaw agents on remote customer Mac Minis, but changes either:
- Don't persist after restart
- Appear in config but don't actually work
- Cause Gateway to fail on startup
- Work locally but not on customer devices

This guide provides systematic troubleshooting for managing agent capabilities remotely via Tailscale.

---

## Quick Diagnostic

Before deep troubleshooting, run this quick diagnostic:

```bash
#!/bin/bash
# Quick capability diagnostic
# Usage: ./diagnostic.sh <tailscale-ip>

CUSTOMER_IP="$1"

echo "=== OpenClaw Capability Diagnostic ==="
echo "Customer: $CUSTOMER_IP"
echo ""

echo "1. Gateway running?"
ssh "openclaw@$CUSTOMER_IP" "ps aux | grep openclaw-gateway | grep -v grep"

echo ""
echo "2. OpenClaw version:"
ssh "openclaw@$CUSTOMER_IP" "openclaw --version"

echo ""
echo "3. Current capabilities:"
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq '.agents.defaults.capabilities // []'"

echo ""
echo "4. Config file validity:"
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty && echo 'Valid JSON' || echo 'Invalid JSON'"

echo ""
echo "5. Recent errors:"
ssh "openclaw@$CUSTOMER_IP" "grep -i 'capabilit\|error' ~/.openclaw/logs/gateway.err.log | tail -10"
```

---

## Common Scenarios & Solutions

### Scenario 1: Capability Doesn't Persist After Restart

**Symptoms:**
```bash
# You add capability
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities += [\"browser-control\"]" ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json'

# Verify it's there
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities" ~/.openclaw/openclaw.json'
# Output: ["browser-control"]  ✓

# Restart Gateway
ssh openclaw@100.66.145.48 "pkill -f openclaw-gateway && sleep 3 && /opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@*/node_modules/openclaw/dist/index.js gateway --port 18789"

# Check again after restart
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities" ~/.openclaw/openclaw.json'
# Output: []  ✗ (capability disappeared!)
```

**Root Causes:**

#### 1A. LaunchAgent Overwrites Config on Start

**Diagnosis:**
```bash
# Check if LaunchAgent exists
ssh openclaw@100.66.145.48 "cat ~/Library/LaunchAgents/com.openclaw.gateway.plist"

# Look for environment variables or startup scripts that might reset config
ssh openclaw@100.66.145.48 "grep -i 'openclaw\|config' ~/Library/LaunchAgents/com.openclaw.gateway.plist"
```

**Solution:**

If LaunchAgent has config initialization logic, you need to:

1. **Disable LaunchAgent temporarily**
   ```bash
   ssh openclaw@100.66.145.48 "launchctl unload ~/Library/LaunchAgents/com.openclaw.gateway.plist"
   ```

2. **Update config**
   ```bash
   ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities += [\"browser-control\"]" ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json'
   ```

3. **Start Gateway manually** (bypassing LaunchAgent)
   ```bash
   ssh openclaw@100.66.145.48 "/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@*/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"
   ```

4. **Test if capability works**

5. **If working, update LaunchAgent or remove its config initialization**

#### 1B. Multiple Config Files Exist

**Diagnosis:**
```bash
# Find all openclaw config files
ssh openclaw@100.66.145.48 "find / -name 'openclaw.json' 2>/dev/null"

# Check which config Gateway actually loads
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway"
# Look for --config flag
```

**Solution:**

```bash
# Ensure only one config exists
ssh openclaw@100.66.145.48 "ls -la ~/.openclaw/openclaw.json"
ssh openclaw@100.66.145.48 "ls -la ~/.config/openclaw/openclaw.json 2>/dev/null || echo 'Does not exist'"

# Remove duplicate if found
ssh openclaw@100.66.145.48 "rm ~/.config/openclaw/openclaw.json"

# Update the correct config
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities += [\"browser-control\"]" ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json'
```

#### 1C. Config Gets Reset by openclaw CLI on Startup

Some OpenClaw versions initialize default config if certain fields are missing.

**Solution:**

```bash
# Ensure all required fields exist before adding capability
ssh openclaw@100.66.145.48 'cat > /tmp/update-config.sh <<EOF
#!/bin/bash
CONFIG=~/.openclaw/openclaw.json

# Ensure agents.defaults exists
jq ".agents.defaults //= {}" \$CONFIG > /tmp/config.json && mv /tmp/config.json \$CONFIG

# Ensure capabilities array exists
jq ".agents.defaults.capabilities //= []" \$CONFIG > /tmp/config.json && mv /tmp/config.json \$CONFIG

# Now add capability
jq ".agents.defaults.capabilities += [\"browser-control\"]" \$CONFIG > /tmp/config.json && mv /tmp/config.json \$CONFIG

echo "Updated config:"
jq ".agents.defaults.capabilities" \$CONFIG
EOF

chmod +x /tmp/update-config.sh
/tmp/update-config.sh'
```

---

### Scenario 2: Capability in Config But Not Available to Agent

**Symptoms:**
```bash
# Config shows capability
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities" ~/.openclaw/openclaw.json'
# Output: ["browser-control"]  ✓

# But agent doesn't have it
# Test by sending message to bot that requires browser
# Bot responds: "I don't have browser access"
```

**Root Causes:**

#### 2A. Capability Requires Additional Tool Configuration

Some capabilities need both:
1. The capability enabled
2. The corresponding tool configured

**Solution:**

```bash
# Browser capability needs browser tool config
ssh openclaw@100.66.145.48 'cat > /tmp/add-browser.json <<EOF
{
  "agents": {
    "defaults": {
      "capabilities": ["browser-control"],
      "tools": [
        {
          "name": "browser",
          "enabled": true,
          "config": {
            "headless": false,
            "defaultTimeout": 30000
          }
        }
      ]
    }
  }
}
EOF

# Merge with existing config
jq -s ".[0] * .[1]" ~/.openclaw/openclaw.json /tmp/add-browser.json > /tmp/merged.json
mv /tmp/merged.json ~/.openclaw/openclaw.json

# Restart Gateway
pkill -SIGUSR1 openclaw-gateway'
```

#### 2B. Capability Plugin Not Installed

Some capabilities are plugins that need separate installation.

**Diagnosis:**
```bash
# Check installed plugins
ssh openclaw@100.66.145.48 "openclaw plugins list 2>/dev/null || echo 'Plugin command not available'"

# Check Gateway startup logs for plugin errors
ssh openclaw@100.66.145.48 "grep -i 'plugin\|capability' ~/.openclaw/logs/gateway.log | head -20"
```

**Solution:**

```bash
# Update OpenClaw (may include missing plugins)
ssh openclaw@100.66.145.48 "openclaw update"

# Restart Gateway
ssh openclaw@100.66.145.48 "pkill -f openclaw-gateway && sleep 3 && openclaw gateway start --port 18789"

# Verify capability is now available
ssh openclaw@100.66.145.48 "tail -30 ~/.openclaw/logs/gateway.log | grep -i 'capabilit\|tool.*loaded'"
```

#### 2C. macOS Permission Not Granted

Some capabilities require macOS permissions (browser automation, calendar access, etc.).

**Diagnosis:**
```bash
# Check for permission denied errors
ssh openclaw@100.66.145.48 "grep -i 'permission\|denied\|authorized' ~/.openclaw/logs/gateway.err.log | tail -10"
```

**Solution:**

Contact customer and have them:
1. Open **System Settings** → **Privacy & Security**
2. Grant permissions for:
   - **Automation** (for browser control)
   - **Calendar** (for calendar access)
   - **Full Disk Access** (if agent needs file system access)
3. Restart Gateway after granting permissions

---

### Scenario 3: Gateway Won't Start After Adding Capability

**Symptoms:**
```bash
# Add capability
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities += [\"browser-control\"]" ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json'

# Try to start Gateway
ssh openclaw@100.66.145.48 "openclaw gateway start --port 18789"
# Gateway terminates immediately

# No Gateway process running
ssh openclaw@100.66.145.48 "ps aux | grep openclaw-gateway | grep -v grep"
# (empty output)
```

**Root Causes:**

#### 3A. Invalid JSON After Edit

**Diagnosis:**
```bash
# Validate JSON
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq empty"
# If error: JSON syntax is broken
```

**Solution:**

```bash
# Restore from backup
ssh openclaw@100.66.145.48 "ls -la ~/.openclaw/openclaw.json.backup*"
ssh openclaw@100.66.145.48 "cp ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d) ~/.openclaw/openclaw.json"

# Or fix JSON manually
ssh openclaw@100.66.145.48 "vim ~/.openclaw/openclaw.json"

# Validate before starting
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | jq empty && echo 'Valid JSON'"
```

#### 3B. Invalid Capability Name

**Diagnosis:**
```bash
# Check startup error
ssh openclaw@100.66.145.48 "openclaw gateway start --port 18789 2>&1 | head -20"

# Look for "unknown capability" or "invalid capability"
```

**Solution:**

```bash
# List valid capabilities (if OpenClaw supports this)
ssh openclaw@100.66.145.48 "openclaw capabilities list 2>/dev/null || echo 'Command not available'"

# Common valid capabilities:
# - browser-control
# - filesystem-read
# - filesystem-write
# - calendar-read
# - calendar-write
# - email-read
# - email-send

# Fix typo in config
ssh openclaw@100.66.145.48 'jq ".agents.defaults.capabilities = [\"browser-control\"]" ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json'
```

#### 3C. Config Validation Failure

**Diagnosis:**
```bash
# Try starting Gateway manually to see full error
ssh openclaw@100.66.145.48 "openclaw gateway start --port 18789"
# Read error message carefully
```

**Common validation errors:**

- "capabilities must be an array" → Wrong type
- "missing required field: model" → Incomplete config
- "invalid tool configuration" → Tool config malformed

**Solution:**

```bash
# Ensure proper structure
ssh openclaw@100.66.145.48 'cat > /tmp/fix-structure.sh <<EOF
#!/bin/bash
CONFIG=~/.openclaw/openclaw.json

# Ensure capabilities is array
jq "if .agents.defaults.capabilities | type != \"array\" then .agents.defaults.capabilities = [] else . end" \$CONFIG > /tmp/config.json && mv /tmp/config.json \$CONFIG

# Ensure tools is array
jq "if .agents.defaults.tools | type != \"array\" then .agents.defaults.tools = [] else . end" \$CONFIG > /tmp/config.json && mv /tmp/config.json \$CONFIG

echo "Fixed structure. Config now:"
jq ".agents.defaults" \$CONFIG
EOF

chmod +x /tmp/fix-structure.sh
/tmp/fix-structure.sh'
```

---

### Scenario 4: Works Locally But Not on Customer Mac

**Symptoms:**
- Same config works on your support Mac
- Fails on customer Mac Mini with same OpenClaw version

**Root Causes:**

#### 4A. macOS Version Difference

**Diagnosis:**
```bash
# Check macOS versions
echo "Support Mac:"
sw_vers

echo "Customer Mac:"
ssh openclaw@100.66.145.48 "sw_vers"
```

**Solution:**

Some capabilities only work on certain macOS versions. Update customer's macOS if needed (with their permission).

#### 4B. Missing System Dependencies

**Diagnosis:**
```bash
# Check if required binaries exist
ssh openclaw@100.66.145.48 "which node"
ssh openclaw@100.66.145.48 "which python3"
ssh openclaw@100.66.145.48 "/opt/homebrew/bin/node --version"
```

**Solution:**

```bash
# Install Homebrew if missing
ssh openclaw@100.66.145.48 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Install missing dependencies
ssh openclaw@100.66.145.48 "brew install node python3"
```

#### 4C. Permissions Denied on Customer Mac

**Solution:**

Have customer run:
```bash
# Check current permissions
tccutil list

# Reset permissions if stuck
tccutil reset All ai.openclaw.gateway
```

Then re-grant permissions via System Settings.

---

## Systematic Troubleshooting Process

### Step 1: Backup Current Config

```bash
#!/bin/bash
CUSTOMER_IP="$1"

# Create timestamped backup
ssh "openclaw@$CUSTOMER_IP" "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)"

# Verify backup created
ssh "openclaw@$CUSTOMER_IP" "ls -lah ~/.openclaw/openclaw.json.backup*"
```

### Step 2: Validate Current Config

```bash
# Check JSON validity
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty && echo 'Valid JSON' || echo 'INVALID JSON'"

# Check required fields exist
ssh "openclaw@$CUSTOMER_IP" "jq '.agents.defaults.model.primary' ~/.openclaw/openclaw.json"
ssh "openclaw@$CUSTOMER_IP" "jq '.agents.defaults.capabilities' ~/.openclaw/openclaw.json"
```

### Step 3: Add Capability Safely

```bash
#!/bin/bash
CUSTOMER_IP="$1"
CAPABILITY="$2"  # e.g., "browser-control"

echo "Adding capability: $CAPABILITY to $CUSTOMER_IP"

# Ensure structure exists
ssh "openclaw@$CUSTOMER_IP" "jq '.agents.defaults.capabilities //= []' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json"

# Add capability (avoid duplicates)
ssh "openclaw@$CUSTOMER_IP" "jq '.agents.defaults.capabilities |= (. + [\"$CAPABILITY\"] | unique)' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json"

# Validate result
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty && echo 'Valid JSON' || echo 'INVALID - RESTORING BACKUP'"

# If invalid, restore
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty || cp ~/.openclaw/openclaw.json.backup-* ~/.openclaw/openclaw.json"

echo "Current capabilities:"
ssh "openclaw@$CUSTOMER_IP" "jq '.agents.defaults.capabilities' ~/.openclaw/openclaw.json"
```

### Step 4: Test Without Restarting (Reload Config)

```bash
# Send SIGUSR1 to reload config without restart
ssh "openclaw@$CUSTOMER_IP" "pkill -SIGUSR1 openclaw-gateway"

# Wait for reload
sleep 3

# Check logs for reload confirmation
ssh "openclaw@$CUSTOMER_IP" "tail -20 ~/.openclaw/logs/gateway.log | grep -i 'reload\|config'"
```

### Step 5: Full Restart If Reload Doesn't Work

```bash
# Kill Gateway gracefully
ssh "openclaw@$CUSTOMER_IP" "pkill -f openclaw-gateway"

# Wait for shutdown
sleep 3

# Verify it's stopped
ssh "openclaw@$CUSTOMER_IP" "ps aux | grep openclaw-gateway | grep -v grep || echo 'Stopped'"

# Start Gateway
ssh "openclaw@$CUSTOMER_IP" "/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@*/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"

# Verify it started
sleep 5
ssh "openclaw@$CUSTOMER_IP" "ps aux | grep openclaw-gateway | grep -v grep"
```

### Step 6: Verify Capability Works

```bash
# Check Gateway logs for capability initialization
ssh "openclaw@$CUSTOMER_IP" "tail -50 ~/.openclaw/logs/gateway.log | grep -i 'capabilit\|tool.*loaded'"

# Test capability (send test message to bot that requires it)
# Document test in support log
```

### Step 7: Document Changes

```bash
#!/bin/bash
CUSTOMER_IP="$1"
CAPABILITY="$2"

cat >> ~/support-logs/capability-changes.log <<EOF
Date: $(date)
Customer: $CUSTOMER_IP
Capability Added: $CAPABILITY
Technician: $(whoami)
Result: [SUCCESS/FAILED]
Notes: [Add any relevant notes]
---
EOF
```

---

## Prevention: Config Management System

### Create Master Config Templates

```bash
# Store templates in version control
~/customer-configs/templates/
├── base.json              # Minimal working config
├── browser-enabled.json   # With browser capability
├── calendar-enabled.json  # With calendar capability
└── full-featured.json     # All capabilities
```

**base.json:**
```json
{
  "gateway": {
    "port": 18789,
    "bind": "loopback",
    "auth": {
      "mode": "token"
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-3.5-sonnet"
      },
      "capabilities": [],
      "tools": []
    }
  },
  "channels": {
    "telegram": {
      "botToken": "REPLACE_WITH_BOT_TOKEN",
      "dmPolicy": "allowlist",
      "allowFrom": ["REPLACE_WITH_USER_ID"]
    }
  }
}
```

### Deployment Script

```bash
#!/bin/bash
# deploy-config.sh
# Usage: ./deploy-config.sh <customer-ip> <template> <bot-token> <user-id>

CUSTOMER_IP="$1"
TEMPLATE="$2"  # e.g., "browser-enabled"
BOT_TOKEN="$3"
USER_ID="$4"

echo "Deploying $TEMPLATE to $CUSTOMER_IP"

# Generate config from template
jq ".channels.telegram.botToken = \"$BOT_TOKEN\" | .channels.telegram.allowFrom = [\"$USER_ID\"]" \
  ~/customer-configs/templates/$TEMPLATE.json > /tmp/deploy-config.json

# Backup existing config on customer Mac
ssh "openclaw@$CUSTOMER_IP" "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)"

# Deploy new config
scp /tmp/deploy-config.json "openclaw@$CUSTOMER_IP:~/.openclaw/openclaw.json"

# Validate deployed config
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty && echo 'Valid JSON deployed' || echo 'DEPLOYMENT FAILED - INVALID JSON'"

# Restart Gateway
ssh "openclaw@$CUSTOMER_IP" "pkill -f openclaw-gateway && sleep 3 && openclaw gateway start --port 18789"

echo "Deployment complete. Verifying..."
ssh "openclaw@$CUSTOMER_IP" "ps aux | grep openclaw-gateway | grep -v grep && echo 'Gateway running' || echo 'Gateway failed to start'"
```

---

## Emergency Recovery

If everything is broken and you need to recover:

```bash
#!/bin/bash
# emergency-recovery.sh
CUSTOMER_IP="$1"

echo "=== Emergency Recovery for $CUSTOMER_IP ==="

# 1. Kill all openclaw processes
ssh "openclaw@$CUSTOMER_IP" "pkill -9 -f openclaw"

# 2. Find latest backup
LATEST_BACKUP=$(ssh "openclaw@$CUSTOMER_IP" "ls -t ~/.openclaw/openclaw.json.backup* | head -1")
echo "Latest backup: $LATEST_BACKUP"

# 3. Restore backup
ssh "openclaw@$CUSTOMER_IP" "cp $LATEST_BACKUP ~/.openclaw/openclaw.json"

# 4. Validate backup
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty && echo 'Backup valid' || echo 'Backup corrupted - using base template'"

# 5. If backup corrupted, deploy base template
ssh "openclaw@$CUSTOMER_IP" "cat ~/.openclaw/openclaw.json | jq empty" || \
  scp ~/customer-configs/templates/base.json "openclaw@$CUSTOMER_IP:~/.openclaw/openclaw.json"

# 6. Start Gateway
ssh "openclaw@$CUSTOMER_IP" "/opt/homebrew/bin/node ~/Library/pnpm/global/5/.pnpm/openclaw@*/node_modules/openclaw/dist/index.js gateway --port 18789 > /dev/null 2>&1 &"

# 7. Verify
sleep 5
ssh "openclaw@$CUSTOMER_IP" "ps aux | grep openclaw-gateway | grep -v grep && echo 'RECOVERED' || echo 'RECOVERY FAILED'"
```

---

## Related Documentation

- [Tailscale Device Management](../networking/tailscale-device-management.md) - Managing customer devices
- [Remote Support Guide](../client-support/REMOTE-SUPPORT-GUIDE.md) - General remote support procedures
- [Dashboard Troubleshooting](./dashboard-troubleshooting.md) - Remote dashboard access

---

*Last Updated: 2026-02-05*
*Applies to: OpenClaw 2026.2.1+, macOS Sequoia*
