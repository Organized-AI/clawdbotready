# NanoClaw Setup Guide

Deployment toolkit for [NanoClaw](https://github.com/qwibitai/nanoclaw) — a lightweight personal Claude assistant that runs securely in containers, accessible via WhatsApp.

NanoClaw is a minimalist alternative to OpenClaw: a single Node.js process with ~18 source files, 7 production dependencies, and OS-level container isolation instead of application-level permission checks.

## Quick Start

```bash
# 1. Clone NanoClaw
git clone https://github.com/qwibitai/nanoclaw.git
cd nanoclaw

# 2. Open Claude Code and run the setup skill
claude
# Inside Claude Code:
/setup
```

Claude Code's `/setup` skill handles everything interactively. **This guide documents what happens under the hood** and provides helper scripts for ongoing management.

**Setup time**: 15-25 minutes (including WhatsApp authentication)

---

## What NanoClaw Does

```
WhatsApp (baileys) --> SQLite --> Polling loop --> Container (Claude Agent SDK) --> Response
```

- You message Claude from your phone via WhatsApp (e.g., `@Andy what's the weather?`)
- NanoClaw routes the message to an isolated Linux container running Claude Agent SDK
- Each WhatsApp group gets its own memory (`CLAUDE.md`), filesystem, and container sandbox
- A private "main channel" (your self-chat) acts as admin control
- Scheduled tasks let Claude run recurring jobs and notify you
- Agent swarms enable teams of specialized agents collaborating on complex tasks

---

## Prerequisites

### Hardware
- **Mac**: Apple Silicon (M1/M2/M3/M4) — required for Apple Container
- **RAM**: 8GB minimum (16GB recommended for concurrent containers)
- **Disk**: 15GB available (container images + dependencies)
- **Network**: Internet connection (WhatsApp, Claude API)

### Software
| Requirement | Version | Check | Install |
|-------------|---------|-------|---------|
| **macOS** | Sequoia+ | `sw_vers -productVersion` | — |
| **Node.js** | 20+ | `node --version` | `brew install node` |
| **Claude Code** | Latest | `claude --version` | [claude.ai/download](https://claude.ai/download) |
| **Apple Container** | Latest | `container --version` | See [Apple Container Setup](#apple-container-setup) |
| **Git** | Any | `git --version` | `xcode-select --install` |

### Verify All Prerequisites
```bash
# Run the prerequisites check script from this toolkit
./scripts/check-prerequisites.sh
```

### Apple Container Setup

Apple Container is Apple's native container runtime for macOS. **Requires macOS 26 (Tahoe) or later.**

```bash
# Check if already installed
container --version

# If not installed (requires macOS 26+), install via Homebrew
brew install container
brew services start container
```

> **On macOS 15 (Sequoia) or earlier**: Apple Container is not available. Use Docker Desktop instead:
> ```bash
> brew install --cask docker
> open -a Docker   # Wait for daemon to start
> ```
> NanoClaw supports Docker via the `/convert-to-docker` skill. Run it after initial setup.

### Claude Authentication

You need one of:
- **Claude subscription** (Pro/Team/Enterprise) — uses OAuth token
- **Anthropic API key** — direct API access

---

## Installation

### Phase 0: Clone and Install Dependencies

```bash
git clone https://github.com/qwibitai/nanoclaw.git
cd nanoclaw
npm install
```

### Phase 1: Claude Authentication

**Option A: Claude Subscription (OAuth)**
```bash
claude setup-token
# Follow prompts to authenticate
```

**Option B: Anthropic API Key**
```bash
# Create the env file for container mounting
mkdir -p data/env
echo "ANTHROPIC_API_KEY=sk-ant-your-key-here" > data/env/env
```

> Only `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` are exposed to containers. All other credentials stay on the host.

### Phase 2: Build Container Image

```bash
./container/build.sh
```

This builds `nanoclaw-agent:latest` containing:
- Node.js 22
- Chromium (for browser automation)
- Claude Code CLI
- agent-browser
- The agent-runner package

**Verify the build:**
```bash
echo '{"prompt":"What is 2+2?","groupFolder":"test","chatJid":"test@g.us","isMain":false}' | \
  container run -i nanoclaw-agent:latest
```

### Phase 3: Channel Authentication

**Option A: WhatsApp (default)**
```bash
npm run auth
```

1. A QR code appears in your terminal
2. Open WhatsApp on your phone → Linked Devices → Link a Device
3. Scan the QR code
4. Wait for "Authentication successful" message

> The WhatsApp session is stored in `store/auth/` — this is **never** mounted into containers.

**Option B: Telegram (remote-friendly)**

Best for remote deployments where QR code scanning isn't practical:

1. Create a bot via [@BotFather](https://t.me/BotFather) → `/newbot`
2. Copy the bot token
3. Install the Telegram library:
   ```bash
   npm install grammy
   ```
4. Add to `.env`:
   ```bash
   TELEGRAM_BOT_TOKEN=your-bot-token-here
   TELEGRAM_ONLY=true
   ```
5. Add Telegram channel integration to `src/channels/telegram.ts` and wire into `index.ts`

### Phase 4: Configure Assistant

**Set trigger word** (default: `@Andy`):
```bash
# Edit the ASSISTANT_NAME in your environment or config
# The trigger word is what you type in WhatsApp to invoke Claude
export ASSISTANT_NAME="Andy"  # Change to whatever you prefer
```

**Register your main channel** (admin control):
- Send a message in your WhatsApp self-chat (message yourself)
- This becomes your admin channel with elevated privileges

**Register groups**:
- From your main channel, ask the assistant to join specific groups
- Each group gets isolated memory and filesystem

### Phase 5: Configure Mount Allowlist (Optional)

If you want agents to access directories outside the project:

```bash
# Copy the example config
cp config/mount-allowlist.example.json ~/.config/nanoclaw/mount-allowlist.json

# Edit to add your directories
nano ~/.config/nanoclaw/mount-allowlist.json
```

See [config/mount-allowlist.example.json](config/mount-allowlist.example.json) for format.

### Phase 6: Build and Start Service

```bash
# Build TypeScript
npm run build

# Install the launchd service
./scripts/install-service.sh

# Verify it's running
./scripts/status.sh
```

### Phase 7: Test

1. Send `@Andy hello` in a registered WhatsApp chat
2. Check logs: `tail -f logs/nanoclaw.log`
3. Verify response arrives in WhatsApp

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      YOUR PHONE (WhatsApp)                       │
│  Send: "@Andy summarize today's news"                            │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               v
┌─────────────────────────────────────────────────────────────────┐
│                    HOST PROCESS (Node.js)                         │
│                                                                   │
│  ┌─────────────┐  ┌──────────┐  ┌────────────────┐              │
│  │  WhatsApp    │  │  SQLite  │  │  Task Scheduler │              │
│  │  (baileys)   │──│  (msgs)  │  │  (cron/once)    │              │
│  └──────┬──────┘  └────┬─────┘  └───────┬────────┘              │
│         │              │                 │                        │
│  ┌──────v──────────────v─────────────────v──────┐                │
│  │            Message Router / IPC               │                │
│  │     (trigger check, group queue, auth)        │                │
│  └───────────────────┬──────────────────────────┘                │
│                      │                                            │
│  ┌───────────────────v──────────────────────────┐                │
│  │          Container Runner                     │                │
│  │  (spawns isolated containers per invocation)  │                │
│  └───────────────────┬──────────────────────────┘                │
└──────────────────────┼──────────────────────────────────────────┘
                       │
         ┌─────────────v──────────────┐
         │   APPLE CONTAINER (Linux)   │
         │                             │
         │  ┌───────────────────────┐  │
         │  │  Claude Agent SDK     │  │
         │  │  + agent-browser      │  │
         │  │  + Chromium           │  │
         │  └───────────────────────┘  │
         │                             │
         │  Mounts:                    │
         │  /workspace/group (rw)      │
         │  /workspace/global (ro)     │
         │  /workspace/ipc             │
         │  /workspace/env-dir (ro)    │
         └─────────────────────────────┘
```

### Key Source Files

| File | Purpose |
|------|---------|
| `src/index.ts` | Main orchestrator — state, message loop, agent invocation |
| `src/channels/whatsapp.ts` | WhatsApp connection, auth, send/receive |
| `src/container-runner.ts` | Spawns streaming agent containers with mounts |
| `src/router.ts` | Message formatting and outbound routing |
| `src/group-queue.ts` | Per-group message queue with global concurrency limit |
| `src/task-scheduler.ts` | Scheduled task execution |
| `src/ipc.ts` | Inter-process communication and task processing |
| `src/db.ts` | SQLite database operations |
| `src/config.ts` | Configuration (trigger pattern, paths, intervals) |
| `src/mount-security.ts` | Mount validation and security controls |

### Default Configuration

| Setting | Default | Source |
|---------|---------|--------|
| Trigger word | `@Andy` | `ASSISTANT_NAME` env var |
| Poll interval | 2000ms | `src/config.ts` |
| Scheduler poll | 60000ms | `src/config.ts` |
| Container image | `nanoclaw-agent:latest` | `src/config.ts` |
| Container timeout | 30 min | `src/config.ts` |
| Max concurrent containers | 5 | `src/config.ts` |

---

## Security Model

NanoClaw's security relies on **OS-level container isolation**, not application-level permission checks.

### Trust Boundaries

```
┌──────────────────────────────────────────────────────────────────┐
│                     UNTRUSTED ZONE                                │
│  WhatsApp Messages (potentially malicious, prompt injection)      │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                                 v  Trigger check, input validation
┌──────────────────────────────────────────────────────────────────┐
│                  HOST PROCESS (TRUSTED)                            │
│  - Message routing and IPC authorization                          │
│  - Mount validation (external allowlist)                          │
│  - Container lifecycle management                                 │
│  - Credential filtering (only auth vars exposed)                  │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                                 v  Explicit mounts only
┌──────────────────────────────────────────────────────────────────┐
│               CONTAINER (ISOLATED / SANDBOXED)                    │
│  - Agent execution (non-root, uid 1000)                           │
│  - Bash commands run INSIDE container, not on host                │
│  - File operations limited to mounted paths                       │
│  - Network access unrestricted (for web search/fetch)             │
│  - Cannot modify security config or mount allowlist               │
└──────────────────────────────────────────────────────────────────┘
```

### What's Protected

| Asset | Protection |
|-------|------------|
| WhatsApp session (`store/auth/`) | Never mounted into containers |
| Mount allowlist (`~/.config/nanoclaw/`) | External to project, never mounted |
| Host filesystem | Only explicitly allowed dirs are mounted |
| Other group data | Session isolation — groups can't see each other |
| SSH keys, credentials, `.env` | Default blocked patterns prevent mounting |

### Main Channel vs Regular Groups

| Capability | Main Channel | Other Groups |
|------------|-------------|--------------|
| Project root access | Read/write | None |
| Group folder | Read/write | Read/write (own only) |
| Global memory | Read/write | Read-only |
| Send messages to other chats | Yes | No |
| Schedule tasks for other groups | Yes | No |
| View all tasks | Yes | Own group only |
| Additional mount directories | Configurable | Read-only unless allowed |

### Default Blocked Mount Patterns
```
.ssh, .gnupg, .aws, .azure, .gcloud, .kube, .docker,
credentials, .env, .netrc, .npmrc, id_rsa, id_ed25519,
private_key, .secret
```

---

## Helper Scripts

This toolkit provides management scripts in `scripts/`:

### Prerequisites Check
```bash
./scripts/check-prerequisites.sh
```
Validates all requirements before setup.

### Service Management
```bash
./scripts/install-service.sh     # Install and start launchd service
./scripts/status.sh              # Show service status, process info, recent logs
./scripts/start.sh               # Start NanoClaw service
./scripts/stop.sh                # Graceful stop
./scripts/restart.sh             # Stop then start
./scripts/emergency-stop.sh      # Force kill immediately
```

### Container Management
```bash
./scripts/container-rebuild.sh   # Clean rebuild of agent container image
./scripts/container-test.sh      # Run a test prompt through the container
```

### Health Check
```bash
./scripts/health-check.sh        # Comprehensive health check
./scripts/health-check.sh --json # Machine-readable output
```

### Logs
```bash
./scripts/logs.sh                # Tail stdout logs
./scripts/logs.sh --error        # Tail error logs
./scripts/logs.sh --all          # Tail both
```

---

## Customization

NanoClaw uses **code changes over configuration files**. To customize:

### Via Claude Code Skills
```bash
cd nanoclaw
claude
# Then run any skill:
/customize        # Guided customization assistant
/add-telegram     # Add Telegram as a channel
/add-gmail        # Add Gmail integration
/convert-to-docker  # Switch from Apple Container to Docker
```

### Common Customizations

**Change trigger word:**
```bash
# In your shell profile or launchd plist
export ASSISTANT_NAME="Claude"  # or "Bot", "Jarvis", etc.
```

**Add directory access for agents:**
Edit `~/.config/nanoclaw/mount-allowlist.json`:
```json
{
  "allowedRoots": [
    {
      "path": "~/projects",
      "allowReadWrite": true,
      "description": "My dev projects"
    }
  ]
}
```

**Schedule recurring tasks:**
From your main WhatsApp channel:
```
@Andy send me a summary of Hacker News every morning at 8am
@Andy review git history every Friday at 5pm
```

---

## Comparison: NanoClaw vs OpenClaw

| Feature | NanoClaw | OpenClaw |
|---------|----------|----------|
| **Codebase** | ~18 files, 7 deps | 52+ modules, 45+ deps |
| **Architecture** | Single Node.js process | Multi-process gateway |
| **Security** | Container isolation (OS-level) | exec-approvals (app-level) |
| **Default Channel** | WhatsApp | Telegram |
| **Setup** | Claude Code `/setup` skill | Manual or scripted |
| **Customization** | Modify code + skills | Configuration files |
| **Container Runtime** | Apple Container / Docker | None (runs on host) |
| **Memory** | Per-group `CLAUDE.md` files | Gateway session memory |
| **Scheduled Tasks** | Built-in (cron/interval/once) | Via external tools |
| **Agent Swarms** | Built-in | Not available |
| **Browser Automation** | Built-in (Chromium in container) | Not available |
| **Best For** | Personal use, single user | Multi-user, production |

**Choose NanoClaw if**:
- You want a lightweight personal assistant
- You prefer WhatsApp as your messaging channel
- You want OS-level security isolation
- You value a small, understandable codebase
- You're comfortable with code-level customization

**Choose OpenClaw if**:
- You need multi-user/multi-tenant support
- You prefer Telegram or need multiple channels simultaneously
- You need the OpenClaw Gateway ecosystem (dashboard, plugins)
- You want configuration-based customization

---

## Troubleshooting

### WhatsApp Connection Issues

**Problem**: QR code doesn't appear
```bash
# Re-run authentication
npm run auth

# If store/auth is corrupted, clear it
rm -rf store/auth
npm run auth
```

**Problem**: WhatsApp disconnects frequently
```bash
# Check logs for disconnect reason
grep -i "disconnect\|logout\|connection" logs/nanoclaw.log

# Common fix: re-authenticate
rm -rf store/auth
npm run auth
```

### Container Issues

**Problem**: Container build fails
```bash
# Ensure Apple Container is running
container --version

# Clean rebuild (purge build cache)
container builder stop && container builder rm && container builder start
./container/build.sh
```

**Problem**: Container times out
```bash
# Check if containers are running
container ps

# Kill stuck containers
container kill $(container ps -q)

# Verify image exists
container images | grep nanoclaw-agent
```

**Problem**: Agent can't authenticate inside container
```bash
# Verify env file exists
cat data/env/env
# Should contain CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY

# Test container with env
echo '{"prompt":"hello","groupFolder":"test","chatJid":"test@g.us","isMain":false}' | \
  container run -i nanoclaw-agent:latest
```

### Service Issues

**Problem**: launchd service won't start
```bash
# Check plist syntax
plutil -lint ~/Library/LaunchAgents/com.nanoclaw.plist

# Check launchd status
launchctl print gui/$(id -u)/com.nanoclaw

# View error log
tail -50 logs/nanoclaw.error.log

# Common fix: rebuild and reinstall
npm run build
./scripts/install-service.sh
```

**Problem**: NanoClaw runs but doesn't respond
```bash
# Check if process is running
pgrep -f "dist/index.js"

# Check recent messages in DB
sqlite3 data/nanoclaw.db "SELECT * FROM messages ORDER BY timestamp DESC LIMIT 5;"

# Check if trigger word matches
grep "ASSISTANT_NAME" ~/Library/LaunchAgents/com.nanoclaw.plist
```

### Database Issues

**Problem**: SQLite errors
```bash
# Check database integrity
sqlite3 data/nanoclaw.db "PRAGMA integrity_check;"

# Backup and recreate if corrupt
cp data/nanoclaw.db data/nanoclaw.db.backup
rm data/nanoclaw.db
# NanoClaw will recreate on next start
./scripts/restart.sh
```

---

## Logs

### Locations
| Log | Path | Contents |
|-----|------|----------|
| stdout | `logs/nanoclaw.log` | Main application output |
| stderr | `logs/nanoclaw.error.log` | Errors and warnings |
| WhatsApp | `store/` | WhatsApp session data |
| Database | `data/nanoclaw.db` | Messages, groups, tasks |

### Viewing Logs
```bash
# Live stdout
tail -f logs/nanoclaw.log

# Live errors
tail -f logs/nanoclaw.error.log

# Search for specific patterns
grep "error\|fail\|warn" logs/nanoclaw.log | tail -20
```

---

## Backup & Recovery

### What to Back Up
```bash
# Essential data
cp -r data/ backup/data/           # Database, env, sessions
cp -r groups/ backup/groups/       # Per-group memory and files
cp -r store/auth/ backup/auth/     # WhatsApp session

# Optional
cp ~/.config/nanoclaw/mount-allowlist.json backup/
```

### Restore
```bash
# Stop service first
./scripts/stop.sh

# Restore data
cp -r backup/data/ data/
cp -r backup/groups/ groups/
cp -r backup/auth/ store/auth/

# Restart
./scripts/start.sh
```

### Disaster Recovery
```bash
# 1. Stop everything
./scripts/emergency-stop.sh

# 2. Fresh clone
git clone https://github.com/qwibitai/nanoclaw.git nanoclaw-fresh
cd nanoclaw-fresh
npm install

# 3. Restore data from backup
cp -r /path/to/backup/data/ data/
cp -r /path/to/backup/groups/ groups/
cp -r /path/to/backup/auth/ store/auth/

# 4. Rebuild and start
./container/build.sh
npm run build
./scripts/install-service.sh
```

---

## Uninstallation

```bash
# 1. Stop and remove service
launchctl unload ~/Library/LaunchAgents/com.nanoclaw.plist
rm ~/Library/LaunchAgents/com.nanoclaw.plist

# 2. Remove mount allowlist
rm -rf ~/.config/nanoclaw

# 3. Remove NanoClaw directory
cd ..
rm -rf nanoclaw

# 4. (Optional) Remove Apple Container images
container rmi nanoclaw-agent:latest
```

---

## Real-World Deployment Notes

Based on a successful deployment to MBA (M3 MacBook Air, 2026-02-12):

**What worked:**
- macOS 26.3 Tahoe with Apple Container v0.9.0 (native runtime)
- Node 22 LTS (Node 25 breaks `better-sqlite3` native module)
- Telegram channel via `grammy` library (trigger word: @Ninja)
- launchd service with `KeepAlive=true` for auto-restart
- Anthropic API key in `.env` synced to `data/env/env`

**Common issues:**
- Apple Container requires macOS 26+ — fall back to Docker on older macOS
- `npm install` fails with Node 25 on `better-sqlite3` — use `brew install node@22`
- Non-login SSH shells don't load `.zprofile` — prefix with `eval "$(/opt/homebrew/bin/brew shellenv)"`

**Verification:**
```bash
# Check service is running
pgrep -fl "dist/index.js"

# Check logs
tail -f ~/nanoclaw/logs/nanoclaw.log
```

---

## Need Help? Use the Setup Agent

If you prefer guided assistance, the **Clawdbot Setup Agent** can walk you through the NanoClaw deployment via phone or chat — from prerequisites through WhatsApp authentication.

The agent handles dependency installation, Claude authentication, container image building, WhatsApp QR scanning guidance, and service installation.

See [`../clawdbot-setup-agent/`](../clawdbot-setup-agent/) for details, or tell your Clawdbot: *"I want to set up NanoClaw"*.

---

## Further Reading

- [NanoClaw GitHub](https://github.com/qwibitai/nanoclaw)
- [Security Model Details](docs/SECURITY-GUIDE.md)
- [Troubleshooting Deep Dive](docs/TROUBLESHOOTING.md)
- [Phase Implementation Plans](PLANNING/)
- [Apple Container Docs](https://developer.apple.com/documentation/virtualization)

---

**Version**: 1.0.0
**Last Updated**: 2026-02-12
**Platform**: macOS Sequoia+ on Apple Silicon
**Source**: [github.com/qwibitai/nanoclaw](https://github.com/qwibitai/nanoclaw)
