# 🦔 PostHog Integration Plan for Clawdbot

> Analytics, Feature Flags, and Product Insights for Clawdbot Gateway

---

## Overview

This document outlines the integration strategy for adding PostHog analytics to Clawdbot, enabling product insights, feature flagging, and usage tracking across all deployment platforms.

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CLAWDBOT + POSTHOG INTEGRATION                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                        CLAWDBOT GATEWAY                               │ │
│  │                                                                       │ │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │ │
│  │   │   Agent     │  │   Session   │  │   Channel   │                  │ │
│  │   │   Events    │  │   Tracking  │  │   Events    │                  │ │
│  │   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │ │
│  │          │                │                │                         │ │
│  │          └────────────────┼────────────────┘                         │ │
│  │                           │                                          │ │
│  │                    ┌──────┴──────┐                                   │ │
│  │                    │  PostHog    │                                   │ │
│  │                    │  Node SDK   │                                   │ │
│  │                    └──────┬──────┘                                   │ │
│  │                           │                                          │ │
│  └───────────────────────────┼───────────────────────────────────────────┘ │
│                              │                                              │
│              ┌───────────────┴───────────────┐                              │
│              ▼                               ▼                              │
│   ┌────────────────────┐         ┌────────────────────┐                    │
│   │  POSTHOG CLOUD     │   OR    │  POSTHOG SELF-HOST │                    │
│   │  (Recommended)     │         │  (For Compliance)  │                    │
│   │                    │         │                    │                    │
│   │  Free Tier:        │         │  Requirements:     │                    │
│   │  • 1M events/mo    │         │  • 4 vCPU          │                    │
│   │  • 5K recordings   │         │  • 16GB RAM        │                    │
│   │  • 1M flags        │         │  • 30GB+ storage   │                    │
│   │  • US or EU host   │         │  • ~100k events/mo │                    │
│   └────────────────────┘         └────────────────────┘                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Integration Points

| Component | Events to Track | Business Value |
|-----------|-----------------|----------------|
| **CLI Onboarding** | `onboarding_started`, `platform_selected`, `skills_selected`, `onboarding_completed` | Conversion funnel optimization |
| **Gateway** | `gateway_started`, `gateway_health_check`, `channel_connected`, `channel_disconnected` | Reliability monitoring |
| **Channel Usage** | `message_received`, `message_processed`, `tool_invoked`, `error_occurred` | Usage patterns, error detection |
| **Skills** | `skill_installed`, `skill_used`, `skill_error` | Feature adoption, skill marketplace insights |
| **Feature Flags** | A/B test new features, gradual rollouts | Safe deployments |

---

## Phased Implementation

### Phase 0: Project Setup & SDK Integration

**Objective:** Add posthog-node SDK to Clawdbot, create analytics wrapper

**Files to Create/Modify:**
```
clawdbot/
├── src/
│   ├── lib/
│   │   └── analytics/
│   │       ├── posthog.ts       # PostHog client wrapper
│   │       ├── events.ts        # Event type definitions
│   │       └── index.ts         # Export analytics module
│   ├── commands/
│   │   └── onboard.ts           # Add tracking calls
│   └── gateway/
│       └── index.ts             # Add gateway events
├── .cursor/
│   └── rules/
│       └── posthog-context.md   # Agent context rules
└── package.json                 # Add posthog-node dependency
```

---

### Phase 1: Core Analytics Layer

**Events to Implement:**

```typescript
// Event taxonomy
const CLAWDBOT_EVENTS = {
  // Onboarding funnel
  ONBOARDING_STARTED: 'onboarding_started',
  PLATFORM_SELECTED: 'platform_selected',
  SKILLS_SELECTED: 'skills_selected',
  ONBOARDING_COMPLETED: 'onboarding_completed',
  
  // Gateway lifecycle
  GATEWAY_STARTED: 'gateway_started',
  GATEWAY_STOPPED: 'gateway_stopped',
  GATEWAY_ERROR: 'gateway_error',
  
  // Channel events
  CHANNEL_CONNECTED: 'channel_connected',
  CHANNEL_DISCONNECTED: 'channel_disconnected',
  MESSAGE_RECEIVED: 'message_received',
  MESSAGE_PROCESSED: 'message_processed',
  
  // Skills
  SKILL_INSTALLED: 'skill_installed',
  SKILL_INVOKED: 'skill_invoked',
  SKILL_ERROR: 'skill_error',
};
```

---

### Phase 2: Feature Flags for Skills Marketplace

**Feature Flag Use Cases:**

1. **Gradual skill rollout** - Test new skills with subset of users
2. **A/B test onboarding flows** - Optimize conversion
3. **Premium feature gating** - Enable paid features
4. **Beta program** - Early access for engaged users

---

### Phase 3: Self-Hosted Option (Enterprise)

For customers requiring data sovereignty, see `POSTHOG-CLOUD-VS-SELFHOST.md`

---

## Analytics Module Implementation

### Environment Variables

```bash
# Required
POSTHOG_API_KEY=phc_...

# Optional
POSTHOG_HOST=https://app.posthog.com  # or self-hosted URL
POSTHOG_ENABLED=true                   # killswitch
```

### Analytics Wrapper

```typescript
// src/lib/analytics/posthog.ts
import { PostHog } from 'posthog-node';

class ClawdbotAnalytics {
  private posthog: PostHog | null = null;
  private enabled: boolean;
  
  constructor() {
    this.enabled = process.env.POSTHOG_ENABLED !== 'false';
    if (this.enabled && process.env.POSTHOG_API_KEY) {
      this.posthog = new PostHog(process.env.POSTHOG_API_KEY, {
        host: process.env.POSTHOG_HOST || 'https://app.posthog.com',
        flushAt: 20,
        flushInterval: 10000
      });
    }
  }
  
  track(event: string, properties: Record<string, any>, distinctId: string) {
    if (!this.enabled || !this.posthog) return;
    this.posthog.capture({
      distinctId,
      event,
      properties: {
        ...properties,
        timestamp: new Date().toISOString(),
        source: 'clawdbot-gateway'
      }
    });
  }
  
  identify(distinctId: string, properties: Record<string, any>) {
    if (!this.enabled || !this.posthog) return;
    this.posthog.identify({
      distinctId,
      properties
    });
  }
  
  async isFeatureEnabled(flag: string, distinctId: string): Promise<boolean> {
    if (!this.enabled || !this.posthog) return false;
    return await this.posthog.isFeatureEnabled(flag, distinctId) ?? false;
  }
  
  async shutdown() {
    if (this.posthog) await this.posthog.shutdown();
  }
}

export const analytics = new ClawdbotAnalytics();
```

### Event Type Definitions

```typescript
// src/lib/analytics/events.ts
export const EVENTS = {
  // Onboarding
  ONBOARDING_STARTED: 'onboarding_started',
  PLATFORM_SELECTED: 'platform_selected',
  SKILLS_SELECTED: 'skills_selected',
  ONBOARDING_COMPLETED: 'onboarding_completed',
  
  // Gateway
  GATEWAY_STARTED: 'gateway_started',
  GATEWAY_STOPPED: 'gateway_stopped',
  GATEWAY_ERROR: 'gateway_error',
  GATEWAY_HEALTH_CHECK: 'gateway_health_check',
  
  // Channels
  CHANNEL_CONNECTED: 'channel_connected',
  CHANNEL_DISCONNECTED: 'channel_disconnected',
  MESSAGE_RECEIVED: 'message_received',
  MESSAGE_PROCESSED: 'message_processed',
  
  // Skills
  SKILL_INSTALLED: 'skill_installed',
  SKILL_INVOKED: 'skill_invoked',
  SKILL_ERROR: 'skill_error'
} as const;

export type ClawdbotEvent = typeof EVENTS[keyof typeof EVENTS];
```

---

## Usage Examples

### Track Onboarding

```typescript
import { analytics } from '../lib/analytics';
import { EVENTS } from '../lib/analytics/events';

// In onboard command
analytics.track(EVENTS.ONBOARDING_STARTED, {
  platform: 'macos',
  version: '1.0.0'
}, installationId);

// After platform selection
analytics.track(EVENTS.PLATFORM_SELECTED, {
  platform: selectedPlatform,
  deploymentType: 'local' // or 'docker', 'fly', etc.
}, installationId);
```

### Track Gateway Events

```typescript
// In gateway startup
analytics.track(EVENTS.GATEWAY_STARTED, {
  port: config.port,
  bind: config.bind,
  channels: Object.keys(config.channels)
}, gatewayId);

// On channel connect
analytics.track(EVENTS.CHANNEL_CONNECTED, {
  channel: 'whatsapp',
  method: 'qr_scan'
}, gatewayId);
```

### Feature Flags

```typescript
// Check if beta feature is enabled
const showNewUI = await analytics.isFeatureEnabled('new-control-ui', userId);
if (showNewUI) {
  // Render new UI
}
```

---

## Claude Code Prompt

```bash
claude --dangerously-skip-permissions
```

**Paste:**

```markdown
# PostHog Analytics Integration for Clawdbot

## Context
Integrate PostHog analytics into Clawdbot Gateway for product insights and feature flagging.

## Tasks
1. [ ] `npm install posthog-node`
2. [ ] Create `src/lib/analytics/posthog.ts` with wrapper class
3. [ ] Create `src/lib/analytics/events.ts` with event constants
4. [ ] Create `src/lib/analytics/index.ts` barrel export
5. [ ] Add POSTHOG_* env vars to `.env.example`
6. [ ] Update onboarding command to track funnel
7. [ ] Update gateway to track lifecycle events
8. [ ] Add graceful shutdown hook for event flush
9. [ ] Create `.cursor/rules/posthog-context.md` for ongoing AI context

## Deliverables
- Analytics module with PostHog SDK integration
- Event taxonomy for Clawdbot-specific tracking
- Environment configuration
- Agent rules for future development context
```

---

## Environment Variables for Claude Code Web

```bash
ANTHROPIC_API_KEY=sk-ant-...
POSTHOG_API_KEY=phc_...
POSTHOG_HOST=https://app.posthog.com
POSTHOG_ENABLED=true
```

---

## Resources

- [PostHog Node SDK](https://posthog.com/docs/libraries/node)
- [PostHog Feature Flags](https://posthog.com/docs/feature-flags)
- [PostHog Self-Hosting](https://posthog.com/docs/self-host)
- [Event Naming Best Practices](https://posthog.com/docs/getting-started/send-events#best-practices)

---

*Last Updated: January 2026*
*Project: Clawdbot Ready - clawdbot.organizedai.vip*
