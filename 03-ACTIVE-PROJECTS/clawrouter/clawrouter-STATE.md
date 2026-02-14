# ClawRouter — Project State

**Last Updated:** 2026-02-12

---

## Current Phase

**Planning** — Defining integration approach and task breakdown.

---

## Decisions Made

### 2026-02-12: Integration Approach
**Decision**: Fork/submodule ClawRouter into the Clawdbot Ready repo on `feature/clawrouter` branch
**Rationale**: Follows the branch strategy defined in OPENCLAW-UPLEVEL-PLAN.md
**Source**: https://github.com/Organized-AI/ClawRouter

### 2026-02-12: Routing Modes
**Decision**: Support three modes — local, cloud, hybrid
**Rationale**: Different deployment sizes need different strategies (see OPENCLAW-CAPACITY-PLAN.md)
- **Local**: 5 clients on Mac Studio, all models via Ollama
- **Cloud**: Moltworker/remote deployments, route to API providers
- **Hybrid**: 10+ clients, local-first with cloud overflow for 70B

### 2026-02-12: Priority P2
**Decision**: ClawRouter is Phase 3 in the uplevel plan (after just-bash and nanoclaw)
**Rationale**: Messaging and execution must work before optimizing costs

---

## Active Blockers

None — can begin implementation when Phase 1 (just-bash) and Phase 2 (nanoclaw) are stable.

---

## Open Questions

### x402 Micropayments
**Question**: Should x402 crypto payments be enabled by default or opt-in?
**Leaning**: Opt-in. Standard API keys as default, x402 as advanced configuration.

### Tier Tuning Per Client
**Question**: Should each client have configurable tier thresholds or use global defaults?
**Leaning**: Global defaults with per-client overrides in client profile JSON.

---

## Implementation Status

- [ ] Fork/submodule ClawRouter
- [ ] Configure 14-dimension scoring
- [ ] Set up model provider API keys
- [ ] Wire between Gateway and model APIs
- [ ] Create routing configuration
- [ ] Implement fallback chains
- [ ] Add cost tracking and reporting
- [ ] Create per-customer model preferences
- [ ] Write integration tests
- [ ] Document configuration options
