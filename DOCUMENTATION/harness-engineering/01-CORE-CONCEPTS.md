# Core Concepts

> **"Agent = Model + Harness. If you're not the model, you're the harness."**
> — Viv Trivedy, HumanLayer

---

## What Is a Harness?

A harness is everything beyond the model itself that makes an AI agent functional. It's the scaffolding that transforms a language model from a text generator into a system that ships code, manages infrastructure, and completes real work.

### Harness Components

| Component | Examples |
|---|---|
| **Prompts** | System prompts, `CLAUDE.md`, `AGENTS.md`, skill files, subagent prompts |
| **Tools** | Skills, MCP servers, tool descriptions and schemas |
| **Infrastructure** | Filesystem access, sandbox environments, headless browsers |
| **Orchestration** | Subagent spawning, handoffs, model routing |
| **Enforcement** | Hooks, middleware, pre-commit checks, permission gates |
| **Observability** | Logs, traces, cost metering, latency tracking |
| **Memory** | Context files, memory stores, search integration |
| **Recovery** | Rollback paths, error loops, context resets |

### Why the Distinction Matters

Claude Code, Cursor, Codex, Aider, and Cline often wrap the same underlying model. Their behaviors differ dramatically because their harnesses differ:

- How they manage context windows
- What tools they expose
- How they handle errors and recovery
- What rules they enforce via hooks
- How they decompose long tasks

The harness is the product. The model is a component.

---

## The Skill-Issue Reframe

Traditional thinking attributes agent failures to model limitations: "the model isn't smart enough," "we need a better model," "wait for the next release."

Harness engineering reframes this:

> **"It's not a model problem. It's a configuration problem."**
> — HumanLayer

### What This Means in Practice

| Traditional View | Harness Engineering View |
|---|---|
| "The model keeps deleting tests" | "We need a pre-commit hook that blocks test removal" |
| "The agent makes unsafe bash commands" | "We need a destructive-command blocklist in hooks" |
| "It forgets our coding conventions" | "Our `AGENTS.md` is missing or too long" |
| "The agent stops too early" | "We need a Ralph Loop to intercept completion" |
| "It produces inconsistent output" | "We need a planner/evaluator split" |

### The Evidence

**Terminal Bench 2.0**: Claude Opus 4.6 in Claude Code scores lower than the same model in a custom harness. Same model, different scores — the delta is pure harness.

**Viv's team**: Moved a coding agent from **Top 30 to Top 5** on benchmarks by changing only the harness. Zero model changes.

> **"The gap between what today's models can do and what you see them doing is largely a harness gap."**

---

## The Ratchet Discipline

The most important principle in harness engineering: **every agent mistake becomes a permanent rule.**

### How It Works

```
Agent makes mistake
        │
        ▼
Diagnose root cause
        │
        ▼
Add constraint to harness
(AGENTS.md, hook, tool config, subagent)
        │
        ▼
Constraint prevents recurrence
        │
        ▼
Harness quality ratchets upward
(never slides back)
```

### The Rule

> **"Every line in a good `AGENTS.md` should be traceable back to a specific thing that went wrong."**

You add constraints after real failures. You remove them only when improved models render them redundant. You never brainstorm rules into existence — you earn them through pain.

### Why This Works

This creates a one-way quality valve:
- Failures tighten constraints
- Constraints prevent recurrence
- The harness only gets better over time
- Each deployment accumulates institutional knowledge

This is why harness engineering is a discipline, not a downloadable framework. The right harness reflects **your** specific failure history.

---

## Working Backwards from Behavior

The most useful design pattern: derive harness components from desired behaviors, not from feature lists.

### The Process

```
Behavior you want (or want to fix)
        │
        ▼
Harness component that delivers it
```

### The Test

> **"If you can't name the behaviour a component exists to deliver, it probably shouldn't be there."**

Every piece of scaffolding must justify its existence through a specific behavioral outcome. If a hook, rule, or tool can't be traced to a concrete behavior it enables or prevents, remove it.

### Examples

| Desired Behavior | Harness Component |
|---|---|
| "Agent should never force-push to main" | Hook: block `git push --force` to main/master |
| "Agent should run tests after editing code" | Hook: auto-run test suite after file edits |
| "Agent should follow our import conventions" | `AGENTS.md`: document import ordering rules |
| "Agent should not exceed $50/day in API costs" | Budget middleware with cost tracking |
| "Agent should ask before destructive operations" | Permission gate in execution layer |

---

## The Model-Harness Training Loop

A feedback loop exists between harness design and model training:

```
Harness designers discover useful primitives
        │
        ▼
Primitives get standardized into products
        │
        ▼
Products are used during next-gen model training
        │
        ▼
Improved model uses those primitives better
        │
        ▼
New capabilities unlock → new harness patterns needed
        │
        ▼
    (cycle repeats)
```

### Practical Implications

- Models specifically improve at actions harness designers prioritize: filesystem operations, bash, planning, subagent dispatch
- Opus 4.6 behaves differently inside Claude Code versus other harnesses because of co-training
- Tool logic changes can cause regressions due to overfitting to specific patterns
- **The best harness isn't the one the model was trained inside — it's the one designed for your task**

### Harnesses Don't Shrink — They Move

Better models kill certain failure modes while unlocking new tasks with their own failure modes:

> **"Every component in a harness encodes an assumption about what the model can't do on its own."**
> — Anthropic

- When models improve → load-bearing components should exit
- When models unlock new capabilities → new scaffolding becomes necessary
- The total harness complexity stays roughly constant — it just shifts

---

## Key Takeaways

1. **The harness is the product.** The model is a component inside it.
2. **Failures are configuration problems**, not model limitations.
3. **The ratchet only tightens.** Every mistake earns a new rule. Rules exit only when models outgrow them.
4. **Work backwards from behavior.** No component without a named behavior it delivers.
5. **Harnesses are living systems.** Not a config file you set up once.
6. **The harness gap is the opportunity.** Same model, different harness, dramatically different results.
