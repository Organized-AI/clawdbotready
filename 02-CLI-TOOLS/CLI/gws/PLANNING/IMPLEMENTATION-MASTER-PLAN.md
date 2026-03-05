# gws-workspace — Implementation Master Plan

**Project Path:** ~/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/gws-workspace  
**Machine:** M4 Mac Mini (jordaaan)  
**Tool:** @googleworkspace/cli (gws)

---

## Pre-Implementation Checklist

### ✅ Documentation (Complete)
| Component | Location | Status |
|-----------|----------|--------|
| CLAUDE.md | project root | ✅ |
| Master Plan | PLANNING/IMPLEMENTATION-MASTER-PLAN.md | ✅ |

### ⏳ Code Implementation (To Build)
| Component | Location | Status |
|-----------|----------|--------|
| GCP OAuth credentials | CONFIG/credentials/ | ⏳ |
| gws auth config | CONFIG/gws-config.json | ⏳ |
| OpenClaw skills symlinks | ~/.openclaw/skills/gws-* | ⏳ |
| BHT workflow scripts | SCRIPTS/ | ⏳ |
| gws MCP server config | CONFIG/mcp-server.json | ⏳ |
| Client automation | CLI-TOOLS/ | ⏳ |

---

## Implementation Phases Overview

| Phase | Name | Deliverable | Dependencies |
|-------|------|-------------|--------------|
| 0 | Project Setup | Directory structure, config scaffolding | None |
| 1 | Auth & GCP | OAuth setup, gws auth login | Phase 0 |
| 2 | OpenClaw Skills | gws skills → ~/.openclaw/skills/ | Phase 1 |
| 3 | Core Workflows | Drive audit, Gmail ops, Calendar scripts | Phase 2 |
| 4 | MCP Server | gws as Claude Code MCP | Phase 1 |
| 5 | Client Automation | Myosin / BiOptimizers / RTT / Teleios tools | Phase 3 |

---

## Phase Details

### Phase 0 — Project Setup
- Scaffold all directories (done)
- Write CLAUDE.md and master plan (done)
- Create CONFIG/gws-config.template.json
- Create CONFIG/clients.template.json
- Write .gitignore (exclude credentials)
- Initialize git repo

### Phase 1 — Auth & GCP
- Verify gws is installed (`gws --version`)
- Run `gws auth setup` → walk through GCP project config
- Enable required APIs (Drive, Gmail, Calendar, Sheets, Admin)
- Run `gws auth login` → complete OAuth flow
- Verify: `gws drive files list --params '{"pageSize":5}'`
- Document auth process in DOCUMENTATION/auth-setup.md

### Phase 2 — OpenClaw Skills Integration
- Clone or inspect gws skills from GitHub
- Symlink gws-drive, gws-gmail, gws-calendar, gws-sheets into ~/.openclaw/skills/
- Verify gws-shared skill auto-install block
- Test skills fire correctly in OpenClaw
- Document skills inventory in DOCUMENTATION/skills-inventory.md

### Phase 3 — Core BHT Workflows
- Drive audit script: list client files, flag orphaned docs
- Gmail ops: list/search/label by client domain
- Calendar script: list upcoming client events
- Sheets ops: read/write tracker data
- Save all as SCRIPTS/gws-*.sh

### Phase 4 — MCP Server Setup
- Configure gws MCP server (stdio or SSE)
- Add to Claude Code MCP config (~/.claude/mcp.json or project-level)
- Test: Claude Code can invoke gws tools via MCP
- Document MCP config in DOCUMENTATION/mcp-setup.md

### Phase 5 — Client-Specific Automation
- Myosin: Drive folder structure audit, shared drive access check
- BiOptimizers: GTM/Sheets tracker automation
- RTT: Gmail comms filter, GHL-adjacent calendar sync
- Teleios: Drive doc access audit
- Save as CLI-TOOLS/clients/<client-name>/

