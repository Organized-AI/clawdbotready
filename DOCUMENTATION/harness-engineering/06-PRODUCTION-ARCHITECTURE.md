# Production Architecture

What a mature agent harness looks like in production — layered architecture, component interactions, and the emerging Harness-as-a-Service model.

---

## Mature Harness Architecture

Based on Fareed Khan's analysis of Claude Code's architecture, a production-grade harness is structured in distinct layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                       INPUT LAYER                               │
│  ┌──────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │   User   │  │    Session      │  │    Permission         │  │
│  │Interface │  │    Manager      │  │    Gate               │  │
│  └──────────┘  └─────────────────┘  └───────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     KNOWLEDGE LAYER                             │
│  ┌──────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │  Skill   │  │    Context      │  │    Task               │  │
│  │ Registry │  │   Compressor    │  │    Graph              │  │
│  └──────────┘  └─────────────────┘  └───────────────────────┘  │
│  ┌──────────┐  ┌─────────────────┐                              │
│  │ Memory   │  │  AGENTS.md      │                              │
│  │  Store   │  │   Loader        │                              │
│  └──────────┘  └─────────────────┘                              │
├─────────────────────────────────────────────────────────────────┤
│                    INTEGRATION LAYER                             │
│  ┌──────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │   MCP    │  │    External     │  │    Web                │  │
│  │ Runtime  │  │    Servers      │  │   Search              │  │
│  └──────────┘  └─────────────────┘  └───────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     EXECUTION LAYER                             │
│  ┌──────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │   Tool   │  │   Streaming     │  │    Prompt             │  │
│  │ Dispatch │  │    Runtime      │  │    Cache              │  │
│  └──────────┘  └─────────────────┘  └───────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      OUTPUT LAYER                               │
│  ┌──────────────────┐  ┌────────────────────────────────────┐  │
│  │ Verified Task    │  │    Self-Check                      │  │
│  │ Results          │  │    Loop                            │  │
│  └──────────────────┘  └────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                   OBSERVABILITY LAYER                           │
│  ┌──────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │  Event   │  │   Background    │  │    Cost               │  │
│  │   Bus    │  │   Executor      │  │   Metering            │  │
│  └──────────┘  └─────────────────┘  └───────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                    MULTI-AGENT LAYER                            │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐  ┌───────────────┐  │
│  │ Subagent │  │ Teammate │  │   FSM   │  │  Autonomous   │  │
│  │ Spawning │  │ Mailboxes│  │Protocol │  │    Board      │  │
│  └──────────┘  └──────────┘  └─────────┘  └───────────────┘  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Worktree Isolator                         │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

Every concept from the other wiki pages appears as a named component in this architecture.

---

## Layer Responsibilities

### Input Layer
**Purpose**: Receive, validate, and authorize requests.

| Component | Role |
|---|---|
| User Interface | CLI, web UI, API endpoint — how humans interact |
| Session Manager | Track conversation state, handle reconnection, manage lifecycle |
| Permission Gate | Authorize actions based on policy (auto-approve, require-approval, block) |

### Knowledge Layer
**Purpose**: Provide the agent with the right context at the right time.

| Component | Role |
|---|---|
| Skill Registry | Catalog of available skills, loaded on-demand (progressive disclosure) |
| Context Compressor | Summarize and offload older context to fight context rot |
| Task Graph | Track task decomposition, dependencies, and completion state |
| Memory Store | Persistent knowledge across sessions (AGENTS.md, decisions, preferences) |
| AGENTS.md Loader | Inject project rules into system prompt, reload on changes |

### Integration Layer
**Purpose**: Connect to external systems and data sources.

| Component | Role |
|---|---|
| MCP Runtime | Execute Model Context Protocol tools (database, APIs, services) |
| External Servers | Connect to third-party services, MCP servers, custom APIs |
| Web Search | Access post-training knowledge (docs, current data, library versions) |

### Execution Layer
**Purpose**: Run tools and manage the model interaction loop.

| Component | Role |
|---|---|
| Tool Dispatch | Select and invoke the right tool for each action |
| Streaming Runtime | Handle streaming responses, partial results, cancellation |
| Prompt Cache | Cache and reuse prompt prefixes to reduce latency and cost |

### Output Layer
**Purpose**: Verify results before delivering to the user.

| Component | Role |
|---|---|
| Verified Task Results | Final output after all checks pass |
| Self-Check Loop | Auto-verification (typecheck, lint, test) before reporting completion |

### Observability Layer
**Purpose**: Make everything visible and debuggable.

| Component | Role |
|---|---|
| Event Bus | Central stream of all agent events and decisions |
| Background Executor | Run async tasks (logging, metrics) without blocking the agent |
| Cost Metering | Track tokens, API calls, and compute spend |

### Multi-Agent Layer
**Purpose**: Coordinate multiple agents working together.

| Component | Role |
|---|---|
| Subagent Spawning | Create child agents for parallel or specialized work |
| Teammate Mailboxes | Async message-passing between agents |
| FSM Protocol | State machine for agent lifecycle (idle → working → reviewing → done) |
| Autonomous Board | Governance layer for approval/rejection of agent actions |
| Worktree Isolator | Separate git worktree per agent to prevent conflicts |

---

## Harness-as-a-Service (HaaS)

### The Shift

The industry is moving from building on **LLM APIs** (providing completions) to building on **harness APIs** (providing runtimes).

```
Old World:                        New World:
┌─────────────┐                   ┌─────────────────────┐
│  LLM API    │                   │  Harness API        │
│  (tokens    │                   │  (loop, tools,      │
│   in/out)   │                   │   context, hooks,   │
│             │                   │   sandbox, agents)  │
└─────────────┘                   └─────────────────────┘
       │                                   │
  Build everything                    Configure and
  from scratch                        customize
```

### Examples of HaaS Platforms

| Platform | What It Provides |
|---|---|
| **Claude Agent SDK** | Loop, tools, context management, subagents |
| **Codex SDK** | Sandbox, execution, tool dispatch |
| **OpenAI Agents SDK** | Orchestration, handoffs, guardrails |

### What You Customize (The Four Pillars)

Instead of building from scratch, you configure:

1. **System Prompt** — Your `AGENTS.md`, project context, behavioral rules
2. **Tools** — Which tools are available, their descriptions and constraints
3. **Context** — What gets loaded, when, and how it's managed
4. **Subagents** — What specialized agents exist and how they coordinate

Focus your effort on **domain-specific prompt and tool design**. Let the harness framework handle the plumbing.

> **"Good agent building is an exercise in iteration. You can't do iterations if you don't have a v0.1."**
> — Viv Trivedy

---

## Where This Is Going

### Current State
Top coding agents (Claude Code, Cursor, Codex, Aider, Cline) resemble each other more than their underlying models do. The models differ; harness patterns converge.

This convergence reflects the industry finding load-bearing scaffolding that transforms generative models into shipping-capable systems.

### Open Problems

Three exciting frontiers identified by Viv Trivedy:

**1. Multi-Agent Orchestration at Scale**
Coordinating many agents on shared codebases — merge conflicts, task assignment, resource allocation, consistency across parallel work.

**2. Self-Healing Harnesses**
Agents that analyze their own traces to identify and fix harness failure modes. The ratchet becomes automatic:
```
Agent fails → Agent reads trace → Agent diagnoses root cause
→ Agent proposes harness fix → Human approves → Harness improves
```

**3. Dynamic Harness Assembly**
Harnesses that dynamically assemble appropriate tools and context just-in-time rather than pre-configuring at startup:
```
Static (today):     Load all tools at startup
Dynamic (future):   Analyze task → assemble tools → execute → release tools
```

> **"Where harnesses stop being static config and start becoming something closer to a compiler."**

---

## Mapping to OpenClaw / Clawdbot

How our current stack maps to the production architecture:

| Architecture Layer | Our Implementation |
|---|---|
| **Input Layer** | OpenClaw Gateway WebSocket control plane (port 18789) |
| **Knowledge Layer** | `CLAUDE.md`, skill files in `.claude/skills/` |
| **Integration Layer** | MCP servers, messaging channels (WhatsApp, Telegram, iMessage) |
| **Execution Layer** | OpenClaw tool dispatch, exec-approvals enforcement |
| **Output Layer** | Health monitoring scripts, self-check loops |
| **Observability Layer** | Gateway logs, health monitor, Moltbook dashboard |
| **Multi-Agent Layer** | Paperclip orchestration (planned), worktree isolation |

### What We Have

- **Permission Gate**: exec-approvals (266 deny-by-default rules)
- **Sandbox**: VM isolation via Lume hypervisor
- **Hooks**: Pre-commit checks, health monitoring
- **Memory**: `CLAUDE.md` with project conventions
- **Observability**: Gateway logs, health monitor scripts

### What We're Building

- **Multi-Agent**: Paperclip integration for agent orchestration
- **Budget Controls**: Per-agent cost tracking via Paperclip
- **Governance**: Approval gates layered on exec-approvals
- **Self-Healing**: Automated ratchet from failure traces (future)

---

## Key Takeaways

1. **Production harnesses are layered.** Input → Knowledge → Integration → Execution → Output → Observability → Multi-Agent.
2. **HaaS is the new default.** Configure a harness framework, don't build from scratch.
3. **Four pillars to customize**: System prompt, tools, context, subagents.
4. **Harness patterns are converging.** Top agents look more alike than their models do.
5. **The frontier is dynamic assembly.** Harnesses evolving from static config toward compiler-like systems.
