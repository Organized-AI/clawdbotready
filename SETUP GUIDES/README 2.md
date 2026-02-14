# SETUP GUIDES

**Primary Focus**: OpenClaw agent deployment and Clawdbot setup on macOS

This directory contains the core deployment toolkits, setup agents, and customer-facing guides for deploying Clawdbot and OpenClaw agents.

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
- Hardware: Apple Silicon (M1/M2/M3/M4)
- OS: macOS Sequoia or later
- Network: Internet connection for initial setup
