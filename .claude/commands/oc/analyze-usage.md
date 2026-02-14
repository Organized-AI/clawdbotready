---
description: Run the full gateway usage analysis pipeline — pull logs from client Mac Mini, analyze sessions, and generate an actionable report with skill/agent/CLI tool suggestions.
---

# Analyze Client Usage

Run the gateway usage intelligence pipeline to understand what the client is doing and what tools to build next.

## Steps

### Step 1: Pull Fresh Logs
Run the log pull script to get the latest session data from the Mac Mini:
```bash
./scripts/pull-gateway-logs.sh
```
This SSHs into `openclaw@100.66.145.48` and pulls session JSONL files, gateway logs, and daily logs to `.analysis/raw/<date>/`.

### Step 2: Analyze
Run the TypeScript analyzer:
```bash
npx tsx scripts/analyze-gateway-usage.ts --raw-dir .analysis/raw/latest
```
This generates:
- `.analysis/reports/latest-report.md` — Human-readable report
- `.analysis/reports/patterns.json` — Machine-readable patterns

### Step 3: Present Report
Read `.analysis/reports/latest-report.md` and present the key findings:
1. Top user intents (what the client is asking for)
2. Tool usage and failure rates
3. Pain points
4. Suggested automations

### Step 4: Act on Suggestions
For each suggested automation in the report, ask the user if they want to create it. Use the gateway-insights skill to generate the appropriate artifact (Skill, Agent, or CLI tool).

## Output
Show a concise summary with the top 3-5 actionable findings, then offer to create specific automations.
