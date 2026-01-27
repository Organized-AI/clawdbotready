# Clawdbot Documentation

Comprehensive documentation for deploying and configuring Clawdbot - a Claude-powered Discord bot.

## Documentation

### Core Guides
- **[Customer Setup Guide](clawdbot-customer-setup-guide.md)** - Complete 1,000+ line guide covering installation, configuration, and customization
- **[Deployment Guide](clawdbot-deployment-guide.md)** - 8 platform deployment options with step-by-step instructions

### Explainer Documents
Located in `/DOCUMENTATION/`:
- **[Deployment Architecture Explained](DOCUMENTATION/clawdbot-deployment-explained.md)** - Visual ASCII diagrams explaining deployment concepts
- **[SSH Tunnel Explained](DOCUMENTATION/ssh-tunnel-explained.md)** - How SSH tunnels provide secure remote access
- **[Tailscale Explained](DOCUMENTATION/tailscale-explained.md)** - Mesh VPN networking for always-on remote access

## Deployment Options

| Platform | Cost | iMessage | Always-on | Best For |
|----------|------|----------|-----------|----------|
| macOS Native | $0 | ✅ | Manual | iMessage users |
| Docker Local | $0 | ❌ | Manual | Portable setup |
| Fly.io | $10-15/mo | ❌ | ✅ | Production |
| Hetzner VPS | $5/mo | ❌ | ✅ | Budget hosting |
| GCP Free Tier | $0-5/mo | ❌ | ✅ | Enterprise |
| DigitalOcean | $6/mo | ❌ | ✅ | Simple VPS |
| macOS VM (Lume) | $0 | ✅ | ✅ | Isolation |

## Quick Start

1. Choose your platform from the [Deployment Guide](clawdbot-deployment-guide.md)
2. Follow the [Customer Setup Guide](clawdbot-customer-setup-guide.md)
3. Reference explainer docs for deeper understanding

## About

Part of the [Organized AI](https://github.com/Organized-AI) ecosystem.
