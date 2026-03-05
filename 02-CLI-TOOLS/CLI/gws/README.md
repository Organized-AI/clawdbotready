# gws — Google Workspace CLI Tool

**Package:** `@googleworkspace/cli`  
**Install:** `npm install -g @googleworkspace/cli`  
**Docs:** https://github.com/googleworkspace/cli

## What It Does

Unified CLI for Drive, Gmail, Calendar, Sheets, Docs, Chat, and Admin — built for humans and agents. Dynamically reads the Google Discovery Service so it stays current as APIs evolve.

Key features:
- Terminal access to all Google Workspace APIs
- 40+ agent skills includeable in OpenClaw (`~/.openclaw/skills/`)
- MCP server mode for Claude Code tool use
- git-style pull/push for Sheets/Docs editing

## Quick Start

```bash
npm install -g @googleworkspace/cli
gws auth setup        # configure GCP project + OAuth
gws auth login        # complete OAuth flow
gws drive files list --params '{"pageSize":5}'
```

## Phases

See `PLANNING/IMPLEMENTATION-MASTER-PLAN.md` for full 6-phase roadmap.

| Phase | Name |
|-------|------|
| 0 | Project Setup |
| 1 | Auth & GCP |
| 2 | OpenClaw Skills Integration |
| 3 | Core BHT Workflows |
| 4 | MCP Server Setup |
| 5 | Client-Specific Automation |

## Claude Code Entry Point

```bash
cd "/Users/jordaaan/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready/02-CLI-TOOLS/CLI/gws"
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and PLANNING/IMPLEMENTATION-MASTER-PLAN.md. Execute PLANNING/implementation-phases/PHASE-0-PROMPT.md.`
