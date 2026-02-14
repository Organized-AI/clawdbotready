# Active Projects Overview

All active development projects in `03-ACTIVE-PROJECTS/`. These are auxiliary to the primary OpenClaw deployment work and focus on tooling, integrations, and SDK development.

---

## Project Summary

| Project | Type | Status | Tech Stack | Priority |
|---------|------|--------|------------|----------|
| [clawdbot-sandbox](#clawdbot-sandbox) | Security SDK | All 7 phases complete | TypeScript, just-bash, AI SDK v6 | Medium |
| [google-ads-cli](#google-ads-cli) | CLI Tool | Ready to execute | TypeScript, google-ads-api, commander | High |
| [meta-ads-cli](#meta-ads-cli) | CLI Tool | In development | TypeScript, commander | Medium |

---

## clawdbot-sandbox

**Package**: `@clawdbot-ready/sandbox` v0.1.0
**Status**: Ready for release (Phase 7/7 complete)
**Location**: `03-ACTIVE-PROJECTS/clawdbot-sandbox/`

### What It Does

Secure sandboxed execution environment for OpenClaw AgentSkills. Uses [just-bash](https://github.com/nichochar/just-bash) to run shell commands inside tiered sandboxes with filesystem, network, and permission controls.

Designed so AI agents can execute bash commands safely without risking the host system.

### Key Features

- **Tiered Sandboxes**: Three levels of escalating access (InMemory, Overlay, ReadWrite)
- **Network Security**: 8 presets (none, github, anthropic, openai, vercel, stripe, standard, full) with URL allowlisting
- **Permission System**: 4 tiers (VPS, Mac Mini, Mac Studio, Agency) controlling command allowlists, filesystem guards, and network access
- **AI SDK Integration**: Tiered bash tool factory compatible with Anthropic AI SDK v6
- **Plugin System**: Lifecycle hooks (onLoad, onUnload, onBeforeExecute, onAfterExecute) with audit logging
- **Error Hierarchy**: 7 custom error classes with structured logging

### Architecture

```
src/
├── sandbox/
│   ├── fs-tiers/          # InMemory, Overlay, ReadWrite sandbox types
│   ├── network/           # Network presets and URL filtering
│   ├── skill-adapter/     # AgentSkill registry and adapter
│   ├── ai-tool/           # AI SDK bash tool integration
│   ├── plugin/            # OpenClaw plugin lifecycle hooks
│   ├── permissions/       # Tier-based permission system
│   └── errors.ts          # Custom error hierarchy
└── index.ts               # Package exports
```

### Phase History

| Phase | Focus | Commit |
|-------|-------|--------|
| 0 | Project setup (TypeScript, Vitest, Biome, Zod v4) | 27bdbef |
| 1 | Filesystem tiers | 27bdbef |
| 2 | Network security | 27bdbef |
| 3 | AgentSkill adapter | 27bdbef |
| 4 | AI SDK bash tool | b376927 |
| 5 | OpenClaw plugin packaging | 5bd9577 |
| 6 | Tier-based permissions | 7c85a54 |
| 7 | Integration tests and hardening | 93f13c3 |

### Test Coverage

204 total tests (201 passed, 3 skipped):
- 14 fs-tiers, 22 network, 38 skill-adapter, 33 ai-tool, 22 plugin, 44 permissions, 20 integration, 11 benchmarks

### Package Exports

```json
{
  ".": "./dist/index.js",
  "./plugin": "./dist/plugin/index.js",
  "./ai": "./dist/sandbox/ai-tool/index.js",
  "./permissions": "./dist/sandbox/permissions/index.js"
}
```

### Next Steps

Ready for npm publication and consumption by OpenClaw Gateway.

---

## google-ads-cli

**Status**: Ready to execute (prerequisites complete, implementation pending)
**Location**: `03-ACTIVE-PROJECTS/google-ads-cli/`
**Priority**: High (business-critical)

### What It Does

Lightweight CLI replacement for the original Python-based Google Ads skill that caused EMFILE errors on the client Mac Mini. Provides Google Ads API access for OpenClaw agents via a single-file skill wrapper.

### Problem It Solves

The original Python skill had **15,923 files** in its virtualenv. The OpenClaw file watcher opened 10,267 file descriptors, hitting the macOS limit and crashing the Telegram bot with EMFILE errors. This CLI replaces all of that with a single Node.js tool.

### Commands

| Command | Description |
|---------|-------------|
| `campaigns:list [--filter NAME]` | List campaigns |
| `metrics:cpa [--filter NAME] [--date DATE]` | CPA metrics (critical for client) |
| `budget:update --campaign-id ID --amount CENTS` | Update campaign budget |
| `report:generate [--filter NAME] [--date RANGE]` | Performance report |
| `campaign:manage [--action create\|pause\|enable]` | Manage campaign state |

### Tech Stack

- Node.js + TypeScript
- `google-ads-api` v18+
- `commander` for CLI parsing
- Deployed to M1 Mac Mini (openclaw@100.66.145.48)

### Implementation Plan

5 phases, estimated 3.75 hours total:

| Phase | Task | Time |
|-------|------|------|
| 1 | Project setup | 15 min |
| 2 | Core implementation (5 commands) | 2 hrs |
| 3 | Configuration and installation | 30 min |
| 4 | OpenClaw integration | 30 min |
| 5 | Testing and verification | 30 min |

### Prerequisites (all complete)

- SSH access to M1 Mac Mini
- Original Python skill archived
- Credentials extracted
- Gateway stable at ~56 file descriptors
- EMFILE issue fixed (LaunchAgent limits increased)

### Success Criteria

- CLI installed and working on Mac Mini
- 1 file in skills/ directory (vs 15,923)
- File descriptors stable at ~56
- Telegram bot functional with full Google Ads features

---

## meta-ads-cli

**Package**: `meta-ads-cli` v1.0.0
**Status**: In development (CLI structure complete, ready for feature expansion)
**Location**: `03-ACTIVE-PROJECTS/meta-ads-cli/`

### What It Does

CLI tool for Meta/Facebook Marketing API. Manages ad accounts, campaigns, ad sets, ads, creatives, insights, and targeting research. Follows the same pattern as google-ads-cli for OpenClaw agent integration.

### Architecture

```
src/
├── index.ts              # CLI entry with commander
├── lib/
│   ├── client.ts         # Meta Graph API wrapper
│   ├── auth.ts           # OAuth authentication
│   └── format.ts         # Output formatting (tables, JSON)
└── commands/
    ├── accounts.ts       # Account management
    ├── campaigns.ts      # Campaign operations
    ├── adsets.ts         # Ad set operations
    ├── ads.ts            # Ad management
    ├── targeting.ts      # Interest/location research
    ├── insights.ts       # Performance metrics
    └── auth-cmd.ts       # OAuth login flow
```

### Commands (40+)

**Account Management**: `accounts`, `account-info`, `account-pages`

**Campaign Operations**: `campaigns`, `campaign-details`, `create-campaign`, `update-campaign`

**Ad Set Management**: `adsets`, `adset-details`, `create-adset`, `update-adset`

**Ad Management**: `ads`, `ad-details`, `creatives`, `create-ad`, `update-ad`

**Creative and Imaging**: `upload-image`, `create-creative`

**Insights and Reporting**: `insights`, `report`

**Targeting Research**: `search-interests`, `interest-suggestions`, `audience-size`, `search-locations`

**Authentication**: `login`, `token-status`

### Tech Stack

- Node.js >= 18.0.0
- TypeScript 5.7.0
- `commander` 12.1.0

### Global Options

- `--json` for raw JSON output
- `--verbose` for detailed output

---

## Archive Policy

Projects are archived when:
- **Deployed and stable** for 24+ hours: moved to `.archive/`
- **Cancelled**: moved to `.archive/`
- **On hold**: kept in `03-ACTIVE-PROJECTS/` with status note

Archived projects go to `.archive/` with dated folder names.
