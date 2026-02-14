# Organized AI Marketplace — Roadmap

**Created:** 2026-02-12

---

## Phase 1: Skill Catalog & Metadata
- Audit all existing skills in .claude/skills/
- Define skill metadata schema (name, version, vertical, memory estimate, dependencies)
- Create marketplace catalog index (JSON registry)
- Tag each skill with vertical classification
- Document skill capabilities and integration points

## Phase 2: Plugin Loader System
- Build plugin loader that scans skill directories
- Match loaded skills to client profile configuration
- Implement hot-reload (add/remove skills without restart)
- Memory tracking per loaded skill
- Error isolation (bad skill doesn't crash Gateway)

## Phase 3: Client Profile Manager
- CRUD operations for client profiles
- Vertical-based templates (marketing, sales, product, data)
- Per-client addon toggle
- Model preference configuration per client
- Budget tracking and limits

## Phase 4: Gateway Integration
- Wire plugin loader into OpenClaw Gateway startup
- Skill-aware request routing (skills inform ClawRouter tier)
- Per-client skill availability in agent context
- Skill usage event emission to PostHog

## Phase 5: Admin Dashboard
- Web UI for managing client skill configurations
- Skill catalog browser with descriptions and memory estimates
- Per-client usage analytics
- One-click vertical activation

## Phase 6: Self-Service & Custom Skills (v2)
- Client-facing skill marketplace UI
- Custom skill development toolkit (skill-creator-enhanced)
- Skill publishing workflow (develop → test → publish)
- Revenue sharing for third-party skill authors
- Skill rating and review system
