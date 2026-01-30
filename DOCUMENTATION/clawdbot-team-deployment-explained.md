# Clawdbot Team Deployment Guide

> How to deploy a single Clawdbot instance for team-wide access

---

## Overview

A single Clawdbot instance can serve an entire organization. This guide covers architecture patterns, configuration, and considerations for team deployments.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     ONE CLAWDBOT → MANY USERS                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                        ┌───────────────────┐                            │
│                        │   CLAWDBOT        │                            │
│                        │   GATEWAY         │                            │
│                        │                   │                            │
│                        │  • 1 API Key      │                            │
│                        │  • 1 Config       │                            │
│                        │  • 1 Server       │                            │
│                        └─────────┬─────────┘                            │
│                                  │                                      │
│              ┌───────────────────┼───────────────────┐                  │
│              │                   │                   │                  │
│              ▼                   ▼                   ▼                  │
│        ┌──────────┐        ┌──────────┐        ┌──────────┐            │
│        │ Discord  │        │  Slack   │        │ WhatsApp │            │
│        │ (Guild)  │        │(Workspace)│       │ (Group)  │            │
│        └────┬─────┘        └────┬─────┘        └────┬─────┘            │
│             │                   │                   │                  │
│        ┌────┴────┐         ┌────┴────┐         ┌────┴────┐             │
│        │ Team of │         │ Team of │         │ Team of │             │
│        │   10    │         │   10    │         │   10    │             │
│        └─────────┘         └─────────┘         └─────────┘             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Table of Contents

1. [Architecture Patterns](#architecture-patterns)
2. [Channel-Specific Team Setup](#channel-specific-team-setup)
3. [Context & Conversation Behavior](#context--conversation-behavior)
4. [Rate Limiting & Queuing](#rate-limiting--queuing)
5. [Cost Estimation for Teams](#cost-estimation-for-teams)
6. [Security Considerations](#security-considerations)
7. [Configuration Examples](#configuration-examples)

---

## Architecture Patterns

### Pattern A: Shared Channel (Recommended for Collaboration)

```
┌─────────────────────────────────────────────────────────────────┐
│                SHARED CHANNEL PATTERN                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Discord Server / Slack Workspace                               │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                                                          │   │
│   │   #ask-claude (Public Team Channel)                     │   │
│   │   ┌──────────────────────────────────────────────────┐  │   │
│   │   │                                                   │  │   │
│   │   │  @alice: @Clawdbot summarize the Q4 report       │  │   │
│   │   │  🤖 Clawdbot: Here's the summary...              │  │   │
│   │   │                                                   │  │   │
│   │   │  @bob: @Clawdbot what were the key metrics?      │  │   │
│   │   │  🤖 Clawdbot: Based on the report...             │  │   │
│   │   │                                                   │  │   │
│   │   │  (All team members see all conversations)        │  │   │
│   │   │                                                   │  │   │
│   │   └──────────────────────────────────────────────────┘  │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ✅ Benefits:                                                   │
│   • Knowledge sharing - everyone learns from each other         │
│   • Context accumulates - bot remembers channel history         │
│   • Transparent - see what colleagues are asking                │
│   • Single source of truth                                      │
│                                                                  │
│   ⚠️ Considerations:                                             │
│   • No privacy for sensitive questions                          │
│   • Context can get mixed between topics                        │
│   • May need channel-per-project for large teams                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pattern B: Private DMs (For Individual Privacy)

```
┌─────────────────────────────────────────────────────────────────┐
│                  PRIVATE DM PATTERN                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│   │   Alice     │    │    Bob      │    │   Carol     │        │
│   │   (DM)      │    │   (DM)      │    │   (DM)      │        │
│   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘        │
│          │                  │                  │                │
│          │   Private        │   Private        │   Private      │
│          │   Context        │   Context        │   Context      │
│          │                  │                  │                │
│          └──────────────────┼──────────────────┘                │
│                             │                                    │
│                      ┌──────┴──────┐                            │
│                      │  CLAWDBOT   │                            │
│                      │  GATEWAY    │                            │
│                      └─────────────┘                            │
│                                                                  │
│   ✅ Benefits:                                                   │
│   • Each user has private conversation history                  │
│   • Context isolated per user                                   │
│   • Sensitive questions stay private                            │
│   • Personalized responses                                      │
│                                                                  │
│   ⚠️ Considerations:                                             │
│   • No knowledge sharing between team                           │
│   • Each user starts with blank context                         │
│   • Harder to audit/monitor usage                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pattern C: Hybrid (Best of Both Worlds)

```
┌─────────────────────────────────────────────────────────────────┐
│                    HYBRID PATTERN                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Discord Server                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                                                          │   │
│   │   PUBLIC CHANNELS (Shared Context)                      │   │
│   │   ├── #ai-general      → Team questions, visible        │   │
│   │   ├── #ai-engineering  → Engineering-specific           │   │
│   │   └── #ai-marketing    → Marketing-specific             │   │
│   │                                                          │   │
│   │   PRIVATE (Per-User Context)                            │   │
│   │   └── DM with @Clawdbot → Personal/sensitive queries    │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Configuration:                                                 │
│   {                                                              │
│     "discord": {                                                 │
│       "guilds": {                                                │
│         "GUILD_ID": {                                            │
│           "allowedChannels": ["ai-general", "ai-eng", "ai-mkt"],│
│           "allowDMs": true                                       │
│         }                                                        │
│       }                                                          │
│     }                                                            │
│   }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Channel-Specific Team Setup

### Discord (Best for Teams)

```
┌─────────────────────────────────────────────────────────────────┐
│                  DISCORD TEAM SETUP                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   STEP 1: Create Team Discord Server                            │
│   ─────────────────────────────────────                         │
│   • New server dedicated to AI assistant                        │
│   • OR add bot to existing team server                          │
│                                                                  │
│   STEP 2: Create Channel Structure                              │
│   ────────────────────────────────────                          │
│   #ai-assistant (main channel)                                  │
│   #ai-help (overflow/support)                                   │
│   #ai-logs (optional, for monitoring)                           │
│                                                                  │
│   STEP 3: Configure Roles                                       │
│   ───────────────────────────                                   │
│   @AI-User → Can message in AI channels                         │
│   @AI-Admin → Can manage bot settings                           │
│                                                                  │
│   STEP 4: Invite Team Members                                   │
│   ────────────────────────────                                  │
│   Assign @AI-User role to all 10 team members                   │
│                                                                  │
│   STEP 5: Configure clawdbot.json                               │
│   ───────────────────────────────                               │
│                                                                  │
│   {                                                              │
│     "channels": {                                                │
│       "discord": {                                               │
│         "enabled": true,                                         │
│         "guilds": {                                              │
│           "123456789": {                                         │
│             "allowedChannels": [                                 │
│               "ai-assistant",                                    │
│               "ai-help"                                          │
│             ],                                                   │
│             "allowedRoles": ["AI-User", "AI-Admin"],            │
│             "allowDMs": true,                                    │
│             "mentionRequired": true                              │
│           }                                                      │
│         }                                                        │
│       }                                                          │
│     }                                                            │
│   }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Slack (Enterprise Teams)

```
┌─────────────────────────────────────────────────────────────────┐
│                   SLACK TEAM SETUP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   STEP 1: Create Slack App                                      │
│   ────────────────────────                                      │
│   • api.slack.com/apps → Create New App                         │
│   • Add Bot Token Scopes:                                       │
│     - chat:write                                                │
│     - channels:history                                          │
│     - groups:history                                            │
│     - im:history                                                │
│     - users:read                                                │
│                                                                  │
│   STEP 2: Install to Workspace                                  │
│   ────────────────────────────                                  │
│   • OAuth & Permissions → Install to Workspace                  │
│   • Copy Bot User OAuth Token                                   │
│                                                                  │
│   STEP 3: Create Dedicated Channels                             │
│   ─────────────────────────────────                             │
│   #claude-assistant                                              │
│   #claude-engineering                                            │
│   #claude-support                                                │
│                                                                  │
│   STEP 4: Invite Bot to Channels                                │
│   ──────────────────────────────                                │
│   /invite @clawdbot                                              │
│                                                                  │
│   STEP 5: Configure clawdbot.json                               │
│   ───────────────────────────────                               │
│                                                                  │
│   {                                                              │
│     "channels": {                                                │
│       "slack": {                                                 │
│         "enabled": true,                                         │
│         "botToken": "xoxb-...",                                 │
│         "appToken": "xapp-...",                                 │
│         "allowedChannels": [                                     │
│           "C01234567",                                           │
│           "C89012345"                                            │
│         ],                                                       │
│         "allowDMs": true,                                        │
│         "mentionRequired": true                                  │
│       }                                                          │
│     }                                                            │
│   }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### WhatsApp/Telegram (Allowlist Model)

```
┌─────────────────────────────────────────────────────────────────┐
│              WHATSAPP/TELEGRAM TEAM SETUP                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   For WhatsApp & Telegram, use allowlist to control access      │
│                                                                  │
│   WHATSAPP CONFIG                                                │
│   ───────────────                                               │
│   {                                                              │
│     "channels": {                                                │
│       "whatsapp": {                                              │
│         "enabled": true,                                         │
│         "dmPolicy": "allowlist",                                 │
│         "allowFrom": [                                           │
│           "+15551234567",    // Alice                            │
│           "+15552345678",    // Bob                              │
│           "+15553456789",    // Carol                            │
│           "+15554567890",    // Dave                             │
│           "+15555678901",    // Eve                              │
│           "+15556789012",    // Frank                            │
│           "+15557890123",    // Grace                            │
│           "+15558901234",    // Henry                            │
│           "+15559012345",    // Iris                             │
│           "+15550123456"     // Jack                             │
│         ]                                                        │
│       }                                                          │
│     }                                                            │
│   }                                                              │
│                                                                  │
│   TELEGRAM CONFIG                                                │
│   ───────────────                                               │
│   {                                                              │
│     "channels": {                                                │
│       "telegram": {                                              │
│         "enabled": true,                                         │
│         "botToken": "YOUR_BOT_TOKEN",                           │
│         "dmPolicy": "allowlist",                                 │
│         "allowFrom": [                                           │
│           "123456789",    // Alice's Telegram ID                 │
│           "234567890",    // Bob's Telegram ID                   │
│           "345678901"     // Carol's Telegram ID                 │
│         ],                                                       │
│         "allowGroups": [                                         │
│           "-1001234567890"  // Team Group Chat ID                │
│         ]                                                        │
│       }                                                          │
│     }                                                            │
│   }                                                              │
│                                                                  │
│   NOTE: Use Telegram groups for shared context,                 │
│         DMs for private conversations                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Context & Conversation Behavior

### How Context Works with Multiple Users

```
┌─────────────────────────────────────────────────────────────────┐
│                  CONTEXT BEHAVIOR                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   SHARED CHANNELS (Discord/Slack channels, Telegram groups)    │
│   ─────────────────────────────────────────────────────────     │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  #team-ai-channel                                        │   │
│   │                                                          │   │
│   │  Context Window (Last N messages):                       │   │
│   │  ┌────────────────────────────────────────────────────┐ │   │
│   │  │ [Alice] What's our Q4 revenue?                     │ │   │
│   │  │ [Bot]   Q4 revenue was $2.3M...                    │ │   │
│   │  │ [Bob]   Break that down by region                  │ │   │
│   │  │ [Bot]   Here's the regional breakdown...           │ │   │
│   │  │ [Carol] Compare to Q3                              │ │   │
│   │  │ [Bot]   Comparing Q4 to Q3...                      │ │   │
│   │  └────────────────────────────────────────────────────┘ │   │
│   │                                                          │   │
│   │  → Bot sees ALL messages from ALL users                 │   │
│   │  → Can reference previous context from any user         │   │
│   │  → Context is SHARED across team                        │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   PRIVATE DMs (Individual conversations)                        │
│   ──────────────────────────────────────                        │
│                                                                  │
│   ┌──────────────────┐  ┌──────────────────┐                   │
│   │ Alice's DM       │  │ Bob's DM         │                   │
│   │ ┌──────────────┐ │  │ ┌──────────────┐ │                   │
│   │ │ [Alice] Hi   │ │  │ │ [Bob] Hello  │ │                   │
│   │ │ [Bot] Hi!    │ │  │ │ [Bot] Hi!    │ │                   │
│   │ │ ...          │ │  │ │ ...          │ │                   │
│   │ └──────────────┘ │  │ └──────────────┘ │                   │
│   │                  │  │                  │                   │
│   │ ISOLATED context │  │ ISOLATED context │                   │
│   └──────────────────┘  └──────────────────┘                   │
│                                                                  │
│   → Each DM has SEPARATE context                                │
│   → Bob cannot see Alice's conversation                         │
│   → Context starts fresh for each user                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Context Window Limits

```
┌─────────────────────────────────────────────────────────────────┐
│                CONTEXT WINDOW MANAGEMENT                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Claude Model Context Windows:                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Claude 3.5 Sonnet  │  200K tokens  │  ~150K words      │   │
│   │  Claude 3 Opus      │  200K tokens  │  ~150K words      │   │
│   │  Claude 3 Haiku     │  200K tokens  │  ~150K words      │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   For a team of 10 in a shared channel:                         │
│   ─────────────────────────────────────                         │
│   • Average message: ~100 tokens                                │
│   • Bot response: ~500 tokens                                   │
│   • Per exchange: ~600 tokens                                   │
│   • Context can hold: ~300 exchanges before rolling off         │
│                                                                  │
│   RECOMMENDATION:                                                │
│   ───────────────                                               │
│   • For busy teams, create topic-specific channels              │
│   • #ai-engineering, #ai-sales, #ai-support                     │
│   • Keeps context focused and relevant                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Rate Limiting & Queuing

### How Concurrent Requests Are Handled

```
┌─────────────────────────────────────────────────────────────────┐
│                  MESSAGE QUEUE BEHAVIOR                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   When multiple team members message simultaneously:            │
│                                                                  │
│   T=0s    Alice: "Summarize the report"                         │
│   T=1s    Bob: "What's the weather?"                            │
│   T=2s    Carol: "Write an email draft"                         │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                    MESSAGE QUEUE                         │   │
│   │                                                          │   │
│   │   ┌─────────┐   ┌─────────┐   ┌─────────┐               │   │
│   │   │ Alice   │──▶│ Bob     │──▶│ Carol   │               │   │
│   │   │ (proc)  │   │ (wait)  │   │ (wait)  │               │   │
│   │   └─────────┘   └─────────┘   └─────────┘               │   │
│   │       │                                                  │   │
│   │       ▼                                                  │   │
│   │   ┌─────────────────┐                                    │   │
│   │   │  Claude API     │                                    │   │
│   │   │  (Processing)   │                                    │   │
│   │   └─────────────────┘                                    │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Processing Order: First-In-First-Out (FIFO)                   │
│   Typical Response Time: 2-10 seconds per request               │
│                                                                  │
│   For a team of 10:                                              │
│   • Light usage: No noticeable delay                            │
│   • Heavy usage: 10-30 second waits possible                    │
│   • Solution: Multiple channels or rate limit guidance          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Anthropic API Rate Limits

```
┌─────────────────────────────────────────────────────────────────┐
│                 API RATE LIMITS (Anthropic)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Tier 1 (Default):                                              │
│   • 50 requests/minute                                           │
│   • 40,000 tokens/minute                                        │
│   • 1,000,000 tokens/day                                        │
│                                                                  │
│   For a team of 10:                                              │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  50 req/min ÷ 10 users = 5 requests/user/minute         │   │
│   │  That's 1 message every 12 seconds per person           │   │
│   │  Usually sufficient for normal usage                     │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   If you need more capacity:                                     │
│   • Request Tier 2: 100 req/min, 80K tokens/min                 │
│   • Request Tier 3: 200 req/min, 160K tokens/min                │
│   • Contact Anthropic for enterprise limits                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cost Estimation for Teams

```
┌─────────────────────────────────────────────────────────────────┐
│                 TEAM COST ESTIMATION                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Claude 3.5 Sonnet Pricing:                                    │
│   • Input:  $3.00 / 1M tokens                                   │
│   • Output: $15.00 / 1M tokens                                  │
│                                                                  │
│   Average Conversation:                                          │
│   • Input: ~500 tokens (user message + context)                 │
│   • Output: ~300 tokens (bot response)                          │
│   • Cost per exchange: ~$0.006                                  │
│                                                                  │
│   TEAM USAGE SCENARIOS                                           │
│   ────────────────────                                          │
│                                                                  │
│   Light Usage (10 users, 10 msg/day each):                      │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  100 messages/day × 30 days = 3,000 messages/month      │   │
│   │  3,000 × $0.006 = ~$18/month                            │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Medium Usage (10 users, 30 msg/day each):                     │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  300 messages/day × 30 days = 9,000 messages/month      │   │
│   │  9,000 × $0.006 = ~$54/month                            │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Heavy Usage (10 users, 50 msg/day each):                      │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  500 messages/day × 30 days = 15,000 messages/month     │   │
│   │  15,000 × $0.006 = ~$90/month                           │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Power Usage (10 users, 100 msg/day each, long context):       │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  1,000 messages/day × 30 days = 30,000 messages/month   │   │
│   │  30,000 × $0.015 (longer context) = ~$450/month         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   TOTAL MONTHLY COST (Infrastructure + API)                     │
│   ─────────────────────────────────────────                     │
│   │ Usage   │ API Cost │ Hosting │ Total    │                  │
│   ├─────────┼──────────┼─────────┼──────────┤                  │
│   │ Light   │ $18      │ $10     │ $28/mo   │                  │
│   │ Medium  │ $54      │ $10     │ $64/mo   │                  │
│   │ Heavy   │ $90      │ $15     │ $105/mo  │                  │
│   │ Power   │ $450     │ $15     │ $465/mo  │                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Considerations

### Access Control Matrix

```
┌─────────────────────────────────────────────────────────────────┐
│                 TEAM SECURITY MODEL                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   AUTHENTICATION LAYERS                                          │
│   ─────────────────────                                         │
│                                                                  │
│   Layer 1: Platform Auth                                         │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Discord: Must be in server + have role                  │   │
│   │  Slack: Must be in workspace + invited to channel        │   │
│   │  WhatsApp: Must be on allowlist                          │   │
│   │  Telegram: Must be on allowlist or in allowed group      │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Layer 2: Channel Restrictions                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  • Bot only responds in configured channels             │   │
│   │  • Can require @mention to respond                       │   │
│   │  • Can restrict to specific roles                        │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Layer 3: Gateway Auth                                          │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  • Gateway token required for Control UI access          │   │
│   │  • Tailscale/SSH for remote administration               │   │
│   │  • Operator-only access to server                        │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   DATA VISIBILITY                                                │
│   ───────────────                                               │
│   │ Data Type        │ Who Can See                │            │
│   ├──────────────────┼────────────────────────────┤            │
│   │ Channel messages │ All channel members        │            │
│   │ DM conversations │ Only the DM participant    │            │
│   │ API usage/costs  │ Owner/Operators only       │            │
│   │ Server logs      │ Operators only             │            │
│   │ Config file      │ Operators only             │            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Audit & Compliance

```
┌─────────────────────────────────────────────────────────────────┐
│                 AUDIT CAPABILITIES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Built-in Logging:                                              │
│   • All messages logged to ~/.clawdbot/logs/                    │
│   • Includes: timestamp, user, channel, message content         │
│   • Rotation: daily files, configurable retention               │
│                                                                  │
│   Log Format Example:                                            │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ 2026-01-27T10:15:32Z | discord | #ai-channel |          │   │
│   │ user:alice#1234 | "Summarize the Q4 report"             │   │
│   │                                                          │   │
│   │ 2026-01-27T10:15:35Z | discord | #ai-channel |          │   │
│   │ bot:clawdbot | "Here's the Q4 summary..."               │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   For compliance needs:                                          │
│   • Export logs to SIEM (Splunk, Datadog, etc.)                 │
│   • Enable message retention policies                            │
│   • Configure PII redaction if required                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuration Examples

### Full Team Configuration (Discord + Slack + WhatsApp)

```json
{
  "gateway": {
    "bind": "lan",
    "port": 18789,
    "token": "your-secure-gateway-token"
  },
  
  "channels": {
    "discord": {
      "enabled": true,
      "botToken": "your-discord-bot-token",
      "guilds": {
        "123456789012345678": {
          "name": "Company Team Server",
          "allowedChannels": [
            "ai-assistant",
            "ai-engineering", 
            "ai-sales",
            "ai-support"
          ],
          "allowedRoles": ["Team Member", "AI User"],
          "allowDMs": true,
          "mentionRequired": true
        }
      }
    },
    
    "slack": {
      "enabled": true,
      "botToken": "xoxb-your-slack-bot-token",
      "appToken": "xapp-your-slack-app-token",
      "allowedChannels": [
        "C01234ABCDE",
        "C56789FGHIJ"
      ],
      "allowDMs": true,
      "mentionRequired": false
    },
    
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [
        "+15551234567",
        "+15552345678",
        "+15553456789",
        "+15554567890",
        "+15555678901",
        "+15556789012",
        "+15557890123",
        "+15558901234",
        "+15559012345",
        "+15550123456"
      ]
    },
    
    "telegram": {
      "enabled": true,
      "botToken": "your-telegram-bot-token",
      "dmPolicy": "allowlist",
      "allowFrom": ["123456789", "234567890"],
      "allowGroups": ["-1001234567890"]
    }
  },
  
  "models": {
    "default": "anthropic:claude-sonnet-4-20250514"
  },
  
  "logging": {
    "level": "info",
    "retention": "30d",
    "includeUserMessages": true
  }
}
```

---

## Quick Reference

### Team Deployment Checklist

```
□ Choose architecture pattern (Shared/Private/Hybrid)
□ Select primary channel (Discord recommended for teams)
□ Create dedicated channels/groups
□ Configure access controls (roles, allowlists)
□ Set up gateway with secure token
□ Add all team members to allowlist/roles
□ Test with 2-3 users before full rollout
□ Document usage guidelines for team
□ Set up cost monitoring/alerts
□ Configure logging for audit needs
```

### Commands for Team Management

```bash
# Add user to WhatsApp allowlist
clawdbot config set channels.whatsapp.allowFrom[+] "+15551234567"

# List current Discord guilds
clawdbot channels list discord

# View team usage statistics
clawdbot stats --period 7d

# Export logs for audit
clawdbot logs export --start 2026-01-01 --end 2026-01-31 --output audit.json

# Check rate limit status
clawdbot api status
```

---

*Last Updated: January 2026*
*Part of: [claudebotready](https://github.com/Organized-AI/claudebotready) documentation*
