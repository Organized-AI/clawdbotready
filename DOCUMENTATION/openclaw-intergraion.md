# 🦞 OpenClaw Gateway Integration

> Integrating the OpenClaw AI assistant gateway with Clawdbot Ready

---

## Overview

OpenClaw is a personal AI assistant gateway that powers Clawdbot's multi-channel messaging capabilities. This document covers how to integrate the OpenClaw gateway into your Clawdbot deployment.

**OpenClaw Stats:**
- ⭐ 117k GitHub stars
- 🦞 MIT Licensed
- 📱 Multi-channel: WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Teams, and more
- 🖥️ Platforms: macOS, Linux, Windows (WSL2), iOS, Android

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CLAWDBOT + OPENCLAW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   MESSAGING CHANNELS                                                        │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐             │
│   │WhatsApp │ │Telegram │ │  Slack  │ │ Discord │ │ Signal  │             │
│   └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘             │
│        │           │           │           │           │                   │
│        └───────────┴───────────┼───────────┴───────────┘                   │
│                                │                                           │
│                                ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────────┐ │
│   │                      OPENCLAW GATEWAY                               │ │
│   │                                                                     │ │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │ │
│   │   │  Sessions   │  │   Tools     │  │   Skills    │               │ │
│   │   │  Manager    │  │   Engine    │  │  Marketplace│               │ │
│   │   └─────────────┘  └─────────────┘  └─────────────┘               │ │
│   │                                                                     │ │
│   │   WebSocket Control Plane: ws://127.0.0.1:18789                    │ │
│   │                                                                     │ │
│   └──────────────────────────────┬──────────────────────────────────────┘ │
│                                  │                                         │
│                                  ▼                                         │
│   ┌─────────────────────────────────────────────────────────────────────┐ │
│   │                       AI MODEL PROVIDERS                            │ │
│   │                                                                     │ │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │ │
│   │   │  Anthropic  │  │   OpenAI    │  │   Other     │               │ │
│   │   │  Claude     │  │   GPT-4     │  │   Models    │               │ │
│   │   └─────────────┘  └─────────────┘  └─────────────┘               │ │
│   │                                                                     │ │
│   └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Installation Options

### Option 1: Git Submodule (Recommended)

Add OpenClaw as a git submodule to your Clawdbot Ready project:

```bash
cd "/Users/jordaaan/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready"

# Add OpenClaw as a submodule
git submodule add https://github.com/openclaw/openclaw.git openclaw-gateway

# Initialize and update
git submodule update --init --recursive

# Commit the submodule
git add .gitmodules openclaw-gateway
git commit -m "feat: add OpenClaw gateway as submodule"
```

### Option 2: Clone Separately

Clone OpenClaw alongside your project:

```bash
cd "/Users/jordaaan/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready"

# Clone into the project
git clone https://github.com/openclaw/openclaw.git openclaw-gateway
```

### Option 3: NPM Global Install

Install OpenClaw globally:

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick Setup

### Prerequisites

- **Node.js ≥ 22** (required)
- **pnpm** (recommended for source builds)
- **Anthropic API key** or **Claude Pro/Max subscription**

### Step 1: Install Dependencies

```bash
# If using submodule/clone
cd openclaw-gateway
pnpm install
pnpm ui:build
pnpm build
```

### Step 2: Run Onboarding Wizard

```bash
# Global install
openclaw onboard --install-daemon

# Or from source
pnpm openclaw onboard --install-daemon
```

### Step 3: Start Gateway

```bash
openclaw gateway --port 18789 --verbose
```

### Step 4: Configure Channels

Edit `~/.openclaw/openclaw.json`:

```json
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  },
  "channels": {
    "whatsapp": {
      "enabled": true,
      "allowFrom": ["+1234567890"]
    },
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN"
    },
    "discord": {
      "enabled": true,
      "token": "YOUR_DISCORD_BOT_TOKEN"
    }
  }
}
```

---

## Integration with Clawdbot VM Setup

For macOS VM deployments via Lume, integrate OpenClaw into the VM setup script:

### Add to `setup.sh`:

```bash
# Install OpenClaw Gateway
echo "Installing OpenClaw Gateway..."
npm install -g openclaw@latest

# Run onboarding (non-interactive for VM)
openclaw onboard --install-daemon --non-interactive

# Start gateway as background service
openclaw gateway --port 18789 --bind loopback &
```

### Add to `settings.env`:

```bash
# OpenClaw Gateway Configuration
OPENCLAW_PORT=18789
OPENCLAW_BIND=loopback
OPENCLAW_MODEL=anthropic/claude-opus-4-5

# Channel tokens (set these)
TELEGRAM_BOT_TOKEN=
DISCORD_BOT_TOKEN=
SLACK_BOT_TOKEN=
SLACK_APP_TOKEN=
```

---

## Key Features for Clawdbot

### Multi-Channel Support

| Channel | Status | Notes |
|---------|--------|-------|
| WhatsApp | ✅ | QR code pairing via Baileys |
| Telegram | ✅ | Bot token required |
| Discord | ✅ | Bot token + application setup |
| Slack | ✅ | Bolt SDK, requires app tokens |
| Signal | ✅ | Requires signal-cli |
| iMessage | ✅ | macOS only |
| Microsoft Teams | ✅ | Bot Framework setup |
| WebChat | ✅ | Built-in web interface |

### Security Features

- **DM Pairing** - Unknown senders receive pairing codes
- **Allowlists** - Control who can message your assistant
- **Sandboxing** - Docker isolation for non-main sessions
- **Tailscale Integration** - Secure remote access

### Skills Marketplace

OpenClaw supports a skills registry at **ClawdHub.com** - integrate with Clawdbot's skill selection during onboarding.

---

## Directory Structure After Integration

```
Clawdbot Ready/
├── DOCUMENTATION/
├── PLANNING/
│   ├── POSTHOG-INTEGRATION-PLAN.md
│   └── POSTHOG-CLOUD-VS-SELFHOST.md
├── openclaw-gateway/              # OpenClaw submodule/clone
│   ├── src/
│   ├── packages/
│   ├── skills/
│   ├── ui/
│   ├── docs/
│   ├── package.json
│   └── README.md
├── openclaw-vm-setup/
│   ├── config/
│   │   └── settings.env
│   ├── setup.sh
│   └── ...
└── README.md
```

---

## Chat Commands Reference

| Command | Description |
|---------|-------------|
| `/status` | Session status (model, tokens, cost) |
| `/new` or `/reset` | Reset session |
| `/compact` | Compact session context |
| `/think <level>` | Set thinking level (off/low/medium/high) |
| `/verbose on/off` | Toggle verbose mode |
| `/usage off/tokens/full` | Set usage footer |
| `/restart` | Restart gateway (owner-only) |
| `/activation mention/always` | Group activation toggle |

---

## PostHog Analytics Integration

Combine OpenClaw with your PostHog integration:

```typescript
// Track OpenClaw gateway events
analytics.track('gateway_started', {
  port: 18789,
  channels: ['whatsapp', 'telegram', 'discord'],
  model: 'anthropic/claude-opus-4-5'
}, gatewayId);

// Track channel connections
analytics.track('channel_connected', {
  channel: 'whatsapp',
  method: 'qr_scan'
}, gatewayId);

// Track message processing
analytics.track('message_processed', {
  channel: 'telegram',
  responseTime: 1.2,
  tokensUsed: 450
}, sessionId);
```

---

## Resources

- **OpenClaw Repo:** https://github.com/openclaw/openclaw
- **Documentation:** https://docs.openclaw.ai
- **Getting Started:** https://docs.openclaw.ai/start/getting-started
- **Configuration:** https://docs.openclaw.ai/gateway/configuration
- **Security Guide:** https://docs.openclaw.ai/gateway/security
- **Discord Community:** https://discord.gg/clawd
- **ClawdHub Skills:** https://clawdhub.com

---

*Last Updated: January 2026*
*Project: Clawdbot Ready - clawdbot.organizedai.vip*