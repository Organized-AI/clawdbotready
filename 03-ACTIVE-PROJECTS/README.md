# 03-ACTIVE-PROJECTS

Active development projects that integrate with or extend the OpenClaw stack.

## Current Projects

### [`clawrouter/`](clawrouter/)
**ClawRouter — Intelligent Model Routing**

**Status**: Planning
**Priority**: P2 — Optimization Layer
**Source**: [Organized-AI/ClawRouter](https://github.com/Organized-AI/ClawRouter)

**Problem**: OpenClaw hardcodes a single expensive model for every request — "hi" and "analyze this contract" both hit Claude 3.5 Sonnet.

**Solution**: 14-dimension weighted scoring routes each request to the cheapest capable model. 30+ models, 4 tiers (SIMPLE/MEDIUM/COMPLEX/REASONING), 100% local routing in <1ms. Average 96% cost savings on mixed workloads.

**Key files**:
- [`clawrouter-PROJECT.md`](clawrouter/clawrouter-PROJECT.md) — Architecture and integration points
- [`clawrouter-STATE.md`](clawrouter/clawrouter-STATE.md) — Decisions and open questions
- [`clawrouter-ROADMAP.md`](clawrouter/clawrouter-ROADMAP.md) — 5-phase implementation plan

---

### [`organized-ai-marketplace/`](organized-ai-marketplace/)
**Custom Skills via Organized AI Marketplace**

**Status**: Planning
**Priority**: P2 — Client Differentiation Layer

**Problem**: All OpenClaw clients get the same generic agent. No mechanism to customize capabilities per vertical, distribute skills, or monetize add-on modules.

**Solution**: Skill distribution and management system — packages Claude Code skills as installable plugins organized by vertical (Marketing, Sales, Product, Data, GTM/MarTech, Dev). Per-client profiles control which skills load. Supports Starter ($997), Pro ($2,497), Premium ($4,997), and Enterprise tiers.

**Key files**:
- [`marketplace-PROJECT.md`](organized-ai-marketplace/marketplace-PROJECT.md) — Full skill catalog and architecture
- [`marketplace-STATE.md`](organized-ai-marketplace/marketplace-STATE.md) — Decisions and open questions
- [`marketplace-ROADMAP.md`](organized-ai-marketplace/marketplace-ROADMAP.md) — 6-phase implementation plan

---

### [`google-ads-cli/`](google-ads-cli/)
**Google Ads CLI Rebuild** — Lightweight Google Ads API access for OpenClaw agents

**Status**: Deployed
**Priority**: High (business-critical bot functionality)

**Problem**: Original Python skill had 15,923 files in venv → EMFILE error → Telegram bot broken

**Solution**: Rebuilt as lightweight Node.js/TypeScript CLI tool (1 file in skills/ vs 15,923). Deployed to client Mac Mini at ~/google-ads-cli/ with wrapper at ~/bin/google-ads-cli.

---

### [`meta-ads-cli/`](meta-ads-cli/)
**Meta Ads CLI** — Meta/Facebook Ads API access for OpenClaw agents

**Status**: Built
**Priority**: Medium

---

### [`openclaw-qmd-memory/`](openclaw-qmd-memory/)
**OpenClaw QMD Memory** — Persistent memory system for OpenClaw agents

**Status**: Planning
**Priority**: Medium

---

### [`clawdbot-sandbox/`](clawdbot-sandbox/)
**Clawdbot Sandbox** — just-bash sandboxed shell integration (8-phase build)

**Status**: Phase 7 Complete
**Priority**: P0 — Foundation

---

## Adding New Projects

When adding new active projects to this directory:

1. Create project subdirectory: `03-ACTIVE-PROJECTS/project-name/`
2. Add project README with context
3. Include task specification if using phased execution
4. Update this README with project entry
5. Keep planning artifacts in project directory

---

## Relationship to Primary Focus

Projects in this directory are **not part of the core OpenClaw deployment workflow**. They are:
- Auxiliary development tasks
- Side projects that integrate with OpenClaw
- Experimental features
- One-off tooling needs

For core deployment work, see [`../SETUP GUIDES/`](../SETUP%20GUIDES/).

---

## Archive Policy

When a project in this directory is:
- ✅ **Deployed successfully** and stable for 24+ hours → Move to `.archive/`
- ❌ **Cancelled** or no longer needed → Move to `.archive/`
- 🔄 **On hold** but may resume → Keep in `03-ACTIVE-PROJECTS/` with status note

Archived projects go to [`../.archive/`](../.archive/) with dated folder name (e.g., `project-name-archived-2026-02-05`).
