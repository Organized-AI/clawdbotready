# Phase 2: nanoclaw Messaging Integration

## Claude Code Prompt

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md, CLAUDE.md, and PLANNING/features/PHASE-1-JUST-BASH.md for context.
Verify Phase 1 is complete by checking for packages/sandbox/ and the feature/just-bash-sandbox branch.

You are integrating nanoclaw (https://github.com/Organized-AI/nanoclaw) as the messaging gateway layer for OpenClaw.

## Branch Setup
git checkout main && git pull
git checkout -b feature/nanoclaw-messaging

## Tasks

### 1. Add nanoclaw to project
- Clone the repo: git submodule add https://github.com/Organized-AI/nanoclaw.git packages/nanoclaw
- Review its architecture: Node.js 20+, TypeScript, SQLite, container isolation
- Verify it builds: cd packages/nanoclaw && npm install && npm run build

### 2. Configure nanoclaw → OpenClaw Gateway
Create packages/nanoclaw-bridge/src/index.ts:
- Bridge between nanoclaw's messaging interface and OpenClaw Gateway
- Route incoming messages from WhatsApp/iMessage/Telegram to Gateway
- Route Gateway responses back to messaging channels
- Handle per-group context isolation (each chat group = isolated agent context)

### 3. Wire just-bash sandbox as execution backend
- nanoclaw's sandboxed filesystem → replaced by just-bash InMemoryFs
- When agent wants to execute a command → routes through @clawdbot-ready/sandbox
- Each group gets its own sandbox instance (isolated filesystems)

### 4. Configure messaging channels
Create config/messaging.env:
```
# WhatsApp Business API
WHATSAPP_TOKEN=
WHATSAPP_PHONE_ID=
WHATSAPP_VERIFY_TOKEN=

# Telegram Bot
TELEGRAM_BOT_TOKEN=

# iMessage (macOS only, via Messages.app integration)
IMESSAGE_ENABLED=true

# General
DEFAULT_CHANNEL=whatsapp
MAX_GROUP_CONTEXTS=50
CONTEXT_MEMORY_LIMIT_MB=256
```

### 5. Set up scheduled tasks
- Configure nanoclaw's task scheduler to use cron syntax
- Create default scheduled tasks:
  - Daily health report
  - Weekly usage summary
  - Configurable custom tasks per group

### 6. Container isolation setup
- For VM deployments: nanoclaw containers run INSIDE the Lume VM
- For native deployments: use Apple Container framework (or Docker fallback)
- Document both approaches in setup guides

### 7. Create setup guide
Create DOCUMENTATION/openclaw/messaging-setup.md:
- WhatsApp Business API setup walkthrough
- Telegram Bot creation steps
- iMessage configuration (macOS only)
- Group context management
- Scheduled tasks configuration

### 8. Integration tests
Create tests/nanoclaw-integration.test.ts:
- Test message routing (incoming → Gateway → response)
- Test group context isolation
- Test sandbox execution per group
- Test scheduled task execution
- Test channel switching

### 9. Git commit
git add -A
git commit -m "feat: integrate nanoclaw messaging gateway

- Add nanoclaw as messaging layer (WhatsApp, iMessage, Telegram)
- Bridge nanoclaw to OpenClaw Gateway
- Per-group context isolation with sandboxed filesystems
- Scheduled task system with cron syntax
- Container isolation for defense-in-depth

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] WhatsApp messages reach agent via nanoclaw
- [ ] Each group has isolated context and filesystem
- [ ] Commands execute through just-bash sandbox
- [ ] Scheduled tasks run on configured intervals
- [ ] iMessage support working on macOS deployments
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
WHATSAPP_TOKEN=your-whatsapp-token
WHATSAPP_PHONE_ID=your-phone-id
TELEGRAM_BOT_TOKEN=your-telegram-token
```
