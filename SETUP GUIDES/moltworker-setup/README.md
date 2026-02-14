# OpenClaw on Cloudflare Workers (Moltworker)

Automated setup scripts for deploying OpenClaw as a Cloudflare Worker with sandboxed containers.

## Overview

This toolkit automates the deployment of OpenClaw on Cloudflare's infrastructure using [Moltworker](https://github.com/cloudflare/moltworker). Instead of managing your own hardware, the agent runs in a Cloudflare Sandbox container with persistent storage via R2.

**Best for:** Cloud-first deployment, no hardware required, global edge network
**Cost:** ~$35-40/month (Workers Paid plan + container runtime)
**Requirements:**
- Cloudflare account with Workers Paid plan ($5/month)
- Anthropic API key (or Cloudflare AI Gateway)
- Node.js 18+ and npm
- ~15 minutes for full setup

## Platform Comparison

| Feature | VM-Isolated (Lume) | Native macOS | Cloudflare Workers |
|---------|--------------------|--------------|--------------------|
| Hardware required | Apple Silicon Mac | Apple Silicon Mac | None (cloud) |
| Monthly cost | $0 (own hardware) | $0 (own hardware) | ~$35-40 |
| iMessage support | Yes | Yes | No |
| Setup time | ~30 min | ~15 min | ~15 min |
| Always-on | Requires Mac on | Requires Mac on | Yes (cloud) |
| Global access | Via Tailscale | Via Tailscale | Built-in (edge) |
| Isolation | VM boundary | Process-level | Container sandbox |
| Persistence | Disk | Disk | R2 (5-min sync) |
| Browser automation | No | No | Yes (CDP) |
| Admin UI | No | No | Yes (built-in) |

## Quick Start

```bash
# 1. Clone moltworker and enter directory
git clone https://github.com/cloudflare/moltworker.git
cd moltworker

# 2. Run the setup script (from this toolkit)
cp /path/to/moltworker-setup/config/settings.env .env.local
# Edit .env.local with your values

# 3. Or use the automated setup
./setup.sh all
```

## What It Does

The setup process runs through 6 phases:

| Phase | Description |
|-------|-------------|
| 0 | Verify prerequisites (Node.js, npm, Wrangler, CF account) |
| 1 | Clone moltworker and configure secrets |
| 2 | Enable Cloudflare Access (admin UI protection) |
| 3 | Deploy to Cloudflare Workers |
| 4 | Configure R2 persistence and chat channels |
| 5 | Verify deployment and pair devices |

## Directory Structure

```
moltworker-setup/
├── setup.sh                    # Master orchestration script
├── config/
│   ├── settings.env            # Your deployment configuration
│   └── exec-approvals.json     # Command allowlist (for agent)
├── scripts/
│   ├── status.sh               # Check deployment status
│   ├── deploy.sh               # Deploy/redeploy to Workers
│   ├── backup.sh               # Trigger R2 backup
│   ├── restart.sh              # Restart sandbox container
│   ├── logs.sh                 # View worker logs (wrangler tail)
│   ├── teardown.sh             # Remove deployment
│   └── set-secret.sh           # Helper to set wrangler secrets
├── logs/                       # Setup and operation logs
├── PLANNING/                   # Implementation planning
│   ├── IMPLEMENTATION-MASTER-PLAN.md
│   └── implementation-phases/
│       ├── PHASE-0-PROMPT.md   # Prerequisites verification
│       ├── PHASE-1-PROMPT.md   # Clone and configure
│       ├── PHASE-2-PROMPT.md   # Cloudflare Access setup
│       ├── PHASE-3-PROMPT.md   # Deploy to Workers
│       ├── PHASE-4-PROMPT.md   # R2 + chat channels
│       └── PHASE-5-PROMPT.md   # Verify and pair devices
└── README.md                   # This file
```

## Configuration

Edit `config/settings.env` before running setup:

```bash
# Required
ANTHROPIC_API_KEY=""            # Your Anthropic API key
MOLTBOT_GATEWAY_TOKEN=""        # Auto-generated if empty

# Cloudflare Access (for admin UI)
CF_ACCESS_TEAM_DOMAIN=""        # e.g. myteam.cloudflareaccess.com
CF_ACCESS_AUD=""                # Application Audience tag

# Optional: R2 Persistence
R2_ACCESS_KEY_ID=""
R2_SECRET_ACCESS_KEY=""
CF_ACCOUNT_ID=""

# Optional: Chat Channels
TELEGRAM_BOT_TOKEN=""
DISCORD_BOT_TOKEN=""
SLACK_BOT_TOKEN=""
SLACK_APP_TOKEN=""
```

## Usage

### Initial Setup

```bash
# Run all phases
./setup.sh all

# Or run phases individually
./setup.sh 0    # Verify prerequisites
./setup.sh 1    # Clone + configure secrets
./setup.sh 2    # Cloudflare Access
./setup.sh 3    # Deploy
./setup.sh 4    # R2 + channels
./setup.sh 5    # Verify + pair devices
```

### Daily Operations

```bash
# Check deployment status
./scripts/status.sh

# View live logs
./scripts/logs.sh

# Trigger R2 backup
./scripts/backup.sh

# Restart the sandbox container
./scripts/restart.sh

# Redeploy after changes
./scripts/deploy.sh

# Set a new secret
./scripts/set-secret.sh TELEGRAM_BOT_TOKEN "your-token"
```

### Emergency

```bash
# Remove the entire deployment
./scripts/teardown.sh
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Cloudflare Edge                        │
│                                                         │
│  ┌───────────────┐    ┌──────────────────────────┐     │
│  │  CF Access     │    │  Sandbox Container       │     │
│  │  (Auth Gate)   │───▶│  ┌──────────────────┐   │     │
│  └───────────────┘    │  │  OpenClaw Gateway │   │     │
│         │              │  │  Port 18789       │   │     │
│         │              │  └──────────────────┘   │     │
│         │              │          │               │     │
│  ┌──────┴──────┐      │  ┌───────┴────────┐    │     │
│  │  Admin UI   │      │  │  R2 Sync       │    │     │
│  │  /_admin/   │      │  │  (every 5 min) │    │     │
│  └─────────────┘      │  └────────────────┘    │     │
│                        └──────────────────────────┘     │
│         │                         │                      │
└─────────┼─────────────────────────┼──────────────────────┘
          │                         │
    ┌─────┴─────┐          ┌───────┴───────┐
    │  Browser  │          │  R2 Bucket    │
    │  (Admin)  │          │  (Backups)    │
    └───────────┘          └───────────────┘
          │
    ┌─────┴──────────────────────────────┐
    │         Chat Channels               │
    │  Telegram  Discord  Slack           │
    └─────────────────────────────────────┘
```

## Cost Breakdown

| Component | Monthly Cost |
|-----------|-------------|
| Workers Paid plan | $5.00 |
| Container memory (4 GiB 24/7) | ~$26.00 |
| Container CPU (~10% utilization) | ~$2.00 |
| Container disk (8 GB) | ~$1.50 |
| R2 storage (free tier) | $0.00 |
| Cloudflare Access (free) | $0.00 |
| **Total (always-on)** | **~$34.50** |

**Cost reduction:** Set `SANDBOX_SLEEP_AFTER=10m` to sleep the container when idle. Only pay for active minutes.

## Security Model

Moltworker uses a different security model than VM/native deployments:

| Layer | Protection |
|-------|-----------|
| Cloudflare Access | Identity-based auth for admin UI |
| Gateway Token | Secret token for Control UI access |
| Device Pairing | Explicit per-device approval required |
| Container Sandbox | Isolated from other Workers |
| R2 Encryption | Backups encrypted at rest |

## Need Help? Use the Setup Agent

If you prefer guided assistance, the **Clawdbot Setup Agent** can walk you through the Cloudflare Workers deployment via phone or chat — no Wrangler experience required.

The agent handles prerequisites validation, moltworker cloning, Cloudflare authentication, secret configuration, R2 setup, and channel pairing.

See [`../clawdbot-setup-agent/`](../clawdbot-setup-agent/) for details, or tell your Clawdbot: *"I want to deploy on Cloudflare Workers"*.

---

## Real-World Deployment Notes

Based on a successful deployment to MBA (M3 MacBook Air, 2026-02-12):

**What worked:**
- `npm run deploy` (not `wrangler deploy` directly) — uses custom build step
- OpenRouter as AI provider via legacy `AI_GATEWAY_BASE_URL` + `AI_GATEWAY_API_KEY` secrets
- `DEV_MODE=true` for initial testing (bypasses CF Access)
- Discord bot in pairing mode for channel setup

**Common issues:**
- Cloudflare API tokens may lack Workers permissions — use `wrangler login` (browser OAuth) instead
- Node 25+ can cause build issues — Node 22 LTS is safer
- First `wrangler deploy` builds a container image which takes 5-7 seconds

**Verification command:**
```bash
curl -s "https://YOUR-WORKER.workers.dev/"
# Expected: {"ok":true,"status":"running"}
```

---

## Limitations

- **No iMessage**: Cloudflare containers cannot run macOS, so no iMessage support
- **Cold starts**: Container takes 1-2 minutes to start from sleep
- **Ephemeral disk**: Without R2, data is lost on container restart
- **No Apple-specific features**: No access to macOS APIs, Shortcuts, etc.
- **Experimental**: Moltworker is a Cloudflare proof of concept, not production-supported
