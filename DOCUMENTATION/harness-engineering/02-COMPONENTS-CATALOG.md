# Harness Components Catalog

A reference of every component in a well-designed agent harness, what it does, and why it matters.

---

## Component Map

```
┌─────────────────────────────────────────────────────────┐
│                    HARNESS LAYERS                        │
│                                                          │
│  ┌── Input ──────────────────────────────────────────┐  │
│  │  User Interface │ Session Manager │ Permission Gate│  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│  ┌── Knowledge ──────────────────────────────────────┐  │
│  │  Skill Registry │ Context Compressor │ Task Graph  │  │
│  │  Memory Store   │ AGENTS.md Loader                │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│  ┌── Integration ────────────────────────────────────┐  │
│  │  MCP Runtime │ External Servers │ Web Search      │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│  ┌── Execution ──────────────────────────────────────┐  │
│  │  Tool Dispatch │ Streaming Runtime │ Prompt Cache  │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│  ┌── Output ─────────────────────────────────────────┐  │
│  │  Verified Task Results │ Self-Check Loop           │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│  ┌── Observability ──────────────────────────────────┐  │
│  │  Event Bus │ Background Executor │ Cost Metering   │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│  ┌── Multi-Agent ────────────────────────────────────┐  │
│  │  Subagent Spawning │ Teammate Mailboxes │ FSM     │  │
│  │  Autonomous Board  │ Worktree Isolator            │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

*Architecture based on Fareed Khan's analysis of Claude Code's structure.*

---

## 1. Filesystem & Git — Durable State

### What It Is
Read/write access to a persistent filesystem with git version control.

### Why It Matters
Without filesystem access, agents copy-paste into chat windows. With it, agents get a workspace for:
- Reading data and project context
- Offloading intermediate work (plans, notes, partial results)
- Coordinating with other agents and humans
- Persisting state across context resets

### What Git Adds
- **Rollback**: Undo agent mistakes with `git revert` or `git checkout`
- **Experimentation**: Branch per approach, merge the winner
- **Audit trail**: Every change attributed and timestamped
- **Collaboration**: Multiple agents work on branches simultaneously via worktrees

### Harness Design Decisions
- What directories can the agent read/write?
- Are there protected paths (credentials, config)?
- How are git operations guarded (hooks on force-push, main branch protection)?

---

## 2. Bash & Code Execution

### What It Is
General-purpose shell access for running commands, scripts, and programs.

### Why It Matters
> Instead of pre-building tools for every possible action, grant bash access. Agents excel at shell commands, and most tasks collapse to CLI invocations.
> — Simon Willison

Rather than building a custom tool for "check disk space," "run tests," "install packages," or "query a database" — bash handles all of them.

### The Principle
**Provide general-purpose tooling rather than specialized gadgets.** A bash tool replaces dozens of narrow tools, with the model figuring out the right invocation.

### Harness Design Decisions
- What commands are allowed/blocked?
- Is execution sandboxed?
- What's the timeout per command?
- Are destructive commands (`rm -rf`, `DROP TABLE`, `git push --force`) blocked or gated?

---

## 3. Sandboxes

### What It Is
Isolated execution environments that separate the agent from the host system.

### Why It Matters
Bash is powerful but dangerous. Sandboxes provide:
- **Isolation**: Agent can't affect the host filesystem or processes
- **Allow-listing**: Only approved commands/network endpoints available
- **Network isolation**: Prevent data exfiltration
- **Parallelism**: Run multiple agents in separate sandboxes simultaneously

### What Good Sandboxes Include
- Pre-installed language runtimes (Node.js, Python, etc.)
- Git
- Test CLI tools
- Headless browsers (for observation and self-verification)
- Standard unix utilities

### Harness Design Decisions
The model doesn't configure its execution environment — that's a harness-level decision:
- Where does the agent run?
- What's available in the environment?
- How does it verify its own output?

### In OpenClaw Context
Our VM isolation (Lume hypervisor) and exec-approvals (deny-by-default command allowlist) are sandbox components. The VM provides OS-level isolation; exec-approvals provide command-level granularity.

---

## 4. Memory & Search — Continual Learning

### What It Is
Files injected at startup and tools for accessing knowledge beyond the training cutoff.

### Why It Matters
Models have no knowledge beyond weights and current context. Two mechanisms bridge this gap:

**Memory Files** (`AGENTS.md`, `CLAUDE.md`, skill files):
- Injected into the system prompt on startup
- Reloaded when edited mid-session
- Enable crude but effective continual learning
- Encode your project's conventions, constraints, and lessons learned

**Search & MCP Tools**:
- Web search for post-training knowledge (library versions, current docs)
- MCP servers for domain-specific data access
- Documentation fetching for API references

### Harness Design Decisions
- What gets loaded at startup vs. on-demand?
- How large can memory files be before they degrade performance?
- Which search tools are available?
- How is retrieved context prioritized vs. existing context?

---

## 5. Hooks — The Enforcement Layer

### What It Is
Deterministic code that executes at specific lifecycle points — before tool calls, after file edits, before commits, on session start.

### Why It Matters
Hooks enforce what the agent should never forget but often does. They're the bridge between "the model usually does the right thing" and "the system always does the right thing."

### The Design Principle

> **"Success is silent, failures are verbose."**

- Passing typechecks produce no output (zero context cost)
- Failures get injected into the agent's context for self-correction
- Feedback is nearly free in the common case, directly actionable on errors

### Common Hook Patterns

| Lifecycle Point | Hook Action |
|---|---|
| After file edit | Run typecheck + lint |
| Before commit | Run test suite, block if failing |
| Before bash execution | Block destructive commands (`rm -rf`, `DROP TABLE`) |
| Before git push | Block force-push to main/master |
| Before PR creation | Require approval |
| On session start | Load latest memory files, check environment |
| On context reset | Persist state to handoff file |

### Enforcement Examples

```bash
# Block destructive bash commands
if echo "$command" | grep -qE 'rm -rf|git push --force|DROP TABLE'; then
  echo "BLOCKED: Destructive command requires human approval"
  exit 1
fi

# Auto-typecheck after file edits
on_file_edit() {
  result=$(npm run typecheck 2>&1)
  if [ $? -ne 0 ]; then
    echo "TYPECHECK FAILED: $result"  # Injected into agent context
  fi
  # Success = silence (no context cost)
}
```

---

## 6. Context Management

### What It Is
Strategies for managing the finite context window — what goes in, what comes out, and when.

### Why It Matters
As context windows fill, reasoning degrades. This is called **context rot** and it's one of the most important problems in harness design.

### Three Techniques

**Compaction**: Intelligently summarize and offload older context so agents can continue working. Like garbage collection for attention.

**Tool-Call Offloading**: Large outputs (2,000-line logs) clutter context. The harness retains only head and tail tokens above a threshold, offloading full outputs to the filesystem for on-demand reading.

**Progressive Disclosure (Skills)**: Loading every tool description at startup degrades performance. Skills reveal instructions and tools only when the current task requires them.

### For Long-Horizon Work
Full context resets: sessions tear down and rebuild from compact handoff files. This is closer to onboarding a new engineer than traditional memory management — the agent starts fresh but reads a briefing document.

---

## 7. Orchestration — Multi-Agent

### What It Is
Logic for spawning, coordinating, and managing multiple agents working together.

### Components

**Subagent Spawning**: Create child agents for parallel or specialized work. Each subagent gets its own context, tools, and constraints.

**Teammate Mailboxes**: Message-passing between agents. One agent can request work from another without direct coupling.

**FSM Protocol**: Finite state machine for managing agent lifecycle (idle → assigned → working → reviewing → complete).

**Worktree Isolation**: Each agent works in a separate git worktree, preventing filesystem conflicts between parallel agents.

**Autonomous Board**: Governance layer that can approve/reject/redirect agent actions based on rules.

### Harness Design Decisions
- When should work be delegated to a subagent vs. done inline?
- How do agents share context without drowning each other?
- What's the escalation path when an agent is stuck?
- How are conflicts resolved when agents modify the same files?

---

## 8. Observability

### What It Is
Logging, tracing, and metering infrastructure that makes agent behavior visible and debuggable.

### Components

| Component | Purpose |
|---|---|
| **Event Bus** | Central stream of all agent actions and decisions |
| **Tool-Call Tracing** | Record every tool invocation with inputs, outputs, and timing |
| **Cost Metering** | Track token usage, API calls, and compute costs |
| **Latency Tracking** | Measure time per step for optimization |
| **Audit Logs** | Immutable record of all actions (for compliance and debugging) |
| **Background Executor** | Run observability tasks without blocking agent work |

### Why It Matters
Without observability, harness debugging is guesswork. With it, you can:
- Trace a failure back to its root cause
- Identify which harness components are load-bearing
- Measure the cost/benefit of each component
- Detect performance regressions when harness changes ship

---

## 9. Permission Gates

### What It Is
Authorization layer that controls which actions require human approval.

### Spectrum

```
Fully Autonomous ◀──────────────────────────────▶ Fully Supervised
       │                                                 │
  "Run everything"                              "Approve everything"
       │                                                 │
  High throughput,                              Low throughput,
  high risk                                     low risk
```

### Design Choices
- Which actions are auto-approved? (read files, run tests)
- Which require approval? (push code, create PRs, send messages)
- Which are blocked entirely? (delete branches, drop databases)
- Can approval be pre-authorized for categories? (e.g., "all git operations are OK")

### In OpenClaw Context
Our exec-approvals system implements this: deny-by-default with 266 rules specifying what's allowed, what's denied with alerts, and what requires approval.

---

## Component Interaction Summary

```
User Request
    │
    ▼
Permission Gate ──→ Blocked? → Notify user
    │
    ▼
Knowledge Layer ──→ Load AGENTS.md, skills, memory
    │
    ▼
Tool Dispatch ──→ Select tools, prepare calls
    │
    ▼
Hooks (pre) ──→ Validate, block destructive ops
    │
    ▼
Sandbox Execution ──→ Run in isolated environment
    │
    ▼
Hooks (post) ──→ Typecheck, lint, test
    │
    ▼
Context Management ──→ Compact if needed
    │
    ▼
Observability ──→ Log, trace, meter
    │
    ▼
Output ──→ Verified result to user
```
