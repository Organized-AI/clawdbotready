# Clawdbot Ready × just-bash — Implementation Master Plan

**Created:** 2026-02-07
**Project Path:** `/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/OpenClaw`
**Runtime:** Node.js / TypeScript
**Repository:** TBD (organized-ai or jhillbht)

---

## Project Overview

Integrate Vercel's `just-bash` sandboxed shell environment into the OpenClaw/Clawdbot Ready stack to provide a secure execution layer for AgentSkills. This protects customer hardware from destructive commands while maintaining full agent capability.

**Source:** https://github.com/vercel-labs/just-bash

---

## Architecture Decision

```
┌─────────────────────────────────────────────┐
│           Gateway Daemon (OpenClaw)          │
│         Claude Opus 4.5 / Local Models       │
├─────────────────────────────────────────────┤
│         just-bash Security Membrane          │
│  ┌───────────┬────────────┬───────────────┐ │
│  │ InMemoryFs│ OverlayFs  │ ReadWriteFs   │ │
│  │ (default) │ (preview)  │ (trusted only)│ │
│  └───────────┴────────────┴───────────────┘ │
│  ┌──────────────────────────────────────┐   │
│  │ Network Allow-List (per skill tier)  │   │
│  └──────────────────────────────────────┘   │
├─────────────────────────────────────────────┤
│            121 AgentSkills                   │
│     File ops · Web automation · Data proc   │
└─────────────────────────────────────────────┘
```

---

## Tier Mapping

| Tier | Product | Filesystem | Network | Price Range |
|------|---------|-----------|---------|-------------|
| 1 | VPS | InMemoryFs | None | $297/mo |
| 2 | Mac Mini M4 | OverlayFs | Standard presets | $1,497-$1,997/mo |
| 3 | Mac Studio | ReadWriteFs (scoped) | Full presets | $4,997-$7,997/mo |
| 4 | Agency | ReadWriteFs + custom cmds | Unrestricted | $9,997-$14,997/mo |

---

## Implementation Phases

| Phase | Name | Dependencies |
|-------|------|-------------|
| 0 | Project Setup & just-bash Install | None |
| 1 | Sandbox Core — Filesystem Tiers | Phase 0 |
| 2 | Network Security Layer | Phase 1 |
| 3 | AgentSkill Adapter | Phase 1, 2 |
| 4 | AI SDK Bash Tool Integration | Phase 3 |
| 5 | OpenClaw Plugin Packaging | Phase 4 |
| 6 | Tier-Based Permission System | Phase 5 |
| 7 | Integration Testing & Hardening | All |

See `implementation-phases/` directory for individual phase prompts.
