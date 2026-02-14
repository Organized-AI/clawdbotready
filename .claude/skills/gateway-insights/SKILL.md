---
name: gateway-insights
description: |
  Analyze OpenClaw Gateway usage patterns and generate Skills, Agents, or CLI tools
  based on real client behavior. Reads analysis reports from .analysis/reports/ and
  turns detected patterns into actionable automation.
  Use when: (1) User says "gateway insights", "analyze usage", "what is my client doing",
  (2) User wants to create tools from usage patterns, (3) User asks "what should I build next",
  (4) After running the log analysis pipeline (just log-report or scripts/pull-gateway-logs.sh + analyze-gateway-usage.ts).
metadata:
  version: 1.0.0
  integrates_with:
    - skill-creator-enhanced (skill) - for packaging generated skills
    - openclaw-session-learning (skill) - complementary session history analysis
  triggers:
    - "gateway insights"
    - "analyze usage"
    - "what is my client doing"
    - "create tools from logs"
    - "what should I build"
    - "usage patterns"
---

# Gateway Usage Insights

Turn real client behavior into purpose-built automation.

## Workflow

### 1. Check for Latest Report

Read `.analysis/reports/latest-report.md` and `.analysis/reports/patterns.json`.

If no report exists, tell the user to run the pipeline first:
```bash
./scripts/pull-gateway-logs.sh        # Pull logs from Mac Mini
npx tsx scripts/analyze-gateway-usage.ts --raw-dir .analysis/raw/latest  # Analyze
```

### 2. Present Key Findings

Summarize from the report:
- **Top intents**: What is the client actually asking for?
- **Tool failures**: What's breaking?
- **Capability gaps**: Where did the agent say "I can't do that"?
- **Repeated patterns**: What gets asked over and over?

### 3. Review Suggested Automations

The report includes a "Suggested Automations" section. For each suggestion, evaluate:
- Is the pattern real and recurring? (Check the User Message Timeline)
- Would automation save the client time?
- Does it fit the existing tool ecosystem?

### 4. Generate Automation

For each approved suggestion, create the appropriate artifact:

#### Skill (domain knowledge + multi-step workflows)
Create `.claude/skills/<name>/SKILL.md` with:
```yaml
---
name: <skill-name>
description: |
  <What it does, when to use it>
  Use when: <trigger conditions from report>
---
```
Best for: Recurring domain queries (Google Ads performance, reporting)

#### Agent (specialized workers)
Create `.claude/agents/<name>.md` with:
```yaml
---
name: <agent-name>
description: <What it does>
triggers:
  - "<trigger phrase>"
---
```
Best for: Multi-step workflows (campaign management, audit sequences)

#### CLI Tool (single-command shortcuts)
Create `02-CLI-TOOLS/CLI/<name>.sh` following the `session-tools.sh` pattern:
- `#!/usr/bin/env bash` + `set -euo pipefail`
- Color helpers, input validation
- Clear help text
Best for: Frequently repeated single commands

### 5. Validate Against Real Usage

After creating an automation, cross-reference against the User Message Timeline in the report:
- Would this have helped in the actual conversations?
- Does it handle the edge cases visible in the logs?
- Does it address the pain points identified?

## Data Sources

| Source | Path | Format |
|--------|------|--------|
| Analysis report | `.analysis/reports/latest-report.md` | Markdown |
| Structured patterns | `.analysis/reports/patterns.json` | JSON |
| Raw session logs | `.analysis/raw/<date>/sessions/*.jsonl` | NDJSON |
| Gateway system log | `.analysis/raw/<date>/logs/gateway.log` | Plain text |

## Priority Decision Tree

```
Pattern from report
    |
    +-- Repeated 5+ times, single tool call
    |   -> CLI Tool (highest ROI, fastest to build)
    |
    +-- Repeated 3+ times, requires domain context
    |   -> Skill (with references/ for domain knowledge)
    |
    +-- Multi-step sequence, needs confirmation gates
    |   -> Agent (with step-by-step workflow)
    |
    +-- Tool failure / capability gap
        -> Fix the root cause first, then automate
```

## Running the Pipeline

```bash
# Full pipeline (pull + analyze)
./scripts/pull-gateway-logs.sh && npx tsx scripts/analyze-gateway-usage.ts --raw-dir .analysis/raw/latest

# Just analyze (if logs already pulled)
npx tsx scripts/analyze-gateway-usage.ts --raw-dir .analysis/raw/latest

# View report
cat .analysis/reports/latest-report.md
```
