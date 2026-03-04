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

### 2. CLI Headless Mode (`claude -p`)

**What**: Shell out to the `claude` CLI in non-interactive print mode.

**How it works**:
```bash
claude -p "Summarize the recent changes in this repo" \
  --output-format json \
  --allowedTools "Read,Glob,Grep" \
  --max-turns 5 \
  --max-budget-usd 1.00 \
  --no-session-persistence
```

**Strengths**:
- Simple shell integration — just spawn a process
- Full CLI flag control (tools, budget, model, system prompts)
- Can pipe input: `cat error.log | claude -p "Explain this error"`
- Supports `--continue` and `--resume` for session management
- Respects project `.claude/settings.json` and CLAUDE.md

**Weaknesses**:
- Requires exec-approvals to allow the `claude` binary
- Each invocation is a separate process (overhead)
- Shell escaping complexity for dynamic prompts
- Harder to stream results back in real-time vs SDK

**Security impact**: MEDIUM — requires adding `claude` to exec-approvals allowlist.

**exec-approvals entry needed**:
```json
{
  "id": "allow-claude-code-cli",
  "description": "Claude Code CLI in headless mode only",
  "binary": "/usr/local/bin/claude",
  "action": "allow",
  "argument_rules": {
    "required_args": ["-p"],
    "forbidden_args": ["--dangerously-skip-permissions"],
    "forbidden_patterns": ["sudo", "rm -rf", "curl", "wget"],
    "max_total_length": 10000
  }
}
```

**Best for**: Simple one-shot tasks, piping data through Claude, scripts that already use shell.

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

### 5. Teleport (Terminal <-> Web Bridge)

**What**: Use the existing Teleport skill to seamlessly transfer sessions between Claude Code terminal and web interfaces.

**How it works**:
- `&` prefix or `--remote` flag sends tasks to Claude Code Web
- `/teleport` or `--teleport` brings web sessions back to terminal
- `/tasks` checks status of parallel remote tasks

**Strengths**:
- Best of both worlds — start local, continue on web, or vice versa
- Already implemented in the Clawdbot Ready project
- Enables fire-and-forget pattern (send to web, check later)
- Good for long-running tasks that shouldn't block the terminal

**Weaknesses**:
- Depends on both local Claude Code and claude.ai/code being available
- Git state must be clean for transfers
- Branch management complexity
- Session context may not transfer perfectly

**Security impact**: LOW-MEDIUM — uses existing Claude Code permissions.

**Best for**: Offloading long tasks to the cloud, picking up work across devices, parallel execution of independent tasks.

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

## Decision Matrix

| Method | Autonomous? | Multi-session? | Local access? | Cost model | Security | Setup complexity |
|--------|-------------|----------------|---------------|------------|----------|-----------------|
| **Agent SDK** | Yes | Yes (parallel) | Via tools | API tokens | Low | Low (npm install) |
| **CLI `-p`** | Yes | Yes (processes) | Full | API tokens | Medium | Medium (exec-approvals) |
| **Remote Control** | No (human-in-loop) | No (1 session) | Full | Subscription | Medium | Medium |
| **Web** | Semi (manual trigger) | Yes | No (cloud) | Subscription | Low | Low |
| **Teleport** | Semi | Yes (fire-forget) | Hybrid | Both | Low-Med | Low (already built) |
| **Claude Desktop** | No (human-in-loop) | No | Via MCP | Subscription | Medium | Medium (MCP config) |

---

## Recommended Implementation Order

### Tier 1: Immediate (no exec-approvals changes)
1. **Agent SDK** — Most capable, most secure, most programmatic. This is the primary workhorse for multi-agent coordination.

### Tier 2: Near-term (minimal exec-approvals changes)
2. **CLI `-p` mode** — For shell-based workflows and piping. Add `claude` to exec-approvals with strict argument rules.
3. **Teleport** — Already built. Enable OpenClaw to use the `&` prefix pattern for fire-and-forget.

### Tier 3: Operator-assisted
4. **Remote Control** — For supervised sessions where the operator wants mobile monitoring.
5. **Claude Desktop** — For operators who prefer GUI interaction with MCP tools.
6. **Web** — For cloud-based parallel work on GitHub repos.

---

## Security Considerations

### API Key Management
- Agent SDK and CLI modes require `ANTHROPIC_API_KEY`
- Store in secure location (not in workspace, not in git)
- Consider key rotation schedule
- Set per-session budget limits (`--max-budget-usd`)

### Exec-Approvals Changes
For CLI mode, add to `config/exec-approvals.json`:
```json
{
  "id": "allow-claude-code-cli",
  "description": "Claude Code CLI - headless mode only, no skip-permissions",
  "binary": "/usr/local/bin/claude",
  "action": "allow",
  "argument_rules": {
    "required_args": ["-p"],
    "forbidden_args": [
      "--dangerously-skip-permissions",
      "--permission-mode bypassPermissions"
    ],
    "max_total_length": 10000
  }
}
```

### Tool Scoping
When spawning Claude Code sessions, always scope tools:
```typescript
// Good: explicit allowlist
allowedTools: ["Read", "Edit", "Glob", "Grep", "Bash(git *)"]

// Bad: unrestricted
allowedTools: undefined  // allows everything
```

### Budget Limits
Always set cost caps:
```typescript
maxBudgetUsd: 5.00  // per-session limit
maxTurns: 20        // prevent runaway loops
```

### Monitoring
- Log all Claude Code session starts/stops
- Track token usage per session
- Alert on budget threshold breaches
- Audit tool usage patterns

---

## Architecture: OpenClaw as Multi-Agent Coordinator

```
┌─────────────────────────────────────────────────┐
│                  OpenClaw Gateway                 │
│              (Native macOS Host)                  │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │           Access Method Router               │ │
│  │                                               │ │
│  │  Task analysis → Pick best method:            │ │
│  │  • Quick code fix? → Agent SDK (Sonnet)       │ │
│  │  • Deep refactor? → Agent SDK (Opus)          │ │
│  │  • Shell pipeline? → CLI -p mode              │ │
│  │  • Long background? → Teleport to Web         │ │
│  │  • Need oversight? → Remote Control           │ │
│  │  • GitHub-only? → Claude Code Web             │ │
│  └──────┬──────┬──────┬──────┬──────┬───────────┘ │
│         │      │      │      │      │              │
│    ┌────▼──┐ ┌─▼───┐ ┌▼────┐ ┌▼───┐ ┌▼─────┐     │
│    │Agent  │ │CLI  │ │Tele-│ │RC  │ │Web   │     │
│    │SDK    │ │-p   │ │port │ │    │ │      │     │
│    │       │ │     │ │     │ │    │ │      │     │
│    │Parallel│ │Shell│ │Fire │ │Mon-│ │Cloud │     │
│    │sessions│ │pipe │ │forget│ │itor│ │repos │    │
│    └───────┘ └─────┘ └─────┘ └────┘ └──────┘     │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## Open Questions

1. **API key vs subscription**: Should OpenClaw use API tokens (pay-per-use) or ride the operator's Max subscription (flat rate)? SDK needs API key. RC/Web need subscription.

2. **Autonomy level**: Should OpenClaw auto-select the access method, or should it propose and let the operator approve?

3. **Cost governance**: What's the per-task and per-day budget ceiling? Who gets alerted when thresholds are approached?

4. **Session persistence**: Should Claude Code sessions be saved for audit/replay? How long to retain?

5. **Repo access**: Which repos should OpenClaw's Claude Code sessions have access to? All repos on the machine, or a scoped list?

---

## Next Steps

- [ ] Decision: Approve Tier 1 (Agent SDK) for implementation
- [ ] Decision: Set budget limits and cost governance policy
- [ ] Decision: Define which repos/directories are in scope
- [ ] Implementation: Add `@anthropic-ai/claude-agent-sdk` to OpenClaw dependencies
- [ ] Implementation: Build access method router
- [ ] Implementation: Add monitoring/logging for Claude Code sessions
- [ ] Implementation: Update exec-approvals for CLI mode (Tier 2)
- [ ] Testing: Validate Agent SDK integration end-to-end
- [ ] Documentation: Update CLAUDE.md with new capabilities
