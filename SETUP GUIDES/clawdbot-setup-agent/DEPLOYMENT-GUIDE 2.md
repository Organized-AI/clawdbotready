# Clawdbot Setup Assistant - Deployment Guide

**Version**: 1.0.0
**Target Platform**: OpenClaw Gateway on macOS/Linux server
**Estimated Setup Time**: 45-60 minutes
**Last Updated**: 2026-02-02

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Testing](#testing)
6. [Going Live](#going-live)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Server Requirements

- **OpenClaw Gateway** installed and running
- **Phone integration** (iMessage or WhatsApp connected)
- **Server OS**: macOS Sequoia+ or Linux with Docker
- **Resources**: 2GB RAM, 10GB disk space
- **Access**: SSH access to server, sudo privileges

### Software Dependencies

```bash
# Check if installed
command -v openclaw    # OpenClaw CLI
command -v jq          # JSON processor
command -v ssh-keygen  # SSH key generation
command -v curl        # HTTP client
```

Install missing dependencies:

```bash
# macOS
brew install jq openssh curl

# Linux
sudo apt install jq openssh-client curl
```

### Phone Number Setup

Your OpenClaw Gateway must have a phone number configured:

```bash
# Check current phone number
openclaw config get phone_number

# If not set, configure it
openclaw config set phone_number "+1234567890"

# Test by sending yourself a message
openclaw send --to "+1234567890" "Test message"
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  User calls setup hotline                           │
│  ↓                                                   │
│  Your Server (OpenClaw Gateway)                     │
│  ├─ Agent: setup-assistant                          │
│  ├─ Scripts: ssh-manager, remote-setup              │
│  └─ Config: agent-exec-approvals.json               │
│      ↓                                               │
│      Generates temp SSH credentials (2hr expiry)    │
│      ↓                                               │
│      Sends setup command to user via SMS            │
│      ↓                                               │
│  User's Mac                                          │
│  ├─ Runs setup command                              │
│  ├─ Installs SSH key                                │
│  └─ Agent connects via SSH                          │
│      ↓                                               │
│      Agent runs setup.sh phases                     │
│      ↓                                               │
│      Clawdbot deployed ✅                            │
└─────────────────────────────────────────────────────┘
```

**Key Components:**

1. **Agent Config** (`agent-config.md`) - AI agent prompt and behavior
2. **Conversation Flow** (`conversation-flow.md`) - Decision tree logic
3. **SSH Manager** (`scripts/ssh-manager.sh`) - Temporary credential generation
4. **Remote Setup** (`scripts/remote-setup.sh`) - Phase execution engine
5. **Exec Approvals** (`config/agent-exec-approvals.json`) - Security controls

---

## Installation

### Step 1: Copy Agent Files to Server

```bash
# On your local machine, package the agent
cd clawdbot-setup-agent
tar -czf setup-assistant-agent.tar.gz \
    agent-config.md \
    conversation-flow.md \
    scripts/ \
    config/

# Copy to your server
scp setup-assistant-agent.tar.gz your-server:~/

# SSH to server
ssh your-server

# Extract
cd ~
tar -xzf setup-assistant-agent.tar.gz
```

### Step 2: Install to OpenClaw

```bash
# Create agent directory
mkdir -p ~/.openclaw/agents/setup-assistant

# Copy agent files
cp agent-config.md ~/.openclaw/agents/setup-assistant/
cp conversation-flow.md ~/.openclaw/agents/setup-assistant/
cp -r scripts ~/.openclaw/agents/setup-assistant/
cp -r config ~/.openclaw/agents/setup-assistant/

# Make scripts executable
chmod +x ~/.openclaw/agents/setup-assistant/scripts/*.sh

# Copy exec-approvals to OpenClaw config
cp config/agent-exec-approvals.json ~/.openclaw/config/

# Create required directories
mkdir -p ~/.openclaw/setup-assistant/{ssh-creds,state,snapshots}
mkdir -p ~/.openclaw/logs/remote-setups
```

### Step 3: Register Agent with OpenClaw

```bash
# Add agent to OpenClaw's agent registry
openclaw agent register \
    --name "setup-assistant" \
    --description "Automated Clawdbot setup assistant" \
    --config ~/.openclaw/agents/setup-assistant/agent-config.md \
    --triggers "set up clawdbot,install clawdbot,deploy openclaw"

# Verify registration
openclaw agent list | grep setup-assistant
```

### Step 4: Configure Server URL

Edit [`scripts/ssh-manager.sh`](scripts/ssh-manager.sh) line 234:

```bash
# BEFORE:
local setup_script_url="https://YOUR-SERVER.com/setup-ssh"

# AFTER:
local setup_script_url="https://your-actual-server.com/setup-ssh"
```

### Step 5: Create Setup Endpoint

Create HTTP endpoint that serves the SSH setup script:

```bash
# Create setup script
cat > ~/.openclaw/web/setup-ssh.sh <<'EOF'
#!/usr/bin/env bash
# SSH Setup Script for Clawdbot Assistant
# Usage: curl -fsSL https://your-server.com/setup-ssh | bash -s [TOKEN]

set -euo pipefail

TOKEN="${1:-}"
if [[ -z "$TOKEN" ]]; then
    echo "Error: Token required"
    exit 1
fi

# Fetch public key from server
PUBLIC_KEY=$(curl -fsSL "https://your-server.com/api/setup-ssh/key/${TOKEN}")

if [[ -z "$PUBLIC_KEY" ]]; then
    echo "Error: Invalid or expired token"
    exit 1
fi

# Install key
mkdir -p ~/.ssh
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "✓ Setup complete! Agent can now connect."
EOF

chmod +x ~/.openclaw/web/setup-ssh.sh
```

Configure your web server (nginx/apache) to serve this script at `/setup-ssh`.

**Example nginx config:**

```nginx
location /setup-ssh {
    alias /home/your-user/.openclaw/web/setup-ssh.sh;
    default_type text/plain;
}

location /api/setup-ssh/key/ {
    proxy_pass http://localhost:8080;  # Your API endpoint
}
```

Create API endpoint to serve public keys:

```bash
# This would be part of your OpenClaw API
# Example endpoint: GET /api/setup-ssh/key/{token}
# Returns: Public key for that token
```

---

## Configuration

### 1. Agent Personality

Edit [`agent-config.md`](agent-config.md) to customize:

```markdown
## Personality

- **Tone**: [Friendly / Professional / Minimal]
- **Language**: [Simple / Technical]
- **Update Frequency**: [Every 2-3 min / Every 5 min]
```

### 2. Security Settings

Edit [`config/agent-exec-approvals.json`](config/agent-exec-approvals.json):

```json
{
  "default_action": "deny",  // Never change this
  "log_all_attempts": true,  // Keep for audit

  "rate_limiting": {
    "max_commands_per_minute": 60,  // Adjust if needed
    "max_failed_attempts": 10       // Tune based on testing
  }
}
```

### 3. SSH Credential Expiry

Edit [`scripts/ssh-manager.sh`](scripts/ssh-manager.sh) line 13:

```bash
# Default: 2 hours
EXPIRY_HOURS=2

# For testing: 4 hours
EXPIRY_HOURS=4
```

### 4. Deployment Paths

To add new deployment paths (Docker, cloud VPS), edit:

[`conversation-flow.md`](conversation-flow.md) - Add new options to Node 2

[`scripts/remote-setup.sh`](scripts/remote-setup.sh) - Add new path handling

---

## Testing

### Test 1: SSH Manager

```bash
cd ~/.openclaw/agents/setup-assistant

# Generate test credential
./scripts/ssh-manager.sh generate test-user-123

# Should output:
# ✓ Temporary SSH Credential Created
# Token: abc123def456...

# List credentials
./scripts/ssh-manager.sh list

# Check status
./scripts/ssh-manager.sh status abc123def456

# Revoke
./scripts/ssh-manager.sh revoke abc123def456
```

### Test 2: Remote Setup Executor

```bash
# Note: Requires active SSH credential and Mac IP

# Generate credential
TOKEN=$(./scripts/ssh-manager.sh generate test-user | grep "Token:" | awk '{print $2}')

# Save user Mac IP to state (normally done by agent)
mkdir -p ~/.openclaw/setup-assistant/state
cat > ~/.openclaw/setup-assistant/state/${TOKEN}.json <<EOF
{
  "token": "${TOKEN}",
  "user_mac_ip": "user@192.168.1.100",  # Replace with test Mac
  "current_phase": 0
}
EOF

# Test connection
./scripts/remote-setup.sh test-connection $TOKEN

# Run system checks
./scripts/remote-setup.sh system-checks $TOKEN

# Run Phase 0 (prerequisites)
./scripts/remote-setup.sh run-with-retry $TOKEN vm 0

# Check status
./scripts/remote-setup.sh status $TOKEN
```

### Test 3: Agent Trigger

```bash
# Test agent activation
openclaw test-agent setup-assistant "I want to set up clawdbot"

# Should respond with greeting and deployment path question
```

### Test 4: End-to-End Simulation

```bash
# Run full simulation (safe mode, no actual setup)
openclaw agent test setup-assistant \
    --mode simulation \
    --user-responses "vm,yes,yes" \
    --mac-ip "user@test-mac.local"

# Check logs
tail -f ~/.openclaw/logs/setup-assistant.log
```

---

## Going Live

### Pre-Launch Checklist

- [ ] All tests pass
- [ ] SSH manager generates credentials correctly
- [ ] Exec-approvals loaded and enforced
- [ ] Phone number connected to OpenClaw
- [ ] Web endpoint serving setup script
- [ ] Monitoring configured
- [ ] Backup/rollback tested
- [ ] Human escalation path tested

### Launch Steps

1. **Enable Agent**

```bash
openclaw agent enable setup-assistant
```

2. **Announce Phone Number**

Publicize your setup hotline number:

```
📱 Automated Clawdbot Setup: Text "set up clawdbot" to +1-XXX-XXX-XXXX
```

3. **Monitor First Setups**

Watch logs in real-time during first few setups:

```bash
tail -f ~/.openclaw/logs/setup-assistant.log
```

4. **Prepare Human Support**

Ensure support team is ready for escalations:
- Access to agent logs
- Ability to take over SSH sessions
- Troubleshooting playbook

### Soft Launch

Start with limited audience:

1. **Internal testing** (your team)
2. **Beta testers** (trusted users)
3. **Gradual rollout** (increase over weeks)

Monitor success rate and iterate on error handling.

---

## Monitoring

### Real-Time Monitoring

```bash
# Active setups
openclaw agent stats setup-assistant

# Recent errors
grep ERROR ~/.openclaw/logs/setup-assistant.log | tail -20

# Success rate today
openclaw agent metrics setup-assistant --today
```

### Dashboards

Access metrics dashboard:

```bash
open ~/.openclaw/metrics/setup-assistant-dashboard.html
```

Key metrics to track:

- **Setup success rate** (target: 95%+)
- **Average setup time** (target: <30 min)
- **Error rate by phase** (identify problem phases)
- **Escalation rate** (target: <10%)
- **User satisfaction** (post-setup survey)

### Alerts

Configure alerts for:

```bash
# High error rate
openclaw alert setup-assistant \
    --condition "error_rate > 20%" \
    --notify "admin@your-domain.com"

# Failed setups
openclaw alert setup-assistant \
    --condition "setup_failed" \
    --notify "sms:+1234567890"

# Credential abuse
openclaw alert setup-assistant \
    --condition "max_attempts_exceeded" \
    --notify "security@your-domain.com"
```

### Daily Reports

Schedule daily summary:

```bash
# Add to crontab
crontab -e

# Send report at 9 AM
0 9 * * * openclaw agent report setup-assistant --email admin@your-domain.com
```

---

## Troubleshooting

### Issue: Agent Not Responding

**Symptoms:** User texts trigger phrase, no response

**Diagnosis:**

```bash
# Check agent status
openclaw agent status setup-assistant

# Check if agent is enabled
openclaw agent list | grep setup-assistant

# Check recent logs
tail -50 ~/.openclaw/logs/openclaw.log
```

**Fix:**

```bash
# Restart agent
openclaw agent restart setup-assistant

# If still fails, re-register
openclaw agent unregister setup-assistant
openclaw agent register --config ~/.openclaw/agents/setup-assistant/agent-config.md
```

---

### Issue: SSH Connection Fails

**Symptoms:** "SSH connection failed" in logs

**Diagnosis:**

```bash
# Check token validity
./scripts/ssh-manager.sh status [TOKEN]

# Test SSH manually
ssh -i [KEY-PATH] user@[MAC-IP] echo "test"

# Check if user installed key
ssh user@[MAC-IP] 'cat ~/.ssh/authorized_keys'
```

**Fix:**

```bash
# Regenerate credential
./scripts/ssh-manager.sh revoke [OLD-TOKEN]
./scripts/ssh-manager.sh generate [USER-ID]

# Resend setup command to user
openclaw send --to [USER-PHONE] "[NEW-COMMAND]"
```

---

### Issue: Phase Fails Repeatedly

**Symptoms:** Same phase fails 3+ times

**Diagnosis:**

```bash
# View phase logs
./scripts/remote-setup.sh status [TOKEN]

# Check specific error
grep "Phase [N]" ~/.openclaw/logs/remote-setups/[TOKEN].log
```

**Fix:**

```bash
# Apply manual fix
ssh -i [KEY] user@[MAC-IP]

# Manually debug issue
cd ~/clawdbot-ready/SETUP\ GUIDES/openclaw-vm-setup
./setup.sh [PHASE]

# Once fixed, resume setup
./scripts/remote-setup.sh run [TOKEN] vm [PHASE]
```

---

### Issue: Exec-Approvals Blocking Valid Commands

**Symptoms:** "Command denied" for legitimate setup commands

**Diagnosis:**

```bash
# Check exec-approvals log
grep DENY ~/.openclaw/logs/setup-agent-exec.log

# Find blocked command
tail -20 ~/.openclaw/logs/setup-agent-exec.log
```

**Fix:**

Edit [`config/agent-exec-approvals.json`](config/agent-exec-approvals.json), add allow rule:

```json
{
  "id": "allow-new-command",
  "description": "Description of why this is needed",
  "binary": "/path/to/binary",
  "action": "allow",
  "argument_rules": {
    "allowed_args": ["safe", "args"]
  }
}
```

Reload config:

```bash
openclaw config reload
```

---

### Issue: High Escalation Rate

**Symptoms:** >20% of setups escalate to human

**Diagnosis:**

```bash
# Most common escalation reasons
grep "escalate" ~/.openclaw/logs/setup-assistant.log | \
    awk '{print $NF}' | sort | uniq -c | sort -rn
```

**Fix:**

Add auto-fixes for common errors:

Edit [`scripts/remote-setup.sh`](scripts/remote-setup.sh), add new error pattern:

```bash
detect_error() {
    # ... existing patterns ...

    elif echo "$output" | grep -qi "new error pattern"; then
        echo "new_error_type"
```

Add fix:

```bash
apply_fix() {
    # ... existing fixes ...

    new_error_type)
        log "$token" "Applying fix for new error"
        # Fix commands here
        success "Fix applied"
        return 0
        ;;
```

---

### Emergency Procedures

**If agent is compromised or misbehaving:**

```bash
# 1. Immediately disable agent
openclaw agent disable setup-assistant

# 2. Revoke all active credentials
./scripts/ssh-manager.sh cleanup
rm -rf ~/.openclaw/setup-assistant/ssh-creds/*

# 3. Create emergency stop file
touch ~/.openclaw/EMERGENCY_STOP

# 4. Review logs for suspicious activity
grep -i "suspicious\|unauthorized\|denied" ~/.openclaw/logs/setup-agent-exec.log

# 5. Notify security team
echo "Agent emergency stop triggered" | mail -s "SECURITY ALERT" security@your-domain.com
```

**To resume after emergency:**

```bash
# 1. Fix the issue
# 2. Remove emergency stop file
rm ~/.openclaw/EMERGENCY_STOP

# 3. Re-enable agent
openclaw agent enable setup-assistant

# 4. Monitor closely
tail -f ~/.openclaw/logs/setup-assistant.log
```

---

## Security Best Practices

1. **Credential Hygiene**
   - Run cleanup daily: `crontab -e` → `0 2 * * * /path/to/ssh-manager.sh cleanup`
   - Monitor for expired credentials not cleaned up

2. **Audit Logs**
   - Review exec-approvals log weekly
   - Investigate all denied commands
   - Look for patterns of suspicious activity

3. **Rate Limiting**
   - Monitor commands per minute
   - Alert on unusual spikes
   - Block users exceeding limits

4. **Human Oversight**
   - Review escalations weekly
   - Update auto-fixes based on patterns
   - Conduct monthly security audits

5. **Backup**
   - Backup state directory daily
   - Keep logs for 90 days minimum
   - Test restore procedures quarterly

---

## Support

### Documentation
- Agent Config: [`agent-config.md`](agent-config.md)
- Conversation Flow: [`conversation-flow.md`](conversation-flow.md)
- Setup Guides: `../../SETUP GUIDES/`

### Getting Help
- **Issues**: File in GitHub Issues
- **Security**: Email security@your-domain.com
- **General**: Join Discord/Slack community

### Enterprise Support
Contact for priority support, custom development, or white-label licensing.

---

## Changelog

### v1.0.0 (2026-02-02)
- Initial release
- VM and native deployment paths
- Auto-retry with error detection
- Temporary SSH credentials (2hr expiry)
- Comprehensive exec-approvals
- Friendly conversational agent
- Human escalation workflow

---

**Deployment checklist complete? You're ready to help users set up Clawdbot with zero technical knowledge! 🚀**
