# OpenClaw × Apify — Phased Build Plan

**Project:** Clawdbot Ready
**Path:** `Clawdbot Ready/`
**Reference:** `SETUP GUIDES/OPENCLAW-ARCHITECTURE-MAP.html`
**Dependencies:** OpenClaw installed, Apify account + CLI, Anthropic API key

---

## Pre-Implementation Checklist

| Component | Location | Status |
|-----------|----------|--------|
| OpenClaw Architecture Map | `SETUP GUIDES/OPENCLAW-ARCHITECTURE-MAP.html` | ✅ |
| ClawHost Setup Guide | `SETUP GUIDES/clawhost-setup-guide.md` | ✅ |
| OpenClaw Native Setup | `openclaw-native-setup/` | ✅ |
| OpenClaw VM Setup | `openclaw-vm-setup/` | ✅ |
| Apify Skills (to build) | `skills/apify-*` | ⏳ |
| Cron Pre-fetch Jobs (to build) | `scripts/cron/` | ⏳ |
| Webhook Handler (to build) | `scripts/webhooks/` | ⏳ |
| Integration Tests (to build) | `scripts/tests/` | ⏳ |

---

## Phase Overview

| Phase | Name | Dependencies | Complexity |
|-------|------|-------------|------------|
| 0 | Foundation & Apify CLI Setup | None | Simple |
| 1 | Skills — Agent-Initiated Apify Actors | Phase 0 | Medium |
| 2 | Cron + Pre-fetch Pipeline | Phase 1 | Medium |
| 3 | Webhook → Isolated Agent Turns | Phase 2 | Complex |
| 4 | MCP Direct Tool Integration | Phase 1 | Medium |
| 5 | Context Budget Manager | Phase 1-4 | Complex |
| 6 | Channel Delivery & End-to-End Testing | Phase 1-5 | Complex |

---

## Phase 0: Foundation & Apify CLI Setup

**Goal:** OpenClaw running with Apify CLI authenticated and accessible from agent exec tool.

### Tasks

1. Verify OpenClaw daemon is running and accepting WebSocket connections on `127.0.0.1:18789`
2. Install Apify CLI globally: `npm i -g apify-cli`
3. Authenticate: `apify login --token <APIFY_TOKEN>`
4. Create `~/.openclaw/skills/apify-base/` directory structure
5. Write `SKILL.md` for apify-base with YAML frontmatter defining when agent should consider Apify actors
6. Create `TOOLS.md` addition documenting Apify exec patterns (CLI call, curl to API, output parsing)
7. Test: Agent can run `apify call apify/hello-world` via exec tool and receive structured output

### Success Criteria

- [ ] `openclaw status` shows daemon healthy
- [ ] `apify whoami` returns authenticated user
- [ ] Agent exec of `apify call apify/hello-world` returns valid JSON
- [ ] `apify-base` skill loads in agent session

---

## Phase 1: Skills — Agent-Initiated Apify Actors

**Goal:** Agent autonomously decides when to call Apify actors for web data needs. Results are structured and minimal.

### Tasks

1. Create `~/.openclaw/skills/apify-web-scraper/SKILL.md` — teaches agent to use `apify/website-content-crawler` for on-demand page scraping
2. Create `~/.openclaw/skills/apify-google-search/SKILL.md` — teaches agent to use `apify/google-search-scraper` for search queries
3. Create `~/.openclaw/skills/apify-social-listener/SKILL.md` — teaches agent to monitor social mentions via relevant actors
4. Implement output truncation helper script (`scripts/apify-output-trim.sh`) that extracts only essential fields from actor output JSON
5. Add skill chaining logic: agent reads actor output → trims → only injects summary into context
6. Test: Ask agent "What's the latest news about OpenClaw?" — agent should autonomously invoke google-search skill, trim results, respond with sources

### Success Criteria

- [ ] 3 Apify skills registered and loadable
- [ ] Agent autonomously invokes correct skill based on query type
- [ ] Tool output per invocation stays under 500 tokens after trimming
- [ ] Agent cites sources from Apify results

---

## Phase 2: Cron + Pre-fetch Pipeline

**Goal:** Scheduled Apify actor runs that store results locally. Agent reads pre-fetched summaries instead of scraping live. Zero context cost at interaction time.

### Tasks

1. Create `scripts/cron/` directory with job definitions
2. Build `morning-briefing.sh` — runs `apify/google-search-scraper` for configured topics → writes `~/.openclaw/prefetch/morning-briefing.md`
3. Build `competitor-monitor.sh` — runs website-content-crawler on competitor URLs → diffs against previous run → writes `~/.openclaw/prefetch/competitor-changes.md`
4. Build `social-mentions.sh` — scrapes configured social queries → writes `~/.openclaw/prefetch/social-mentions.md`
5. Register cron jobs in OpenClaw via agent cron tool or `openclaw.json` config
6. Create `~/.openclaw/skills/apify-prefetch-reader/SKILL.md` — teaches agent to read prefetch files when asked about monitored topics
7. Add HEARTBEAT.md entry: "Check prefetch directory for unread briefings"
8. Test: Cron fires → file written → next heartbeat agent reads and can summarize without any live API calls

### Success Criteria

- [ ] 3 cron jobs running on schedule
- [ ] Prefetch files written as clean Markdown summaries (under 200 lines each)
- [ ] Agent reads prefetch on heartbeat and can answer questions from cached data
- [ ] Zero Apify API calls during user interaction for monitored topics

---

## Phase 3: Webhook → Isolated Agent Turns

**Goal:** Apify actor completion triggers OpenClaw webhook → isolated agent session processes results and delivers alert to configured channel.

### Tasks

1. Configure OpenClaw webhook endpoint (check `openclaw.json` for webhook settings)
2. Create webhook handler script that receives Apify webhook payload and injects into isolated agent session
3. Build `apify-alert-processor` skill — teaches isolated agent how to parse Apify webhook payloads and format alerts
4. Configure Apify actor webhook integration: on run completion → POST to OpenClaw webhook URL
5. Set up channel delivery: agent formats alert → sends via `message` tool to configured channel (Discord/Telegram/WhatsApp)
6. Build price-drop monitor as reference implementation: Apify actor scrapes product page on schedule → detects price change → webhook → agent alerts user on Telegram
7. Test: Trigger Apify actor manually → webhook fires → agent processes → message appears in channel

### Success Criteria

- [ ] Webhook endpoint receiving Apify payloads
- [ ] Isolated sessions created (no main context pollution)
- [ ] Alert messages delivered to at least 1 channel
- [ ] Price-drop reference implementation working end-to-end

---

## Phase 4: MCP Direct Tool Integration

**Goal:** Apify actors available as MCP tools for quick single-call lookups. Context budget enforced.

### Tasks

1. Check if OpenClaw supports MCP tool registration (mcpc or native MCP)
2. Register 2-3 high-value Apify actors as MCP tools (RAG web browser, Google Search, content extractor)
3. Implement token budget wrapper: before returning MCP tool result, truncate to max 400 tokens
4. Add `TOOLS.md` guidance: "Prefer skills/prefetch over MCP for multi-step research. Use MCP only for single quick lookups."
5. Test: Agent uses MCP tool for single lookup, result stays within token budget

### Success Criteria

- [ ] MCP tools registered and callable
- [ ] Token budget enforced (max 400 tokens per result)
- [ ] Agent prefers skills/prefetch pattern over MCP for complex queries
- [ ] No context rot from chained MCP calls

---

## Phase 5: Context Budget Manager

**Goal:** Cross-cutting system that tracks context window usage from all Apify integrations and enforces limits.

### Tasks

1. Create `scripts/context-budget.sh` — estimates current context usage from session transcript
2. Build context budget skill that agent checks before invoking any Apify tool
3. Implement fallback behavior: if budget >70% → use prefetch only; if >85% → refuse new Apify calls and suggest compaction
4. Add pre-compaction memory flush for Apify data: before compaction, write important Apify findings to MEMORY.md
5. Create monitoring dashboard data: log context usage per Apify invocation to `~/.openclaw/metrics/context-usage.jsonl`
6. Test: Fill context with multiple Apify calls → budget manager triggers → agent falls back to prefetch

### Success Criteria

- [ ] Context budget tracked per session
- [ ] Fallback behavior triggers at 70% and 85% thresholds
- [ ] Pre-compaction flush preserves critical Apify findings
- [ ] Metrics logged for analysis

---

## Phase 6: Channel Delivery & End-to-End Testing

**Goal:** All 4 Apify integration patterns working together, delivering through multiple channels, with comprehensive test coverage.

### Tasks

1. End-to-end test: Skills pattern — user asks question → agent scrapes via Apify → responds with sources
2. End-to-end test: Cron pattern — scheduled scrape → prefetch file → heartbeat reads → morning briefing delivered to Telegram
3. End-to-end test: Webhook pattern — external event → Apify actor → webhook → isolated session → alert on Discord
4. End-to-end test: MCP pattern — quick lookup → token-budgeted result → inline response
5. Cross-pattern test: Agent decides which pattern to use based on query type and context budget
6. Channel matrix test: Verify delivery works across Discord, Telegram, and WhatsApp for each pattern
7. Write `SETUP GUIDES/APIFY-INTEGRATION-GUIDE.md` documenting all patterns with examples
8. Update CLAUDE.md with Apify integration context for future Claude Code sessions

### Success Criteria

- [ ] All 4 patterns passing end-to-end tests
- [ ] Agent intelligently selects pattern based on context
- [ ] Delivery confirmed on 3+ channels
- [ ] Integration guide written and added to SETUP GUIDES
- [ ] CLAUDE.md updated

---

## Execution Protocol

```bash
cd "/Users/jordaaan/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/Clawdbot Ready"
claude --dangerously-skip-permissions

# In Claude Code:
"Read PLANNING/OPENCLAW-APIFY-BUILD-PLAN.md and execute Phase 0"
```

### Phase Completion

After each phase:
1. Verify all success criteria checkboxes
2. Git commit: `git commit -am "Phase X complete: [phase name]"`
3. Move to next phase prompt
