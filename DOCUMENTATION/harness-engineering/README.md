# Harness Engineering Wiki

> **"A decent model with a great harness beats a great model with a bad harness."**

Harness Engineering is the discipline of building the scaffolding — prompts, tools, context policies, hooks, sandboxes, subagents, feedback loops, and recovery paths — that transforms a language model into a system that completes actual work.

Based on [Addy Osmani's synthesis](https://addyosmani.com/blog/agent-harness-engineering/) of work by Viv Trivedy (HumanLayer), Anthropic, and the broader agent engineering community.

---

## The Core Equation

```
Agent = Model + Harness

If you're not the model, you're the harness.
```

Claude Code, Cursor, Codex, Aider, and Cline are all harnesses around sometimes-identical models. Their observable behaviors differ because of harness design, not model differences.

---

## Wiki Contents

| Document | What It Covers |
|---|---|
| [Core Concepts](./01-CORE-CONCEPTS.md) | The mental model — what a harness is, why it matters, the skill-issue reframe, the ratchet discipline |
| [Components Catalog](./02-COMPONENTS-CATALOG.md) | Every harness component explained — filesystem, bash, sandboxes, memory, hooks, context management, orchestration |
| [Patterns & Techniques](./03-PATTERNS-AND-TECHNIQUES.md) | Proven patterns — context rot mitigation, long-horizon execution, Ralph Loops, planner/generator/evaluator splits |
| [AGENTS.md Best Practices](./04-AGENTS-MD-GUIDE.md) | How to write and maintain effective `AGENTS.md` / `CLAUDE.md` files — the pilot's checklist approach |
| [Troubleshooting & Ratchet Playbook](./05-RATCHET-PLAYBOOK.md) | Turning failures into permanent improvements — the ratchet methodology with worked examples |
| [Production Architecture](./06-PRODUCTION-ARCHITECTURE.md) | What a mature harness looks like in production — layers, components, and the Harness-as-a-Service model |

---

## Quick Start: The 3 Things That Matter Most

If you read nothing else:

1. **Every mistake becomes a rule.** When an agent fails, don't just fix the output — update the harness so it can't happen again. This is the ratchet.

2. **Work backwards from behavior.** If you can't name the behavior a component exists to deliver, it probably shouldn't be there.

3. **Keep `AGENTS.md` short.** Pilot's checklist, not style guide. Under 60 lines. Each line earned by a real failure, not brainstormed into existence.

---

## Key Principles

### It's Not a Model Problem — It's a Configuration Problem
Agent failures are signals for harness improvements. If an agent comments out tests, that's not a model limitation — it's a missing pre-commit hook, a gap in `AGENTS.md`, or the absence of a reviewer subagent.

### The Harness Gap
> "The gap between what today's models can do and what you see them doing is largely a harness gap."

Terminal Bench 2.0 evidence: the same model (Claude Opus 4.6) scores differently in different harnesses. Viv's team moved a coding agent from Top 30 to Top 5 by changing only the harness.

### Harnesses Are Living Systems
> "A harness is a living system, not a config file you set up once."

The best harness reflects your specific failure history. It tightens after mistakes and loosens when better models make constraints unnecessary. Opus 4.6 eliminated context-anxiety scaffolding that Sonnet 4.5 required — but unlocked new tasks with their own failure modes.

### Harnesses Converge
Top coding agents resemble each other more than their underlying models do. The models differ; harness patterns converge. The industry is finding load-bearing scaffolding that transforms generative models into shipping-capable systems.

---

## How This Applies to Clawdbot / OpenClaw

This wiki is directly relevant to our OpenClaw Gateway deployments:

- **`CLAUDE.md`** in this repo is our harness rulebook — every convention traces to a past failure
- **exec-approvals** are our hook enforcement layer — deny-by-default tool execution
- **VM isolation** is our sandbox — the agent runs in a controlled environment
- **Health monitoring scripts** are our observability layer
- **Moltbook / Paperclip integration** is our orchestration layer for multi-agent coordination

When improving our OpenClaw deployment, apply harness engineering principles: trace every new rule to a specific failure, keep configuration lean, and treat the harness as a living system.

---

## Source Material

- [Agent Harness Engineering — Addy Osmani](https://addyosmani.com/blog/agent-harness-engineering/)
- Viv Trivedy / HumanLayer — harness engineering framework and terminology
- Anthropic — model-harness co-training insights
- Fareed Khan — Claude Code architecture analysis
- Simon Willison — bash-first agent tooling philosophy
