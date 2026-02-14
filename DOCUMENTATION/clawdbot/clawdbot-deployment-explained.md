# Clawdbot Deployment Architecture Explained

> A comprehensive guide to understanding deployment options, containerization, and infrastructure decisions for Clawdbot

---

## Table of Contents

1. [What is Deployment?](#what-is-deployment)
2. [Deployment Architecture Concepts](#deployment-architecture-concepts)
3. [Local vs Cloud: The Trade-offs](#local-vs-cloud-the-trade-offs)
4. [Docker Containerization Explained](#docker-containerization-explained)
5. [Platform Deep Dive](#platform-deep-dive)
6. [Remote Access Architectures](#remote-access-architectures)
7. [Service Management](#service-management)
8. [Configuration Files Explained](#configuration-files-explained)
9. [Security Considerations](#security-considerations)
10. [Decision Framework](#decision-framework)

---

## What is Deployment?

Deployment is the process of making your software accessible and running. For Clawdbot, this means setting up the gateway service that bridges your AI models with messaging channels.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    THE DEPLOYMENT JOURNEY                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│    CODE                DEPLOYMENT              RUNNING SERVICE          │
│                                                                         │
│  ┌─────────┐         ┌─────────────┐         ┌─────────────────┐       │
│  │         │         │             │         │                 │       │
│  │ Source  │───────► │   Install   │───────► │    Gateway      │       │
│  │  Code   │         │   + Config  │         │   Accepting     │       │
│  │         │         │             │         │   Connections   │       │
│  └─────────┘         └─────────────┘         └─────────────────┘       │
│                                                      │                  │
│    What you                Where & how               │                  │
│    download                you run it         ┌──────┴──────┐          │
│                                               │             │          │
│                                               ▼             ▼          │
│                                          WhatsApp      Telegram        │
│                                          Discord       iMessage        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Deployment Decisions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    THREE FUNDAMENTAL QUESTIONS                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  1. WHERE?                                                       │   │
│  │     ├── Your machine (local)                                     │   │
│  │     ├── Cloud server (VPS)                                       │   │
│  │     └── Platform-as-a-Service (Fly.io)                          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  2. HOW?                                                         │   │
│  │     ├── Native installation (npm install -g)                     │   │
│  │     ├── Docker container                                         │   │
│  │     └── Virtual machine (Lume for macOS)                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  3. ACCESS?                                                      │   │
│  │     ├── Local only (same machine)                               │   │
│  │     ├── SSH tunnel (secure, manual)                             │   │
│  │     └── Tailscale (mesh VPN, automatic)                         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Deployment Architecture Concepts

### Single Machine Architecture

The simplest setup - everything runs on one machine:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SINGLE MACHINE DEPLOYMENT                            │
│                    (Your Mac/Linux/Windows PC)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      CLAWDBOT GATEWAY                             │ │
│  │                                                                   │ │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │ │
│  │   │   Agent     │  │   Session   │  │   Tools     │             │ │
│  │   │   Manager   │  │   Manager   │  │   Runtime   │             │ │
│  │   │             │  │             │  │             │             │ │
│  │   │ Handles AI  │  │ Tracks user │  │ Executes    │             │ │
│  │   │ model calls │  │ convos      │  │ actions     │             │ │
│  │   └─────────────┘  └─────────────┘  └─────────────┘             │ │
│  │          │                │                │                     │ │
│  │          └────────────────┼────────────────┘                     │ │
│  │                           │                                       │ │
│  │                    ┌──────┴──────┐                               │ │
│  │                    │  Channel    │                               │ │
│  │                    │  Connectors │                               │ │
│  │                    │             │                               │ │
│  │                    │ • WhatsApp  │                               │ │
│  │                    │ • Telegram  │                               │ │
│  │                    │ • Discord   │                               │ │
│  │                    │ • iMessage  │                               │ │
│  │                    └─────────────┘                               │ │
│  │                           │                                       │ │
│  │                    Port 18789                                     │ │
│  └───────────────────────────┼───────────────────────────────────────┘ │
│                              │                                          │
│                     localhost:18789                                     │
│                              │                                          │
│                     ┌────────┴────────┐                                │
│                     │   Web Browser   │                                │
│                     │   Control UI    │                                │
│                     └─────────────────┘                                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Split Architecture (Gateway + Remote Client)

For accessing your Clawdbot from multiple devices:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SPLIT ARCHITECTURE                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│    HOME/OFFICE (Always Running)          MOBILE (Access Anywhere)      │
│                                                                         │
│  ┌───────────────────────────┐         ┌───────────────────────────┐   │
│  │     M4 Mac Mini           │         │    M1 MacBook Pro         │   │
│  │                           │         │                           │   │
│  │  ┌─────────────────────┐ │  ◄───►  │  ┌─────────────────────┐ │   │
│  │  │  Clawdbot Gateway   │ │   VPN   │  │  Clawdbot Client    │ │   │
│  │  │  (The Brain)        │ │   or    │  │  (Remote Mode)      │ │   │
│  │  │                     │ │  SSH    │  │                     │ │   │
│  │  │  • Runs 24/7        │ │  Tunnel │  │  • Connects to      │ │   │
│  │  │  • Handles all AI   │ │         │  │    gateway          │ │   │
│  │  │  • Manages channels │ │         │  │  • Sends commands   │ │   │
│  │  └─────────────────────┘ │         │  └─────────────────────┘ │   │
│  │                           │         │                           │   │
│  │  IP: 192.168.1.100        │         │  Location: Anywhere       │   │
│  │  Tailscale: 100.64.0.1    │         │                           │   │
│  └───────────────────────────┘         └───────────────────────────┘   │
│                                                                         │
│                                                                         │
│  WHY THIS SETUP?                                                       │
│  ═══════════════                                                       │
│                                                                         │
│  • Mac Mini stays home = Always connected to messaging channels        │
│  • MacBook travels with you = Access from coffee shop, hotel, etc.    │
│  • One gateway, many clients = Same AI from all your devices          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Local vs Cloud: The Trade-offs

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LOCAL vs CLOUD DEPLOYMENT                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    LOCAL DEPLOYMENT                              │   │
│  │                    (Your Own Hardware)                           │   │
│  │                                                                   │   │
│  │  ✅ PROS                        ❌ CONS                          │   │
│  │  ────────                       ────────                         │   │
│  │  • $0 ongoing cost              • Depends on home internet       │   │
│  │  • Full control                 • Power outages = downtime       │   │
│  │  • Data stays home              • Need remote access setup       │   │
│  │  • iMessage works               • Hardware maintenance           │   │
│  │  • Maximum performance          • IP may change (dynamic)        │   │
│  │                                                                   │   │
│  │  BEST FOR: Personal use, privacy-conscious, iMessage needed     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│                              VS                                         │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    CLOUD DEPLOYMENT                              │   │
│  │                    (VPS / PaaS)                                  │   │
│  │                                                                   │   │
│  │  ✅ PROS                        ❌ CONS                          │   │
│  │  ────────                       ────────                         │   │
│  │  • 99.9% uptime                 • $5-15/month cost               │   │
│  │  • Static IP                    • Data on third-party server    │   │
│  │  • No home hardware             • No iMessage (needs macOS)     │   │
│  │  • Easy HTTPS                   • Limited resources (RAM)       │   │
│  │  • Access from anywhere         • More complex setup            │   │
│  │                                                                   │   │
│  │  BEST FOR: Always-on reliability, team use, no home server     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Cost Comparison Over Time

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    COST ANALYSIS (12 MONTHS)                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Platform              Monthly    Year 1      Year 2      Year 3       │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                         │
│  LOCAL (existing Mac)                                                   │
│  └── Electricity only    ~$5       $60         $120        $180        │
│                                                                         │
│  LOCAL (new Mac Mini)                                                   │
│  └── + Hardware          ~$5       $660*       $720        $780        │
│      * includes $599 Mac Mini                                          │
│                                                                         │
│  HETZNER VPS (CX11)                                                    │
│  └── Budget cloud        $5        $60         $120        $180        │
│                                                                         │
│  FLY.IO                                                                │
│  └── Managed platform    $12       $144        $288        $432        │
│                                                                         │
│  GCP (e2-small)                                                        │
│  └── Enterprise          $12       $144        $288        $432        │
│                                                                         │
│                                                                         │
│  VERDICT:                                                              │
│  ═════════                                                             │
│  • Already have a Mac? → Local is cheapest                            │
│  • Need iMessage? → Must be local macOS                               │
│  • Want set-and-forget? → Fly.io or Hetzner                           │
│  • Budget-conscious cloud? → Hetzner at $5/mo                         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Docker Containerization Explained

Docker packages your application and all its dependencies into an isolated "container" that runs consistently anywhere.

### Without Docker vs With Docker

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    WITHOUT DOCKER                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  "It works on my machine!" 😤                                          │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │   Your Mac      │    │   Your VPS      │    │   Friend's PC   │    │
│  │                 │    │                 │    │                 │    │
│  │  Node.js 20     │    │  Node.js 18 ❌  │    │  Node.js 21 ❌  │    │
│  │  npm 10         │    │  npm 8 ❌       │    │  npm 10         │    │
│  │  macOS libs     │    │  Linux libs ❌  │    │  Windows ❌     │    │
│  │                 │    │                 │    │                 │    │
│  │  ✅ WORKS       │    │  ❌ BROKEN      │    │  ❌ BROKEN      │    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    │
│                                                                         │
│  Problem: Every environment is different                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                    WITH DOCKER                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  "It works everywhere!" 😎                                              │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │   Your Mac      │    │   Your VPS      │    │   Friend's PC   │    │
│  │                 │    │                 │    │                 │    │
│  │  ┌───────────┐ │    │  ┌───────────┐ │    │  ┌───────────┐ │    │
│  │  │ Container │ │    │  │ Container │ │    │  │ Container │ │    │
│  │  │           │ │    │  │           │ │    │  │           │ │    │
│  │  │ Node 20   │ │    │  │ Node 20   │ │    │  │ Node 20   │ │    │
│  │  │ All deps  │ │    │  │ All deps  │ │    │  │ All deps  │ │    │
│  │  │ Same libs │ │    │  │ Same libs │ │    │  │ Same libs │ │    │
│  │  └───────────┘ │    │  └───────────┘ │    │  └───────────┘ │    │
│  │                 │    │                 │    │                 │    │
│  │  ✅ WORKS       │    │  ✅ WORKS       │    │  ✅ WORKS       │    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    │
│                                                                         │
│  Solution: Container carries its own environment                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Docker Architecture for Clawdbot

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DOCKER CONTAINER ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  HOST MACHINE (Your Computer or VPS)                                   │
│  ═══════════════════════════════════                                   │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      DOCKER ENGINE                                │ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐ │ │
│  │  │              clawdbot-gateway container                     │ │ │
│  │  │                                                             │ │ │
│  │  │  ┌───────────────────────────────────────────────────────┐ │ │ │
│  │  │  │  CONTAINER FILESYSTEM (isolated)                      │ │ │ │
│  │  │  │                                                       │ │ │ │
│  │  │  │  /home/node/.clawdbot/  ◄────┐  (config, tokens)     │ │ │ │
│  │  │  │  /home/node/clawd/      ◄────┤  (workspace)          │ │ │ │
│  │  │  │                              │                        │ │ │ │
│  │  │  └──────────────────────────────┼────────────────────────┘ │ │ │
│  │  │                                 │                           │ │ │
│  │  │         VOLUME MOUNTS ──────────┘                           │ │ │
│  │  │         (data survives container restarts)                  │ │ │
│  │  │                                                             │ │ │
│  │  │  Port 18789 (internal) ─────────┐                          │ │ │
│  │  └─────────────────────────────────┼───────────────────────────┘ │ │
│  │                                    │                              │ │
│  │              PORT MAPPING ─────────┘                              │ │
│  │              127.0.0.1:18789 ◄──► 18789                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                    │                                                    │
│                    ▼                                                    │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                    HOST FILESYSTEM                                │ │
│  │                                                                   │ │
│  │   ~/.clawdbot/              │    ~/clawd/                        │ │
│  │   ├── clawdbot.json         │    ├── agent-workspace/            │ │
│  │   ├── tokens/               │    ├── projects/                   │ │
│  │   ├── sessions/             │    └── artifacts/                  │ │
│  │   └── logs/                 │                                    │ │
│  │                              │                                    │ │
│  │   YOUR config persists      │    YOUR data persists              │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Docker Key Concepts

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DOCKER TERMINOLOGY                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  TERM              ANALOGY              WHAT IT IS                      │
│  ──────────────────────────────────────────────────────────────────────│
│                                                                         │
│  IMAGE             Blueprint            Read-only template with code   │
│                    (like a recipe)      and dependencies               │
│                                                                         │
│  CONTAINER         Running instance     Live process created from      │
│                    (cooked meal)        an image                        │
│                                                                         │
│  VOLUME            External storage     Persistent data that           │
│                    (your fridge)        survives container death        │
│                                                                         │
│  PORT MAPPING      Door number          How traffic reaches your       │
│                    (apt 18789)          container from outside          │
│                                                                         │
│  COMPOSE           Multi-container      YAML file defining your        │
│                    orchestra            full application stack          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### docker-compose.yml Anatomy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DOCKER COMPOSE FILE EXPLAINED                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  services:                           ◄── Define your containers        │
│    clawdbot-gateway:                 ◄── Container name                │
│      image: clawdbot:latest          ◄── Which image to use            │
│      build: .                        ◄── Or build from Dockerfile      │
│      restart: unless-stopped         ◄── Auto-restart on crash         │
│                                                                         │
│      environment:                    ◄── Set env variables             │
│        - NODE_ENV=production                                           │
│        - CLAWDBOT_GATEWAY_PORT=18789                                   │
│        - CLAWDBOT_GATEWAY_TOKEN=${CLAWDBOT_GATEWAY_TOKEN}              │
│                            ▲                                            │
│                            └── Reads from .env file                    │
│                                                                         │
│      volumes:                        ◄── Mount host folders            │
│        - ~/.clawdbot:/home/node/.clawdbot                              │
│        - ~/clawd:/home/node/clawd                                      │
│            ▲            ▲                                               │
│            │            └── Container path                             │
│            └── Host path (your machine)                                │
│                                                                         │
│      ports:                          ◄── Expose ports                  │
│        - "127.0.0.1:18789:18789"                                       │
│             ▲          ▲     ▲                                         │
│             │          │     └── Container port                        │
│             │          └── Host port                                   │
│             └── Only localhost (secure!)                               │
│                                                                         │
│      command: ["node", "dist/index.js", "gateway", ...]                │
│               ▲                                                         │
│               └── Override default startup command                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Platform Deep Dive

### Platform Decision Matrix

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PLATFORM SELECTION GUIDE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│              ┌─────────────────────────────────────────┐               │
│              │      What's your priority?              │               │
│              └────────────────┬────────────────────────┘               │
│                               │                                         │
│         ┌─────────────────────┼─────────────────────┐                  │
│         │                     │                     │                  │
│         ▼                     ▼                     ▼                  │
│    ┌─────────┐          ┌─────────┐          ┌─────────┐              │
│    │  FREE   │          │ ALWAYS  │          │ IMESSAGE │              │
│    │  $0/mo  │          │   ON    │          │ SUPPORT  │              │
│    └────┬────┘          └────┬────┘          └────┬────┘              │
│         │                    │                    │                    │
│         ▼                    ▼                    ▼                    │
│    ┌─────────┐          ┌─────────┐          ┌─────────┐              │
│    │ Have    │          │ Cloud   │          │  macOS  │              │
│    │ a Mac?  │          │ VPS     │          │   VM    │              │
│    └────┬────┘          │         │          │ (Lume)  │              │
│    Yes  │  No           │ Fly.io  │          │         │              │
│    │    │               │ Hetzner │          │ Apple   │              │
│    ▼    ▼               │ GCP     │          │ Silicon │              │
│  macOS  Docker          └─────────┘          │ Only    │              │
│  Native Local                                └─────────┘              │
│                                                                         │
│                                                                         │
│  PLATFORM FEATURE MATRIX:                                              │
│  ════════════════════════                                              │
│                                                                         │
│  Platform      │ Cost │ Uptime │ iMsg │ Setup │ Remote │ HTTPS        │
│  ──────────────┼──────┼────────┼──────┼───────┼────────┼──────        │
│  macOS Native  │  $0  │  Med   │  ✅  │ Easy  │ Manual │  No          │
│  Docker Local  │  $0  │  Med   │  ❌  │ Med   │ Manual │  No          │
│  Fly.io        │ $12  │ High   │  ❌  │ Easy  │ Built  │ Auto         │
│  Hetzner       │  $5  │ High   │  ❌  │ Hard  │ Manual │ Manual       │
│  GCP           │ $12  │ High   │  ❌  │ Hard  │ Manual │ Manual       │
│  macOS VM      │  $0  │  Med   │  ✅  │ Med   │ Manual │  No          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Fly.io Architecture

Fly.io is a Platform-as-a-Service that runs your Docker containers globally:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FLY.IO ARCHITECTURE                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  YOUR WORKFLOW                                                         │
│  ═════════════                                                         │
│                                                                         │
│  ┌─────────┐     ┌─────────┐     ┌─────────────────────────────────┐  │
│  │  Your   │     │  flyctl │     │         Fly.io Cloud           │  │
│  │ Laptop  │────▶│  deploy │────▶│                                 │  │
│  │         │     │         │     │  ┌───────────────────────────┐ │  │
│  └─────────┘     └─────────┘     │  │    Your App (my-clawdbot) │ │  │
│                                   │  │                           │ │  │
│                                   │  │  ┌─────────────────────┐ │ │  │
│  What fly.io handles:            │  │  │  VM Instance        │ │ │  │
│  • Auto HTTPS certificates       │  │  │  2 vCPU / 2GB RAM   │ │ │  │
│  • Load balancing                │  │  │                     │ │ │  │
│  • Auto-restart on crash         │  │  │  clawdbot-gateway   │ │ │  │
│  • Global edge network           │  │  │  running on :3000   │ │ │  │
│  • Persistent volumes            │  │  └─────────────────────┘ │ │  │
│                                   │  │           │              │ │  │
│                                   │  │  ┌────────┴───────────┐ │ │  │
│                                   │  │  │  Persistent Volume │ │ │  │
│                                   │  │  │  clawdbot_data     │ │ │  │
│                                   │  │  │  /data mounted     │ │ │  │
│                                   │  │  └────────────────────┘ │ │  │
│                                   │  └───────────────────────────┘ │  │
│                                   │              │                  │  │
│                                   │              ▼                  │  │
│                                   │  https://my-clawdbot.fly.dev   │  │
│                                   └─────────────────────────────────┘  │
│                                                                         │
│  fly.toml KEY SETTINGS:                                                │
│  ═════════════════════                                                 │
│                                                                         │
│  auto_stop_machines = false    ◄── Keep running (don't sleep)         │
│  min_machines_running = 1      ◄── Always have one instance           │
│  size = "shared-cpu-2x"        ◄── 2 shared vCPU cores                │
│  memory = "2048mb"             ◄── 2GB RAM for AI workloads           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### VPS Deployment (Hetzner/GCP)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VPS DEPLOYMENT ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  YOUR VPS (Virtual Private Server)                                     │
│  ═════════════════════════════════                                     │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      CLOUD DATA CENTER                            │ │
│  │                      (Hetzner / GCP / etc)                        │ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐ │ │
│  │  │                    YOUR VPS INSTANCE                        │ │ │
│  │  │                    (Debian 12 / Ubuntu)                     │ │ │
│  │  │                                                             │ │ │
│  │  │  Public IP: 65.108.xx.xx                                   │ │ │
│  │  │                                                             │ │ │
│  │  │  ┌─────────────────────────────────────────────────────┐   │ │ │
│  │  │  │                 DOCKER                               │   │ │ │
│  │  │  │                                                      │   │ │ │
│  │  │  │  ┌────────────────────────────────────────────────┐ │   │ │ │
│  │  │  │  │          clawdbot-gateway                      │ │   │ │ │
│  │  │  │  │                                                │ │   │ │ │
│  │  │  │  │   Port 18789 ───► 127.0.0.1:18789             │ │   │ │ │
│  │  │  │  │                   (localhost only!)           │ │   │ │ │
│  │  │  │  └────────────────────────────────────────────────┘ │   │ │ │
│  │  │  └─────────────────────────────────────────────────────┘   │ │ │
│  │  │                         │                                   │ │ │
│  │  │                    NOT exposed to internet!                │ │ │
│  │  │                    (secure by default)                     │ │ │
│  │  └─────────────────────────┼───────────────────────────────────┘ │ │
│  │                            │                                      │ │
│  │  SSH Server ◄──────────────┘                                      │ │
│  │  Port 22                                                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                 │                                                       │
│                 │ SSH Tunnel                                           │
│                 │                                                       │
│  ┌──────────────┴────────────────────────────────────────────────────┐ │
│  │                    YOUR LAPTOP                                     │ │
│  │                                                                   │ │
│  │  $ ssh -L 18789:127.0.0.1:18789 root@65.108.xx.xx               │ │
│  │                                                                   │ │
│  │  Browser: http://localhost:18789 ────► VPS:18789                │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  WHY 127.0.0.1 BINDING?                                                │
│  ══════════════════════                                                │
│                                                                         │
│  ports:                                                                │
│    - "127.0.0.1:18789:18789"   ◄── Only accessible via SSH tunnel    │
│                                                                         │
│  vs                                                                    │
│                                                                         │
│    - "0.0.0.0:18789:18789"     ◄── Exposed to internet (DANGEROUS!)   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Remote Access Architectures

### Comparison of Access Methods

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    REMOTE ACCESS METHODS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  METHOD 1: SSH TUNNEL                                                  │
│  ════════════════════                                                  │
│                                                                         │
│  ┌─────────────┐         SSH (encrypted)         ┌─────────────┐      │
│  │  MacBook    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶│  Mac Mini   │      │
│  │  (remote)   │    Port 22                      │  (gateway)  │      │
│  │             │                                 │             │      │
│  │ localhost   │ ◄─────────────────────────────▶│ :18789      │      │
│  │ :18789      │    Tunnel forwards traffic     │ Clawdbot    │      │
│  └─────────────┘                                 └─────────────┘      │
│                                                                         │
│  ✅ No install needed  │  ❌ Breaks when network changes               │
│  ✅ Very secure        │  ❌ Manual setup each time                    │
│  ✅ Works anywhere     │  ❌ Need SSH access                           │
│                                                                         │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                         │
│  METHOD 2: TAILSCALE                                                   │
│  ═══════════════════                                                   │
│                                                                         │
│  ┌─────────────┐      Tailscale Mesh VPN        ┌─────────────┐      │
│  │  MacBook    │◄━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶│  Mac Mini   │      │
│  │  (remote)   │    100.64.0.2                  │  (gateway)  │      │
│  │             │                                 │             │      │
│  │ Access via  │                                │ 100.64.0.1  │      │
│  │ 100.64.0.1  │    WireGuard encrypted        │ :18789      │      │
│  │ :18789      │    P2P when possible           │ Clawdbot    │      │
│  └─────────────┘                                 └─────────────┘      │
│                                                                         │
│  ✅ Auto-reconnect     │  ❌ Software install needed                   │
│  ✅ Works on mobile    │  ❌ Account required                          │
│  ✅ MagicDNS names     │  ❌ Third-party dependency                    │
│                                                                         │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                         │
│  METHOD 3: DIRECT (Dangerous!)                                         │
│  ════════════════════════════                                          │
│                                                                         │
│  ┌─────────────┐         PUBLIC INTERNET        ┌─────────────┐      │
│  │  MacBook    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶│  Mac Mini   │      │
│  │  (remote)   │    Unencrypted!                │  (gateway)  │      │
│  │             │                                 │             │      │
│  │ Access via  │                ⚠️ EXPOSED       │ 0.0.0.0     │      │
│  │ public IP   │                                │ :18789      │      │
│  │ :18789      │    Anyone can connect!         │ Clawdbot    │      │
│  └─────────────┘                                 └─────────────┘      │
│                                                                         │
│  ❌ NEVER DO THIS WITHOUT HTTPS + AUTHENTICATION                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Service Management

### macOS (launchd) vs Linux (systemd)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SERVICE MANAGEMENT                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  macOS: launchd                       Linux: systemd                   │
│  ══════════════                       ══════════════                   │
│                                                                         │
│  Install as daemon:                   Create service file:             │
│  $ clawdbot gateway install           $ sudo nano /etc/systemd/...     │
│                                                                         │
│  Start:                               Start:                           │
│  $ launchctl load ...                 $ sudo systemctl start ...       │
│                                                                         │
│  Stop:                                Stop:                            │
│  $ launchctl bootout ...              $ sudo systemctl stop ...        │
│                                                                         │
│  Restart:                             Restart:                         │
│  $ launchctl kickstart -k ...         $ sudo systemctl restart ...     │
│                                                                         │
│  Status:                              Status:                          │
│  $ launchctl list | grep ...          $ sudo systemctl status ...      │
│                                                                         │
│  Logs:                                Logs:                            │
│  $ tail ~/.clawdbot/logs/...          $ journalctl -u ...              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### launchd Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LAUNCHD SERVICE LIFECYCLE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                        macOS BOOT                                      │
│                            │                                            │
│                            ▼                                            │
│                    ┌───────────────┐                                   │
│                    │   launchd     │    (PID 1 - the boss)             │
│                    │   starts      │                                   │
│                    └───────┬───────┘                                   │
│                            │                                            │
│           ┌────────────────┼────────────────┐                          │
│           │                │                │                          │
│           ▼                ▼                ▼                          │
│    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                 │
│    │ System       │ │ User Login   │ │ com.clawdbot │                 │
│    │ Services     │ │ Services     │ │ .gateway     │                 │
│    └──────────────┘ └──────────────┘ └──────┬───────┘                 │
│                                             │                          │
│                                    ┌────────┴────────┐                 │
│                                    │                 │                 │
│                                    ▼                 ▼                 │
│                            ┌─────────────┐   ┌─────────────┐          │
│                            │  Clawdbot   │   │   Crashes   │          │
│                            │  Gateway    │   │      ?      │          │
│                            │  Running    │   └──────┬──────┘          │
│                            └─────────────┘          │                  │
│                                    ▲                │                  │
│                                    │                │                  │
│                                    └────────────────┘                  │
│                                      Auto-restart!                     │
│                                                                         │
│  PLIST LOCATION:                                                       │
│  ~/Library/LaunchAgents/com.clawdbot.gateway.plist                    │
│                                                                         │
│  KEY SETTINGS:                                                         │
│  • RunAtLoad: true      ◄── Start on login                            │
│  • KeepAlive: true      ◄── Restart if crashes                        │
│  • StandardOutPath      ◄── Where logs go                             │
│  • StandardErrorPath    ◄── Where errors go                           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Configuration Files Explained

### File Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CLAWDBOT FILE STRUCTURE                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ~/.clawdbot/                     ◄── Configuration directory          │
│  ├── clawdbot.json                ◄── Main config file                 │
│  ├── tokens/                      ◄── API tokens (encrypted)           │
│  │   ├── anthropic.enc                                                 │
│  │   └── openai.enc                                                    │
│  ├── sessions/                    ◄── Active conversations             │
│  │   ├── whatsapp/                                                     │
│  │   └── telegram/                                                     │
│  └── logs/                        ◄── Runtime logs                     │
│      ├── gateway.log                                                   │
│      └── error.log                                                     │
│                                                                         │
│  ~/clawd/                         ◄── Workspace directory              │
│  ├── agent-workspace/             ◄── Where agents do work             │
│  ├── projects/                    ◄── Your projects                    │
│  └── artifacts/                   ◄── Generated files                  │
│                                                                         │
│                                                                         │
│  WHY TWO DIRECTORIES?                                                  │
│  ═══════════════════                                                   │
│                                                                         │
│  ~/.clawdbot/  = SYSTEM (small, sensitive, backed up carefully)       │
│  ~/clawd/      = DATA (large, frequently changing, your work)         │
│                                                                         │
│  This separation means:                                                │
│  • Easy backup of config without huge workspace                       │
│  • Can mount different workspace per environment                      │
│  • Clear security boundary                                            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### clawdbot.json Anatomy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CONFIG FILE STRUCTURE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  {                                                                      │
│    "gateway": {                      ◄── Server settings               │
│      "bind": "lan",                  ◄── Network interface             │
│      "port": 18789,                  ◄── Listen port                   │
│      "token": "abc123..."            ◄── Auth token (required!)        │
│    },                                                                   │
│                                                                         │
│    "channels": {                     ◄── Messaging platforms           │
│      "whatsapp": {                                                      │
│        "dmPolicy": "allowlist",      ◄── Who can message               │
│        "allowFrom": ["+1555..."]     ◄── Allowed numbers               │
│      },                                                                 │
│      "telegram": {                                                      │
│        "botToken": "123:ABC..."      ◄── Bot credentials               │
│      }                                                                  │
│    },                                                                   │
│                                                                         │
│    "models": {                       ◄── AI model settings             │
│      "default": "anthropic:claude-sonnet-4-20250514"                   │
│    }                                                                    │
│  }                                                                      │
│                                                                         │
│                                                                         │
│  BIND OPTIONS:                                                         │
│  ═════════════                                                         │
│                                                                         │
│  "bind": "localhost"    ◄── Only this machine (127.0.0.1)             │
│  "bind": "lan"          ◄── Local network (192.168.x.x)               │
│  "bind": "all"          ◄── Any interface (0.0.0.0) ⚠️ CAREFUL        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Security Considerations

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SECURITY CHECKLIST                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ✅ DO:                                                                 │
│  ══════                                                                │
│                                                                         │
│  [✓] Generate strong gateway token                                     │
│      $ openssl rand -hex 32                                            │
│                                                                         │
│  [✓] Bind to localhost or LAN only                                    │
│      ports: "127.0.0.1:18789:18789"                                    │
│                                                                         │
│  [✓] Use SSH tunnel or Tailscale for remote                           │
│      Never expose directly to internet                                 │
│                                                                         │
│  [✓] Keep API keys in secure storage                                  │
│      Use environment variables, not config files                       │
│                                                                         │
│  [✓] Set restrictive DM policies                                      │
│      "dmPolicy": "allowlist"                                           │
│                                                                         │
│                                                                         │
│  ❌ DON'T:                                                              │
│  ════════                                                              │
│                                                                         │
│  [✗] Expose port 18789 to public internet                             │
│      ports: "0.0.0.0:18789:18789"  ◄── DANGEROUS!                     │
│                                                                         │
│  [✗] Use weak or default tokens                                       │
│      "token": "password123"  ◄── EASILY GUESSED!                      │
│                                                                         │
│  [✗] Store API keys in git                                            │
│      Add .env to .gitignore                                            │
│                                                                         │
│  [✗] Allow anyone to message your bot                                 │
│      "dmPolicy": "open"  ◄── SPAM MAGNET!                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Decision Framework

### Quick Start Flowchart

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT DECISION TREE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                         START HERE                                      │
│                             │                                           │
│                             ▼                                           │
│                    ┌────────────────┐                                  │
│                    │  Do you need   │                                  │
│                    │   iMessage?    │                                  │
│                    └───────┬────────┘                                  │
│                      Yes   │   No                                      │
│                       │    │    │                                      │
│          ┌────────────┘    │    └────────────┐                         │
│          ▼                 │                 ▼                         │
│   ┌──────────────┐        │         ┌──────────────┐                  │
│   │ macOS ONLY   │        │         │ Do you have  │                  │
│   │              │        │         │ a Mac?       │                  │
│   │ • Native     │        │         └──────┬───────┘                  │
│   │ • Lume VM    │        │          Yes   │   No                     │
│   └──────────────┘        │           │    │    │                     │
│                           │    ┌──────┘    │    └──────┐              │
│                           │    ▼           │           ▼              │
│                           │ ┌────────┐     │    ┌──────────────┐      │
│                           │ │ macOS  │     │    │ Docker or    │      │
│                           │ │ Native │     │    │ Cloud VPS    │      │
│                           │ └────────┘     │    └──────────────┘      │
│                           │                │                          │
│                           └────────────────┤                          │
│                                            │                          │
│                                            ▼                          │
│                                   ┌────────────────┐                  │
│                                   │ Want always-on │                  │
│                                   │ reliability?   │                  │
│                                   └───────┬────────┘                  │
│                                     Yes   │   No                      │
│                                      │    │    │                      │
│                         ┌────────────┘    │    └──────┐               │
│                         ▼                 │           ▼               │
│                  ┌──────────────┐         │    ┌──────────────┐       │
│                  │ Cloud:       │         │    │ Local:       │       │
│                  │ • Fly.io     │         │    │ • Native     │       │
│                  │ • Hetzner    │         │    │ • Docker     │       │
│                  │ • GCP        │         │    │              │       │
│                  └──────────────┘         │    └──────────────┘       │
│                                           │                           │
│                                           ▼                           │
│                              ┌──────────────────────┐                 │
│                              │   CONGRATULATIONS!   │                 │
│                              │   You've chosen a    │                 │
│                              │   deployment path    │                 │
│                              └──────────────────────┘                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

### Essential Commands

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    COMMAND CHEAT SHEET                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  NATIVE macOS                                                          │
│  ═══════════                                                           │
│  npm install -g clawdbot@latest     # Install                          │
│  clawdbot onboard --install-daemon  # Setup + auto-start               │
│  clawdbot status                    # Check health                     │
│  clawdbot gateway token             # Show auth token                  │
│                                                                         │
│  DOCKER                                                                │
│  ══════                                                                │
│  docker compose build               # Build image                      │
│  docker compose up -d               # Start detached                   │
│  docker compose logs -f             # Follow logs                      │
│  docker compose down                # Stop everything                  │
│                                                                         │
│  FLY.IO                                                                │
│  ══════                                                                │
│  fly apps create my-clawdbot        # Create app                       │
│  fly volumes create clawdbot_data   # Add storage                      │
│  fly secrets set KEY=value          # Add secrets                      │
│  fly deploy                         # Deploy/update                    │
│  fly logs                           # View logs                        │
│                                                                         │
│  REMOTE ACCESS                                                         │
│  ═════════════                                                         │
│  ssh -L 18789:127.0.0.1:18789 user@server  # SSH tunnel               │
│  tailscale up                              # Start Tailscale           │
│  tailscale ip -4                           # Get Tailscale IP          │
│                                                                         │
│  TROUBLESHOOTING                                                       │
│  ═══════════════                                                       │
│  clawdbot doctor                    # Diagnose issues                  │
│  clawdbot gateway health            # Check gateway                    │
│  tail -f ~/.clawdbot/logs/*.log     # Watch logs                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## See Also

- [SSH Tunnel Explained](../networking/ssh-tunnel-explained.md) - Deep dive into SSH tunneling
- [Tailscale Explained](../networking/tailscale-explained.md) - Understanding mesh VPNs

---

*Last Updated: January 2026*
*Part of the Clawdbot DOCUMENTATION series*
