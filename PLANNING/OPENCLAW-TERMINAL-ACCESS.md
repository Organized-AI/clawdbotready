# OpenClaw Terminal Access: Claude Code Integration

> Planning document for giving OpenClaw agents access to Claude Code through multiple interfaces.

**Created**: 2026-03-04
**Status**: Planning / Discussion
**Related**: PHASE-5-AGENT-SANDBOX.md, exec-approvals.json, OPENCLAW-UPLEVEL-PLAN.md

---

## Vision

Give OpenClaw agents **options** for accessing Claude Code — not locked into a single method. The agent should be able to choose the right access method based on the task at hand, just like a developer picks between terminal, web, and mobile depending on context.

## Why This Matters

OpenClaw currently operates in a restricted sandbox (deny-by-default exec-approvals). It can read/write workspace files and run basic commands — but it can't do real development work. Giving it Claude Code access transforms it from a messaging gateway into a **development orchestrator** that can:

- Fix bugs and ship features across repos
- Manage infrastructure and deployments
- Coordinate multiple parallel workstreams
- Self-improve its own codebase

---

## Access Methods

### 1. Claude Agent SDK (Library Integration)

**What**: Import `@anthropic-ai/claude-agent-sdk` directly into OpenClaw's Node.js process.

**How it works**:
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Fix the auth bug in packages/gateway/src/auth.ts",
  options: {
    allowedTools: ["Read", "Edit", "Bash", "Glob", "Grep"],
    model: "sonnet",
    maxBudgetUsd: 2.00,
  }
})) {
  // Stream results back to the chat client
}
```

**Strengths**:
- No shell access needed — it's a library call inside OpenClaw's process
- Full programmatic control (tools, budget, model, permissions)
- Can run multiple sessions in parallel via `Promise.all()`
- Session resumption via `session_id`
- Structured JSON output with schema enforcement

**Weaknesses**:
- Requires `ANTHROPIC_API_KEY` in OpenClaw's environment
- Each session consumes API tokens (cost management needed)
- No access to MCP servers or project-specific `.claude/` config unless configured

**Security impact**: LOW — no exec-approvals changes needed. SDK runs in-process.

**Best for**: Programmatic multi-agent coordination, automated PR creation, parallel research tasks.

---

### 2. CLI Headless Mode (`claude -p`) — DETAILED

**What**: Shell out to the `claude` CLI in non-interactive print mode. OpenClaw spawns `claude -p` as a child process, feeds it a prompt + flags, and collects structured output. No human interaction needed.

**How it works**:
```bash
claude -p "Summarize the recent changes in this repo" \
  --output-format json \
  --allowedTools "Read,Glob,Grep" \
  --max-turns 5 \
  --max-budget-usd 1.00 \
  --no-session-persistence
```

---

#### Complete Flag Reference (for OpenClaw integration)

##### Output Formats

| Flag | Format | Use case |
|------|--------|----------|
| `--output-format text` | Plain text (default) | Simple results piped to logs |
| `--output-format json` | Structured JSON | Parse result, session_id, usage, structured_output |
| `--output-format stream-json` | NDJSON (one JSON per line) | Real-time progress streaming back to chat client |

**JSON output structure** (what OpenClaw parses):
```json
{
  "result": "The text response from Claude",
  "session_id": "uuid-for-resume",
  "structured_output": {},
  "usage": { "input_tokens": 1200, "output_tokens": 450, "cost_usd": 0.02 }
}
```

**Stream-JSON filtering** (for real-time progress):
```bash
claude -p "Build and test" \
  --output-format stream-json \
  --verbose \
  --include-partial-messages | \
  jq -rj 'select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'
```

##### Tool Control

```bash
# Explicit allowlist (RECOMMENDED for OpenClaw)
--allowedTools "Read,Edit,Glob,Grep"

# Wildcard patterns for Bash
--allowedTools "Bash(git *)" "Bash(npm run *)" "Read" "Edit"

# Deny specific tools
--disallowedTools "Bash(rm *)" "Bash(sudo *)"

# Restrict total available tools
--tools "Bash,Edit,Read"
```

**Available tool names**: `Read`, `Edit`, `Write`, `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `Agent`, `MCP`

##### Model Selection

```bash
--model sonnet      # claude-sonnet-4-6 (fast, cheap — default workhorse)
--model opus        # claude-opus-4-6 (deep reasoning — complex tasks)
--model haiku       # claude-haiku-4-5 (fastest, cheapest — triage/routing)
```

##### System Prompt Injection

| Flag | Behavior | OpenClaw use case |
|------|----------|-------------------|
| `--system-prompt "..."` | **Replace** entire system prompt | Full control, custom personality |
| `--system-prompt-file ./prompt.txt` | **Replace** from file | Reproducible prompts stored in config |
| `--append-system-prompt "..."` | **Append** to defaults | Add rules while keeping CLAUDE.md |
| `--append-system-prompt-file ./rules.txt` | **Append** from file | Load customer-specific rules |

**Recommended for OpenClaw**: Use `--append-system-prompt` to inject task context while preserving the project's CLAUDE.md and settings.json.

##### Session Management

```bash
# One-shot (no persistence)
claude -p "Quick analysis" --no-session-persistence

# Multi-turn with session reuse
session_id=$(claude -p "Analyze codebase" --output-format json | jq -r '.session_id')
claude -p "Now fix the top issue" --resume "$session_id" --output-format json
claude -p "Run the tests" --resume "$session_id" --output-format json

# Continue most recent session
claude -p "What was I working on?" --continue

# Fork a session (new ID, same context)
claude -p "Try alternative approach" --resume "$session_id" --fork-session
```

##### Safety Rails

```bash
--max-turns 10          # Hard limit on agentic turns (prevents runaway loops)
--max-budget-usd 2.00   # Hard limit on API spend per invocation
--permission-mode plan   # Read-only analysis (no writes, no bash)
```

##### Structured Output (JSON Schema enforcement)

```bash
claude -p "Extract all API endpoints from this codebase" \
  --output-format json \
  --json-schema '{
    "type": "object",
    "properties": {
      "endpoints": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "method": {"type": "string"},
            "path": {"type": "string"},
            "handler": {"type": "string"}
          }
        }
      }
    },
    "required": ["endpoints"]
  }'
```

OpenClaw can enforce output schemas to get machine-parseable results every time.

##### MCP Servers in CLI Mode

```bash
# Load MCP config for tool access
claude -p "Query the database" --mcp-config ./mcp-servers.json

# Strict mode (ONLY use specified servers)
claude -p "Query the database" --strict-mcp-config --mcp-config ./mcp-servers.json

# Allow specific MCP tools
--allowedTools "MCP(postgres/query)" "MCP(github/create-pr)"
```

##### Additional Working Directories

```bash
# Give Claude access to multiple repos
claude -p "Compare the auth implementations" \
  --add-dir ../other-repo \
  --add-dir ../shared-lib
```

---

#### OpenClaw Integration Patterns

##### Pattern A: One-shot task with structured result

```bash
# OpenClaw receives: "What's broken in the tests?"
claude -p "Run the test suite and report failures" \
  --output-format json \
  --allowedTools "Bash(npm test *)" "Read" "Grep" \
  --max-turns 5 \
  --max-budget-usd 1.00 \
  --append-system-prompt "Return a concise summary. No code blocks unless showing the fix."
```

OpenClaw parses `.result` and sends it back to the chat client.

##### Pattern B: Multi-turn development session

```bash
# Step 1: Analyze
sid=$(claude -p "Analyze the auth module for security issues" \
  --output-format json \
  --permission-mode plan \
  --max-budget-usd 0.50 | jq -r '.session_id')

# Step 2: Fix (same session, now with write access)
claude -p "Fix the top 3 issues you found" \
  --resume "$sid" \
  --output-format json \
  --allowedTools "Read,Edit,Bash(npm test *)" \
  --max-budget-usd 2.00

# Step 3: Commit (same session)
claude -p "Commit the changes with a descriptive message" \
  --resume "$sid" \
  --output-format json \
  --allowedTools "Bash(git *)" \
  --max-budget-usd 0.50
```

##### Pattern C: Parallel execution (multiple processes)

```bash
# Fire 3 independent tasks simultaneously
claude -p "Fix the login bug" --output-format json --max-budget-usd 2.00 &
claude -p "Add unit tests for user service" --output-format json --max-budget-usd 2.00 &
claude -p "Update the API documentation" --output-format json --max-budget-usd 1.00 &
wait  # All 3 run concurrently
```

Each gets its own session, own context, own budget. OpenClaw collects results when all finish.

##### Pattern D: Piping data through Claude

```bash
# Error log analysis
cat /var/log/openclaw/gateway.log | claude -p \
  "Summarize the errors from the last hour. Group by type." \
  --output-format json --max-budget-usd 0.50

# PR review
gh pr diff 42 | claude -p \
  "Review this PR for security issues and performance problems" \
  --append-system-prompt "Be concise. Rate severity: low/medium/high/critical." \
  --output-format json --max-budget-usd 1.00

# Config validation
cat config/settings.env | claude -p \
  "Validate this configuration. Flag any security issues or missing values." \
  --output-format json --max-budget-usd 0.25
```

---

#### Strengths (expanded)

- **Full autonomy**: No human interaction needed. Fire and collect.
- **Complete flag control**: Tools, budget, model, system prompt, output format — all configurable per invocation
- **Session chaining**: Multi-turn workflows via `--resume` with session IDs
- **Parallel execution**: Multiple `claude -p` processes run concurrently
- **Piping**: Feed any data via stdin — logs, diffs, configs, error output
- **Structured output**: `--json-schema` enforces machine-parseable results
- **Project awareness**: Respects `.claude/settings.json`, CLAUDE.md, and `.claude/commands/`
- **MCP support**: Load MCP servers for database, API, and custom tool access
- **Cost control**: `--max-budget-usd` and `--max-turns` prevent runaway spend
- **Model flexibility**: Route cheap tasks to Haiku, complex to Opus, default to Sonnet

#### Weaknesses (expanded)

- **exec-approvals required**: Must add `claude` binary to the allowlist
- **Process overhead**: Each invocation spawns a new Node.js process (~2-3s startup)
- **Shell escaping**: Dynamic prompts with special characters need careful escaping
- **No real-time streaming to chat**: `stream-json` works for logs but parsing NDJSON in real-time adds complexity vs SDK's native async iterators
- **Skills unavailable**: `/commit`, `/review-pr`, etc. don't work in `-p` mode — describe the task instead
- **Context window**: Each `-p` call starts fresh unless `--resume` is used; no automatic context sharing between parallel processes

#### Security Impact: MEDIUM

Requires adding `claude` to exec-approvals. The risk is that Claude Code itself can execute Bash commands, creating a "Claude spawning Claude" chain. Mitigations:

1. **Force `-p` flag** via exec-approvals `required_args`
2. **Block `--dangerously-skip-permissions`** via `forbidden_args`
3. **Scope tools** with `--allowedTools` on every invocation
4. **Cap spend** with `--max-budget-usd` on every invocation
5. **Cap turns** with `--max-turns` to prevent infinite loops
6. **Read-only mode** with `--permission-mode plan` for analysis tasks
7. **No session persistence** with `--no-session-persistence` for sensitive operations

**exec-approvals entry**:
```json
{
  "id": "allow-claude-code-cli",
  "description": "Claude Code CLI - headless mode only, scoped permissions",
  "binary": "/usr/local/bin/claude",
  "action": "allow",
  "argument_rules": {
    "required_args": ["-p"],
    "forbidden_args": [
      "--dangerously-skip-permissions",
      "--allow-dangerously-skip-permissions",
      "--permission-mode auto-accept"
    ],
    "forbidden_patterns": ["sudo", "rm -rf"],
    "max_total_length": 10000
  }
}
```

#### Best for

- Autonomous one-shot tasks (analyze, fix, test, commit)
- Multi-turn development sessions via `--resume`
- Parallel workloads (3-5 concurrent `claude -p` processes)
- Piping data through Claude (logs, diffs, configs)
- Structured data extraction with `--json-schema`
- Cost-controlled automation with hard budget caps

---

### 3. Remote Control

**What**: OpenClaw starts a `claude remote-control` session on the Mac, then the operator monitors/interacts via claude.ai/code or the Claude mobile app.

**How it works**:
1. OpenClaw runs `claude remote-control` in a project directory
2. Session URL + QR code are generated
3. Operator connects from browser or Claude iOS/Android app
4. Conversation stays in sync across terminal + remote devices
5. Claude runs locally — full filesystem, MCP servers, tools available

**Strengths**:
- Full local environment access (MCP servers, project config, filesystem)
- Human-in-the-loop — operator can monitor and intervene
- Works from phone/tablet/any browser
- Session survives network drops (auto-reconnect)
- No API key needed (uses claude.ai subscription)

**Weaknesses**:
- One session at a time per Claude Code instance
- Requires Max plan (Pro coming soon), no API key support
- Terminal must stay open (process exits = session ends)
- Not suitable for autonomous multi-agent work
- Requires exec-approvals for `claude` binary

**Security impact**: MEDIUM — needs `claude` in exec-approvals, but human stays in the loop.

**Best for**: Supervised development sessions, operator wants to monitor agent work from phone, debugging sessions where human judgment is needed.

---

### 4. Claude Code on the Web

**What**: OpenClaw triggers Claude Code Web sessions at claude.ai/code that run on Anthropic's cloud infrastructure.

**How it works**:
- Sessions run on Anthropic-managed cloud (not local machine)
- Connect to GitHub repos directly — no local clone needed
- Multiple sessions can run in parallel
- Access via browser at claude.ai/code

**Strengths**:
- No local resources consumed
- Multiple parallel sessions supported
- No exec-approvals changes needed (runs in cloud)
- Full Claude Code capabilities in sandboxed cloud environment
- Good for tasks on repos OpenClaw doesn't have locally

**Weaknesses**:
- No access to local filesystem, MCP servers, or local tools
- Requires Max plan subscription
- No direct programmatic API to spawn web sessions (manual or via Teleport)
- Limited to what's available in the cloud sandbox
- Can't interact with local OpenClaw services

**Security impact**: LOW — runs entirely in Anthropic's cloud, isolated from local machine.

**Best for**: Working on GitHub repos without local setup, kicking off background tasks, parallel workstreams that don't need local access.

---

### 5. Teleport (Terminal <-> Web Bridge) — DETAILED

**What**: Seamlessly transfer sessions between Claude Code terminal and Claude Code Web (claude.ai/code). Send heavy work to the cloud, continue local work, pull results back when ready. Already implemented as a skill in this project.

**Core philosophy**: "Work where it makes sense. Execute in the cloud. Finish on your machine."

---

#### Commands Reference

##### Terminal → Web (Sending tasks to the cloud)

| Command | Description | OpenClaw use |
|---------|-------------|--------------|
| `& <task>` | Prefix any message with `&` to send to a new web session | Primary fire-and-forget mechanism |
| `claude --remote "<task>"` | Explicit remote execution from CLI | Scriptable alternative to `&` |
| `claude --permission-mode plan` | Enter read-only plan mode before sending | Safe pre-flight analysis |

**What happens when you send**:
1. Task is sent to Claude Code Web with current conversation context
2. A new web session is created on an Anthropic-managed cloud VM
3. The repository is cloned and the cloud environment is prepared
4. Claude works autonomously (operator can steer via web UI if desired)
5. Changes are pushed to a new branch when complete
6. Operator is notified — can create PR or teleport back

**Multiple `&` tasks create independent parallel web sessions.** This is the key differentiator — you can have 5 web sessions running simultaneously while continuing local work.

##### Web → Terminal (Bringing sessions back)

| Command | Description | OpenClaw use |
|---------|-------------|--------------|
| `/teleport` or `/tp` | Interactive session picker (inside Claude Code) | Pull completed work back |
| `claude --teleport` | Interactive picker from shell | Script-friendly |
| `claude --teleport <session-id>` | Teleport specific session by ID | Fully automated |
| `t` key in `/tasks` view | Teleport the selected task | Quick operator action |
| "Open in CLI" button | In web UI, copies teleport command | Operator-initiated |

**What happens when you teleport back**:
1. Claude verifies you're in the correct repository
2. Fetches and checks out the branch from the remote session
3. Loads the full conversation history into your terminal
4. You continue with full local tool access (MCP servers, filesystem, etc.)

##### Monitoring

| Command | Description |
|---------|-------------|
| `/tasks` | View all parallel web sessions: status, duration, session ID |

##### Configuration

| Command | Description |
|---------|-------------|
| `/remote-env` | Configure cloud environment: network level, pre-installed tools, env vars |
| `check-tools` | Ask Claude to list all tools available in the cloud environment |

---

#### Cloud Environment Capabilities

When a task is teleported to the web, it runs on an Anthropic-managed VM with:

| Category | Available |
|----------|-----------|
| Languages | Python 3.x, Node.js LTS, Ruby 3.x, Go, Rust, Java |
| Package Managers | pip, npm, yarn, pnpm, gem, cargo |
| Databases | PostgreSQL 16, Redis 7.0 |
| Build Tools | Make, CMake, Gradle, Maven |
| Network | Configurable via `/remote-env` |

---

#### Pre-Teleport Requirements (Web → Terminal)

All four must be satisfied before bringing a session back:

| # | Requirement | Verify | Fix |
|---|-------------|--------|-----|
| 1 | **Clean git state** | `git status` | `git stash push -u -m "Pre-teleport"` |
| 2 | **Correct repository** | `git remote -v` | `cd` to correct repo or `git clone` |
| 3 | **Branch on remote** | `git fetch --all && git branch -r` | Wait for session to complete |
| 4 | **Same account** | `claude auth status` | `claude auth logout && claude auth login` |

**Automated pre-flight check** (OpenClaw can run this before any teleport):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Check 1: Clean git state
if [ -n "$(git status --porcelain)" ]; then
  echo "FAIL: Uncommitted changes. Stashing..."
  git stash push -u -m "Pre-teleport: $(date +%Y%m%d-%H%M%S)"
fi

# Check 2: Correct repo
EXPECTED_REMOTE="github.com/Organized-AI/clawdbotready"
ACTUAL_REMOTE=$(git remote get-url origin)
if [[ "$ACTUAL_REMOTE" != *"$EXPECTED_REMOTE"* ]]; then
  echo "FAIL: Wrong repository. Expected $EXPECTED_REMOTE, got $ACTUAL_REMOTE"
  exit 1
fi

# Check 3: Branch available
git fetch --all --quiet
if ! git branch -r | grep -q "$TARGET_BRANCH"; then
  echo "FAIL: Branch $TARGET_BRANCH not found on remote"
  exit 1
fi

# Check 4: Auth
if ! claude auth status --text 2>/dev/null | grep -q "authenticated"; then
  echo "FAIL: Not authenticated. Run: claude auth login"
  exit 1
fi

echo "OK: All pre-teleport checks passed"
```

---

#### OpenClaw Integration Patterns

##### Pattern A: Fire-and-forget (primary autonomous pattern)

```
User (via iMessage) → "Add dark mode to the dashboard"
    ↓
OpenClaw receives message
    ↓
OpenClaw sends: & Add dark mode to the dashboard. Use Tailwind dark: variants.
                  Create a toggle in the settings page. Update all components.
    ↓
New web session created (runs autonomously in Anthropic cloud)
    ↓
OpenClaw replies to user: "Working on it — I've sent this to a cloud session.
                           I'll let you know when it's ready."
    ↓
[10 minutes later — web session completes, pushes branch]
    ↓
OpenClaw detects completion via /tasks polling
    ↓
OpenClaw teleports back: claude --teleport <session-id>
    ↓
OpenClaw runs tests locally, creates PR, notifies user
```

This is the **most powerful autonomous pattern** — OpenClaw offloads heavy development to the cloud, continues handling other messages locally, and pulls results back when ready.

##### Pattern B: Parallel workstreams

```bash
# OpenClaw sends 3 tasks to the cloud simultaneously
& Fix the authentication bug in packages/gateway/src/auth.ts
& Add unit tests for the user service (aim for 80% coverage)
& Update the API documentation to match the new endpoints

# Each creates an independent web session
# OpenClaw monitors all 3 via /tasks
# As each completes, teleport back and merge
```

##### Pattern C: Heavy compute offload

```bash
# Large codebase analysis that would take 20+ minutes locally
& Analyze the entire codebase for security vulnerabilities.
  Check all dependencies for known CVEs.
  Review authentication flows for OWASP Top 10 issues.
  Create a detailed report with severity ratings and fix recommendations.

# This runs in the cloud while OpenClaw stays responsive
```

##### Pattern D: Worktree isolation (prevents branch conflicts)

```bash
# Create an isolated worktree for the teleported session
git worktree add ../teleport-work feature-branch
cd ../teleport-work
claude --teleport <session-id>

# Work in isolation — main working tree untouched
# When done:
git worktree remove ../teleport-work
```

This integrates with the `git-worktree-master` skill already in the project.

##### Pattern E: Hybrid local+cloud workflow

```bash
# Step 1: Quick local analysis (CLI -p, fast)
analysis=$(claude -p "What's the root cause of the auth failures?" \
  --output-format json --permission-mode plan --max-budget-usd 0.50 | jq -r '.result')

# Step 2: Send the fix to the cloud (Teleport, background)
& Based on this analysis: "$analysis"
  Fix the root cause in packages/gateway/src/auth.ts.
  Add regression tests. Run the full test suite.

# Step 3: Continue handling other tasks locally while cloud works
```

This combines CLI `-p` (fast local analysis) with Teleport (heavy cloud execution).

---

#### When to Use Web vs Terminal

| Scenario | Use | Why |
|----------|-----|-----|
| Long-running builds/tests (10+ min) | Web | Don't block the local terminal |
| Parallel feature work | Web | Multiple sessions run independently |
| Tasks while laptop is closed | Web | Cloud runs independently |
| Repos not cloned locally | Web | Cloud clones from GitHub directly |
| Git operations (commit, push, PR) | Terminal | Full local git access |
| MCP tool integrations | Terminal | MCP servers run locally |
| Local filesystem operations | Terminal | Direct disk access |
| Quick fixes (< 2 min) | Terminal | No clone/setup overhead |
| Complex debugging | Plan locally → execute on web | Best of both |
| Security-sensitive operations | Terminal | Keep data local |

---

#### Skill Integrations

Teleport works with three other skills already in this project:

**boris** (verification methodology):
- Run `/verify` and `/commit` before sending to web
- Run `/status` and `/verify` after teleporting back
- Ensures quality gates on both sides of the transfer

**long-runner** (multi-context orchestration):
- Offload heavy features to `&` web sessions
- Continue local work in parallel
- Monitor with `/tasks`
- Teleport back when ready

**git-worktree-master** (branch isolation):
- Create isolated worktree for teleported sessions
- Prevents branch conflicts with main working tree
- Clean up worktree when session is merged

---

#### Error Handling

| Error Category | Common Issue | Resolution |
|----------------|-------------|------------|
| **Git State** | Uncommitted changes | Auto-stash before teleport |
| **Git State** | Merge conflict in progress | Resolve or abort before teleport |
| **Repository** | Wrong repo (URL mismatch) | `cd` to correct repo |
| **Repository** | Not a git repository | Initialize or clone |
| **Branch** | Branch not found on remote | Wait for web session to push |
| **Branch** | Branch has diverged | `git fetch && git reset` or create worktree |
| **Auth** | Session not found (404) | Session may have expired — check `/tasks` |
| **Auth** | Authentication expired | `claude auth logout && claude auth login` |
| **Network** | Connection timeout | Retry — sessions survive network drops (~10 min tolerance) |
| **Session** | Stuck/unresponsive | Cancel and re-send task |

**Recovery procedure for failed teleport**:
```bash
# Manual branch checkout (bypass teleport)
git fetch origin
git checkout -b recovered-work origin/web-session-branch

# Recover stashed changes (if stashed pre-teleport)
git stash list
git stash pop
```

---

#### Strengths (expanded)

- **True fire-and-forget**: Send task, forget about it, get notified when done
- **Parallel execution**: 5+ web sessions running simultaneously
- **No local resources**: Cloud sessions use Anthropic's compute, not your Mac
- **Full context transfer**: Conversation history carries across terminal ↔ web
- **Already built**: Teleport skill exists in this project — just needs OpenClaw integration
- **Human-optional**: Operator can monitor web sessions in browser, or ignore them entirely
- **Branch-based handoff**: All work comes back as git branches — clean, mergeable, auditable
- **Composable with CLI -p**: Use `-p` for fast local analysis, `&` for heavy cloud execution

#### Weaknesses (expanded)

- **Git cleanliness required**: Must stash/commit before web→terminal transfer
- **Branch management**: Each web session creates a branch — can pile up if not cleaned
- **No local tool access**: Web sessions can't use MCP servers or local services
- **Session one-way**: `&` always creates a *new* web session — can't resume an existing one
- **Clone overhead**: Web sessions clone the full repo each time (~30s-2min depending on size)
- **Subscription required**: Max plan needed for claude.ai/code access
- **Completion detection**: OpenClaw needs to poll `/tasks` to detect when web sessions finish — no push notification mechanism

#### Security Impact: LOW-MEDIUM

- Uses existing Claude Code permissions for the terminal side
- Cloud sessions are fully sandboxed by Anthropic
- All work comes back as git branches — auditable, reversible
- No direct exec-approvals changes needed (Teleport is a skill, not a binary)
- **Risk**: Web sessions have network access in the cloud — could potentially exfiltrate repo contents. Mitigated by Anthropic's cloud security model.

#### Best for

- Heavy development tasks that take 10+ minutes
- Parallel feature work across multiple branches
- Tasks that shouldn't block the terminal (operator keeps chatting)
- Long-running test suites or builds
- Cross-device workflows (start on Mac, monitor from phone)
- Combining with CLI `-p` for hybrid local+cloud workflows

---

### 6. Claude Desktop (MCP-based)

**What**: Use Claude Desktop app with MCP servers to give Claude access to OpenClaw's tools and filesystem.

**How it works**:
- Configure MCP servers in Claude Desktop that expose OpenClaw capabilities
- Claude Desktop connects to local MCP servers for file access, terminal, etc.
- Operator interacts through the Claude Desktop GUI

**Strengths**:
- Rich GUI experience
- MCP server ecosystem (filesystem, git, database, etc.)
- Good for operators who prefer desktop apps
- Can expose custom OpenClaw tools via MCP

**Weaknesses**:
- Requires Claude Desktop installed and configured
- MCP server setup needed for each capability
- Not programmatic — requires human interaction
- Desktop app must stay open

**Security impact**: MEDIUM — MCP servers control what Claude can access.

**Best for**: Operator-driven development sessions, rich UI experience, custom tool integrations.

---

## Strategic Approach: Max Plan First

### Why Max-first?

The Max plan ($200/mo) is already paid for. Every task routed through subscription-based methods (CLI `-p`, Teleport, Remote Control, Web) has **zero marginal cost**. Agent SDK burns API tokens on top of the subscription — it should be the fallback, not the default.

```
Cost per task:
  CLI -p (Max plan)     → $0.00  (included in subscription)
  Teleport/Web          → $0.00  (included in subscription)
  Remote Control        → $0.00  (included in subscription)
  Agent SDK             → $0.02-5.00+  (API tokens, per task)
```

**The strategic question isn't "which method is most capable?" — it's "which method extracts the most value from what we're already paying for?"**

### Decision: API key vs subscription → **Subscription first, API as overflow**

The Max plan includes:
- Unlimited Claude Code terminal sessions (CLI `-p`)
- Claude Code Web sessions (Teleport `&` targets)
- Remote Control sessions
- Higher rate limits than Pro

API tokens (Agent SDK) are reserved for:
- Burst capacity beyond Max plan rate limits
- Programmatic multi-agent coordination that genuinely needs SDK features (structured output schemas, in-process callbacks)
- Customer-facing automation where per-task cost tracking is required

---

## Decision Matrix

| Method | Autonomous? | Multi-session? | Local access? | Cost | Security | Priority |
|--------|-------------|----------------|---------------|------|----------|----------|
| **CLI `-p`** | **Yes** | **Yes (processes)** | **Full** | **$0 (Max)** | Medium | **PRIMARY** |
| **Teleport** | **Yes (fire-forget)** | **Yes (parallel)** | **Hybrid** | **$0 (Max)** | Low-Med | **PRIMARY** |
| **Remote Control** | No (human-in-loop) | No (1 session) | Full | $0 (Max) | Medium | SECONDARY |
| **Web** | Semi (manual) | Yes | No (cloud) | $0 (Max) | Low | SECONDARY |
| **Claude Desktop** | No (human-in-loop) | No | Via MCP | $0 (Max) | Medium | TERTIARY |
| **Agent SDK** | Yes | Yes (parallel) | Via tools | **$$$ (API)** | Low | **LAST RESORT** |

---

## Recommended Implementation Order

### Tier 1: Primary Workhorses (Max plan, autonomous, $0/task)

These two methods handle 90% of OpenClaw's autonomous work at zero marginal cost.

#### 1a. CLI `-p` — Local autonomous execution
- **When**: Task needs local filesystem, MCP servers, or quick turnaround (< 5 min)
- **Cost**: $0 (Max plan subscription)
- **Setup**: Add `claude` to exec-approvals with strict argument rules
- **Autonomy**: Full — fire prompt, collect result, no human needed

#### 1b. Teleport (`&`) — Cloud autonomous execution
- **When**: Task is long-running (10+ min), parallelizable, or shouldn't block the terminal
- **Cost**: $0 (Max plan subscription)
- **Setup**: Already built as a skill — just wire OpenClaw to use `&` prefix
- **Autonomy**: Full — fire to cloud, poll `/tasks`, teleport back when done

**Together they cover everything**:
- Fast local task? → CLI `-p`
- Long cloud task? → Teleport `&`
- Need both? → CLI `-p` for analysis, `&` for execution (Pattern E)
- Need 5 things at once? → 5x `&` parallel web sessions

### Tier 2: Operator-Assisted (Max plan, human-in-loop, $0/task)

#### 2a. Remote Control — Mobile supervision
- **When**: Operator wants to monitor/steer from phone or browser
- **Cost**: $0 (Max plan)
- **Trigger**: Operator explicitly requests supervised mode

#### 2b. Claude Code Web — Cloud-only repos
- **When**: Working on repos not cloned locally, or operator wants web UI
- **Cost**: $0 (Max plan)
- **Trigger**: Repo not available locally, or operator prefers web

#### 2c. Claude Desktop — MCP-powered GUI
- **When**: Operator prefers desktop GUI with custom MCP tools
- **Cost**: $0 (Max plan)
- **Trigger**: Operator has Claude Desktop configured

### Tier 3: Last Resort (API tokens, per-task cost)

#### 3. Agent SDK — Programmatic fallback
- **When**: Max plan rate limits hit, need structured JSON schemas enforced at the SDK level, or building customer-facing automation that requires per-task cost attribution
- **Cost**: $0.02-5.00+ per task (API tokens)
- **Trigger**: Only when Tier 1 methods can't handle the requirement

**Why last?** Every SDK call costs money on top of the subscription. If CLI `-p` can do the same thing for $0, use CLI `-p`. The SDK's advantages (in-process callbacks, native async iterators, structured output) rarely outweigh the cost savings of Max plan methods — and CLI `-p` supports `--json-schema` for structured output anyway.

---

## Architecture: Max-Plan-Optimized Coordinator

```
┌──────────────────────────────────────────────────────────────┐
│                     OpenClaw Gateway                          │
│                   (Native macOS Host)                          │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Task Router (Max-Plan-First)                 │ │
│  │                                                            │ │
│  │  Incoming task → Classify → Route:                         │ │
│  │                                                            │ │
│  │  ┌─────────────────────────────────────────┐               │ │
│  │  │ Is it a quick local task? (< 5 min)     │──Yes──→ CLI -p│ │
│  │  └──────────────┬──────────────────────────┘               │ │
│  │                 No                                          │ │
│  │  ┌─────────────────────────────────────────┐               │ │
│  │  │ Long-running or parallelizable?         │──Yes──→ & Tel │ │
│  │  └──────────────┬──────────────────────────┘               │ │
│  │                 No                                          │ │
│  │  ┌─────────────────────────────────────────┐               │ │
│  │  │ Operator wants to supervise?            │──Yes──→ RC    │ │
│  │  └──────────────┬──────────────────────────┘               │ │
│  │                 No                                          │ │
│  │  ┌─────────────────────────────────────────┐               │ │
│  │  │ Rate limited / need SDK features?       │──Yes──→ SDK   │ │
│  │  └──────────────┬──────────────────────────┘               │ │
│  │                 No                                          │ │
│  │                 └──→ Default to CLI -p                      │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                Execution Layer                          │    │
│  │                                                          │    │
│  │  ┌──────────┐  ┌──────────┐  ┌─────┐  ┌─────┐  ┌───┐  │    │
│  │  │ CLI -p   │  │ Teleport │  │ RC  │  │ Web │  │SDK│  │    │
│  │  │          │  │          │  │     │  │     │  │   │  │    │
│  │  │ LOCAL    │  │ CLOUD    │  │LOCAL│  │CLOUD│  │API│  │    │
│  │  │ $0/task  │  │ $0/task  │  │ $0  │  │ $0  │  │$$$│  │    │
│  │  │ Fast     │  │ Parallel │  │Watch│  │Repos│  │FB │  │    │
│  │  └──────────┘  └──────────┘  └─────┘  └─────┘  └───┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                Session Lifecycle                        │    │
│  │                                                          │    │
│  │  1. Task arrives (iMessage/Telegram/API)                 │    │
│  │  2. Router classifies → picks method                    │    │
│  │  3. Session spawns (local process or cloud `&`)          │    │
│  │  4. Monitor: poll /tasks (cloud) or wait PID (local)     │    │
│  │  5. Collect result: parse JSON (local) or teleport (cloud)│   │
│  │  6. Post-process: run tests, create PR, notify user      │    │
│  │  7. Log session metadata for audit                       │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## Operational Patterns

### The Daily Workflow

Most days, OpenClaw handles tasks like this:

```
Morning:
  User: "Fix the login bug"
  Router: Quick local fix → CLI -p (3 min, $0)

  User: "Also add 2FA support and update the docs"
  Router: Two independent tasks → & Teleport x2 ($0, parallel cloud)
  OpenClaw: "Both are running in the cloud. I'll let you know."

Afternoon:
  [Cloud sessions complete]
  OpenClaw: Teleports both back, runs tests, creates PRs
  OpenClaw: "Both PRs are ready for review."

  User: "Walk me through the 2FA implementation"
  Router: Operator wants to steer → Remote Control
  OpenClaw: Starts RC session, operator follows along on phone

Evening:
  User: "Run a full security audit across all repos"
  Router: Long + multi-repo → & Teleport (heavy compute, $0)
  OpenClaw: "Running in the cloud. Results tomorrow morning."
```

**Zero API tokens burned all day.**

### When Agent SDK Gets Used

```
Scenario 1: Rate limit hit
  3x Teleport sessions + 2x CLI -p already running
  New urgent task arrives
  Router: Max plan at capacity → Agent SDK (overflow, ~$1.50)

Scenario 2: Structured multi-agent coordination
  Need 10 agents working on different files simultaneously
  with in-process callbacks between them
  Router: SDK's async iterators are genuinely better here → Agent SDK (~$5.00)

Scenario 3: Customer-facing automation
  Client's system needs per-task cost attribution
  Router: SDK provides usage tracking per session → Agent SDK (billable)
```

---

## Security Considerations

### For Max Plan Methods (CLI `-p` and Teleport)

#### Exec-Approvals (CLI `-p` only)
Add to `config/exec-approvals.json`:
```json
{
  "id": "allow-claude-code-cli",
  "description": "Claude Code CLI - headless mode only, scoped permissions",
  "binary": "/usr/local/bin/claude",
  "action": "allow",
  "argument_rules": {
    "required_args": ["-p"],
    "forbidden_args": [
      "--dangerously-skip-permissions",
      "--allow-dangerously-skip-permissions",
      "--permission-mode auto-accept"
    ],
    "forbidden_patterns": ["sudo", "rm -rf"],
    "max_total_length": 10000
  }
}
```

#### Tool Scoping (every CLI `-p` invocation)
```bash
# Always scope tools explicitly
--allowedTools "Read,Edit,Glob,Grep,Bash(git *),Bash(npm test *)"

# Never leave tools unscoped
# Never allow unrestricted Bash
```

#### Turn Limits (prevent runaway sessions)
```bash
--max-turns 15    # Hard cap on agentic loops
```

#### Teleport Security
- Cloud sessions are sandboxed by Anthropic — low risk
- All work returns as git branches — auditable, revertable
- No exec-approvals changes needed (Teleport is a skill, not a binary)
- Pre-teleport checks enforce clean git state before pulling back

### For Agent SDK (when used as fallback)

#### API Key Protection
- Store `ANTHROPIC_API_KEY` outside workspace (e.g., macOS Keychain, `~/.config/openclaw/.env`)
- Never commit to git — verify `.gitignore` coverage
- Rotate quarterly minimum

#### Budget Caps
```typescript
// Always set per-session limits
maxBudgetUsd: 5.00
maxTurns: 20

// Track daily spend across all SDK sessions
// Alert operator at 80% of daily ceiling
```

### Monitoring (all methods)
- Log every session start/stop with method, duration, task summary
- Track Max plan rate limit proximity (warn at 80% utilization)
- For SDK sessions: track token usage and cost per session
- Audit tool usage patterns weekly
- Alert on anomalous session durations (> 30 min for CLI -p, > 2 hours for Teleport)

---

## Open Questions — DECIDED

### 1. ~~API key vs subscription~~ → **DECIDED: Max plan first, SDK as overflow only.**

See "Strategic Approach: Max Plan First" section above.

---

### 2. ~~Rate limit awareness~~ → **DECIDED: Empirical measurement + adaptive routing.**

**What we know** (as of March 2026):
- Max 20x ($200/mo) = 20× Pro's token allowance
- **5-hour rolling window** — resets every 5 hours, countdown shown in CLI
- **Weekly cap** — introduced Aug 2025 to prevent 24/7 background usage
- Capacity: ~480 Sonnet hours/week or ~40 Opus hours/week on Max 20x
- All Claude.ai + Claude Code activity shares one usage bucket
- When either limit hits, all new prompts are blocked immediately
- **Extra usage** can be purchased at API rates once the included limit is hit

**Practical concurrent capacity** (estimated for Max 20x):
- 3-5 concurrent CLI `-p` sessions (Sonnet) = sustainable for a full workday
- 1-2 concurrent CLI `-p` sessions (Opus) = sustainable but burns weekly cap faster
- 3-5 concurrent Teleport `&` web sessions = sustainable (cloud-side, same bucket)
- Mixed: 2x CLI `-p` + 3x Teleport = sweet spot for most days

**Decision: Adaptive routing with soft limits**

```
OpenClaw tracks its own usage estimate:
  - Each CLI -p invocation: log start time, model, estimated tokens
  - Each Teleport &: log send time, assume ~15 min Sonnet session

When estimated 5-hour usage > 70% of Max 20x allowance:
  → Switch new tasks to Sonnet (if currently using Opus)
  → Queue non-urgent tasks for next 5-hour window
  → Alert operator: "Approaching rate limit, queueing low-priority tasks"

When estimated 5-hour usage > 90%:
  → Route urgent tasks to Agent SDK (overflow, API tokens)
  → Hold everything else until next reset
  → Alert operator: "Rate limit imminent, using API tokens for urgent work"

When weekly limit > 80%:
  → Reduce parallelism (max 2 concurrent sessions)
  → Prefer Sonnet over Opus for remaining capacity
  → Alert operator: "Weekly limit at 80%, throttling to conserve"
```

This is a **soft estimation** — Anthropic doesn't expose exact token counts via CLI, so OpenClaw tracks wall-clock time × model tier as a proxy. Empirical calibration needed in Phase 1.

---

### 3. ~~Autonomy level~~ → **DECIDED: Auto-route Tier 1, confirm Tier 2+, override available.**

| Method | Auto-route? | Rationale |
|--------|-------------|-----------|
| CLI `-p` (Sonnet) | **Yes, always** | Low cost, fast, reversible. No reason to ask. |
| CLI `-p` (Opus) | **Yes, with notification** | Higher token burn, but still $0. Notify operator which model was chosen. |
| Teleport `&` | **Yes, always** | Fire-and-forget by design. Operator gets notified when complete. |
| Remote Control | **No — operator must request** | Human-in-loop by definition. Operator says "walk me through it." |
| Claude Desktop | **No — operator must request** | GUI mode, operator initiates. |
| Agent SDK | **Yes, but only as overflow** | Only triggers when Max plan limits are hit. Notify operator with cost estimate. |

**Override mechanism**: Operator can force a method by prefixing their message:
```
"!local Fix the login bug"      → Forces CLI -p (even if router would pick Teleport)
"!cloud Add 2FA support"        → Forces Teleport & (even for quick tasks)
"!watch Refactor the auth flow"  → Forces Remote Control
"!sdk Run 10 parallel analyses"  → Forces Agent SDK (operator accepts cost)
```

Without a prefix, the router auto-selects based on the decision tree in the Architecture section.

---

### 4. ~~Session persistence~~ → **DECIDED: Persist all, auto-prune at 30 days.**

**What's stored**: Claude Code sessions live as JSONL in `~/.claude/projects/` with directory paths encoded. They store full conversation history, tool calls, and context state.

**Decision**:
- **Persist every session** — CLI `-p` (via `--resume` ID), Teleport (via session ID from `/tasks`), SDK (via SDK response objects)
- **Log metadata** to OpenClaw's own session ledger (`logs/session-ledger.jsonl`):
  ```jsonl
  {"id":"sess_abc123","method":"cli-p","model":"sonnet","start":"2026-03-05T10:00:00Z","end":"2026-03-05T10:03:22Z","task":"Fix login bug","outcome":"success","branch":"fix/login-bug","tokens_est":15000}
  ```
- **Auto-prune**: Delete JSONL session files older than 30 days. Keep the ledger entry permanently (it's just metadata, tiny).
- **Resume capability**: OpenClaw can `claude --resume <session-id>` to continue a previous session if follow-up work is needed. This is powerful for multi-turn tasks that span hours or days.

**Why persist everything?**
- Audit trail for what the AI did and when
- Resume capability for multi-turn work
- Usage pattern analysis (feeds into the `gateway-insights` skill)
- Debugging failed sessions
- Storage cost is negligible (~1-5 MB per session, pruned at 30 days)

---

### 5. ~~Repo scoping~~ → **DECIDED: Scoped list in config, expandable by operator.**

**Decision: Config-defined allowlist with operator override.**

```bash
# ~/.config/openclaw/repo-scope.json
{
  "allowed_repos": [
    "/Users/operator/clawdbotready",
    "/Users/operator/openclaw-gateway",
    "/Users/operator/client-project-alpha"
  ],
  "default_repo": "/Users/operator/clawdbotready",
  "allow_operator_override": true
}
```

**Rules**:
- CLI `-p` sessions receive `--cwd <repo-path>` scoped to the allowed list
- If a task mentions a repo not in the list, OpenClaw asks the operator before proceeding
- Operator can add repos on-the-fly: `"!scope add /Users/operator/new-project"`
- Teleport `&` sessions clone from GitHub — scoped by which repos the Claude.ai account has access to (GitHub OAuth)

**Why not "all repos on the Mac"?**
- An autonomous AI agent with access to every directory on the machine is an unnecessary blast radius
- A compromised session could read/modify unrelated projects
- Scoped list + operator override gives full flexibility with defense in depth

**Why not "current project only"?**
- OpenClaw serves multiple projects (client work, internal tools, etc.)
- Forcing single-project mode would require constant reconfiguration
- The operator already trusts OpenClaw with these repos — just make it explicit

---

### 6. ~~Teleport polling interval~~ → **DECIDED: Adaptive polling — 30s → 60s → 5min.**

Cloud sessions vary wildly in duration (30 seconds for a quick fix, 45 minutes for a refactor). Fixed polling wastes either resources or time.

**Decision: Exponential backoff with a ceiling.**

```
Session sent via & at T=0

T+0 to T+2min:   Poll every 30s  (6 polls — catches quick tasks)
T+2min to T+10min: Poll every 60s  (8 polls — catches medium tasks)
T+10min onward:   Poll every 5min (ongoing — catches long-running tasks)

Total polls for a 30-min session: ~14 (minimal overhead)
Total polls for a 2-hour session: ~28
```

**On completion detection**:
- OpenClaw teleports the session back immediately
- Runs post-processing (tests, PR creation)
- Notifies the operator with results

**On timeout** (configurable, default 4 hours):
- OpenClaw alerts: "Cloud session `sess_abc` has been running for 4 hours. Should I cancel it?"
- Operator can extend, cancel, or check the web UI manually

**Future optimization**: If Anthropic adds webhook/push notification support for `/tasks` completion, switch to event-driven and eliminate polling entirely.

---

### 7. ~~Branch cleanup~~ → **DECIDED: Auto-delete after merge, warn at 7 days, force-clean at 30 days.**

Teleport creates a branch per cloud session. Without cleanup, the remote accumulates stale branches fast.

**Decision: Three-tier lifecycle.**

| Age | Status | Action |
|-----|--------|--------|
| 0-7 days | Active | Keep. Operator may still be reviewing. |
| 7 days | Unmerged | Warn operator: "Branch `teleport/fix-auth-abc` is 7 days old and unmerged. Keep or delete?" |
| 30 days | Unmerged | Auto-delete remote branch. Log deletion. Operator can recover from local reflog if needed. |
| Any | Merged | Auto-delete remote branch immediately after merge confirmation. |

**Implementation**:
```bash
# Daily cleanup job (OpenClaw cron or scheduled task)
# 1. List all teleport/* branches
# 2. Check merge status against main
# 3. Delete merged branches
# 4. Warn on 7-day unmerged
# 5. Force-delete 30-day unmerged (with logging)

git branch -r --merged main | grep 'teleport/' | xargs -I{} git push origin --delete {}
```

**Branch naming convention** (enforced by Teleport skill):
```
teleport/<task-slug>-<short-session-id>
# Examples:
teleport/fix-login-bug-abc12
teleport/add-2fa-support-def34
teleport/security-audit-ghi56
```

This makes branches self-documenting and easy to identify in `git branch -r` output.

**Local worktree cleanup** (for Pattern D):
```bash
# After teleport-back and merge, clean up the worktree
git worktree remove ../teleport-work --force
git worktree prune
```

---

## Next Steps

### Phase 1: CLI `-p` Integration (Tier 1a)
- [ ] Add `claude` to exec-approvals with strict argument rules
- [ ] Build OpenClaw → CLI `-p` spawner (Node.js `child_process`)
- [ ] Implement JSON output parsing for `.result` and `.session_id`
- [ ] Add `--resume` support for multi-turn sessions
- [ ] Test with real tasks: analyze, fix, test, commit cycle
- [ ] Measure Max plan rate limits empirically

### Phase 2: Teleport Integration (Tier 1b)
- [ ] Wire OpenClaw to send `&` prefixed tasks (fire-and-forget)
- [ ] Build `/tasks` polling loop for session completion detection
- [ ] Implement automated teleport-back with pre-flight checks
- [ ] Add worktree isolation for parallel teleport sessions
- [ ] Test parallel cloud execution (3-5 simultaneous sessions)
- [ ] Build branch cleanup automation

### Phase 3: Task Router
- [ ] Build classification logic (quick/local vs long/cloud vs supervised)
- [ ] Implement routing rules with method selection
- [ ] Add fallback chain: CLI -p → Teleport → SDK
- [ ] Rate limit detection and automatic SDK overflow
- [ ] Operator notification for routing decisions

### Phase 4: Monitoring & Observability
- [ ] Session logging (start, stop, method, duration, outcome)
- [ ] Rate limit proximity tracking
- [ ] SDK usage + cost tracking (when used)
- [ ] Weekly audit report generation
- [ ] Alert thresholds for anomalous behavior

### Phase 5: Agent SDK Fallback (Tier 3 — only if needed)
- [ ] Add `@anthropic-ai/claude-agent-sdk` to OpenClaw dependencies
- [ ] Build SDK session wrapper with budget caps
- [ ] Implement overflow routing from rate-limited Max plan methods
- [ ] Per-task cost attribution logging
- [ ] Test SDK ↔ Max plan method interop
