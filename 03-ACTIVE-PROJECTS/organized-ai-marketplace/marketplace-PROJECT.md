# Organized AI Marketplace — Custom Skills for OpenClaw

**Project:** Custom Skills Distribution via Organized AI Marketplace
**Priority:** P2 — Client Differentiation Layer
**Status:** Planning
**Created:** 2026-02-12

---

## Problem

OpenClaw clients all get the same generic agent. There's no mechanism to:
1. Customize agent capabilities per client vertical (marketing, sales, product, data)
2. Distribute and manage skills/plugins across client deployments
3. Monetize specialized capabilities as add-on modules
4. Allow clients to discover and install skills self-service

## Solution

The Organized AI Marketplace is a skill distribution and management system that:
- Packages Claude Code skills as installable plugins for OpenClaw agents
- Organizes skills by vertical (marketing, sales, product, data, GTM, dev)
- Provides per-client skill configuration via client profiles
- Enables self-service skill discovery and installation
- Tracks skill usage for billing and analytics

---

## Skill Catalog by Vertical

### Core Infrastructure (Bundled with every deployment)
| Skill | Purpose |
|-------|---------|
| boris | Verification-first methodology — quality gate for agent outputs |
| long-runner | Multi-context orchestration for complex tasks |
| openclaw-session-learning | Learn from past client interactions |
| methodology | Route to appropriate workflow by task type |
| tech-stack-orchestrator | Analyze infrastructure, recommend integrations |
| phased-build | Break large projects into trackable phases |
| gsd-mode | Fresh-context orchestration, prevent context rot |

### Marketing Suite (~250 MB)
| Skill | Purpose |
|-------|---------|
| brand-voice | Maintain consistent brand tone across content |
| campaign-planning | Strategic campaign creation and scheduling |
| content-creation | Blog posts, social copy, email sequences |
| competitive-analysis | Market positioning and competitor tracking |
| performance-analytics | Campaign ROI and metrics analysis |

### Sales Suite (~200 MB)
| Skill | Purpose |
|-------|---------|
| account-research | Deep prospect/account intelligence |
| call-prep | Pre-call briefings with talking points |
| competitive-intelligence | Win/loss analysis and battlecards |
| draft-outreach | Personalized email/LinkedIn sequences |
| daily-briefing | Morning pipeline and activity summary |
| create-an-asset | Generate sales collateral on demand |

### Product Suite (~200 MB)
| Skill | Purpose |
|-------|---------|
| feature-spec | PRD and spec generation |
| roadmap-management | Roadmap tracking and prioritization |
| metrics-tracking | Product analytics and KPI dashboards |
| stakeholder-comms | Status updates and stakeholder reporting |
| user-research-synthesis | Interview analysis and insight extraction |
| competitive-analysis | Feature gap and market analysis |

### Data Suite (~350 MB)
| Skill | Purpose |
|-------|---------|
| data-exploration | Guided data discovery and profiling |
| data-visualization | Chart and graph generation |
| statistical-analysis | Hypothesis testing and regression |
| sql-queries | Natural language to SQL |
| interactive-dashboard-builder | Live dashboard creation |
| data-validation | Data quality checks and anomaly detection |

### GTM / MarTech Suite (~200 MB)
| Skill | Purpose |
|-------|---------|
| gtm-ai-plugin | Google Tag Manager automation |
| tidy-gtm | GTM container cleanup and optimization |
| linkedin-capi-setup | LinkedIn Conversions API deployment |
| blade-linkedin | LinkedIn Insight Tag management |
| data-audit | Meta Ads account auditing |

### Dev / Infrastructure Suite (~150 MB)
| Skill | Purpose |
|-------|---------|
| organized-codebase-applicator | Project structure standardization |
| stripe | Payment integration |
| frontend-design | UI/UX design assistance |
| hookify | Webhook and event system setup |

---

## Architecture

```
┌───────────────────────────────────────────────┐
│            Organized AI Marketplace            │
│                                               │
│  ┌─────────────┐  ┌─────────────────────┐    │
│  │  Skill      │  │  Client Profile     │    │
│  │  Registry   │  │  Manager            │    │
│  │             │  │                     │    │
│  │  catalog/   │  │  config/clients/    │    │
│  │  metadata   │  │  vertical selection │    │
│  │  versions   │  │  addon toggles      │    │
│  └──────┬──────┘  └──────────┬──────────┘    │
│         │                    │               │
│         └────────┬───────────┘               │
│                  │                           │
│         ┌────────▼──────────┐                │
│         │   Plugin Loader   │                │
│         │                   │                │
│         │  Scan skills/     │                │
│         │  Match to client  │                │
│         │  Hot-reload       │                │
│         │  Usage tracking   │                │
│         └────────┬──────────┘                │
│                  │                           │
└──────────────────┼───────────────────────────┘
                   │
                   ▼
          ┌────────────────┐
          │  OpenClaw      │
          │  Gateway       │
          │  (per-client)  │
          └────────────────┘
```

---

## Client Profile Configuration

```json
{
  "client_id": "blade-marketing",
  "tier": "pro",
  "core_plugins": [
    "boris", "long-runner", "methodology",
    "openclaw-session-learning", "phased-build", "gsd-mode"
  ],
  "vertical_plugins": ["marketing"],
  "addon_plugins": ["data-audit", "gtm-ai-plugin"],
  "local_models": {
    "fast": "llama3.2:3b",
    "general": "llama3.1:8b",
    "smart": "llama3.3:70b",
    "code": "qwen2.5-coder:7b"
  }
}
```

---

## Service Tier Mapping

| Tier | Price | Verticals | Add-ons | Models |
|------|-------|-----------|---------|--------|
| **Starter** | $997/mo | None (core only) | None | 3B fast only |
| **Pro** | $2,497/mo | 1 vertical included | Up to 3 | 3B + 8B + 70B |
| **Premium** | $4,997/mo | All verticals | Unlimited | Full stack + cloud hybrid |
| **Enterprise** | Custom | All + custom skills | Custom | Dedicated hardware |

---

## Dependencies

- **Depends on**: OpenClaw Gateway (running), plugin loader system
- **Enhances**: ClawRouter (skills inform routing decisions), PostHog (skill usage analytics)
- **Source skills from**: .claude/skills/ (existing), marketplace registry (new)

---

## Success Criteria

- [ ] Skills organized by vertical with clear catalog
- [ ] Per-client profile selects which skills load
- [ ] Plugin loader scans and hot-reloads skills
- [ ] Skill usage tracked for billing and analytics
- [ ] Client can self-service enable/disable skills
- [ ] Memory footprint matches capacity plan estimates
