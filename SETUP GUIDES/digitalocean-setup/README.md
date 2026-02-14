# OpenClaw on DigitalOcean (1-Click Deploy)

Automated setup guide for deploying OpenClaw on a DigitalOcean Droplet via the official 1-Click Marketplace image.

## Overview

DigitalOcean offers a [1-Click Deploy](https://marketplace.digitalocean.com/apps/moltbot) for OpenClaw — a pre-configured Droplet image with Docker isolation, firewall hardening, fail2ban, and gateway authentication baked in. This is the fastest path to a production-ready cloud OpenClaw instance.

**Best for:** Always-on cloud deployment, no hardware required, budget-friendly
**Cost:** Starting at $12/month (4 GB RAM / 2 vCPU Droplet)
**Requirements:**
- DigitalOcean account
- LLM provider API key (Anthropic, OpenAI, or Gradient)
- ~5 minutes for full setup

**Source:** [digitalocean.com/blog/moltbot-on-digitalocean](https://www.digitalocean.com/blog/moltbot-on-digitalocean)

## Platform Comparison

| Feature | VM-Isolated (Lume) | Native macOS | Cloudflare Workers | **DigitalOcean** |
|---------|--------------------|--------------|--------------------|------------------|
| Hardware required | Apple Silicon Mac | Apple Silicon Mac | None (cloud) | **None (cloud)** |
| Monthly cost | $0 (own hardware) | $0 (own hardware) | ~$35-40 | **$12-96** |
| iMessage support | Yes | Yes | No | **No** |
| Setup time | ~30 min | ~15 min | ~15 min | **~5 min** |
| Always-on | Requires Mac on | Requires Mac on | Yes (cloud) | **Yes (cloud)** |
| Global access | Via Tailscale | Via Tailscale | Built-in (edge) | **Droplet IP / Tailscale** |
| Isolation | VM boundary | Process-level | Container sandbox | **Docker container** |
| Persistence | Disk | Disk | R2 (5-min sync) | **Disk (block storage)** |
| Browser automation | No | No | Yes (CDP) | **No** |
| Admin UI | No | No | Yes (built-in) | **Yes (web dashboard)** |
| 1-Click deploy | No | No | No | **Yes** |

## Sizing Guide

| Usage Level | Droplet Size | RAM | CPU | Monthly Cost |
|-------------|-------------|-----|-----|-------------|
| Personal (1-5 users) | Basic | 4 GB | 2 vCPU | $12/mo |
| Small Team (5-20) | Basic | 8 GB | 4 vCPU | $24/mo |
| Medium Team (20-50) | Basic | 16 GB | 8 vCPU | $48/mo |
| Large Team (50+) | Basic | 32 GB | 16 vCPU | $96/mo |

## Quick Start

### Step 1: Deploy the Droplet

1. Go to the [OpenClaw Marketplace page](https://marketplace.digitalocean.com/apps/moltbot)
2. Click **Create OpenClaw Droplet**
3. Select a region close to your users
4. Choose a Droplet size (4 GB / 2 vCPU minimum)
5. Add your SSH key
6. Click **Create Droplet**

### Step 2: Connect via SSH

Wait ~60 seconds for provisioning to complete, then:

```bash
ssh root@YOUR_DROPLET_IP
```

A welcome message confirms OpenClaw is installed and ready for configuration.

### Step 3: Interactive Configuration

The first login triggers interactive setup:

1. **Select LLM provider** — Gradient, OpenAI, or Anthropic
2. **Paste your API key** — the key for your chosen provider
3. **Service auto-restarts** — OpenClaw applies the configuration
4. **Copy the dashboard URL** — shown in the welcome message

### Step 4: Access the Web Dashboard

Open the dashboard URL from Step 3 in your browser. This gives you:
- Live agent logs
- Configuration editor
- Channel management
- Device pairing

### Step 5: Configure Messaging Channels

#### Telegram

```bash
/opt/openclaw-cli.sh channels add
# Select Telegram
# Create bot via @BotFather → /newbot
# Paste bot token when prompted
# Add your Telegram user ID to the dashboard allowlist
```

#### WhatsApp

```bash
/opt/openclaw-cli.sh channels add
# Select WhatsApp
# Scan QR code with WhatsApp on your phone
```

#### Discord / Slack / Signal

Follow the same `channels add` flow — the CLI walks you through each provider's setup.

## Architecture

```
┌────────────────────────────────────────────────────────┐
│              DigitalOcean Droplet (Ubuntu 24.04)        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Docker Container                     │   │
│  │                                                   │   │
│  │  ┌──────────────────┐   ┌───────────────────┐   │   │
│  │  │  OpenClaw Gateway │   │  Node.js 22       │   │   │
│  │  │  Port 18789       │   │  Runtime          │   │   │
│  │  └──────────────────┘   └───────────────────┘   │   │
│  │          │                                       │   │
│  │  ┌───────┴──────────┐                           │   │
│  │  │  Web Dashboard   │                           │   │
│  │  │  Logs + Config   │                           │   │
│  │  └──────────────────┘                           │   │
│  └─────────────────────────────────────────────────┘   │
│                    │                                     │
│  ┌─────────────────┼───────────────────────────────┐   │
│  │  Host Security   │                               │   │
│  │  • UFW Firewall  │  • Non-root execution         │   │
│  │  • fail2ban      │  • Rate limiting               │   │
│  │  • Gateway token │  • Device pairing              │   │
│  └─────────────────────────────────────────────────┘   │
│                    │                                     │
└────────────────────┼────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │    Chat Channels        │
        │  Telegram  WhatsApp     │
        │  Discord   Slack        │
        │  Signal    Google Chat  │
        │  MS Teams               │
        └─────────────────────────┘
```

## Security Features (Built-In)

The 1-Click image comes pre-hardened with:

| Layer | Protection |
|-------|-----------|
| **Container Isolation** | OpenClaw runs in Docker, isolating agent execution from the host |
| **Gateway Authentication** | Unique token generated per deployment — only authorized clients connect |
| **Firewall (UFW)** | Locked-down rules, minimal open ports |
| **fail2ban** | Auto-blocks abusive traffic patterns (SSH brute-force, etc.) |
| **Non-root Execution** | Gateway process runs as unprivileged user inside the container |
| **Device Pairing** | Enabled by default — each messaging device must be explicitly approved |

## Management Commands

| Task | Command |
|------|---------|
| Check service status | `systemctl status openclaw` |
| View live logs | `journalctl -u openclaw -f` |
| Edit environment config | `nano /opt/openclaw.env` |
| Restart OpenClaw | `systemctl restart openclaw` |
| Open TUI dashboard | `/opt/openclaw-tui.sh` |
| Add channels | `/opt/openclaw-cli.sh channels add` |

## Manual Configuration

If you need to change settings after initial setup:

```bash
# Edit the environment file
nano /opt/openclaw.env

# Apply changes
systemctl restart openclaw
```

### Key Environment Variables

```bash
# LLM Provider (set during interactive setup)
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Gateway
OPENCLAW_GATEWAY_TOKEN=<auto-generated>
OPENCLAW_GATEWAY_PORT=18789

# Optional: Telegram
TELEGRAM_BOT_TOKEN=<from-botfather>

# Optional: Additional channels
DISCORD_BOT_TOKEN=
SLACK_BOT_TOKEN=
```

## Remote Access Options

### Option 1: Direct IP (Simple)

Access the dashboard and gateway directly via the Droplet's public IP:

```bash
# Dashboard
open http://YOUR_DROPLET_IP:18789/

# Note: Consider restricting access via UFW if on public internet
```

### Option 2: SSH Tunnel (Most Secure)

Forward the gateway port through SSH — zero public exposure:

```bash
# From your local machine
ssh -N -L 18789:127.0.0.1:18789 root@YOUR_DROPLET_IP

# Access at
open http://127.0.0.1:18789/

# Persistent tunnel with autossh
brew install autossh
autossh -M 0 -f -N -L 18789:127.0.0.1:18789 root@YOUR_DROPLET_IP
```

### Option 3: Tailscale (Best of Both Worlds)

Install Tailscale on the Droplet for private mesh networking:

```bash
# On the Droplet
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# From your local machine
open http://DROPLET_TAILSCALE_IP:18789/
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| SSH fails immediately after deploy | Wait 60 seconds — provisioning is still running |
| "Connection refused" on port 18789 | `systemctl status openclaw` to check if service is running |
| Gateway token not working | Check `/opt/openclaw.env` for the generated token |
| Channel not responding | Verify bot token and allowlist in the web dashboard |
| High memory usage | Upgrade Droplet size or reduce concurrent agent sessions |
| fail2ban locked you out | Access via DigitalOcean console, then `fail2ban-client set sshd unbanip YOUR_IP` |
| Need to reset everything | `systemctl stop openclaw && rm /opt/openclaw.env` then re-SSH to trigger fresh setup |

## Backups

### Droplet Snapshots

```bash
# Create a snapshot via doctl CLI
doctl compute droplet-action snapshot YOUR_DROPLET_ID --snapshot-name "openclaw-backup-$(date +%F)"

# Or use the DigitalOcean web console:
# Droplets → Your Droplet → Snapshots → Take Snapshot
```

### Automated Backups

Enable DigitalOcean's automated weekly backups for $2.40/month (20% of Droplet cost):
- Droplets → Your Droplet → Backups → Enable Backups

## Limitations

- **No iMessage**: Linux Droplets cannot run macOS, so no iMessage/BlueBubbles support
- **No Apple-specific features**: No access to macOS APIs, Shortcuts, Apple Keychain
- **No browser automation**: Standard Droplet doesn't include headless browser (unlike Cloudflare Workers)
- **Single region**: Droplet runs in one datacenter (unlike edge deployments)
- **Root access required**: Initial setup requires root SSH — set up a non-root user after deploy

## Directory Structure

```
digitalocean-setup/
├── README.md                   # This file
├── config/
│   └── settings.env            # Configuration template
├── scripts/
│   ├── status.sh               # Check Droplet + OpenClaw status
│   ├── logs.sh                 # View live OpenClaw logs
│   ├── backup.sh               # Create Droplet snapshot
│   ├── restart.sh              # Restart OpenClaw service
│   ├── channels.sh             # Add/manage messaging channels
│   └── teardown.sh             # Remove deployment
├── logs/                       # Local operation logs
└── PLANNING/
    ├── IMPLEMENTATION-MASTER-PLAN.md
    └── implementation-phases/
        ├── PHASE-0-PROMPT.md   # Prerequisites + account setup
        ├── PHASE-1-PROMPT.md   # Deploy 1-Click Droplet
        ├── PHASE-2-PROMPT.md   # Configure LLM provider
        ├── PHASE-3-PROMPT.md   # Set up messaging channels
        └── PHASE-4-PROMPT.md   # Verify + harden
```

## Related Resources

- [DigitalOcean Marketplace: OpenClaw](https://marketplace.digitalocean.com/apps/moltbot)
- [DigitalOcean Blog: OpenClaw on DigitalOcean](https://www.digitalocean.com/blog/moltbot-on-digitalocean)
- [OpenClaw Docs](https://docs.molt.bot/)
- [OpenClaw GitHub](https://github.com/moltbot/moltbot)
- [DigitalOcean: What is OpenClaw?](https://www.digitalocean.com/resources/articles/what-is-openclaw)
- [Clawdbot Deployment Guide](../clawdbot-deployment-guide.md)

## Need Help? Use the Setup Agent

If you prefer guided assistance, the **Clawdbot Setup Agent** can walk you through the DigitalOcean deployment via phone or chat — no command-line experience required.

The agent guides you through account creation, Droplet deployment, LLM configuration, and channel setup with friendly step-by-step instructions.

See [`../clawdbot-setup-agent/`](../clawdbot-setup-agent/) for details, or tell your Clawdbot: *"I want to deploy on DigitalOcean"*.

---

*Added: February 2026*
*Status: Production-Ready (1-Click Marketplace Image)*
