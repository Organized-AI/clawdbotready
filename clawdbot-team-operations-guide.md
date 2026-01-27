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
