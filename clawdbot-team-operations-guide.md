# Clawdbot Team Operations Guide

> Multi-operator playbook for teams managing Clawdbot deployments

---

## Table of Contents

1. [Team Structure](#team-structure)
2. [Access Levels & Permissions](#access-levels--permissions)
3. [Onboarding Checklist](#onboarding-checklist)
4. [Daily Operations](#daily-operations)
5. [Deployment Workflows](#deployment-workflows)
6. [Incident Response](#incident-response)
7. [Security Protocols](#security-protocols)
8. [Communication Standards](#communication-standards)
9. [Handoff Procedures](#handoff-procedures)
10. [Quick Reference](#quick-reference)

---

## Team Structure

### Recommended Roles (Scale to Team Size)

```
┌─────────────────────────────────────────────────────────────────┐
│                      TEAM STRUCTURE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐                                               │
│   │   OWNER     │  Full admin access, billing, API keys         │
│   │  (1 person) │  Discord server owner privileges              │
│   └──────┬──────┘                                               │
│          │                                                       │
│   ┌──────┴──────┐                                               │
│   │  OPERATORS  │  Server management, deployments               │
│   │ (2-3 people)│  Configuration changes, monitoring            │
│   └──────┬──────┘                                               │
│          │                                                       │
│   ┌──────┴──────┐                                               │
│   │ MODERATORS  │  User management, content moderation          │
│   │ (3-4 people)│  Basic troubleshooting, escalation            │
│   └──────┬──────┘                                               │
│          │                                                       │
│   ┌──────┴──────┐                                               │
│   │  OBSERVERS  │  Read-only access, reporting                  │
│   │ (2-3 people)│  Analytics review, documentation              │
│   └─────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Role Responsibilities Matrix

| Responsibility | Owner | Operator | Moderator | Observer |
|----------------|:-----:|:--------:|:---------:|:--------:|
| API Key Management | ✅ | ❌ | ❌ | ❌ |
| Billing & Costs | ✅ | 👁️ | ❌ | ❌ |
| Deploy/Restart Bot | ✅ | ✅ | ❌ | ❌ |
| Configuration Changes | ✅ | ✅ | ❌ | ❌ |
| Discord Permissions | ✅ | ✅ | 👁️ | ❌ |
| User Whitelisting | ✅ | ✅ | ✅ | ❌ |
| View Logs | ✅ | ✅ | ✅ | ✅ |
| Respond to Incidents | ✅ | ✅ | ⚡ | 📢 |
| Documentation Updates | ✅ | ✅ | ✅ | ✅ |

**Legend:** ✅ Full | 👁️ View Only | ⚡ Escalate | 📢 Report | ❌ None

---

## Access Levels & Permissions

### Credential Distribution

```
┌────────────────────────────────────────────────────────────────┐
│                    CREDENTIAL TIERS                             │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  TIER 1 - OWNER ONLY (Never Share)                             │
│  ├── Anthropic API Key                                          │
│  ├── Discord Bot Token                                          │
│  ├── Server SSH Keys (root)                                     │
│  └── Billing Account Access                                     │
│                                                                 │
│  TIER 2 - OPERATORS (Secure Channel Only)                      │
│  ├── Server Access (non-root user)                             │
│  ├── Tailscale Join Key (single-use)                           │
│  ├── Docker Registry Credentials                                │
│  └── Monitoring Dashboard Login                                 │
│                                                                 │
│  TIER 3 - MODERATORS (Standard Distribution)                   │
│  ├── Discord Moderator Role                                     │
│  ├── Log Viewer Access                                          │
│  └── Status Dashboard URL                                       │
│                                                                 │
│  TIER 4 - OBSERVERS (Public-ish)                               │
│  ├── Read-only Dashboard                                        │
│  └── Documentation Access                                       │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### Access Request Process

1. **New team member** requests access via designated channel
2. **Owner/Operator** verifies identity and role assignment
3. **Credentials issued** via secure method (1Password, Bitwarden, etc.)
4. **Access logged** in team access ledger
5. **Confirmation** sent to team channel

### Access Revocation Checklist

When a team member leaves:

- [ ] Remove from Discord server roles
- [ ] Revoke Tailscale device authorization
- [ ] Remove SSH keys from authorized_keys
- [ ] Rotate any shared passwords they had access to
- [ ] Remove from monitoring/dashboard systems
- [ ] Update team access ledger
- [ ] Notify team of access changes

---

## Onboarding Checklist

### New Team Member Setup

#### All Roles
- [ ] Add to team communication channel (Slack/Discord)
- [ ] Share documentation repository access
- [ ] Provide status dashboard URL
- [ ] Review this operations guide
- [ ] Introduce to team async

#### Moderators (Additional)
- [ ] Assign Discord Moderator role
- [ ] Train on user whitelisting process
- [ ] Review escalation procedures
- [ ] Shadow existing moderator for 1 shift

#### Operators (Additional)
- [ ] Generate SSH key pair for server access
- [ ] Add public key to authorized_keys
- [ ] Issue Tailscale join invitation
- [ ] Walk through deployment process
- [ ] Perform supervised deployment
- [ ] Review incident response playbook

#### Owners (Additional)
- [ ] Full credential handoff (secure meeting)
- [ ] Billing account access transfer
- [ ] API key rotation procedure
- [ ] Emergency contact procedures

---

## Daily Operations

### Health Check Routine

```
┌─────────────────────────────────────────────────────────────────┐
│                    DAILY HEALTH CHECK                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  MORNING (Start of Shift)                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 1. Check bot online status in Discord                   │    │
│  │ 2. Review overnight logs for errors                     │    │
│  │ 3. Verify API usage within limits                       │    │
│  │ 4. Check server resource usage (CPU/RAM/Disk)           │    │
│  │ 5. Review any pending user requests                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  EVENING (End of Shift)                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 1. Log shift summary in ops channel                     │    │
│  │ 2. Note any ongoing issues for next shift               │    │
│  │ 3. Update incident tracker if applicable                │    │
│  │ 4. Confirm bot still responsive                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Shift Handoff Template

```markdown
## Shift Handoff - [DATE]

**Outgoing:** @username
**Incoming:** @username
**Time:** HH:MM UTC

### Status
- Bot: 🟢 Online / 🟡 Degraded / 🔴 Down
- Server: 🟢 Healthy / 🟡 Warning / 🔴 Critical

### Active Issues
- [ ] Issue description (link to thread)

### Completed This Shift
- Item 1
- Item 2

### Needs Attention
- Task requiring follow-up

### Notes
Any additional context for incoming operator
```

---

## Deployment Workflows

### Standard Deployment Process

```
┌─────────────────────────────────────────────────────────────────┐
│                  DEPLOYMENT WORKFLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. ANNOUNCE                                                     │
│     └── Post in ops channel: "Starting deployment"              │
│                                                                  │
│  2. PRE-FLIGHT                                                   │
│     ├── Backup current config                                   │
│     ├── Note current version/commit                             │
│     └── Verify rollback procedure                               │
│                                                                  │
│  3. DEPLOY                                                       │
│     ├── Pull latest changes                                     │
│     ├── Apply configuration                                     │
│     └── Restart service                                         │
│                                                                  │
│  4. VERIFY                                                       │
│     ├── Check bot comes online                                  │
│     ├── Test basic functionality                                │
│     ├── Review logs for errors                                  │
│     └── Monitor for 15 minutes                                  │
│                                                                  │
│  5. COMPLETE                                                     │
│     ├── Post in ops channel: "Deployment complete"              │
│     └── Document any issues encountered                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Commands Reference

```bash
# SSH into server (Operators only)
ssh clawdbot@your-server.com

# OR via Tailscale
ssh clawdbot@machine-name

# Check current status
sudo launchctl list | grep clawdbot
# OR for Docker
docker ps | grep clawdbot

# View recent logs
tail -100 ~/.clawdbot/logs/clawdbot.log

# Restart service (macOS)
sudo launchctl stop com.clawdbot.service
sudo launchctl start com.clawdbot.service

# Restart service (Docker)
docker compose restart

# Restart service (Linux systemd)
sudo systemctl restart clawdbot
```

### Rollback Procedure

If deployment fails:

1. **Stop** the new version immediately
2. **Restore** backed-up configuration
3. **Restart** with previous version
4. **Verify** functionality restored
5. **Document** what went wrong
6. **Notify** team of rollback

---

## Incident Response

### Severity Levels

| Level | Name | Description | Response Time | Escalation |
|-------|------|-------------|---------------|------------|
| S1 | Critical | Bot completely down, affecting all users | Immediate | Owner + All Operators |
| S2 | Major | Significant feature broken, many users affected | < 1 hour | On-call Operator |
| S3 | Minor | Single feature degraded, workaround exists | < 4 hours | Any Operator |
| S4 | Low | Cosmetic issue, no functional impact | Next business day | Document only |

### Incident Response Flowchart

```
┌─────────────────────────────────────────────────────────────────┐
│                 INCIDENT RESPONSE FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                    ┌──────────────┐                              │
│                    │ Issue        │                              │
│                    │ Detected     │                              │
│                    └──────┬───────┘                              │
│                           │                                      │
│                    ┌──────▼───────┐                              │
│                    │ Assess       │                              │
│                    │ Severity     │                              │
│                    └──────┬───────┘                              │
│                           │                                      │
│           ┌───────────────┼───────────────┐                     │
│           │               │               │                     │
│     ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐              │
│     │ S1/S2     │   │ S3        │   │ S4        │              │
│     │ ESCALATE  │   │ TRIAGE    │   │ DOCUMENT  │              │
│     │ NOW       │   │ & FIX     │   │ & QUEUE   │              │
│     └─────┬─────┘   └─────┬─────┘   └─────┬─────┘              │
│           │               │               │                     │
│     ┌─────▼─────┐   ┌─────▼─────┐         │                     │
│     │ War Room  │   │ Apply     │         │                     │
│     │ Response  │   │ Fix       │         │                     │
│     └─────┬─────┘   └─────┬─────┘         │                     │
│           │               │               │                     │
│           └───────────────┼───────────────┘                     │
│                           │                                      │
│                    ┌──────▼───────┐                              │
│                    │ Post-Mortem  │                              │
│                    │ (S1/S2 only) │                              │
│                    └──────────────┘                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Common Issues Quick Reference

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| Bot offline | Service crashed | Restart service |
| Bot online but not responding | Discord connection issue | Check Discord status, restart |
| Slow responses | API rate limiting | Check usage, wait for reset |
| "API Error" messages | Invalid/expired API key | Verify key in config |
| Permission denied errors | Discord role misconfigured | Check bot permissions |
| Out of memory | Memory leak or config issue | Restart, review logs |

### Incident Documentation Template

```markdown
## Incident Report - [DATE] - [TITLE]

### Summary
Brief description of what happened

### Timeline (UTC)
- HH:MM - Issue first detected
- HH:MM - Response initiated
- HH:MM - Root cause identified
- HH:MM - Fix applied
- HH:MM - Service restored

### Impact
- Users affected: X
- Duration: X minutes
- Features impacted: List

### Root Cause
Technical explanation of what went wrong

### Resolution
What was done to fix it

### Prevention
Steps to prevent recurrence

### Action Items
- [ ] Action item 1 - @owner
- [ ] Action item 2 - @owner
```

---

## Security Protocols

### Security Checklist

```
┌─────────────────────────────────────────────────────────────────┐
│                  SECURITY REQUIREMENTS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CREDENTIALS                                                     │
│  ├── ✅ API keys stored in environment variables only           │
│  ├── ✅ Never commit secrets to git                             │
│  ├── ✅ Rotate keys quarterly (or on team changes)              │
│  └── ✅ Use password manager for team credentials               │
│                                                                  │
│  ACCESS                                                          │
│  ├── ✅ SSH key-based auth only (no passwords)                  │
│  ├── ✅ Tailscale for remote access (no direct exposure)        │
│  ├── ✅ Principle of least privilege for all roles              │
│  └── ✅ Remove access immediately when team members leave       │
│                                                                  │
│  NETWORK                                                         │
│  ├── ✅ Bot binds to localhost/LAN only                         │
│  ├── ✅ No direct public internet exposure                      │
│  ├── ✅ HTTPS for any web interfaces                            │
│  └── ✅ Firewall rules reviewed monthly                         │
│                                                                  │
│  MONITORING                                                      │
│  ├── ✅ Log all admin actions                                   │
│  ├── ✅ Alert on authentication failures                        │
│  ├── ✅ Review access logs weekly                               │
│  └── ✅ Monitor for unusual API usage patterns                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Security Incident Response

If you suspect a security breach:

1. **STOP** - Do not make changes that could destroy evidence
2. **ISOLATE** - Disconnect affected systems if safe to do so
3. **ESCALATE** - Contact Owner immediately (phone if necessary)
4. **DOCUMENT** - Note everything you observe with timestamps
5. **PRESERVE** - Keep logs and don't restart services until directed

---

## Communication Standards

### Channel Structure

| Channel | Purpose | Who Posts |
|---------|---------|-----------|
| #ops-announcements | Deployments, maintenance windows | Operators, Owner |
| #ops-incidents | Active incident coordination | All team |
| #ops-general | Day-to-day operations discussion | All team |
| #ops-logs | Automated alerts and logs | Bots only |
| #handoff | Shift transitions | Operators |

### Communication Templates

#### Maintenance Announcement
```
🔧 **Scheduled Maintenance**

**When:** [DATE] [TIME] UTC
**Duration:** ~[X] minutes
**Impact:** [Brief description]
**Action Required:** None

Updates will be posted here.
```

#### Incident Start
```
🚨 **Incident Detected**

**Severity:** S[1-4]
**Status:** Investigating
**Impact:** [Brief description]
**Lead:** @username

Updates every [15/30/60] minutes.
```

#### Incident Resolved
```
✅ **Incident Resolved**

**Duration:** [X] minutes
**Root Cause:** [Brief]
**Resolution:** [What fixed it]

Post-mortem to follow for S1/S2.
```

---

## Handoff Procedures

### Shift Schedule Template

| Day | Shift 1 (00-08 UTC) | Shift 2 (08-16 UTC) | Shift 3 (16-24 UTC) |
|-----|---------------------|---------------------|---------------------|
| Mon | @operator1 | @operator2 | @operator3 |
| Tue | @operator2 | @operator3 | @operator1 |
| Wed | @operator3 | @operator1 | @operator2 |
| Thu | @operator1 | @operator2 | @operator3 |
| Fri | @operator2 | @operator3 | @operator1 |
| Sat | @operator3 | @operator1 | @operator2 |
| Sun | @operator1 | @operator2 | @operator3 |

### Handoff Checklist

Before going off-shift:
- [ ] Post shift summary in #handoff
- [ ] Document any ongoing issues
- [ ] Confirm incoming operator is available
- [ ] Direct handoff for any S1/S2 incidents

When coming on-shift:
- [ ] Read previous shift summary
- [ ] Review any open incidents
- [ ] Perform health check
- [ ] Acknowledge handoff in channel

---

## Quick Reference

### Emergency Contacts

| Role | Name | Contact | When to Use |
|------|------|---------|-------------|
| Owner | [Name] | [Phone/Signal] | S1 incidents, security issues |
| Primary Operator | [Name] | [Phone/Signal] | S1/S2 escalation |
| Backup Operator | [Name] | [Phone/Signal] | Primary unavailable |

### Important URLs

| Resource | URL |
|----------|-----|
| Status Dashboard | `https://your-dashboard.com` |
| Documentation | `https://github.com/Organized-AI/claudebotready` |
| Anthropic Status | `https://status.anthropic.com` |
| Discord Status | `https://discordstatus.com` |

### Command Cheat Sheet

```bash
# Status check
sudo launchctl list | grep clawdbot           # macOS
docker ps | grep clawdbot                      # Docker
sudo systemctl status clawdbot                 # Linux

# Restart
sudo launchctl kickstart -k system/com.clawdbot.service  # macOS
docker compose restart                         # Docker
sudo systemctl restart clawdbot                # Linux

# Logs
tail -f ~/.clawdbot/logs/clawdbot.log         # Follow logs
grep ERROR ~/.clawdbot/logs/clawdbot.log      # Find errors
journalctl -u clawdbot -f                      # Linux systemd

# Remote access
ssh user@machine                               # Direct SSH
ssh user@machine-name                          # Via Tailscale
```

### Escalation Path

```
Issue Detected
     │
     ▼
Can Moderator resolve? ──Yes──▶ Resolve & Document
     │
    No
     │
     ▼
Can Operator resolve? ──Yes──▶ Resolve & Document
     │
    No
     │
     ▼
Is it S1/S2? ──Yes──▶ Contact Owner IMMEDIATELY
     │
    No
     │
     ▼
Document & Queue for Owner review
```

---

## Appendix: Team Access Ledger

| Name | Role | Access Granted | Access Level | Granted By | Notes |
|------|------|----------------|--------------|------------|-------|
| [Name] | Owner | [Date] | Full | - | Primary owner |
| [Name] | Operator | [Date] | Tier 2 | @owner | - |
| [Name] | Moderator | [Date] | Tier 3 | @owner | - |

---

*Last Updated: [DATE]*
*Maintained by: [TEAM/OWNER]*

---

## Multi-User Configuration

> Essential configuration for running one Clawdbot instance serving multiple team members

### Session Isolation Configuration

Clawdbot supports per-user context isolation through `session.dmScope`:

```json
{
  "session": {
    "dmScope": "per-channel-peer",
    "identityLinks": {
      "discord:alice123": "alice@company.com",
      "slack:UALICE": "alice@company.com",
      "discord:bob456": "bob@company.com",
      "slack:UBOB": "bob@company.com"
    }
  }
}
```

**Session Scope Options:**

| Scope | Behavior | Use Case |
|-------|----------|----------|
| `per-channel-peer` | Each user gets isolated context per channel | Recommended for teams |
| `per-peer` | Same user shares context across channels | Cross-platform continuity |
| `shared` | All users share conversation context | Group collaboration |

### Access Control Patterns

#### Discord (Recommended for Teams)

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "guilds": {
        "GUILD_ID": {
          "allowedChannels": ["ask-claude", "engineering"],
          "allowedRoles": ["team-member", "admin"],
          "mentionRequired": true
        }
      },
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
```

#### WhatsApp Allowlist

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [
        "+15551111111",
        "+15552222222",
        "+15553333333",
        "+15554444444",
        "+15555555555",
        "+15556666666",
        "+15557777777",
        "+15558888888",
        "+15559999999",
        "+15550000000"
      ]
    }
  }
}
```

#### Telegram with Groups

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN",
      "dmPolicy": "allowlist",
      "allowFrom": ["123456789", "987654321"],
      "groupPolicy": "allowlist",
      "allowedGroups": ["-1001234567890"]
    }
  }
}
```

### Pairing Workflow (Self-Service Onboarding)

```
┌─────────────────────────────────────────────────────────────────┐
│                    DM PAIRING WORKFLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   1. New team member DMs the bot                                │
│      ↓                                                           │
│   2. Bot responds: "Your pairing code is: ABC123"               │
│      ↓                                                           │
│   3. User reports code to Operator via Slack/Teams              │
│      ↓                                                           │
│   4. Operator approves:                                          │
│      $ clawdbot pairing approve discord ABC123                  │
│      ↓                                                           │
│   5. User can now interact with bot ✅                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Commands:**
```bash
# List pending pairing requests
clawdbot pairing list --provider discord

# Approve a pairing
clawdbot pairing approve discord ABC123

# Revoke access
clawdbot pairing revoke discord USER_ID
```

### Rate Limiting for Teams

```json
{
  "rateLimits": {
    "perUser": {
      "messagesPerMinute": 10,
      "messagesPerHour": 60,
      "tokensPerDay": 50000
    },
    "global": {
      "concurrentRequests": 3,
      "requestsPerMinute": 50
    }
  }
}
```

### Message Queue Behavior

When multiple team members message simultaneously:

```
T=0s  User A sends message → Processing
T=0s  User B sends message → Queued (position 1)
T=0s  User C sends message → Queued (position 2)
T=3s  User A gets response → User B starts processing
T=6s  User B gets response → User C starts processing
```

**Key points:**
- Messages processed First-In-First-Out (FIFO)
- "Typing" indicator shows during processing
- No messages are dropped - all are queued
- Heavy usage may result in 5-30 second waits

### Audit Logging for Teams

```json
{
  "logging": {
    "audit": {
      "enabled": true,
      "logFile": "~/.clawdbot/logs/audit.log",
      "logEvents": [
        "message_received",
        "message_sent", 
        "tool_used",
        "rate_limit_hit"
      ],
      "includeUserIdentity": true,
      "includeTokenCounts": true
    }
  }
}
```

**Sample audit log:**
```
2026-01-27T10:30:00Z [discord:alice#1234] message_received channel=ask-claude tokens=150
2026-01-27T10:30:03Z [discord:alice#1234] tool_used tool=web_search
2026-01-27T10:30:05Z [discord:alice#1234] message_sent tokens=1200 latency=5.2s
```

### Cost Control for Teams

```json
{
  "costControls": {
    "monthlyBudget": 200,
    "warningThreshold": 0.8,
    "perUserLimits": {
      "dailyTokens": 50000,
      "monthlyTokens": 500000
    },
    "alerts": {
      "slack": "#billing-alerts",
      "email": "admin@company.com"
    }
  }
}
```

### Team Cost Estimation

| Team Size | Usage Level | Est. Monthly Cost |
|-----------|-------------|-------------------|
| 10 users | Light (10 msg/day/user) | $50 |
| 10 users | Medium (20 msg/day/user) | $100 |
| 10 users | Heavy (50 msg/day/user) | $250 |
| 10 users | Power (100 msg/day/user) | $500 |

### Adding New Team Members

**Via Allowlist:**
```bash
# WhatsApp
clawdbot config set channels.whatsapp.allowFrom --append "+15551234567"

# Telegram
clawdbot config set channels.telegram.allowFrom --append "123456789"
```

**Via Pairing:**
```bash
# User sends DM, gets code
clawdbot pairing approve discord XYZ789
```

**Via Discord Role:**
- Add user to server
- Assign `team-member` role
- User can now @mention bot in allowed channels

### Removing Team Members

```bash
# Remove from allowlist
clawdbot config set channels.whatsapp.allowFrom --remove "+15551234567"

# Revoke pairing
clawdbot pairing revoke discord USER_ID

# Clear user's session (optional)
clawdbot sessions clear discord:USER_ID
```

### Multi-User Session Commands

```bash
# List all active sessions
clawdbot sessions list

# View specific user's session
clawdbot sessions get discord:alice123

# Clear a user's context (fresh start)
clawdbot sessions clear discord:alice123

# View usage by user
clawdbot stats --by-user --period 7d
```

