# OpenClaw Native macOS Locked-Down Installation Guide

**Target Machine:** M4 Mac Mini (jordaaan)
**Threat Model:** Internal (agent) attacks — prompt injection, hallucinated commands, credential theft
**Philosophy:** Least privilege with defense-in-depth — assume the agent will try to do harmful things

---

## Table of Contents

1. [Threat Model Deep Dive](#threat-model-deep-dive)
2. [Dedicated User Account Setup](#dedicated-user-account-setup)
3. [Strict exec-approvals Configuration](#strict-exec-approvals-configuration)
4. [TCC Permission Lockdown](#tcc-permission-lockdown)
5. [LaunchAgent Configuration & Monitoring](#launchagent-configuration--monitoring)
6. [File System Sandboxing](#file-system-sandboxing)
7. [Network Restrictions](#network-restrictions)
8. [Real-Time Monitoring Dashboard](#real-time-monitoring-dashboard)
9. [Audit Logging](#audit-logging)
10. [Emergency Kill Switch](#emergency-kill-switch)

---

## Threat Model Deep Dive

### Attack Vectors from the Agent

| Attack Type | Example | Mitigation |
|-------------|---------|------------|
| **Prompt Injection** | Malicious PDF instructs agent to exfiltrate files | Strict exec-approvals allowlist |
| **Hallucinated Commands** | Agent "helpfully" runs `rm -rf ~` | Command allowlist, no wildcards |
| **Credential Harvesting** | Agent reads `~/.ssh/id_rsa` | File system sandboxing |
| **Data Exfiltration** | Agent curls files to external server | Network egress restrictions |
| **Persistence** | Agent modifies LaunchAgents | Read-only system directories |
| **Privilege Escalation** | Agent attempts sudo | No sudo access for service account |
| **Keychain Access** | Agent tries to dump passwords | Separate keychain, no unlock |

### Defense Layers

```
┌──────────────────────────────────────────────────────────────┐
│  Layer 1: Dedicated User Account                              │
│  • No admin privileges                                        │
│  • No sudo access                                             │
│  • Isolated home directory                                    │
├──────────────────────────────────────────────────────────────┤
│  Layer 2: exec-approvals                                      │
│  • Deny by default                                            │
│  • Explicit allowlist of safe commands                        │
│  • Argument validation                                        │
├──────────────────────────────────────────────────────────────┤
│  Layer 3: TCC Permissions                                     │
│  • Minimal required permissions                               │
│  • Revoke unused access                                       │
│  • Per-app granularity                                        │
├──────────────────────────────────────────────────────────────┤
│  Layer 4: File System Sandbox                                 │
│  • Restricted read paths                                      │
│  • Restricted write paths                                     │
│  • No access to sensitive directories                         │
├──────────────────────────────────────────────────────────────┤
│  Layer 5: Network Restrictions                                │
│  • Egress filtering                                           │
│  • No arbitrary HTTP requests                                 │
│  • Monitored connections                                      │
├──────────────────────────────────────────────────────────────┤
│  Layer 6: Real-Time Monitoring                                │
│  • Command logging                                            │
│  • Anomaly detection                                          │
│  • Alert on suspicious activity                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Dedicated User Account Setup

### Step 1: Create Service Account

```bash
# Create a non-admin user for OpenClaw
# Run these as your admin account

# Create the user (will prompt for password - use a strong one)
sudo dscl . -create /Users/openclaw
sudo dscl . -create /Users/openclaw UserShell /bin/zsh
sudo dscl . -create /Users/openclaw RealName "OpenClaw Service"
sudo dscl . -create /Users/openclaw UniqueID 550
sudo dscl . -create /Users/openclaw PrimaryGroupID 20
sudo dscl . -create /Users/openclaw NFSHomeDirectory /Users/openclaw

# Create home directory
sudo mkdir -p /Users/openclaw
sudo chown openclaw:staff /Users/openclaw

# Set a strong password (store this securely!)
sudo dscl . -passwd /Users/openclaw "YOUR_STRONG_PASSWORD_HERE"

# CRITICAL: Ensure user is NOT an admin
sudo dscl . -delete /Groups/admin GroupMembership openclaw 2>/dev/null || true
```

### Step 2: Verify Non-Admin Status

```bash
# Confirm user cannot sudo
sudo -u openclaw sudo -l
# Should show: "User openclaw is not allowed to run sudo"

# Confirm not in admin group
groups openclaw
# Should NOT include "admin"
```

### Step 3: Create Required Directories

```bash
# Create OpenClaw directories with proper ownership
sudo mkdir -p /Users/openclaw/.openclaw
sudo mkdir -p /Users/openclaw/.openclaw/logs
sudo mkdir -p /Users/openclaw/.openclaw/workspace
sudo chown -R openclaw:staff /Users/openclaw/.openclaw

# Set restrictive permissions
sudo chmod 700 /Users/openclaw/.openclaw
sudo chmod 755 /Users/openclaw/.openclaw/workspace
```

---

## Strict exec-approvals Configuration

This is the most critical security control. The exec-approvals system determines exactly what commands the agent can run.

### Step 1: Create Deny-by-Default Configuration

Create `/Users/openclaw/.openclaw/exec-approvals.json`:

```json
{
  "version": "1.0",
  "default_action": "deny",
  "log_all_attempts": true,
  "log_file": "/Users/openclaw/.openclaw/logs/exec-approvals.log",

  "rules": [
    {
      "id": "allow-echo",
      "description": "Allow basic echo for output",
      "binary": "/bin/echo",
      "action": "allow",
      "argument_rules": {
        "max_args": 10,
        "max_total_length": 1000,
        "forbidden_patterns": [">>", ">", "|", ";", "`", "$(", "&&"]
      }
    },
    {
      "id": "allow-date",
      "description": "Allow date command",
      "binary": "/bin/date",
      "action": "allow",
      "argument_rules": {
        "max_args": 3
      }
    },
    {
      "id": "allow-ls-workspace",
      "description": "Allow listing workspace directory only",
      "binary": "/bin/ls",
      "action": "allow",
      "argument_rules": {
        "required_prefix": ["/Users/openclaw/.openclaw/workspace"],
        "forbidden_patterns": [
          "..",
          "~",
          "/Users/openclaw/.ssh",
          "/Users/openclaw/.gnupg",
          "/var",
          "/etc",
          "/System",
          "/Library"
        ]
      }
    },
    {
      "id": "deny-curl",
      "description": "DENY all curl requests - potential exfiltration",
      "binary": "/usr/bin/curl",
      "action": "deny",
      "alert": true
    },
    {
      "id": "deny-wget",
      "description": "DENY wget - potential exfiltration",
      "binary": "/usr/bin/wget",
      "action": "deny",
      "alert": true
    },
    {
      "id": "deny-ssh",
      "description": "DENY ssh - potential lateral movement",
      "binary": "/usr/bin/ssh",
      "action": "deny",
      "alert": true
    },
    {
      "id": "deny-osascript",
      "description": "DENY osascript - too powerful",
      "binary": "/usr/bin/osascript",
      "action": "deny",
      "alert": true
    },
    {
      "id": "deny-security",
      "description": "DENY security command - keychain access",
      "binary": "/usr/bin/security",
      "action": "deny",
      "alert": true
    },
    {
      "id": "deny-launchctl",
      "description": "DENY launchctl - service manipulation",
      "binary": "/bin/launchctl",
      "action": "deny",
      "alert": true
    }
  ],

  "environment_blocklist": [
    "PATH",
    "LD_LIBRARY_PATH",
    "DYLD_*",
    "NODE_OPTIONS",
    "PYTHONPATH",
    "BASH_ENV"
  ]
}
```

### Step 2: Set Configuration Permissions

```bash
# Make exec-approvals config read-only to the service account
sudo chown root:wheel /Users/openclaw/.openclaw/exec-approvals.json
sudo chmod 644 /Users/openclaw/.openclaw/exec-approvals.json
```

---

## TCC Permission Lockdown

### Step 1: Understand Required Permissions

For full iMessage/Camera/Screen capabilities, these TCC permissions are needed:

| Permission | Required For | Risk Level |
|------------|--------------|------------|
| Camera | camera.snap, camera.clip | Medium |
| Microphone | Audio capture | Medium |
| Screen Recording | Screen capture | High |
| Accessibility | UI automation | Very High |
| Full Disk Access | Reading files anywhere | Critical |
| Contacts | Address book access | Medium |
| Calendar | Calendar events | Low |

### Step 2: Grant Minimal Permissions via System Settings

**CRITICAL: Only grant what you actually need.**

1. Open **System Settings → Privacy & Security**
2. For each permission category:
   - Click the category
   - Click the "+" button
   - Navigate to the OpenClaw app
   - Add it with the toggle ON

**Recommended Minimal Set for iMessage:**
- [x] Accessibility (required for message sending)
- [x] Contacts (if you want contact name resolution)
- [ ] Calendar (skip unless needed)
- [ ] Camera (skip unless needed)
- [ ] Microphone (skip unless needed)
- [ ] Screen Recording (skip unless needed)
- [ ] Full Disk Access (NEVER grant this)

---

## LaunchAgent Configuration & Monitoring

### Step 1: Create Monitored LaunchAgent

Create `/Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>bot.molt.gateway</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Applications/OpenClaw.app/Contents/MacOS/OpenClaw</string>
        <string>--config</string>
        <string>/Users/openclaw/.openclaw/config.yaml</string>
    </array>

    <key>UserName</key>
    <string>openclaw</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <!-- Resource Limits -->
    <key>HardResourceLimits</key>
    <dict>
        <key>NumberOfFiles</key>
        <integer>256</integer>
        <key>NumberOfProcesses</key>
        <integer>50</integer>
    </dict>

    <!-- Logging -->
    <key>StandardOutPath</key>
    <string>/Users/openclaw/.openclaw/logs/gateway-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>/Users/openclaw/.openclaw/logs/gateway-stderr.log</string>

    <!-- Security: Working directory restriction -->
    <key>WorkingDirectory</key>
    <string>/Users/openclaw/.openclaw/workspace</string>
</dict>
</plist>
```

### Step 2: Protect LaunchAgent from Modification

```bash
# Make the plist owned by root (openclaw user can't modify)
sudo chown root:wheel /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist
sudo chmod 644 /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist

# Set immutable flag (extra protection)
sudo chflags schg /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist
```

---

## Emergency Kill Switch

### Step 1: Create Kill Script

Create `/usr/local/bin/openclaw-emergency-stop.sh`:

```bash
#!/bin/bash
# EMERGENCY: Immediately stop all OpenClaw processes

echo "=== EMERGENCY STOP INITIATED ==="
echo "Time: $(date)"

# Unload LaunchAgent
sudo -u openclaw launchctl unload /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist 2>/dev/null

# Kill any remaining processes
pkill -9 -u openclaw OpenClaw 2>/dev/null
pkill -9 -u openclaw molt 2>/dev/null

# Block network for openclaw user immediately
sudo pfctl -t openclaw_blocked -T add 0.0.0.0/0

# Log the emergency stop
echo "$(date): EMERGENCY STOP executed by $(whoami)" >> /var/log/openclaw/emergency.log

# Disable auto-restart temporarily
sudo launchctl disable user/550/bot.molt.gateway

echo "=== OpenClaw STOPPED ==="
echo "To restart: sudo /usr/local/bin/openclaw-restart.sh"
```

### Step 2: Create Restart Script

Create `/usr/local/bin/openclaw-restart.sh`:

```bash
#!/bin/bash
# Restart OpenClaw after emergency stop

echo "=== Restarting OpenClaw ==="

# Re-enable the service
sudo launchctl enable user/550/bot.molt.gateway

# Remove network block
sudo pfctl -t openclaw_blocked -T flush

# Load LaunchAgent
sudo -u openclaw launchctl load /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist

# Verify
sleep 2
if sudo -u openclaw launchctl list | grep -q molt; then
    echo "OpenClaw restarted successfully"
else
    echo "ERROR: Failed to restart OpenClaw"
    exit 1
fi
```

---

## Security Maintenance Checklist

### Daily
- [ ] Review `/var/log/openclaw/alerts.log`
- [ ] Check exec-approvals denials in logs
- [ ] Verify service is running as correct user

### Weekly
- [ ] Audit exec-approvals.json for any unauthorized changes
- [ ] Review full unified log for patterns
- [ ] Check TCC permissions haven't changed
- [ ] Test emergency stop script works

### Monthly
- [ ] Review and update exec-approvals allowlist
- [ ] Audit all files in openclaw user's home directory
- [ ] Check for OpenClaw updates (but review changelog first)
- [ ] Test full restart procedure
- [ ] Review network egress logs

---

## Quick Reference Commands

```bash
# Start OpenClaw
sudo -u openclaw launchctl load /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist

# Stop OpenClaw
sudo -u openclaw launchctl unload /Users/openclaw/Library/LaunchAgents/bot.molt.gateway.plist

# Emergency Stop
sudo /usr/local/bin/openclaw-emergency-stop.sh

# Restart After Emergency
sudo /usr/local/bin/openclaw-restart.sh

# Check Status
sudo -u openclaw launchctl list | grep molt

# View Live Logs
tail -f /var/log/openclaw/unified.log

# View Alerts
tail -f /var/log/openclaw/alerts.log

# View Denied Commands
grep "DENIED" /Users/openclaw/.openclaw/logs/exec-approvals.log

# Check LaunchAgent Integrity
/usr/local/bin/monitor-launchagent.sh
```

---

**Document Version:** 1.0
**Last Updated:** January 30, 2026
**Next Review:** April 30, 2026
