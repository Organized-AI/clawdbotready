# Google Workspace Agent (gws-workspace)

## Project Overview
Unified Google Workspace CLI integration for BHT/Myosin client work. Leverages `@googleworkspace/cli` (gws) for terminal-based Drive, Gmail, Calendar, Sheets, Docs, Chat, and Admin access — with OpenClaw skill integration and custom BHT workflow automation.

**Tool:** `gws` — Google Workspace CLI  
**Install:** `npm install -g @googleworkspace/cli`  
**Docs:** https://github.com/googleworkspace/cli

## Objectives
1. Authenticate gws against a GCP project with proper OAuth
2. Install gws agent skills into OpenClaw (`~/.openclaw/skills/`)
3. Build custom BHT workflows (Drive audit, Gmail client comms, Calendar ops)
4. Configure gws as MCP server for Claude Code agent use
5. Create client-specific automation for Myosin, BiOptimizers, RTT, Teleios

## Project Structure
```
.claude/commands/     - Slash commands for Claude Code
CLI-TOOLS/            - gws wrapper scripts and helpers
CONFIG/               - auth config, GCP project details
DOCUMENTATION/        - workflow docs, API references
PLANNING/             - implementation phases
PROMPTS/              - agent prompt templates
SCRIPTS/              - shell automation scripts
```

## Commands (slash)
- `/gws-auth` - Authenticate and verify gws setup
- `/gws-audit` - Run Drive/Gmail audit for a client
- `/gws-sync` - Sync OpenClaw skills from gws repo
- `/gws-workflow` - Execute a named BHT workflow

## Key Config
- `CONFIG/gws-config.json` - GCP project, OAuth paths
- `CONFIG/clients.json` - Client workspace accounts
- `DOCUMENTATION/auth-setup.md` - Auth flow documentation
- `PLANNING/IMPLEMENTATION-MASTER-PLAN.md` - Phase roadmap

## Workflow
1. **Setup**: Install gws, configure GCP OAuth credentials
2. **Skills**: Symlink gws skills into OpenClaw
3. **Workflows**: Build BHT-specific automation scripts
4. **MCP**: Configure gws MCP server for Claude Code
5. **Clients**: Deploy client-specific Drive/Gmail workflows
