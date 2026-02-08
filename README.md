# Clawdbot Ready - macOS Edition

## 🖥️ Deployment Options

This repository supports **two macOS deployment approaches** for Clawdbot on Apple Silicon:

### 1. 🔒 VM-Isolated (Recommended for Production)
**Maximum security with Lume hypervisor virtualization**

- ✅ Full VM-level isolation (stronger than containers)
- ✅ Separate Apple ID support (burner accounts)
- ✅ Easy snapshot/rollback
- ✅ Defense-in-depth security hardening
- ✅ iMessage support
- 📁 Setup: [`openclaw-vm-setup/`](openclaw-vm-setup/) toolkit
- 📖 Guide: [VM Security Hardening](openclaw-macos-vm-security-hardening-guide.md)

**Best for**: Multi-tenant deployments, production environments, maximum isolation

### 2. ⚡ Native macOS (Direct Install)
**Fastest setup, direct hardware access**

- ✅ Zero virtualization overhead
- ✅ Full hardware acceleration
- ✅ Simpler troubleshooting
- ✅ iMessage support
- ✅ Direct system integration
- ⚠️ Shares host system resources
- 📖 Guide: [Native macOS Lockdown](openclaw-native-macos-lockdown-guide.md)

**Best for**: Development, testing, single-user deployments, M1 Mac mini setups

---

## Platform Requirements
- **Hardware**: Apple Silicon (M1/M2/M3/M4)
- **OS**: macOS Sequoia or later
- **Network**: Internet connection for initial setup

For other deployment options (Docker, cloud platforms, x86 hosts), see the [main Clawdbot documentation](https://github.com/Organized-AI).

---

## Overview

Comprehensive documentation and automation toolkit for deploying Clawdbot - a Claude-powered messaging gateway - on macOS with both VM-isolated and native deployment options.

## Documentation

### Core Guides
- **[Customer Setup Guide](clawdbot-customer-setup-guide.md)** - Complete 1,000+ line guide covering installation, configuration, and customization
- **[Deployment Guide](clawdbot-deployment-guide.md)** - 8 platform deployment options with step-by-step instructions
- **[Team Operations Guide](clawdbot-team-operations-guide.md)** - Multi-operator playbook for teams up to 10+ people

### Explainer Documents
Located in `/DOCUMENTATION/`:
- **[Deployment Architecture Explained](DOCUMENTATION/clawdbot-deployment-explained.md)** - Visual ASCII diagrams explaining deployment concepts
- **[SSH Tunnel Explained](DOCUMENTATION/ssh-tunnel-explained.md)** - How SSH tunnels provide secure remote access
- **[Tailscale Explained](DOCUMENTATION/tailscale-explained.md)** - Mesh VPN networking for always-on remote access

## macOS Deployment Comparison

| Feature | VM-Isolated | Native macOS |
|---------|-------------|--------------|
| **Security** | Maximum (VM isolation) | Host-level |
| **Setup Time** | 30-45 min | 10-15 min |
| **iMessage** | ✅ Yes | ✅ Yes |
| **Performance** | Good (virtualized) | Excellent (native) |
| **Isolation** | Full VM boundary | Process-level |
| **Snapshots** | ✅ Yes | ❌ No |
| **Hardware Access** | Limited | Full |
| **Best For** | Production, multi-tenant | Development, testing |
| **Cost** | $0 | $0 |

## Other Deployment Options

For non-macOS deployments, see the broader ecosystem:

| Platform | Cost | iMessage | Always-on | Best For |
|----------|------|----------|-----------|----------|
| Docker Local | $0 | ❌ | Manual | Portable setup |
| Fly.io | $10-15/mo | ❌ | ✅ | Production |
| Hetzner VPS | $5/mo | ❌ | ✅ | Budget hosting |
| GCP Free Tier | $0-5/mo | ❌ | ✅ | Enterprise |
| DigitalOcean | $6/mo | ❌ | ✅ | Simple VPS |

## Team Operations

For teams managing Clawdbot deployments, the [Team Operations Guide](clawdbot-team-operations-guide.md) covers:

- **Team Structure** - 4-tier role system (Owner → Operator → Moderator → Observer)
- **Access Management** - Credential tiers and permission matrices
- **Onboarding/Offboarding** - Checklists for team changes
- **Daily Operations** - Health checks and shift handoffs
- **Incident Response** - Severity levels S1-S4 with escalation paths
- **Security Protocols** - Access control and monitoring requirements
- **Communication Standards** - Channel structure and templates

## Quick Start

### For VM-Isolated Deployment (Recommended)
1. Navigate to deployment toolkit: `cd 01-OPENCLAW-DEPLOYMENT/openclaw-vm-setup`
2. Review the [VM Security Hardening Guide](DOCUMENTATION/openclaw-macos-vm-security-hardening-guide.md)
3. Run the automated setup: `./setup.sh`
4. Follow the [Customer Setup Guide](clawdbot-customer-setup-guide.md) for Gateway configuration
5. For teams, review the [Team Operations Guide](clawdbot-team-operations-guide.md)

### For Native macOS Deployment
1. Navigate to deployment toolkit: `cd 01-OPENCLAW-DEPLOYMENT/openclaw-native-setup`
2. Review the [Native macOS Lockdown Guide](DOCUMENTATION/openclaw-native-macos-lockdown-guide.md)
3. Follow security hardening steps
4. Install Gateway directly on host
5. Configure according to [Customer Setup Guide](clawdbot-customer-setup-guide.md)

### General Resources
- [Deployment Guide](clawdbot-deployment-guide.md) - Compare all platform options
- [SSH Tunnel Explained](DOCUMENTATION/ssh-tunnel-explained.md) - Remote access architecture
- [Tailscale Explained](DOCUMENTATION/tailscale-explained.md) - VPN mesh networking

## About

Part of the [Organized AI](https://github.com/Organized-AI) ecosystem.
