# Clawdbot Setup Assistant Agent

**Version**: 1.1.0
**Status**: Ready for Deployment
**Last Updated**: 2026-02-12

## Overview

An AI-powered setup assistant that guides non-technical users through Clawdbot deployment via phone call. The agent provides **full autonomous terminal automation** with temporary SSH access, eliminating the need for users to understand technical details.

### Key Features

- **Phone-based guidance** via iMessage/WhatsApp integration
- **Automated terminal execution** via temporary SSH credentials
- **Friendly, patient assistance** with non-technical explanations
- **Multi-path support** (VM, native macOS, DigitalOcean, Cloudflare, NanoClaw)
- **Intelligent error handling** with auto-retry and rollback
- **Human escalation** when needed
- **Security-first design** using exec-approvals

---

## Architecture

```
User's Phone
    ↓ (calls setup hotline)
OpenClaw Gateway (your infrastructure)
    ↓ (agent receives call)
Clawdbot Setup Assistant Agent
    ↓ (generates temp SSH credentials)
User's Mac (via SSH tunnel)
    ↓ (runs setup.sh phases)
OpenClaw Deployed ✅
```

### Components

1. **Agent Core** ([`agent-config.md`](agent-config.md)) - Main agent prompt and behavior
2. **SSH Access Layer** ([`scripts/ssh-manager.sh`](scripts/ssh-manager.sh)) - Temporary credential generation
3. **Execution Engine** ([`scripts/remote-setup.sh`](scripts/remote-setup.sh)) - Remote command runner
4. **Decision Tree** ([`conversation-flow.md`](conversation-flow.md)) - Conversation logic
5. **Error Handler** ([`scripts/error-handler.sh`](scripts/error-handler.sh)) - Troubleshooting automation
6. **Security Config** ([`config/agent-exec-approvals.json`](config/agent-exec-approvals.json)) - Command allowlist

---

## Quick Start

### Prerequisites

- OpenClaw Gateway deployed on your infrastructure
- Phone number connected to OpenClaw (iMessage/WhatsApp)
- User has macOS Sequoia+ on Apple Silicon

### Installation

```bash
# 1. Copy agent config to your OpenClaw deployment
cp agent-config.md ~/.openclaw/agents/setup-assistant.md

# 2. Copy execution scripts
cp -r scripts ~/.openclaw/agents/setup-assistant/

# 3. Copy security config
cp config/agent-exec-approvals.json ~/.openclaw/config/

# 4. Restart OpenClaw Gateway
openclaw restart
```

### Usage

**For Users:**
1. Call the setup hotline: `[YOUR PHONE NUMBER]`
2. Say: "I want to set up Clawdbot"
3. Follow voice instructions
4. Wait for confirmation SMS when complete

**For the Agent:**
- Agent automatically activates on trigger phrase
- Guides user through SSH setup
- Runs all phases autonomously
- Sends progress updates
- Notifies on completion or errors

---

## How It Works

### Phase 1: Initial Contact

```
User: "Hi, I want to set up Clawdbot"
Agent: "Great! I'm here to help. I'll guide you through setting up
        Clawdbot on your Mac. This will take about 20-30 minutes,
        and I'll handle all the technical stuff for you.

        First, let me ask a few quick questions:
        1. Do you want maximum security (VM setup) or maximum
           performance (native setup)?
        2. Is your Mac connected to WiFi right now?
        3. Do you know your Mac's admin password?"
```

### Phase 2: SSH Access Setup

```
Agent: "Perfect! Now I'll need temporary access to your Mac's
        terminal to run the installation. Don't worry - this
        access expires in 2 hours and only allows setup commands.

        Here's what to do:
        1. Open the Terminal app (it's in Applications/Utilities)
        2. I'll send you a command to copy and paste
        3. Press Enter and provide your password when asked

        Ready? I'm sending the command now..."

[Agent generates temporary SSH key and sends command via SMS]

curl -fsSL https://[YOUR-SERVER]/setup-ssh | bash -s [TEMP-TOKEN]
```

### Phase 3: Autonomous Setup

```
Agent: "Great! I'm connected. I can see your Mac now.
        Let me check your system...

        ✅ macOS Sequoia detected
        ✅ Apple M4 processor
        ✅ 65GB free space (need 60GB)
        ✅ Internet connection active

        Everything looks good! Starting setup now. I'll keep you
        updated every few minutes. Feel free to put me on speaker
        and do other things - I've got this!"

[Agent runs setup.sh with progress callbacks]

Agent: "Phase 1 complete - Lume installed and VM creating...
        This part takes about 10 minutes, so I'll check back
        when it's ready. You'll hear a ding when I have an update!"
```

### Phase 4: Error Handling

```
[If error occurs]

Agent: "Hmm, I ran into a small issue during Phase 4. The OpenClaw
        installation couldn't find the 'openclaw' command. Let me
        fix that real quick..."

[Agent applies PATH fix from troubleshooting guide]

Agent: "Fixed! That was a PATH configuration issue - basically
        your Mac didn't know where to find the new software.
        Continuing now..."
```

### Phase 5: Completion

```
Agent: "All done! 🎉 Your Clawdbot is now running securely in a
        VM on your Mac. Here's what I set up:

        ✅ Isolated VM with 50GB storage
        ✅ SSH security hardening
        ✅ Firewall rules (localhost-only)
        ✅ OpenClaw Gateway running
        ✅ Monitoring system active
        ✅ Automated backups configured

        I'm sending you a welcome message from your new Clawdbot
        right now! Try texting your bot's number and say hello.

        My temporary access expired automatically. Your Mac is
        all yours again. Enjoy your new AI assistant!"
```

---

## Security Model

### Temporary SSH Credentials

- **Time-limited**: 2-hour expiration (setup typically takes 20-30 min)
- **Single-use**: Key invalidated after successful setup
- **Revocable**: User can kill access anytime with `pkill -f setup-assistant`
- **Audit logged**: All commands logged to `~/.openclaw/logs/setup-audit.log`

### Command Execution

Agent uses **enhanced exec-approvals** with setup-specific permissions:

```json
{
  "context": "setup-assistant-agent",
  "allowed_commands": [
    "/path/to/setup.sh",
    "brew", "lume", "ssh-keygen", "chmod", "mkdir",
    "curl (setup sources only)", "git clone (project repo only)"
  ],
  "forbidden_commands": [
    "rm -rf /", "sudo su", "format", "dd", "any payment/banking apps"
  ]
}
```

### Rollback Safety

Each phase creates a snapshot:
- VM snapshots before Phase 2, 4, 6
- Config backups before changes
- One-command rollback: `./scripts/rollback.sh phase-3`

### Human Escalation

Agent escalates to human support if:
- 3+ consecutive errors in same phase
- User explicitly requests human help
- Security alert triggered (suspicious commands)
- Timeout exceeded (40+ minutes)

---

## Configuration

### Agent Personality

Edit [`agent-config.md`](agent-config.md) to customize:

```markdown
## Personality

- **Tone**: Friendly, patient, encouraging
- **Language**: Non-technical, uses analogies
- **Pacing**: Gives updates every 2-3 minutes during long tasks
- **Humor**: Light jokes OK, but keep it professional
- **Empathy**: Acknowledge user's patience, celebrate progress
```

### Deployment Paths

Configured in [`conversation-flow.md`](conversation-flow.md):

- **VM Setup** (default for production): Uses `SETUP GUIDES/openclaw-vm-setup/`
- **Native Setup** (dev/testing): Uses `SETUP GUIDES/openclaw-native-setup/`
- **DigitalOcean** (fastest cloud): Uses `SETUP GUIDES/digitalocean-setup/`
- **Cloudflare Workers** (edge/global): Uses `SETUP GUIDES/moltworker-setup/`
- **NanoClaw** (lightweight personal): Uses `SETUP GUIDES/nanoclaw-setup/`

### Error Recovery

Edit [`scripts/error-handler.sh`](scripts/error-handler.sh) to add patterns:

```bash
# Pattern: Command not found
if [[ "$error" == *"command not found"* ]]; then
    apply_path_fix  # From v2.2.0 lessons learned
    retry_command
fi

# Pattern: Insufficient disk space
if [[ "$error" == *"No space left"* ]]; then
    notify_user "Need to free up space. Pausing setup..."
    escalate_to_human
fi
```

---

## Testing

### Test Without Real User

```bash
# Simulate user connection
./test/simulate-user.sh

# Run agent in test mode
openclaw agent run setup-assistant --test-mode

# Check logs
tail -f ~/.openclaw/logs/setup-assistant.log
```

### Manual Test Phases

```bash
# Test Phase 1 only (Lume + VM)
./test/test-phase.sh 1

# Test error handling
./test/inject-error.sh "command-not-found" --phase 4

# Test rollback
./test/test-rollback.sh --from-phase 5
```

---

## Monitoring

Agent provides real-time metrics:

- **Active setups**: `openclaw agent stats setup-assistant`
- **Success rate**: Tracked in `~/.openclaw/metrics/setup-success.json`
- **Common errors**: Aggregated in `~/.openclaw/metrics/error-patterns.json`
- **Average time**: Per-phase timing data

### Alerts

Agent sends alerts to your phone when:
- ✅ Setup completes successfully
- ⚠️ Error requires manual intervention
- 🚨 Security violation detected
- 📊 Daily summary (X setups today, Y% success rate)

---

## Troubleshooting

### Agent Not Responding

```bash
# Check agent status
openclaw agent status setup-assistant

# View logs
tail -f ~/.openclaw/logs/setup-assistant.log

# Restart agent
openclaw agent restart setup-assistant
```

### SSH Connection Fails

```bash
# Check temp credentials
./scripts/ssh-manager.sh list-active

# Regenerate credentials
./scripts/ssh-manager.sh regenerate [USER-TOKEN]

# Test connection manually
ssh -i /tmp/setup-temp-key user@[MAC-IP]
```

### Setup Hangs

```bash
# View current phase
./scripts/remote-setup.sh status [USER-TOKEN]

# Kill and restart from checkpoint
./scripts/remote-setup.sh kill [USER-TOKEN]
./scripts/remote-setup.sh resume [USER-TOKEN] --from-phase 3
```

---

## Roadmap

### v1.1 (Current)
- [x] DigitalOcean 1-Click cloud deployment path
- [x] Cloudflare Workers edge deployment path
- [x] NanoClaw lightweight personal assistant path
- [x] All 5 deployment paths integrated

### v1.2 (Next)
- [ ] WhatsApp Business API integration
- [ ] Multi-language support (Spanish, French)
- [ ] Video call option for screen sharing
- [ ] Automatic system requirement detection

### v2.0 (Future)
- [ ] Group setup (multiple users, one call)
- [ ] White-label customization
- [ ] ClawHost Hetzner VPS integration

---

## Credits

**Built for**: Jordan's Clawdbot Ready project
**Based on**: OpenClaw Gateway v2026.1.30
**Incorporates**: openclaw-onboarding skill v2.2.0 lessons
**Security model**: exec-approvals deny-by-default
**Deployment guides**: All 5 paths — `openclaw-vm-setup/`, `openclaw-native-setup/`, `digitalocean-setup/`, `moltworker-setup/`, `nanoclaw-setup/`

---

## Support

- **Documentation**: See [`docs/`](docs/) folder
- **Issues**: File in project's GitHub Issues
- **Community**: Join Clawdbot Discord
- **Enterprise**: Contact for white-label licensing

---

## License

[YOUR LICENSE HERE]

---

**Ready to deploy? Start with the [Installation Guide](docs/INSTALLATION.md)**
