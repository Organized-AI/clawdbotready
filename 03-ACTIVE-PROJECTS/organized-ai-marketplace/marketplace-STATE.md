# Organized AI Marketplace — Project State

**Last Updated:** 2026-02-12

---

## Current Phase

**Planning** — Cataloging skills, defining distribution mechanism, designing client profiles.

---

## Decisions Made

### 2026-02-12: Skill Organization by Vertical
**Decision**: Group skills into 6 verticals (Marketing, Sales, Product, Data, GTM/MarTech, Dev/Infrastructure)
**Rationale**: Clients think in verticals, not individual skill names. Vertical-based selection simplifies onboarding.
**Source**: OPENCLAW-LOCAL-DEMO-PLAN.md and OPENCLAW-CAPACITY-PLAN.md

### 2026-02-12: Core Skills Bundled Free
**Decision**: Infrastructure skills (boris, long-runner, methodology, etc.) bundled with every deployment at no extra cost
**Rationale**: These are quality-of-life improvements that make every agent better. Charging for them reduces adoption.

### 2026-02-12: Memory Budget Per Vertical
**Decision**: Target ~200-350 MB per vertical skill set loaded
**Rationale**: Based on OPENCLAW-CAPACITY-PLAN.md calculations — 10 clients at 250 MB avg = 2.5 GB total, well within Mac Studio headroom.

### 2026-02-12: JSON-Based Client Profiles
**Decision**: Client configuration via JSON files in config/clients/
**Rationale**: Simple, version-controllable, easy to template. No database needed for <20 clients.

---

## Active Blockers

None — can begin skill cataloging and plugin loader development independently.

---

## Open Questions

### Self-Service Skill Installation
**Question**: Should clients be able to install skills themselves via a web UI, or admin-only?
**Leaning**: Admin-only for v1 (via client profile JSON), self-service web UI for v2.

### Skill Versioning
**Question**: How to handle skill version updates across client deployments?
**Leaning**: Semver in skill metadata, admin-controlled rollout per client.

### Custom Skill Development
**Question**: Should clients be able to create their own skills?
**Leaning**: Yes for Enterprise tier. Use skill-creator-enhanced as the development tool.

---

## Implementation Status

- [ ] Catalog all existing skills by vertical
- [ ] Design skill metadata schema (name, version, vertical, memory, deps)
- [ ] Build plugin loader (scan, match to client profile, hot-reload)
- [ ] Create client profile manager (CRUD, templates per vertical)
- [ ] Create skill registry index
- [ ] Wire plugin loader into OpenClaw Gateway
- [ ] Add skill usage tracking (PostHog events)
- [ ] Build admin UI for skill management
- [ ] Write integration tests
- [ ] Document skill authoring guide
