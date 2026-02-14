# 🦞 Clawdbot Setup & Configuration Guide

> **Your AI Employee, Delivered**
> 
> Official setup documentation for [clawdbot.organizedai.vip](https://clawdbot.organizedai.vip)

---

## Table of Contents

1. [What is Clawdbot?](#what-is-clawdbot)
2. [Architecture Overview](#architecture-overview)
3. [Choose Your Platform](#choose-your-platform)
4. [Setup Instructions](#setup-instructions)
5. [Configuration](#configuration)
6. [Remote Access](#remote-access)
7. [Channel Integrations](#channel-integrations)
8. [Troubleshooting](#troubleshooting)

---

## What is Clawdbot?

Clawdbot is a self-hosted AI agent gateway that connects to your favorite messaging platforms (WhatsApp, Telegram, Discord, Slack, iMessage) and executes tasks using AI models like Claude, GPT-4, and others.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLAWDBOT ECOSYSTEM                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   📱 Messaging Channels          🧠 AI Models           🔧 Tools        │
│   ┌─────────────────┐           ┌─────────────┐       ┌─────────────┐  │
│   │ WhatsApp        │           │ Claude      │       │ Browser     │  │
│   │ Telegram        │           │ GPT-4       │       │ File System │  │
│   │ Discord         │──────────▶│ Gemini      │──────▶│ Code Exec   │  │
│   │ Slack           │           │ Local LLMs  │       │ Web Search  │  │
│   │ iMessage        │           └─────────────┘       │ Custom      │  │
│   └─────────────────┘                                 └─────────────┘  │
│            │                                                 │          │
│            │           ┌─────────────────────┐              │          │
│            └──────────▶│  CLAWDBOT GATEWAY   │◀─────────────┘          │
│                        │  (Your AI Employee) │                          │
│                        └─────────────────────┘                          │
│                                   │                                     │
│                        ┌─────────────────────┐                          │
│                        │   Control UI        │                          │
│                        │   http://host:18789 │                          │
│                        └─────────────────────┘                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Architecture Overview

### Single Machine Setup (Recommended for Personal Use)

```
┌─────────────────────────────────────────────────────────────────┐
│                      YOUR COMPUTER                              │
│                    (Mac/Linux/Windows)                          │
│                                                                 │
│    ┌─────────────────────────────────────────────────────┐     │
│    │              CLAWDBOT GATEWAY                       │     │
│    │                                                     │     │
│    │   ┌───────────┐  ┌───────────┐  ┌───────────┐     │     │
│    │   │  Agent    │  │  Session  │  │   Tools   │     │     │
│    │   │  Manager  │  │  Manager  │  │  Runtime  │     │     │
│    │   └───────────┘  └───────────┘  └───────────┘     │     │
│    │                                                     │     │
│    │   ┌───────────────────────────────────────────┐   │     │
│    │   │           Channel Connectors              │   │     │
│    │   │  WhatsApp │ Telegram │ Discord │ Slack   │   │     │
│    │   └───────────────────────────────────────────┘   │     │
│    │                                                     │     │
│    └─────────────────────────────────────────────────────┘     │
│                            │                                    │
│                     Port 18789                                  │
│                            │                                    │
│    ┌─────────────────────────────────────────────────────┐     │
│    │              CONTROL UI (Browser)                   │     │
│    │         http://127.0.0.1:18789                      │     │
│    └─────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Device Setup (Gateway + Remote Access)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  ┌─────────────────────────────────┐                                   │
│  │      GATEWAY SERVER             │                                   │
│  │   (Always-On Machine/VPS)       │                                   │
│  │                                 │                                   │
│  │   ┌─────────────────────────┐  │                                   │
│  │   │   Clawdbot Gateway      │  │                                   │
│  │   │   Port 18789            │  │                                   │
│  │   └─────────────────────────┘  │                                   │
│  │              │                  │                                   │
│  │         Tailscale VPN          │                                   │
│  │         100.x.x.x              │                                   │
│  │              │                  │                                   │
│  └──────────────┼──────────────────┘                                   │
│                 │                                                       │
│    ┌────────────┴────────────┬────────────────────┐                    │
│    │                         │                    │                    │
│    ▼                         ▼                    ▼                    │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐             │
│  │   Laptop     │    │   Phone      │    │   Tablet     │             │
│  │  (Control)   │    │   (Node)     │    │   (Node)     │             │
│  │              │    │              │    │              │             │
│  │  Tailscale   │    │  Tailscale   │    │  Tailscale   │             │
│  │  100.x.x.y   │    │  100.x.x.z   │    │  100.x.x.w   │             │
│  └──────────────┘    └──────────────┘    └──────────────┘             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Docker Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           HOST MACHINE                                  │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                      DOCKER ENGINE                              │  │
│   │                                                                 │  │
│   │   ┌─────────────────────────────────────────────────────────┐  │  │
│   │   │            clawdbot-gateway container                   │  │  │
│   │   │                                                         │  │  │
│   │   │   /home/node/.clawdbot  ◀───────▶  ~/.clawdbot (host)   │  │  │
│   │   │   /home/node/clawd      ◀───────▶  ~/clawd (host)       │  │  │
│   │   │                                                         │  │  │
│   │   │   Port 18789 (internal)                                 │  │  │
│   │   └─────────────────────────────────────────────────────────┘  │  │
│   │                         │                                       │  │
│   │              Port mapping: 127.0.0.1:18789:18789               │  │
│   │                         │                                       │  │
│   └─────────────────────────┼───────────────────────────────────────┘  │
│                             │                                          │
│                    localhost:18789                                     │
│                             │                                          │
│   ┌─────────────────────────┴───────────────────────────────────────┐  │
│   │                     HOST FILESYSTEM                             │  │
│   │                                                                 │  │
│   │   ~/.clawdbot/           │    ~/clawd/                         │  │
│   │   ├── clawdbot.json      │    ├── agent-workspace/             │  │
│   │   ├── tokens/            │    ├── projects/                    │  │
│   │   ├── sessions/          │    └── artifacts/                   │  │
│   │   └── logs/              │                                     │  │
│   │                                                                 │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Choose Your Platform

### Decision Tree

```
                        ┌─────────────────────┐
                        │  Where do you want  │
                        │  to run Clawdbot?   │
                        └──────────┬──────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
     ┌────────────────┐   ┌────────────────┐   ┌────────────────┐
     │  My Computer   │   │    Cloud VPS   │   │  Sandboxed/    │
     │   (Personal)   │   │   (Always-on)  │   │   Isolated     │
     └───────┬────────┘   └───────┬────────┘   └───────┬────────┘
             │                    │                    │
    ┌────────┴────────┐   ┌───────┴───────┐   ┌───────┴───────┐
    │                 │   │               │   │               │
    ▼                 ▼   ▼               ▼   ▼               ▼
┌─────────┐    ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│  macOS  │    │ Docker  │ │  Fly.io │ │ Hetzner │ │   GCP   │ │  Lume   │
│ Native  │    │ Local   │ │         │ │   VPS   │ │         │ │  macOS  │
│         │    │         │ │         │ │         │ │         │ │   VM    │
│  FREE   │    │  FREE   │ │$10-15/mo│ │ $5/mo   │ │$5-12/mo │ │  FREE   │
└─────────┘    └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘
     │              │           │           │           │           │
     │              │           │           │           │           │
     ▼              ▼           ▼           ▼           ▼           ▼
  Easiest      Portable     Quick       Budget      Enterprise  iMessage
  Setup        Anywhere     Deploy      Cloud       Scale       Support
```

### Platform Comparison Matrix

```
┌──────────────────┬────────┬───────────┬─────────────┬──────────────────┐
│     Platform     │  Cost  │ Difficulty│  Best For   │    Unique        │
├──────────────────┼────────┼───────────┼─────────────┼──────────────────┤
│ macOS Native     │  $0    │   ⭐      │ Personal    │ Full macOS tools │
│ Docker Local     │  $0    │   ⭐⭐    │ Portable    │ Any OS support   │
│ Fly.io           │ $10-15 │   ⭐⭐    │ Quick cloud │ Auto HTTPS       │
│ Hetzner VPS      │  $5    │   ⭐⭐⭐  │ Budget      │ Full control     │
│ GCP Compute      │ $5-12  │   ⭐⭐⭐  │ Enterprise  │ Scalable         │
│ macOS VM (Lume)  │  $0    │   ⭐⭐    │ Isolation   │ iMessage support │
└──────────────────┴────────┴───────────┴─────────────┴──────────────────┘
```

---

## Setup Instructions

### Option A: macOS Native (Recommended for Mac Users)

**Prerequisites:** macOS with Node.js 18+

```
┌─────────────────────────────────────────────────────────────────┐
│                    macOS NATIVE SETUP                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Install Node.js (if not installed)                    │
│  ───────────────────────────────────────────                   │
│                                                                 │
│    $ brew install node                                          │
│                                                                 │
│  Step 2: Install Clawdbot                                       │
│  ────────────────────────                                       │
│                                                                 │
│    $ npm install -g clawdbot@latest                             │
│                                                                 │
│  Step 3: Run Onboarding                                         │
│  ───────────────────────                                        │
│                                                                 │
│    $ clawdbot onboard --install-daemon                          │
│                                                                 │
│    This will:                                                   │
│    • Create ~/.clawdbot/ configuration directory               │
│    • Prompt for AI model API keys (Anthropic/OpenAI)           │
│    • Install launchd daemon (auto-start on boot)               │
│    • Start the gateway                                          │
│                                                                 │
│  Step 4: Verify Installation                                    │
│  ───────────────────────────                                    │
│                                                                 │
│    $ clawdbot status                                            │
│    $ clawdbot gateway health                                    │
│                                                                 │
│  Step 5: Access Control UI                                      │
│  ─────────────────────────                                      │
│                                                                 │
│    Open browser: http://127.0.0.1:18789                         │
│                                                                 │
│  Step 6: Get Gateway Token                                      │
│  ─────────────────────────                                      │
│                                                                 │
│    $ clawdbot gateway token                                     │
│    (Paste this into the Control UI)                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Commands Reference:**
```bash
# Install
npm install -g clawdbot@latest

# Onboard (interactive setup)
clawdbot onboard --install-daemon

# Check status
clawdbot status
clawdbot gateway health

# Get token for Control UI
clawdbot gateway token

# View logs
clawdbot logs

# Restart gateway
clawdbot gateway restart

# Run diagnostics
clawdbot doctor
```

---

### Option B: Docker (Any Platform)

**Prerequisites:** Docker Desktop or Docker Engine

```
┌─────────────────────────────────────────────────────────────────┐
│                      DOCKER SETUP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Clone Repository                                       │
│  ────────────────────────                                       │
│                                                                 │
│    $ git clone https://github.com/clawdbot/clawdbot.git         │
│    $ cd clawdbot                                                │
│                                                                 │
│  Step 2: Run Setup Script                                       │
│  ────────────────────────                                       │
│                                                                 │
│    $ ./docker-setup.sh                                          │
│                                                                 │
│    This will:                                                   │
│    • Build the Docker image                                     │
│    • Run onboarding wizard                                      │
│    • Generate gateway token                                     │
│    • Start containers via Docker Compose                        │
│                                                                 │
│  Step 3: Access Control UI                                      │
│  ─────────────────────────                                      │
│                                                                 │
│    Open browser: http://127.0.0.1:18789                         │
│    Token is in .env file: CLAWDBOT_GATEWAY_TOKEN               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Manual Docker Commands:**
```bash
# Build image
docker build -t clawdbot:local -f Dockerfile .

# Run onboarding
docker compose run --rm clawdbot-cli onboard

# Start gateway
docker compose up -d clawdbot-gateway

# View logs
docker compose logs -f clawdbot-gateway

# Health check
docker compose exec clawdbot-gateway node dist/index.js health

# Stop
docker compose down
```

**docker-compose.yml:**
```yaml
services:
  clawdbot-gateway:
    image: clawdbot:local
    build: .
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - CLAWDBOT_GATEWAY_BIND=lan
      - CLAWDBOT_GATEWAY_PORT=18789
      - CLAWDBOT_GATEWAY_TOKEN=${CLAWDBOT_GATEWAY_TOKEN}
    volumes:
      - ~/.clawdbot:/home/node/.clawdbot
      - ~/clawd:/home/node/clawd
    ports:
      - "127.0.0.1:18789:18789"
    command: ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
```

---

### Option C: Fly.io (Quick Cloud Deploy)

**Prerequisites:** Fly.io account, flyctl CLI

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLY.IO SETUP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Install Fly CLI                                        │
│  ───────────────────────                                        │
│                                                                 │
│    macOS:   $ brew install flyctl                               │
│    Linux:   $ curl -L https://fly.io/install.sh | sh           │
│    Windows: $ powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
│                                                                 │
│  Step 2: Login & Create App                                     │
│  ──────────────────────────                                     │
│                                                                 │
│    $ fly auth login                                             │
│    $ git clone https://github.com/clawdbot/clawdbot.git         │
│    $ cd clawdbot                                                │
│    $ fly apps create my-clawdbot                                │
│                                                                 │
│  Step 3: Create Persistent Volume                               │
│  ────────────────────────────────                               │
│                                                                 │
│    $ fly volumes create clawdbot_data --size 1 --region iad     │
│                                                                 │
│  Step 4: Set Secrets                                            │
│  ───────────────────                                            │
│                                                                 │
│    $ fly secrets set CLAWDBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)
│    $ fly secrets set ANTHROPIC_API_KEY=sk-ant-...               │
│                                                                 │
│  Step 5: Deploy                                                 │
│  ────────────                                                   │
│                                                                 │
│    $ fly deploy                                                 │
│                                                                 │
│  Step 6: Access                                                 │
│  ───────────                                                    │
│                                                                 │
│    $ fly open                                                   │
│    URL: https://my-clawdbot.fly.dev                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**fly.toml Configuration:**
```toml
app = "my-clawdbot"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  NODE_ENV = "production"
  CLAWDBOT_STATE_DIR = "/data"

[processes]
  app = "node dist/index.js gateway --allow-unconfigured --port 3000 --bind lan"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = false
  min_machines_running = 1

[[vm]]
  size = "shared-cpu-2x"
  memory = "2048mb"

[mounts]
  source = "clawdbot_data"
  destination = "/data"
```

---

### Option D: Hetzner VPS (Budget Cloud)

**Prerequisites:** Hetzner account, SSH access

```
┌─────────────────────────────────────────────────────────────────┐
│                    HETZNER VPS SETUP                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Create VPS                                             │
│  ──────────────────                                             │
│                                                                 │
│    • Login to Hetzner Cloud Console                            │
│    • Create new server:                                         │
│      - Location: Nuremberg or Falkenstein                       │
│      - Image: Ubuntu 22.04 or Debian 12                        │
│      - Type: CX11 (1 vCPU, 2GB RAM) ~$5/mo                     │
│    • Add your SSH key                                           │
│                                                                 │
│  Step 2: SSH into Server                                        │
│  ───────────────────────                                        │
│                                                                 │
│    $ ssh root@YOUR_VPS_IP                                       │
│                                                                 │
│  Step 3: Install Docker                                         │
│  ──────────────────────                                         │
│                                                                 │
│    $ apt-get update                                             │
│    $ apt-get install -y git curl ca-certificates                │
│    $ curl -fsSL https://get.docker.com | sh                    │
│                                                                 │
│  Step 4: Clone & Setup                                          │
│  ─────────────────────                                          │
│                                                                 │
│    $ git clone https://github.com/clawdbot/clawdbot.git         │
│    $ cd clawdbot                                                │
│    $ mkdir -p /root/.clawdbot /root/clawd                       │
│    $ chown -R 1000:1000 /root/.clawdbot /root/clawd             │
│                                                                 │
│  Step 5: Configure Environment                                  │
│  ────────────────────────────                                   │
│                                                                 │
│    $ cat > .env << EOF                                          │
│    CLAWDBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)               │
│    CLAWDBOT_CONFIG_DIR=/root/.clawdbot                          │
│    CLAWDBOT_WORKSPACE_DIR=/root/clawd                           │
│    EOF                                                          │
│                                                                 │
│  Step 6: Build & Launch                                         │
│  ──────────────────────                                         │
│                                                                 │
│    $ docker compose build                                       │
│    $ docker compose up -d clawdbot-gateway                      │
│                                                                 │
│  Step 7: Access via SSH Tunnel                                  │
│  ────────────────────────────                                   │
│                                                                 │
│    From your laptop:                                            │
│    $ ssh -N -L 18789:127.0.0.1:18789 root@YOUR_VPS_IP          │
│                                                                 │
│    Open browser: http://127.0.0.1:18789                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Option E: GCP Compute Engine

**Prerequisites:** GCP account with billing enabled

```
┌─────────────────────────────────────────────────────────────────┐
│                    GCP COMPUTE ENGINE SETUP                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Install gcloud CLI                                     │
│  ──────────────────────────                                     │
│                                                                 │
│    https://cloud.google.com/sdk/docs/install                   │
│    $ gcloud init                                                │
│    $ gcloud auth login                                          │
│                                                                 │
│  Step 2: Create Project & Enable API                            │
│  ───────────────────────────────────                            │
│                                                                 │
│    $ gcloud projects create my-clawdbot-project                 │
│    $ gcloud config set project my-clawdbot-project              │
│    $ gcloud services enable compute.googleapis.com              │
│                                                                 │
│  Step 3: Create VM                                              │
│  ────────────────                                               │
│                                                                 │
│    $ gcloud compute instances create clawdbot-gateway \         │
│        --zone=us-central1-a \                                   │
│        --machine-type=e2-small \                                │
│        --boot-disk-size=20GB \                                  │
│        --image-family=debian-12 \                               │
│        --image-project=debian-cloud                             │
│                                                                 │
│  Step 4: SSH & Install Docker                                   │
│  ────────────────────────────                                   │
│                                                                 │
│    $ gcloud compute ssh clawdbot-gateway --zone=us-central1-a   │
│    $ sudo apt-get update                                        │
│    $ curl -fsSL https://get.docker.com | sudo sh               │
│    $ sudo usermod -aG docker $USER                              │
│    (logout and login again)                                     │
│                                                                 │
│  Step 5: Follow Docker Setup Steps                              │
│  ─────────────────────────────────                              │
│                                                                 │
│    (Same as Hetzner Step 4-6)                                   │
│                                                                 │
│  Step 6: Access via SSH Tunnel                                  │
│  ────────────────────────────                                   │
│                                                                 │
│    $ gcloud compute ssh clawdbot-gateway --zone=us-central1-a \ │
│        -- -L 18789:127.0.0.1:18789                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Option F: macOS VM with Lume (For iMessage Support)

**Prerequisites:** Apple Silicon Mac (M1/M2/M3/M4)

```
┌─────────────────────────────────────────────────────────────────┐
│                    LUME macOS VM SETUP                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Install Lume                                           │
│  ────────────────────                                           │
│                                                                 │
│    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"
│                                                                 │
│    $ echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc   │
│    $ source ~/.zshrc                                            │
│                                                                 │
│  Step 2: Create macOS VM                                        │
│  ───────────────────────                                        │
│                                                                 │
│    $ lume create clawdbot --os macos --ipsw latest              │
│    (This downloads macOS and opens a VNC window)                │
│                                                                 │
│  Step 3: Complete macOS Setup Assistant                         │
│  ──────────────────────────────────────                         │
│                                                                 │
│    In the VNC window:                                           │
│    • Select language/region                                     │
│    • Create user account (remember password!)                   │
│    • Skip optional features                                     │
│                                                                 │
│  Step 4: Enable SSH in VM                                       │
│  ────────────────────────                                       │
│                                                                 │
│    System Settings → General → Sharing → Remote Login           │
│                                                                 │
│  Step 5: Get VM IP & SSH In                                     │
│  ────────────────────────                                       │
│                                                                 │
│    $ lume get clawdbot                                          │
│    (Note the IP address, e.g., 192.168.64.x)                   │
│                                                                 │
│    $ ssh youruser@192.168.64.x                                  │
│                                                                 │
│  Step 6: Install Clawdbot in VM                                 │
│  ──────────────────────────────                                 │
│                                                                 │
│    $ npm install -g clawdbot@latest                             │
│    $ clawdbot onboard --install-daemon                          │
│                                                                 │
│  Step 7: Run VM Headlessly                                      │
│  ─────────────────────────                                      │
│                                                                 │
│    $ exit  (from SSH)                                           │
│    $ lume stop clawdbot                                         │
│    $ lume run clawdbot --no-display                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuration

### Configuration File Location

```
~/.clawdbot/clawdbot.json
```

### Basic Configuration Template

```json
{
  "gateway": {
    "mode": "local",
    "bind": "auto",
    "port": 18789
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-5",
        "fallbacks": ["openai/gpt-4o"]
      },
      "maxConcurrent": 4
    },
    "list": [
      {
        "id": "main",
        "default": true
      }
    ]
  },
  "auth": {
    "profiles": {
      "anthropic:default": { 
        "mode": "token", 
        "provider": "anthropic" 
      },
      "openai:default": { 
        "mode": "token", 
        "provider": "openai" 
      }
    }
  },
  "channels": {
    "discord": {
      "enabled": false
    },
    "telegram": {
      "enabled": false
    },
    "whatsapp": {
      "enabled": false
    }
  }
}
```

### Environment Variables

```bash
# Required for AI Models
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

# Required for non-local binds
CLAWDBOT_GATEWAY_TOKEN=<your-secure-token>

# Optional
CLAWDBOT_CONFIG_DIR=~/.clawdbot
CLAWDBOT_WORKSPACE_DIR=~/clawd
CLAWDBOT_GATEWAY_BIND=lan
CLAWDBOT_GATEWAY_PORT=18789
```

---

## Remote Access

### Tailscale (Recommended)

```
┌─────────────────────────────────────────────────────────────────┐
│                    TAILSCALE SETUP                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Why Tailscale?                                                 │
│  ──────────────                                                 │
│  • Zero port forwarding                                         │
│  • Works from anywhere (home, coffee shop, mobile)             │
│  • End-to-end encrypted                                         │
│  • Free for personal use (100 devices)                         │
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │  Gateway Host   │         │  Your Laptop    │               │
│  │  (Mac Mini)     │         │  (MacBook)      │               │
│  │                 │         │                 │               │
│  │  Tailscale IP:  │◀────────▶│  Tailscale IP:  │               │
│  │  100.64.0.1     │  WireGuard  100.64.0.2    │               │
│  │                 │  Tunnel  │                 │               │
│  │  Port 18789     │         │  Browser        │               │
│  └─────────────────┘         └─────────────────┘               │
│                                                                 │
│  Step 1: Install on Gateway Host                                │
│  ───────────────────────────────                                │
│                                                                 │
│    $ brew install tailscale     # macOS                        │
│    $ sudo tailscale up                                          │
│    $ tailscale ip -4            # Get IP (e.g., 100.64.0.1)    │
│                                                                 │
│  Step 2: Install on Your Laptop                                 │
│  ──────────────────────────────                                 │
│                                                                 │
│    $ brew install tailscale                                     │
│    $ sudo tailscale up          # Same Tailscale account       │
│                                                                 │
│  Step 3: Access Gateway                                         │
│  ──────────────────────                                         │
│                                                                 │
│    Open browser: http://100.64.0.1:18789                       │
│                                                                 │
│  Optional: Enable MagicDNS                                      │
│  ─────────────────────────                                      │
│                                                                 │
│    In Tailscale admin console, enable MagicDNS                 │
│    Access via: http://gateway-hostname:18789                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### SSH Tunnel (Alternative)

```bash
# Basic tunnel
ssh -L 18789:127.0.0.1:18789 user@gateway-host

# Persistent tunnel with autossh
brew install autossh
autossh -M 0 -f -N -L 18789:127.0.0.1:18789 user@gateway-host

# Then access at http://127.0.0.1:18789
```

---

## Channel Integrations

### WhatsApp Setup

```
┌─────────────────────────────────────────────────────────────────┐
│                    WHATSAPP SETUP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Run channel login                                      │
│  ─────────────────────────                                      │
│                                                                 │
│    $ clawdbot channels login                                    │
│                                                                 │
│  Step 2: Scan QR Code                                           │
│  ────────────────────                                           │
│                                                                 │
│    A QR code will appear in terminal                           │
│    Open WhatsApp on phone → Settings → Linked Devices → Scan   │
│                                                                 │
│  Step 3: Configure in clawdbot.json                            │
│  ──────────────────────────────────                             │
│                                                                 │
│    {                                                            │
│      "channels": {                                              │
│        "whatsapp": {                                            │
│          "enabled": true,                                       │
│          "dmPolicy": "allowlist",                               │
│          "allowFrom": ["+15551234567"]                          │
│        }                                                        │
│      }                                                          │
│    }                                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Telegram Setup

```
┌─────────────────────────────────────────────────────────────────┐
│                    TELEGRAM SETUP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Create Bot via @BotFather                              │
│  ─────────────────────────────────                              │
│                                                                 │
│    • Open Telegram, message @BotFather                         │
│    • Send /newbot                                               │
│    • Follow prompts to name your bot                           │
│    • Copy the bot token                                         │
│                                                                 │
│  Step 2: Add channel                                            │
│  ───────────────────                                            │
│                                                                 │
│    $ clawdbot channels add --channel telegram --token "TOKEN"  │
│                                                                 │
│  Step 3: Configure in clawdbot.json                            │
│  ──────────────────────────────────                             │
│                                                                 │
│    {                                                            │
│      "channels": {                                              │
│        "telegram": {                                            │
│          "enabled": true,                                       │
│          "botToken": "YOUR_BOT_TOKEN"                          │
│        }                                                        │
│      }                                                          │
│    }                                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Discord Setup

```
┌─────────────────────────────────────────────────────────────────┐
│                    DISCORD SETUP                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Create Discord Application                             │
│  ──────────────────────────────────                             │
│                                                                 │
│    • Go to https://discord.com/developers/applications         │
│    • Click "New Application"                                    │
│    • Go to Bot → Add Bot                                        │
│    • Copy the bot token                                         │
│    • Enable "Message Content Intent" under Privileged Intents  │
│                                                                 │
│  Step 2: Invite Bot to Server                                   │
│  ────────────────────────────                                   │
│                                                                 │
│    • OAuth2 → URL Generator                                     │
│    • Scopes: bot                                                │
│    • Permissions: Send Messages, Read Message History          │
│    • Copy URL and open in browser to invite                    │
│                                                                 │
│  Step 3: Add channel                                            │
│  ───────────────────                                            │
│                                                                 │
│    $ clawdbot channels add --channel discord --token "TOKEN"   │
│                                                                 │
│  Step 4: Configure in clawdbot.json                            │
│  ──────────────────────────────────                             │
│                                                                 │
│    {                                                            │
│      "channels": {                                              │
│        "discord": {                                             │
│          "enabled": true,                                       │
│          "guilds": {                                            │
│            "YOUR_GUILD_ID": {                                   │
│              "channels": { "general": { "allow": true } }      │
│            }                                                    │
│          }                                                      │
│        }                                                        │
│      }                                                          │
│    }                                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Common Issues

```
┌─────────────────────────────────────────────────────────────────┐
│                    TROUBLESHOOTING                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Problem: Gateway won't start                                   │
│  ────────────────────────────                                   │
│  Solution:                                                      │
│    $ clawdbot doctor                                            │
│    $ clawdbot logs                                              │
│    Check for port conflicts: lsof -i :18789                    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Problem: "Already running" error                               │
│  ────────────────────────────────                               │
│  Solution:                                                      │
│    $ rm ~/.clawdbot/gateway.*.lock                              │
│    $ clawdbot gateway restart                                   │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Problem: Can't connect remotely                                │
│  ───────────────────────────────                                │
│  Solution:                                                      │
│    • Verify Tailscale is running: tailscale status            │
│    • Check firewall allows port 18789                          │
│    • Ensure CLAWDBOT_GATEWAY_TOKEN is set for non-local        │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Problem: Docker OOM (Out of Memory)                            │
│  ────────────────────────────────────                           │
│  Solution:                                                      │
│    Increase memory in docker-compose.yml:                       │
│    deploy:                                                      │
│      resources:                                                 │
│        limits:                                                  │
│          memory: 2G                                             │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Problem: WhatsApp QR not scanning                              │
│  ─────────────────────────────────                              │
│  Solution:                                                      │
│    • Ensure running inside gateway (not host) for Docker       │
│    • Try: clawdbot channels login --force                      │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Problem: Token rejected in Control UI                          │
│  ─────────────────────────────────────                          │
│  Solution:                                                      │
│    $ clawdbot gateway token                                     │
│    Copy fresh token and paste into UI                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Diagnostic Commands

```bash
# Full system diagnosis
clawdbot doctor

# Gateway status
clawdbot status
clawdbot gateway health

# View logs
clawdbot logs
clawdbot logs --tail 100

# List active sessions
clawdbot sessions list

# Check channel status
clawdbot channels status

# Restart gateway
clawdbot gateway restart

# Reset configuration
clawdbot reset --config
```

---

## Support

**Documentation:** https://docs.clawd.bot

**Purchase & Support:** https://clawdbot.organizedai.vip

**GitHub:** https://github.com/clawdbot/clawdbot

---

*© 2026 Organized AI - clawdbot.organizedai.vip*
