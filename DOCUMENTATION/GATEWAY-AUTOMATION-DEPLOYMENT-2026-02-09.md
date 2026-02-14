# Gateway Automation Deployment — Feb 9, 2026

**For: Jordaaan Hill**
**Client Mac Mini**: `openclaw@100.66.145.48` (Tailscale)
**Gateway**: OpenClaw v2026.2.1, Telegram bot `@SAMyosin_bot`
**Client User**: Sean Clayton (`@sclayton567`)

---

## What We Built

An end-to-end usage intelligence pipeline that:

1. **Pulls session logs** from the client Mac Mini
2. **Analyzes 184 user messages** across 15 sessions to identify patterns
3. **Deployed 4 CLI tools** and a campaign management workflow based on real usage data
4. **Fixed the gateway restart** so the agent can self-heal
5. **Installed a scheduled cron job** for proactive daily reports

Everything is deployed and live.

---

## Usage Analysis Summary

**Period**: Feb 3–9, 2026 | **Sessions**: 15 | **Messages**: 184 | **Tool Calls**: 212

### What Sean Is Actually Asking For

| Intent | Count | What It Means |
|--------|-------|---------------|
| General questions | 108 | Conversational, setup help, "are you there?" |
| Setup & config | 20 | Browser extension, Chrome relay, Asana, Slack, GTM |
| Troubleshooting | 13 | "This is not working", browser control issues |
| Reporting | 12 | Campaign performance, dashboards, daily summaries |
| Google Ads performance | 9 | "How is Blade doing?", CPA checks, keyword research |
| Bot status | 9 | "Are you working now?", connectivity checks |
| Google Ads campaigns | 8 | "What PMAX campaigns are active?", campaign lists |
| Google Ads management | 5 | Pause/enable campaigns, budget changes |

### What Was Breaking

| Tool | Failures | Root Cause |
|------|----------|------------|
| Browser | 26 failures | Chrome extension not installed — Sean struggled with setup |
| Exec | 14 failures | Health check cron reporting issues as failures |
| Gateway restart | 4 failures | `commands.restart=false` blocked self-healing |
| Read | 5 failures | ENOENT — files didn't exist at expected paths |
| Message (Telegram) | 3 failures | `chat not found` — bot not started in DM |
| memory_search | 3 failures | OpenAI API key expired (401) — now fixed |

### Key Observations

- **Browser control is the #1 pain point.** Sean spent multiple sessions trying to install the Chrome extension relay. The agent kept failing to use browser tools because the extension wasn't set up. This needs a guided walkthrough or simplified install.
- **Google Ads queries are the highest-value automation target.** Sean asks about campaign performance almost daily — perfect for proactive reporting.
- **Health check cron inflates "reporting" count.** ~8 of the 12 reporting intents are automated cron health checks, not real user requests.
- **Sean shared credentials in plaintext via Telegram** (Google password, OAuth secrets). Consider a secure onboarding flow for future clients.

---

## What Was Deployed

### 1. Gateway Restart Fix

**Problem**: Agent couldn't restart itself when services hung. Failed 4 times with "Gateway restart is disabled."

**Fix**: Set `commands.restart = true` in `~/.openclaw/openclaw.json` and reloaded config via SIGUSR1.

**Status**: Live and verified.

---

### 2. `blade-daily-report` CLI Tool

**Location**: `~/bin/blade-daily-report` on Mac Mini

**What it does**: Generates a formatted Blade campaign performance summary with CPA, spend, conversions, clicks, and impressions.

**Usage**:
```bash
blade-daily-report              # Today's metrics
blade-daily-report yesterday    # Yesterday
blade-daily-report last7        # Last 7 days
blade-daily-report last30       # Last 30 days
```

**Addresses**: 9 "google-ads-performance" intents. Sean no longer needs to ask "how is Blade doing" — the agent can run this tool instantly or it gets sent automatically via the cron job.

**Verified**: Returns full CPA table + campaign list for Blade account (1741833734).

---

### 3. `campaign-status` CLI Tool

**Location**: `~/bin/campaign-status` on Mac Mini

**What it does**: Lists all active campaigns with status and budget for any Google Ads sub-account.

**Usage**:
```bash
campaign-status                              # Blade (default)
campaign-status --customer-id 6111060860     # Foundation Law
campaign-status --filter PMAX                # Filter by name
campaign-status --help                       # Show all accounts
```

**Known sub-accounts**:
| Customer ID | Account |
|------------|---------|
| 1741833734 | Blade (default) |
| 6111060860 | Myosin - Foundation Law |
| 1729599101 | Myosin - MVA Funnel |
| 6650090207 | Myosin - Mass Tort Law |
| 6890103064 | Teleios Health |

**Addresses**: 8 "google-ads-campaigns" intents. Verified: returns 303 campaigns for Blade.

---

### 4. `fix-memory-search` Diagnostic Tool

**Location**: `~/bin/fix-memory-search` on Mac Mini

**What it does**: Diagnoses the OpenAI API key used for memory_search embeddings. Checks key existence, validates against the embeddings endpoint, and provides fix instructions if broken.

**Usage**:
```bash
fix-memory-search    # Run diagnostics
```

**Addresses**: 3 memory_search failures (was 401 — OpenAI key expired). Verified: key found in skills config, embeddings endpoint responding HTTP 200.

---

### 5. Campaign Management Workflow (TOOLS.md)

**Location**: Documented in `~/.openclaw/workspace/TOOLS.md` on Mac Mini

**What it does**: Provides the agent with a step-by-step safety workflow for campaign modifications:

1. **Confirm** the exact action with the user
2. **Show current state** before making changes
3. **Execute only after explicit confirmation**
4. **Verify** the change took effect
5. **Never** modify campaigns without user approval

**Addresses**: 5 "google-ads-management" intents. This ensures Sean's campaigns can't be accidentally modified.

---

### 6. Scheduled Daily Report (Cron)

**Location**: `~/bin/scheduled-report-cron` on Mac Mini

**Crontab**: `0 8 * * 1-5` — runs at 8:00 AM CST every weekday

**What it does**: Automatically runs `blade-daily-report today` and sends the result to Sean via Telegram through the gateway API. No action needed — Sean gets a performance summary in his Telegram every morning.

**Addresses**: 12 "reporting" intents. Proactive instead of reactive.

**Log file**: `~/logs/scheduled-reports.log`

---

## Infrastructure Created

### Usage Analysis Pipeline

A reusable pipeline for monitoring what the client is doing and identifying new automation opportunities:

| Component | Location | Purpose |
|-----------|----------|---------|
| Log puller | `scripts/pull-gateway-logs.sh` | SSH into Mac Mini, pull session JSONL files |
| Analyzer | `scripts/analyze-gateway-usage.ts` | Parse sessions, classify intents, detect pain points |
| Report | `.analysis/reports/latest-report.md` | Human-readable findings |
| Patterns | `.analysis/reports/patterns.json` | Machine-readable data |
| Skill | `.claude/skills/gateway-insights/SKILL.md` | Turn patterns into automations |
| Command | `/oc:analyze-usage` | Run full pipeline in one step |

**Run the pipeline**:
```bash
./scripts/pull-gateway-logs.sh                                          # Pull logs
npx tsx scripts/analyze-gateway-usage.ts --raw-dir .analysis/raw/latest # Analyze
```

### Deployment Helper

`scripts/deploy-automation.sh` — reusable tool for deploying any script to the Mac Mini:
```bash
./scripts/deploy-automation.sh scripts/my-new-tool.sh my-new-tool
```

Handles: connectivity check, SCP, chmod +x, backup of existing tool, smoke test.

---

## What's on TOOLS.md Now

The agent's `~/.openclaw/workspace/TOOLS.md` (134 lines) now documents:

1. **Google Ads CLI** — all 5 commands with examples and all 14 sub-account IDs
2. **blade-daily-report** — usage and examples
3. **campaign-status** — usage, examples, account list
4. **fix-memory-search** — usage and purpose
5. **Campaign Management (Safe Workflow)** — 5-step confirmation process
6. **scheduled-report-cron** — what it does, cron schedule

The agent reads this file to know what tools are available and how to use them.

---

## Technical Notes

- All scripts source `~/.zprofile` at the top to get the correct PATH in non-interactive shells (SSH/cron). Without this, `~/bin` and homebrew binaries aren't available.
- The gateway runs on port `18789` (not 3578).
- The OpenAI API key is stored at `.skills.entries["openai-image-gen"].apiKey` in `openclaw.json` — not under a top-level `openai` key.
- Session JSONL files use `entry.message` (not `entry.content`) — OpenClaw convention.
- SSH access is `openclaw@` (not `admin@`).

---

## Next Steps

Based on the analysis, these remain unaddressed:

1. **Browser control setup** — The #1 pain point (26 failures). Sean needs a guided Chrome extension install. Consider creating a step-by-step walkthrough or a simpler browser integration.
2. **Multi-account support** — Sean asked about AK law firm and other non-Blade accounts. The tools support `--customer-id` but Sean may not know the IDs. Consider a tool that lists all accounts.
3. **Capability router** — The agent reported "I can't do that" 7 times. A skill that suggests alternatives when a capability isn't available would reduce frustration.
4. **Telegram DM setup** — Message tool failed 3 times with "chat not found". Sean and Jordaaan need to start the bot in DM for direct messages to work.

---

*Generated 2026-02-09 by the Gateway Usage Intelligence Pipeline*
