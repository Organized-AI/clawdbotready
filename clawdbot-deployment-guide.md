# 🦞 Clawdbot Deployment Guide

## Platform Comparison

| Option | Cost | Best For | Complexity | Hardware |
|--------|------|----------|------------|----------|
| **macOS (Local)** | $0 | Personal use, full macOS capabilities | ⭐ Easy | M4 Mini / M1 MacBook |
| **macOS VM (Lume)** | $0 | Sandboxed isolation, iMessage | ⭐⭐ Medium | Apple Silicon Mac |
| **Docker (Local)** | $0 | Containerized, portable | ⭐⭐ Medium | Any machine |
| **Fly.io** | ~$10-15/mo | Quick cloud deploy, auto-HTTPS | ⭐⭐ Medium | Cloud |
| **Hetzner VPS** | ~$5/mo | Budget cloud, full control | ⭐⭐⭐ Advanced | Cloud |
| **GCP Compute Engine** | ~$5-12/mo | Enterprise, scalable | ⭐⭐⭐ Advanced | Cloud |

---

## Jordaaan's Recommended Setup: M4 Mac Mini + Tailscale

### Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    M4 Mac Mini (Office)                     │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Clawdbot      │    │   Gateway       │                │
│  │   Gateway       │───▶│   Port 18789    │                │
│  │   (launchd)     │    │                 │                │
│  └─────────────────┘    └─────────────────┘                │
│                              │                              │
└──────────────────────────────┼──────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
              SSH Tunnel            Tailscale
                    │                     │
                    ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                M1 MacBook Pro (Remote)                      │
│                                                             │
│  ┌─────────────────┐                                       │
│  │   Clawdbot      │    Access Gateway via:                │
│  │   macOS App     │───▶ • SSH: localhost:18789            │
│  │   (Remote Mode) │    • Tailscale: mac-mini:18789        │
│  └─────────────────┘    • Direct WS: ws://ip:18789         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Tailscale Setup (Recommended for Remote Access)

Tailscale creates a secure mesh VPN between your devices. No port forwarding, works from anywhere.

### Step 1: Install on M4 Mac Mini (Office)
```bash
# Install via Homebrew
brew install tailscale

# Start Tailscale and authenticate
sudo tailscale up

# Get your Tailscale IP
tailscale ip -4
# Example output: 100.64.0.1
```

### Step 2: Install on M1 MacBook Pro (Mobile)
```bash
# Install via Homebrew
brew install tailscale

# Start Tailscale and authenticate (same account)
sudo tailscale up

# Verify connection to Mac Mini
tailscale ping <mac-mini-tailscale-ip>
```

### Step 3: Access Clawdbot Remotely
```bash
# From M1 MacBook, access Gateway on M4 Mac Mini
open http://100.64.0.1:18789/

# Or use the Tailscale hostname
open http://mac-mini:18789/
```

### Tailscale MagicDNS (Optional)
Enable MagicDNS in Tailscale admin console for friendly hostnames:
- `mac-mini.tailnet-name.ts.net`

---

## Quick Start Commands

### Option 1: macOS Local (M4 Mac Mini) ⭐ RECOMMENDED
```bash
# Install Clawdbot
npm install -g clawdbot@latest

# Run onboarding + install daemon
clawdbot onboard --install-daemon

# Check status
clawdbot status

# Verify gateway is running
clawdbot gateway health

# Get gateway token
clawdbot gateway token
```

### Option 2: Docker (Any Platform)
```bash
# Clone the repo
git clone https://github.com/clawdbot/clawdbot.git
cd clawdbot

# Run setup script (builds image, runs onboarding, starts gateway)
./docker-setup.sh

# Or manual flow
docker build -t clawdbot:local -f Dockerfile .
docker compose run --rm clawdbot-cli onboard
docker compose up -d clawdbot-gateway

# Health check
docker compose exec clawdbot-gateway node dist/index.js health --token "$CLAWDBOT_GATEWAY_TOKEN"
```

### Option 3: Fly.io (Quick Cloud Deploy)
```bash
# Install flyctl
brew install flyctl

# Clone and create app
git clone https://github.com/clawdbot/clawdbot.git
cd clawdbot
fly apps create my-clawdbot

# Create persistent volume
fly volumes create clawdbot_data --size 1 --region iad

# Set secrets
fly secrets set CLAWDBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)
fly secrets set ANTHROPIC_API_KEY=sk-ant-...

# Deploy
fly deploy

# Access
fly open
```

### Option 4: Hetzner VPS (~$5/mo)
```bash
# SSH into your VPS
ssh root@YOUR_VPS_IP

# Install Docker
apt-get update
apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sh

# Clone and setup
git clone https://github.com/clawdbot/clawdbot.git
cd clawdbot

# Create persistent directories
mkdir -p /root/.clawdbot /root/clawd
chown -R 1000:1000 /root/.clawdbot /root/clawd

# Build and launch
docker compose build
docker compose up -d clawdbot-gateway

# Access via SSH tunnel from laptop
ssh -N -L 18789:127.0.0.1:18789 root@YOUR_VPS_IP
```

### Option 5: GCP Compute Engine
```bash
# Create VM
gcloud compute instances create clawdbot-gateway \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --boot-disk-size=20GB \
  --image-family=debian-12 \
  --image-project=debian-cloud

# SSH in
gcloud compute ssh clawdbot-gateway --zone=us-central1-a

# Install Docker
sudo apt-get update
sudo apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Follow Hetzner steps from here...
```

### Option 6: macOS VM (Lume - for iMessage)
```bash
# Install Lume
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"

# Add to PATH
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc && source ~/.zshrc

# Create VM
lume create clawdbot --os macos --ipsw latest

# After Setup Assistant, enable SSH in VM:
# System Settings → General → Sharing → Remote Login

# Get VM IP
lume get clawdbot

# SSH into VM and install Clawdbot
ssh youruser@192.168.64.x
npm install -g clawdbot@latest
clawdbot onboard --install-daemon

# Run headlessly
lume stop clawdbot
lume run clawdbot --no-display
```

---

## Remote Access Methods

### Method 1: Tailscale (Recommended ⭐)
```bash
# Install on both machines
brew install tailscale
sudo tailscale up

# On M4 Mac Mini - get Tailscale IP
tailscale ip -4  # e.g., 100.64.0.1

# On M1 MacBook - connect directly
open http://100.64.0.1:18789/
# Or with MagicDNS:
open http://mac-mini:18789/
```
**Why Tailscale?**
- Zero port forwarding
- Works from anywhere (coffee shop, mobile hotspot)
- End-to-end encrypted
- Free for personal use (up to 100 devices)

### Method 2: SSH Tunnel (Most Secure, No Install)
```bash
# From M1 MacBook, create tunnel to M4 Mac Mini
ssh -L 18789:127.0.0.1:18789 jordaaan@<mac-mini-ip>

# Access Gateway at
open http://127.0.0.1:18789/

# For persistent tunnel, use autossh
brew install autossh
autossh -M 0 -f -N -L 18789:127.0.0.1:18789 jordaaan@<mac-mini-ip>
```

### Method 3: Clawdbot macOS App (Remote Mode)
1. Install Clawdbot.app on M1 MacBook
2. Settings → Connection → Remote Mode
3. Enter M4 Mac Mini's IP or Tailscale hostname
4. App creates SSH tunnel automatically

---

## Configuration Files

### Gateway Config Location
```
~/.clawdbot/clawdbot.json
```

### Example Config
```json
{
  "gateway": {
    "bind": "lan",
    "port": 18789,
    "token": "your-secure-token"
  },
  "channels": {
    "whatsapp": {
      "dmPolicy": "allowlist",
      "allowFrom": ["+15551234567"]
    },
    "telegram": {
      "botToken": "YOUR_BOT_TOKEN"
    }
  },
  "models": {
    "default": "anthropic:claude-sonnet-4-20250514"
  }
}
```

---

## Launchd Management (macOS)

```bash
# Install as daemon
clawdbot gateway install

# Check daemon status
launchctl list | grep clawdbot

# Restart daemon
launchctl kickstart -k gui/$UID/com.clawdbot.gateway

# Stop daemon
launchctl bootout gui/$UID/com.clawdbot.gateway

# View logs
tail -f ~/.clawdbot/logs/gateway.log
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Gateway not starting | `clawdbot doctor` to diagnose |
| Can't connect remotely | Check firewall, verify port 18789 open |
| SSH tunnel drops | Use `autossh` or Tailscale instead |
| Token rejected | Regenerate with `clawdbot gateway token` |

---

## Docker Configuration (For VPS/Cloud Deployments)

### docker-compose.yml
```yaml
services:
  clawdbot-gateway:
    image: ${CLAWDBOT_IMAGE:-clawdbot:latest}
    build: .
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - HOME=/home/node
      - NODE_ENV=production
      - CLAWDBOT_GATEWAY_BIND=${CLAWDBOT_GATEWAY_BIND:-lan}
      - CLAWDBOT_GATEWAY_PORT=${CLAWDBOT_GATEWAY_PORT:-18789}
      - CLAWDBOT_GATEWAY_TOKEN=${CLAWDBOT_GATEWAY_TOKEN}
    volumes:
      - ${CLAWDBOT_CONFIG_DIR:-~/.clawdbot}:/home/node/.clawdbot
      - ${CLAWDBOT_WORKSPACE_DIR:-~/clawd}:/home/node/clawd
    ports:
      - "127.0.0.1:${CLAWDBOT_GATEWAY_PORT:-18789}:18789"
    command:
      [
        "node",
        "dist/index.js",
        "gateway",
        "--bind",
        "${CLAWDBOT_GATEWAY_BIND:-lan}",
        "--port",
        "${CLAWDBOT_GATEWAY_PORT:-18789}"
      ]
```

### .env Template
```bash
CLAWDBOT_IMAGE=clawdbot:latest
CLAWDBOT_GATEWAY_TOKEN=<generate-with-openssl-rand-hex-32>
CLAWDBOT_GATEWAY_BIND=lan
CLAWDBOT_GATEWAY_PORT=18789
CLAWDBOT_CONFIG_DIR=/root/.clawdbot
CLAWDBOT_WORKSPACE_DIR=/root/clawd
```

### fly.toml (For Fly.io)
```toml
app = "my-clawdbot"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  NODE_ENV = "production"
  CLAWDBOT_STATE_DIR = "/data"
  NODE_OPTIONS = "--max-old-space-size=1536"

[processes]
  app = "node dist/index.js gateway --allow-unconfigured --port 3000 --bind lan"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

[[vm]]
  size = "shared-cpu-2x"
  memory = "2048mb"

[mounts]
  source = "clawdbot_data"
  destination = "/data"
```

---

## Documentation Links

### Platform Guides
- [macOS Setup](https://docs.clawd.bot/platforms/macos)
- [macOS VM (Lume)](https://docs.clawd.bot/platforms/macos-vm)
- [Docker Installation](https://docs.clawd.bot/install/docker)
- [Fly.io Deployment](https://docs.clawd.bot/platforms/fly)
- [Hetzner VPS](https://docs.clawd.bot/platforms/hetzner)
- [GCP Compute Engine](https://docs.clawd.bot/platforms/gcp)

### Gateway & Configuration
- [Gateway Configuration](https://docs.clawd.bot/gateway/configuration)
- [Remote Access](https://docs.clawd.bot/gateway/remote)
- [Tailscale Integration](https://docs.clawd.bot/gateway/tailscale)
- [Security](https://docs.clawd.bot/gateway/security)

### Channels
- [WhatsApp](https://docs.clawd.bot/channels/whatsapp)
- [Telegram](https://docs.clawd.bot/channels/telegram)
- [Discord](https://docs.clawd.bot/channels/discord)
- [iMessage (BlueBubbles)](https://docs.clawd.bot/channels/imessage)

---

## Cost Summary

| Platform | Monthly Cost | Notes |
|----------|--------------|-------|
| macOS Local | $0 | Uses your existing hardware |
| macOS VM (Lume) | $0 | Uses your existing Mac |
| Docker Local | $0 | Uses your existing hardware |
| Fly.io | ~$10-15 | Includes 2GB RAM, auto-HTTPS |
| Hetzner | ~$5 | CX11 VPS, manual setup |
| GCP e2-micro | ~$0 | Free tier eligible, may OOM |
| GCP e2-small | ~$12 | 2 vCPU, 2GB RAM |

---

*Last Updated: January 2026*
*Domain: clawdbot.organizedai.vip*
