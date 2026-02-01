# OpenClaw Prebuild Feature

## Executive Summary

A **white-glove configuration system** that enables business owners to fully customize their Clawdbot before deployment - including name, personality, skills, integrations, and business context. Like tailoring a suit or configuring a vehicle to spec, customers design their AI assistant before receiving it, ensuring a perfect plug-and-play experience.

**Business Model**: SetupClaw (https://setupclaw.com/) - pre-configured Mac Mini hardware shipped with ready-to-use Clawdbot instances.

**Target User**: Business owners purchasing AI assistants for commercial use
**Core Value**: Plug in, log in, your personalized AI assistant is already running

---

## Related Documents

- **[SETUPCLAW-SERVICE-MODEL.md](./SETUPCLAW-SERVICE-MODEL.md)** - Full service model and operations
- **Personality Configuration** - `openclaw-vm-setup/prebuild-data/schemas/personality-config.schema.json`
- **Test Drive System** - `openclaw-vm-setup/prebuild-data/schemas/test-drive.schema.json`
- **Onboarding Flow** - `openclaw-vm-setup/prebuild-data/onboarding-flow.md`

---

## What Makes This Different

| Traditional Setup | Prebuild (SetupClaw) |
|-------------------|----------------------|
| Customer figures it out | We configure it for them |
| Generic bot out of the box | Personalized bot from day one |
| Tech knowledge required | Business owner friendly |
| Hours of configuration | Minutes of conversation |
| Hope it works | Test drive before shipping |
| Self-service only | White-glove option available |

---

## Core Configuration Areas

### 1. Bot Identity & Personality
- **Name**: What customers call the bot (Alex, Luna, Max, etc.)
- **Greeting**: First message customers see
- **Communication style**: Professional, friendly, casual, empathetic
- **Tone sliders**: Warmth, formality, enthusiasm, verbosity
- **Emoji usage**: None, minimal, moderate, frequent

### 2. Business Context
- Company name and description
- Industry (for smart defaults)
- Products/services offered
- Brand keywords and voice
- Unique value proposition

### 3. Capabilities
- **Skills**: Ticket triage, sentiment analysis, calendar, CRM sync, etc.
- **Plugins**: Extended functionality
- **Hooks**: Custom automation triggers
- **Integrations**: PostHog, Moltbook, Slack, etc.

### 4. Behavior Rules
- Topics to avoid
- Escalation triggers
- Promise-making permissions
- Operating hours
- After-hours messaging

### 5. Interface Points
- Primary channel (iMessage, SMS, web, WhatsApp)
- Secondary channels
- Multi-channel setup

---

## Feature Overview: Technical Implementation

---

## Feature Overview

### What Is Prebuild?

Prebuild transforms OpenClaw deployment from "follow this guide and figure it out" to "here's what the community recommends right now, pick what fits your needs."

```
┌──────────────────────────────────────────────────────────────────────┐
│                        PREBUILD ONBOARDING                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Step 1: What's your use case?                                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐    │
│  │  Customer   │ │   Sales     │ │  Internal   │ │   Custom    │    │
│  │   Support   │ │ Outreach    │ │   Comms     │ │             │    │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘    │
│                                                                      │
│  Step 2: Choose your skills (live from Skills Hub)                   │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ⭐ Trending This Week                                        │   │
│  │ ├── calendar-integration (↑42% usage)                        │   │
│  │ ├── smart-reply-v2 (NEW - from Discord #skills-showcase)     │   │
│  │ └── crm-sync (recommended for Sales Outreach)                │   │
│  │                                                               │   │
│  │ 📚 Recommended for Customer Support                          │   │
│  │ ├── ticket-triage (95% satisfaction rate)                    │   │
│  │ ├── sentiment-analysis                                       │   │
│  │ └── escalation-rules                                         │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Step 3: Apply best practices (live from Discord)                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ✅ Security Hardening Pack (from #security-tips)             │   │
│  │ ✅ Rate Limiting Config (from pinned in #production)         │   │
│  │ ☐  Multi-channel Setup (from @poweruser's guide)             │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Step 4: Integrations                                                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                    │
│  │ ☑ PostHog   │ │ ☐ Moltbook  │ │ ☐ Slack     │                    │
│  │  Analytics  │ │   Entry     │ │   Alerts    │                    │
│  └─────────────┘ └─────────────┘ └─────────────┘                    │
│                                                                      │
│                     [Generate My Build] →                            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Differentiators

1. **Real-Time Knowledge**: Pulls latest from Discord, Skills Hub, Moltbook
2. **Curated, Not Overwhelming**: Presents "what's working" not "everything possible"
3. **Commercial-Ready**: PostHog analytics, monitoring, security baked in
4. **Changelog-Aware**: Track what best practices have changed since last build
5. **Per-Build Configuration**: Each deployment is purpose-built, not generic

---

## Data Sources

### 1. OpenClaw Discord Server

| Channel | Data Type | Refresh Frequency | Use In Prebuild |
|---------|-----------|-------------------|-----------------|
| `#skills-showcase` | New skill announcements | Real-time | "New This Week" section |
| `#production` | Production tips, configs | Daily | Best practices checklist |
| `#security-tips` | Security configurations | Daily | Security pack |
| `#troubleshooting` | Common issues & fixes | Weekly | Pre-emptive fixes |
| `#success-stories` | Use case examples | Weekly | Use case templates |
| `#announcements` | Breaking changes | Real-time | Changelog alerts |

**Implementation Options**:
- **Discord Bot**: Join server, listen to channels, store in local DB
- **Discord API**: Fetch messages via bot token with appropriate permissions
- **RSS/Webhook**: If Discord server provides feeds
- **Manual Curation**: Admin-maintained JSON file (fallback)

### 2. Skills Hub

| Data Point | Source | Use In Prebuild |
|------------|--------|-----------------|
| Skill catalog | Skills Hub API | Browsable skill list |
| Install counts | Skills Hub API | "Popular" rankings |
| Recent additions | Skills Hub API | "New This Week" |
| Ratings/reviews | Skills Hub API | Quality indicators |
| Compatibility info | Skills Hub API | Filter by use case |

**Implementation Options**:
- **API Integration**: Direct Skills Hub API calls
- **Cache Layer**: Local cache with TTL to avoid rate limits
- **Webhook Subscription**: If Skills Hub supports push updates

### 3. Moltbook

| Data Point | Source | Use In Prebuild |
|------------|--------|-----------------|
| Popular channels | Moltbook API | Channel recommendations |
| Entry requirements | Moltbook API | Onboarding guidance |
| Use case templates | Moltbook community | Pre-built configs |

### 4. Local Knowledge Base (Fallback/Supplement)

For when live sources are unavailable:
```
prebuild-data/
├── skills-cache.json       # Cached Skills Hub data
├── best-practices.json     # Curated best practices
├── use-case-templates/     # Pre-built configurations
│   ├── customer-support.json
│   ├── sales-outreach.json
│   └── internal-comms.json
└── changelog.json          # What changed since last sync
```

---

## Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PREBUILD SYSTEM                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐        │
│  │   Data Sync   │───▶│  Knowledge    │───▶│   Prebuild    │        │
│  │   Service     │    │   Store       │    │   Wizard      │        │
│  └───────────────┘    └───────────────┘    └───────────────┘        │
│         │                    │                    │                  │
│         ▼                    ▼                    ▼                  │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐        │
│  │   Discord     │    │  Changelog    │    │   Config      │        │
│  │   Skills Hub  │    │   Tracker     │    │   Generator   │        │
│  │   Moltbook    │    │               │    │               │        │
│  └───────────────┘    └───────────────┘    └───────────────┘        │
│                                                   │                  │
│                                                   ▼                  │
│                              ┌───────────────────────────────────┐  │
│                              │      prebuild-config.json         │  │
│                              │                                    │  │
│                              │  {                                 │  │
│                              │    "version": "2026-02-01",        │  │
│                              │    "use_case": "customer_support", │  │
│                              │    "skills": [...],                │  │
│                              │    "best_practices": [...],        │  │
│                              │    "integrations": {               │  │
│                              │      "posthog": true,              │  │
│                              │      "moltbook": false             │  │
│                              │    }                               │  │
│                              │  }                                 │  │
│                              └───────────────────────────────────┘  │
│                                                   │                  │
│                                                   ▼                  │
│                              ┌───────────────────────────────────┐  │
│                              │       setup.sh (Phase 0.5)        │  │
│                              │       Applies prebuild config     │  │
│                              └───────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. Data Sync Service (`prebuild-sync.sh`)

```bash
#!/usr/bin/env bash
# Syncs data from external sources to local knowledge store

sync_discord() {
    # Fetch recent messages from key channels
    # Requires: DISCORD_BOT_TOKEN environment variable
}

sync_skills_hub() {
    # Fetch skill catalog and popularity metrics
    # Requires: SKILLS_HUB_API_KEY environment variable
}

sync_moltbook() {
    # Fetch channel recommendations and templates
    # Requires: MOLTBOOK_API_KEY environment variable
}

generate_changelog() {
    # Compare current sync with previous
    # Generate human-readable changelog
}
```

#### 2. Knowledge Store (`prebuild-data/`)

```json
// knowledge.json - Aggregated, structured data
{
  "last_sync": "2026-02-01T10:30:00Z",
  "skills": {
    "trending": [
      {
        "id": "calendar-integration",
        "name": "Calendar Integration",
        "installs_7d": 142,
        "growth": 0.42,
        "source": "skills_hub",
        "recommended_for": ["sales_outreach", "internal_comms"]
      }
    ],
    "new": [...],
    "by_use_case": {
      "customer_support": [...],
      "sales_outreach": [...],
      "internal_comms": [...]
    }
  },
  "best_practices": {
    "security": [
      {
        "id": "rate-limiting",
        "title": "Rate Limiting Configuration",
        "source": "discord:#production",
        "author": "poweruser#1234",
        "date": "2026-01-28",
        "config": {...}
      }
    ],
    "performance": [...],
    "reliability": [...]
  },
  "use_case_templates": {...},
  "changelog": [
    {
      "date": "2026-02-01",
      "type": "new_skill",
      "description": "smart-reply-v2 added to Skills Hub",
      "link": "..."
    }
  ]
}
```

#### 3. Prebuild Wizard (`prebuild-wizard.sh`)

Interactive CLI that:
1. Presents use case options
2. Shows relevant skills (filtered by use case)
3. Recommends best practices
4. Configures integrations
5. Generates `prebuild-config.json`

#### 4. Config Generator

Outputs structured configuration that `setup.sh` can consume:

```json
// prebuild-config.json
{
  "version": "1.0.0",
  "generated_at": "2026-02-01T12:00:00Z",
  "use_case": {
    "type": "customer_support",
    "template": "high_volume"
  },
  "skills": [
    {
      "id": "ticket-triage",
      "version": "2.1.0",
      "config": {
        "priority_levels": 3,
        "auto_assign": true
      }
    },
    {
      "id": "sentiment-analysis",
      "version": "1.5.0",
      "config": {}
    }
  ],
  "best_practices": [
    {
      "id": "rate-limiting",
      "applied": true,
      "config": {
        "requests_per_minute": 60,
        "burst_limit": 100
      }
    },
    {
      "id": "security-hardening",
      "applied": true,
      "config": {
        "ssh_key_type": "ed25519",
        "password_auth": false
      }
    }
  ],
  "integrations": {
    "posthog": {
      "enabled": true,
      "mode": "cloud",
      "api_key_env": "POSTHOG_API_KEY"
    },
    "moltbook": {
      "enabled": false,
      "entry_channels": []
    },
    "monitoring": {
      "enabled": true,
      "alert_channels": ["email"]
    }
  },
  "source_metadata": {
    "knowledge_version": "2026-02-01T10:30:00Z",
    "skills_from": "skills_hub",
    "practices_from": ["discord", "moltbook"]
  }
}
```

---

## Implementation Phases

### Phase P0: Foundation (Week 1)

**Goal**: Create the data structures and local fallback system

- [ ] Create `prebuild-data/` directory structure
- [ ] Design `knowledge.json` schema
- [ ] Design `prebuild-config.json` schema
- [ ] Create initial best practices JSON (manually curated)
- [ ] Create use case templates (3: customer_support, sales_outreach, internal_comms)
- [ ] Create changelog schema and initial entry

**Deliverables**:
- `openclaw-vm-setup/prebuild-data/` directory
- Schema documentation
- 3 manually curated templates

### Phase P1: CLI Wizard (Week 2)

**Goal**: Build the interactive onboarding experience

- [ ] Create `prebuild-wizard.sh` script
- [ ] Implement use case selection UI
- [ ] Implement skill browser (from local cache initially)
- [ ] Implement best practices checklist
- [ ] Implement integration configuration
- [ ] Generate `prebuild-config.json`
- [ ] Add wizard to `setup.sh` as Phase 0.5

**Deliverables**:
- Working wizard that generates config from local data
- Integration with existing setup flow

### Phase P2: PostHog Integration (Week 2-3)

**Goal**: Bake in analytics from the start

- [ ] Implement PostHog setup in wizard
- [ ] Add PostHog install to Phase 4 (Gateway installation)
- [ ] Configure event tracking for:
  - Skill installations
  - Message processing
  - Error rates
  - Performance metrics
- [ ] Create dashboard templates for common use cases

**Deliverables**:
- PostHog auto-configured during setup
- Pre-built dashboards

### Phase P3: Discord Sync (Week 3-4)

**Goal**: Pull live data from OpenClaw Discord

- [ ] Create Discord bot for data collection
- [ ] Implement channel listeners for key channels
- [ ] Build message parser to extract:
  - Skill announcements
  - Best practice recommendations
  - Configuration snippets
- [ ] Store in knowledge base
- [ ] Generate changelog entries

**API Requirements**:
- Discord Bot Token with read access to:
  - `#skills-showcase`
  - `#production`
  - `#security-tips`
  - `#announcements`

**Deliverables**:
- Working Discord sync
- Real-time skill/practice updates in wizard

### Phase P4: Skills Hub Integration (Week 4-5)

**Goal**: Pull live skill catalog and metrics

- [ ] Integrate with Skills Hub API
- [ ] Fetch skill catalog with metadata
- [ ] Track popularity metrics (installs, ratings)
- [ ] Cache with appropriate TTL
- [ ] Display trending/new skills in wizard

**API Requirements**:
- Skills Hub API access
- Rate limit handling

**Deliverables**:
- Live skill browsing in wizard
- Popularity-based recommendations

### Phase P5: Moltbook Integration (Week 5-6)

**Goal**: Enable Moltbook entry during prebuild

- [ ] Integrate Moltbook API
- [ ] Fetch channel recommendations
- [ ] Implement entry flow during setup
- [ ] Configure auto-join for selected channels

**Deliverables**:
- Optional Moltbook integration in wizard
- Guided channel selection

### Phase P6: Changelog System (Week 6)

**Goal**: Track what changed between syncs

- [ ] Implement diff detection between syncs
- [ ] Generate human-readable changelog
- [ ] Show "what's new since your last build" in wizard
- [ ] Email/notification option for changelog updates

**Deliverables**:
- Changelog generation
- "What's new" display in wizard

### Phase P7: Commercial Polish (Week 7-8)

**Goal**: Production-ready for business use

- [ ] Error handling and fallbacks
- [ ] Offline mode (use cached data)
- [ ] Configuration validation
- [ ] Rollback support for prebuild configs
- [ ] Documentation for business users
- [ ] Security audit of sync services

**Deliverables**:
- Production-ready prebuild system
- Business user documentation

---

## Integration with Existing Setup

### Modified setup.sh Flow

```
Current:
  Phase 0: Prerequisites ─────────────────────────────────────┐
  Phase 1: Lume + VM ─────────────────────────────────────────┤
  Phase 2: SSH Hardening ─────────────────────────────────────┤
  Phase 3: Firewall ──────────────────────────────────────────┤
  Phase 4: Gateway ───────────────────────────────────────────┤
  Phase 5: Monitoring ────────────────────────────────────────┤
  Phase 6: Backup ────────────────────────────────────────────┤
  Phase 7: Helper Scripts ────────────────────────────────────┤
  Phase 8: Testing ───────────────────────────────────────────┘

With Prebuild:
  Phase 0:   Prerequisites ───────────────────────────────────┐
  Phase 0.5: PREBUILD WIZARD ◀──── NEW ───────────────────────┤
             │                                                 │
             ├─▶ Sync latest data from sources                 │
             ├─▶ Present use case options                      │
             ├─▶ Select skills, practices, integrations        │
             └─▶ Generate prebuild-config.json                 │
  Phase 1:   Lume + VM ───────────────────────────────────────┤
  Phase 2:   SSH Hardening (+ prebuild security practices) ◀──┤
  Phase 3:   Firewall (+ prebuild network rules) ◀────────────┤
  Phase 4:   Gateway + Skills + PostHog ◀─────────────────────┤
  Phase 5:   Monitoring (+ prebuild alerts) ◀─────────────────┤
  Phase 6:   Backup ──────────────────────────────────────────┤
  Phase 7:   Helper Scripts ──────────────────────────────────┤
  Phase 8:   Testing (+ validate prebuild selections) ◀───────┘
```

### Command-Line Interface

```bash
# Full setup with prebuild wizard
./setup.sh all

# Skip prebuild (use defaults)
./setup.sh all --skip-prebuild

# Use existing prebuild config
./setup.sh all --prebuild-config ./my-config.json

# Just run prebuild wizard (generate config only)
./setup.sh prebuild

# Sync latest data without full setup
./setup.sh sync

# Show changelog since last sync
./setup.sh changelog
```

---

## Data Privacy & Security

### What Data Is Collected

| Data Type | Collected By | Stored Where | Purpose |
|-----------|--------------|--------------|---------|
| Discord messages | Discord bot | Local knowledge store | Best practices extraction |
| Skill metadata | Skills Hub API | Local cache | Skill recommendations |
| User selections | Prebuild wizard | prebuild-config.json | Configure deployment |
| Usage analytics | PostHog | PostHog cloud/self-hosted | Product improvement |

### Security Considerations

1. **Discord Bot Token**: Stored in environment variable, never committed
2. **API Keys**: All keys in `.env`, gitignored
3. **Knowledge Store**: Local only, no PII
4. **Prebuild Config**: May contain business-specific settings - treat as sensitive

### Privacy Modes

```json
// settings.env additions
PREBUILD_SYNC_ENABLED=true          # Enable/disable external sync
PREBUILD_ANALYTICS_ENABLED=true     # Enable PostHog integration
PREBUILD_OFFLINE_MODE=false         # Use only cached data
```

---

## Success Metrics

### User Experience

- **Time to First Deploy**: Target < 30 minutes with prebuild
- **Configuration Errors**: Target < 5% of deployments
- **Skill Adoption**: Target > 60% of users install recommended skills

### System Health

- **Sync Reliability**: Target > 99% successful syncs
- **Data Freshness**: Target < 24 hour lag from source
- **Wizard Completion Rate**: Target > 80%

### Business Impact

- **Support Tickets**: Target 40% reduction in setup-related tickets
- **Repeat Deployments**: Target > 30% of users deploy multiple instances
- **Feature Adoption**: Track PostHog, Moltbook, monitoring adoption rates

---

## Open Questions

1. **Discord Access**: Do we have permission to run a bot in OpenClaw Discord?
2. **Skills Hub API**: Is there a public API, or do we need partnership?
3. **Moltbook Integration**: What's the official integration path?
4. **Data Curation**: Who maintains the best practices list if auto-sync fails?
5. **Commercial Licensing**: Any licensing implications for commercial use?

---

## Appendix: Example Wizard Session

```
┌──────────────────────────────────────────────────────────────────┐
│             OpenClaw Prebuild Wizard v1.0.0                      │
│             Last synced: 2026-02-01 10:30 AM                     │
└──────────────────────────────────────────────────────────────────┘

📋 What's your primary use case?

  1) Customer Support - Handle inbound messages, ticket triage
  2) Sales Outreach - Proactive messaging, lead follow-up
  3) Internal Communications - Team coordination, notifications
  4) Custom - I'll configure everything manually

Enter choice [1-4]: 1

✅ Selected: Customer Support

────────────────────────────────────────────────────────────────────

📦 Recommended Skills for Customer Support

  TRENDING THIS WEEK:
  [x] ticket-triage v2.1.0 (↑42% installs, 95% satisfaction)
  [x] sentiment-analysis v1.5.0 (AI-powered mood detection)
  [ ] escalation-rules v1.2.0 (auto-escalate to human)

  NEW FROM DISCORD #skills-showcase:
  [ ] smart-reply-v2 (just released yesterday!)

  ALSO POPULAR:
  [ ] knowledge-base-search v3.0.0
  [ ] response-templates v2.0.0

Press SPACE to toggle, ENTER to confirm:

✅ Selected 2 skills: ticket-triage, sentiment-analysis

────────────────────────────────────────────────────────────────────

🛡️ Best Practices (from OpenClaw community)

  SECURITY (from #security-tips):
  [x] SSH key-only auth (Ed25519)
  [x] Rate limiting (60 req/min)
  [x] Firewall localhost-only

  RELIABILITY (from #production, pinned):
  [x] Auto-backup daily at 2 AM
  [x] Health monitoring every 5 min
  [ ] Multi-channel failover

  NEW THIS WEEK:
  [ ] Memory optimization pack (from @poweruser)

Press SPACE to toggle, ENTER to confirm:

✅ Applied 5 best practices

────────────────────────────────────────────────────────────────────

🔌 Integrations

  [x] PostHog Analytics (recommended for commercial use)
      └─ Mode: Cloud (free tier, 1M events/month)

  [ ] Moltbook Entry
      └─ Available channels: #support-bots, #ai-agents

  [x] Monitoring Alerts
      └─ Via: Email (configure later)

  [ ] Slack Notifications

Press SPACE to toggle, ENTER to confirm:

✅ Configured 2 integrations

────────────────────────────────────────────────────────────────────

📄 Generating prebuild-config.json...

{
  "version": "1.0.0",
  "use_case": "customer_support",
  "skills": ["ticket-triage", "sentiment-analysis"],
  "best_practices": ["ssh-hardening", "rate-limiting", ...],
  "integrations": {
    "posthog": { "enabled": true, "mode": "cloud" },
    "monitoring": { "enabled": true }
  }
}

✅ Prebuild configuration saved!

────────────────────────────────────────────────────────────────────

📊 What's New Since Your Last Build (2026-01-25):

  • NEW SKILL: smart-reply-v2 added to Skills Hub
  • UPDATED: Rate limiting best practice (60→50 req/min recommended)
  • DEPRECATED: old-triage-skill removed from recommendations

────────────────────────────────────────────────────────────────────

Ready to proceed with deployment?

  1) Start deployment now (runs Phases 1-8)
  2) Save config and exit (deploy later with --prebuild-config)
  3) Modify selections

Enter choice [1-3]: 1

🚀 Starting OpenClaw deployment with your prebuild configuration...
```

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Confirm data source access** (Discord, Skills Hub, Moltbook)
3. **Begin Phase P0** (foundation and schemas)
4. **Create tracking issues** for each phase

---

*Document created: 2026-02-01*
*Author: Claude (Prebuild Feature Planning)*
*Status: DRAFT - Awaiting Review*
