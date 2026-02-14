# SETUP GUIDES

**Primary Focus**: AI agent deployment — OpenClaw, NanoClaw, and Clawdbot setup across macOS, cloud, and edge

This directory contains deployment toolkits, setup agents, and customer-facing guides for deploying AI agent environments on macOS and cloud platforms.

## Deployment Toolkits

### [`openclaw-vm-setup/`](openclaw-vm-setup/)
**VM-Isolated Deployment** (Recommended for Production)

Full Lume hypervisor virtualization for maximum security:
- VM-level isolation
- Separate Apple ID support (burner accounts)
- Easy snapshot/rollback
- Defense-in-depth security hardening
- iMessage support

**Best for**: Multi-tenant deployments, production environments, maximum isolation

**Quick Start**:
```bash
cd openclaw-vm-setup
./setup.sh all
```

See [openclaw-vm-setup/PLANNING/](openclaw-vm-setup/PLANNING/) for Phase 0-8 implementation details.

---

### [`nanoclaw-setup/`](nanoclaw-setup/)
**NanoClaw — Lightweight Personal Claude Assistant** (Container-Isolated)

A minimalist alternative to OpenClaw built on Claude Agent SDK, accessible via WhatsApp:
- Single Node.js process (~18 source files, 7 dependencies)
- OS-level container isolation (Apple Container or Docker)
- Per-group memory and filesystem isolation
- Scheduled tasks, agent swarms, browser automation
- WhatsApp as primary channel (Telegram/Slack via skills)

**Best for**: Personal use, single-user deployments, lightweight setups

**Quick Start**:
```bash
git clone https://github.com/qwibitai/nanoclaw.git && cd nanoclaw
claude
# Then run: /setup
```

See [nanoclaw-setup/PLANNING/](nanoclaw-setup/PLANNING/) for Phase 0-8 implementation details.

**Source**: [github.com/qwibitai/nanoclaw](https://github.com/qwibitai/nanoclaw)

---

### [`openclaw-native-setup/`](openclaw-native-setup/)
**Native macOS Deployment** (Direct Install)

Direct installation on host macOS for fastest performance:
- Zero virtualization overhead
- Full hardware acceleration
- Simpler troubleshooting
- iMessage support
- Shares host system resources (less isolation)

**Best for**: Development, testing, single-user deployments, M1 Mac mini setups

**Quick Start**:
```bash
cd openclaw-native-setup
# See setup scripts in scripts/
```

---

## Cloud Deployment Toolkits

### [`digitalocean-setup/`](digitalocean-setup/)
**DigitalOcean 1-Click Deploy** (Fastest Cloud Option)

Pre-hardened Droplet image from the DigitalOcean Marketplace:
- 1-Click deploy with interactive first-login setup
- Docker container isolation
- UFW firewall + fail2ban + non-root execution
- Gateway authentication + device pairing
- Starting at $12/month

**Best for**: Always-on cloud deployment, no hardware required, budget-friendly

**Quick Start**: Deploy from the [DigitalOcean Marketplace](https://marketplace.digitalocean.com/apps/moltbot), then SSH in.

See [digitalocean-setup/PLANNING/](digitalocean-setup/PLANNING/) for Phase 0-4 implementation details.

---

### [`moltworker-setup/`](moltworker-setup/)
**Cloudflare Workers Deployment** (Edge / Sandbox)

OpenClaw running in a Cloudflare sandbox container with R2 persistence:
- Global edge network
- Browser automation (CDP)
- Built-in admin UI
- ~$35-40/month

**Best for**: Cloud-first, global access, browser automation use cases

---

### [`clawhost-setup-guide.md`](clawhost-setup-guide.md)
**ClawHost — Hetzner VPS One-Click** (Tier 1)

Self-hostable cloud platform for deploying OpenClaw on Hetzner VPS:
- One-click deploy with automatic DNS + SSL
- White-label ready
- Starting at ~$5/month

**Best for**: Budget cloud deployments, Tier 1 customers

---

## Setup Agent

### [`clawdbot-setup-agent/`](clawdbot-setup-agent/)
**AI-Powered Setup Assistant**

An autonomous AI agent that guides non-technical users through Clawdbot deployment:
- Phone-based setup guidance
- Automated terminal execution via SSH
- Conversation flow with decision trees
- Security-first command allowlisting

See [clawdbot-setup-agent/README.md](clawdbot-setup-agent/README.md) for details.

---

## Customer-Facing Guides

### [`clawdbot-customer-setup-guide.md`](clawdbot-customer-setup-guide.md)
Comprehensive customer-facing setup documentation covering all messaging platform integrations (WhatsApp, Telegram, Discord, Slack, iMessage).

### [`clawdbot-deployment-guide.md`](clawdbot-deployment-guide.md)
Platform comparison guide (macOS local, VM, Docker, cloud) with recommended deployment architecture.

---

## Related Documentation

All additional deployment guides are in [`../DOCUMENTATION/`](../DOCUMENTATION/):
- [VM Security Hardening](../DOCUMENTATION/openclaw-macos-vm-security-hardening-guide.md)
- [Native macOS Lockdown](../DOCUMENTATION/openclaw-native-macos-lockdown-guide.md)
- [SSH Tunnel Setup](../DOCUMENTATION/ssh-tunnel-explained.md)
- [Tailscale Integration](../DOCUMENTATION/tailscale-explained.md)
- [Telegram Bot Setup](../DOCUMENTATION/telegram-channel-troubleshooting.md)

## Automation Scripts

Standalone OpenClaw automation scripts are in [`../scripts/`](../scripts/):
- `auto-deploy-openclaw.sh` - Automated deployment
- `install-openclaw.sh` - Installation script
- `openclaw-health-monitor.sh` - Health monitoring
- `setup-openclaw-autostart.sh` - LaunchAgent setup

---

**Platform Requirements**:
- **macOS toolkits**: Apple Silicon (M1/M2/M3/M4), macOS Sequoia or later
- **Cloud toolkits**: DigitalOcean account, Cloudflare account, or Hetzner account
- **All platforms**: Internet connection, LLM provider API key
