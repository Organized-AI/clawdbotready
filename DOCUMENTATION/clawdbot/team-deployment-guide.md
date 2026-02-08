# Clawdbot Team Deployment Guide

> How to deploy and configure a single Clawdbot instance for teams of 2-10+ people

---

## Table of Contents

1. [Architecture Options](#architecture-options)
2. [Multi-User Configuration](#multi-user-configuration)
3. [Context & Conversation Management](#context--conversation-management)
4. [Rate Limiting & Queueing](#rate-limiting--queueing)
5. [User Identification](#user-identification)
6. [Audit Logging](#audit-logging)
7. [Cost Estimation](#cost-estimation)
8. [Platform-Specific Team Setup](#platform-specific-team-setup)

---

## Architecture Options

### Option A: Shared Channel (Recommended for Teams)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SHARED CHANNEL ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                         ┌───────────────────┐                           │
│                         │   CLAWDBOT        │                           │
│                         │   GATEWAY         │                           │
│                         │                   │                           │
│                         │  Single Instance  │                           │
│                         │  Single API Key   │                           │
│                         └─────────┬─────────┘                           │
│                                   │                                     │
│                    ┌──────────────┴──────────────┐                      │
│                    │                             │                      │
│                    ▼                             ▼                      │
│         ┌─────────────────────┐      ┌─────────────────────┐           │
│         │   DISCORD SERVER    │      │   SLACK WORKSPACE   │           │
│         │                     │      │                     │           │
│         │  #ask-claude        │      │  #claude-assistant  │           │
│         │  #team-projects     │      │  #engineering       │           │
│         │  #general (bot off) │      │  DMs to bot         │           │
│         │                     │      │                     │           │
│         │  👤 User A          │      │  👤 User A          │           │
│         │  👤 User B          │      │  👤 User B          │           │
│         │  👤 User C          │      │  👤 User C          │           │
│         │  ... (10 users)     │      │  ... (10 users)     │           │
│         └─────────────────────┘      └─────────────────────┘           │
│                                                                         │
│  ✅ Shared context - team sees each other's questions                  │
│  ✅ Single billing - one API account                                   │
│  ✅ Easy management - Discord/Slack roles control access               │
│  ⚠️  No privacy - conversations visible to team                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Best for:** Collaborative teams, shared knowledge bases, transparent workflows

---

### Option B: Per-User DMs (Private Conversations)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PER-USER DM ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                         ┌───────────────────┐                           │
│                         │   CLAWDBOT        │                           │
│                         │   GATEWAY         │                           │
│                         │                   │                           │
│                         │  Single Instance  │                           │
│                         │  Single API Key   │                           │
│                         └─────────┬─────────┘                           │
│                                   │                                     │
│      ┌────────────┬───────────────┼───────────────┬────────────┐       │
│      │            │               │               │            │       │
│      ▼            ▼               ▼               ▼            ▼       │
│   ┌──────┐    ┌──────┐       ┌──────┐       ┌──────┐    ┌──────┐      │
│   │ DM   │    │ DM   │       │ DM   │       │ DM   │    │ DM   │      │
│   │User A│    │User B│       │User C│       │User D│    │User E│      │
│   └──────┘    └──────┘       └──────┘       └──────┘    └──────┘      │
│                                                                         │
│   WhatsApp     Telegram       Discord        Slack       iMessage      │
│   Allowlist    Allowlist      DM Policy      DM App      Allowlist     │
│                                                                         │
│  ✅ Private - each user has separate conversation                      │
│  ✅ Per-user context - bot remembers individual preferences            │
│  ✅ Multi-platform - users choose their preferred app                  │
│  ⚠️  No shared knowledge - team can't see each other's queries         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Best for:** Executive assistants, personal productivity, sensitive queries

---

### Option C: Hybrid (Channels + DMs)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    HYBRID ARCHITECTURE                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                         ┌───────────────────┐                           │
│                         │   CLAWDBOT        │                           │
│                         │   GATEWAY         │                           │
│                         └─────────┬─────────┘                           │
│                                   │                                     │
│              ┌────────────────────┼────────────────────┐                │
│              │                    │                    │                │
│              ▼                    ▼                    ▼                │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│   │ SHARED CHANNELS │  │  PRIVATE DMs    │  │ PERSONAL APPS   │        │
│   │                 │  │                 │  │                 │        │
│   │ Discord:        │  │ Discord DMs     │  │ WhatsApp DMs    │        │
│   │  #team-claude   │  │ Slack DMs       │  │ Telegram DMs    │        │
│   │ Slack:          │  │                 │  │ iMessage        │        │
│   │  #ask-ai        │  │                 │  │                 │        │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘        │
│                                                                         │
│   Team questions       Sensitive queries   Personal/mobile use         │
│   Shared learning      Private work        On-the-go access            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Best for:** Most teams - combines collaboration with privacy options

---

## Multi-User Configuration

### Discord Team Configuration

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "guilds": {
        "GUILD_ID_HERE": {
          "name": "Acme Corp Team",
          
          "channelPolicy": "allowlist",
          "allowedChannels": [
            "ask-claude",
            "engineering-help",
            "marketing-ai"
          ],
          
          "dmPolicy": "allowlist",
          "allowedRoles": [
            "team-member",
            "admin",
            "contractor"
          ],
          
          "mentionRequired": true,
          "replyInThread": true
        }
      }
    }
  }
}
```

**Configuration Options Explained:**

| Option | Values | Description |
|--------|--------|-------------|
| `channelPolicy` | `allowlist`, `denylist`, `all` | Which channels bot responds in |
| `allowedChannels` | Array of channel names | Channels where bot is active |
| `dmPolicy` | `allowlist`, `none`, `all` | Who can DM the bot |
| `allowedRoles` | Array of role names | Discord roles that can interact |
| `mentionRequired` | `true`, `false` | Must @mention bot to trigger |
| `replyInThread` | `true`, `false` | Keeps responses in threads |

---

### Slack Team Configuration

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "workspace": {
        "name": "Acme Corp",
        
        "channelPolicy": "allowlist",
        "allowedChannels": [
          "claude-assistant",
          "engineering",
          "product-team"
        ],
        
        "dmPolicy": "all",
        
        "appMention": true,
        "directMessage": true
      }
    }
  }
}
```

---

### WhatsApp Team Allowlist

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [
        "+15551234567",
        "+15559876543",
        "+15555551212",
        "+15558675309",
        "+15551112222",
        "+15553334444",
        "+15555556666",
        "+15557778888",
        "+15559990000",
        "+15550001111"
      ],
      "groupPolicy": "none"
    }
  }
}
```

---

### Telegram Team Configuration

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN",
      
      "dmPolicy": "allowlist",
      "allowedUserIds": [
        123456789,
        987654321,
        111222333
      ],
      
      "groupPolicy": "allowlist",
      "allowedGroupIds": [
        -1001234567890
      ]
    }
  }
}
```

---

## Context & Conversation Management

### How Context Works in Team Deployments

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CONTEXT ISOLATION MODEL                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   SHARED CHANNEL (e.g., Discord #ask-claude)                           │
│   ┌─────────────────────────────────────────────────────────────┐      │
│   │                                                             │      │
│   │   Thread 1 (User A)    Thread 2 (User B)    Thread 3 (User C)     │
│   │   ┌─────────────┐      ┌─────────────┐      ┌─────────────┐│      │
│   │   │ Context: A  │      │ Context: B  │      │ Context: C  ││      │
│   │   │ Q: "Help    │      │ Q: "Write   │      │ Q: "Debug   ││      │
│   │   │  with X"    │      │  email"     │      │  code"      ││      │
│   │   │ A: "..."    │      │ A: "..."    │      │ A: "..."    ││      │
│   │   │ Q: "More"   │      │             │      │             ││      │
│   │   │ A: "..."    │      │             │      │             ││      │
│   │   └─────────────┘      └─────────────┘      └─────────────┘│      │
│   │                                                             │      │
│   │   ✅ Threads = Isolated context per conversation           │      │
│   │   ✅ Each thread maintains its own history                 │      │
│   │   ⚠️  Non-threaded messages = shared/no context            │      │
│   │                                                             │      │
│   └─────────────────────────────────────────────────────────────┘      │
│                                                                         │
│   PRIVATE DM (e.g., WhatsApp to User A)                                │
│   ┌─────────────────────────────────────────────────────────────┐      │
│   │                                                             │      │
│   │   User A's DM Session                                       │      │
│   │   ┌─────────────────────────────────────────────────────┐  │      │
│   │   │ Context: Persistent per-user                        │  │      │
│   │   │                                                     │  │      │
│   │   │ Day 1: "Remember I prefer Python"                   │  │      │
│   │   │ Day 2: "Write that script we discussed"             │  │      │
│   │   │        → Bot remembers Python preference            │  │      │
│   │   │                                                     │  │      │
│   │   └─────────────────────────────────────────────────────┘  │      │
│   │                                                             │      │
│   │   ✅ Per-user context persists across sessions             │      │
│   │   ✅ Private - other team members can't see                │      │
│   │                                                             │      │
│   └─────────────────────────────────────────────────────────────┘      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Context Configuration

```json
{
  "context": {
    "maxHistoryMessages": 50,
    "maxHistoryTokens": 8000,
    
    "threadIsolation": true,
    "dmIsolation": true,
    
    "persistAcrossSessions": true,
    "sessionTimeout": "24h",
    
    "sharedKnowledge": {
      "enabled": false,
      "knowledgeBase": "team-docs"
    }
  }
}
```

---

## Rate Limiting & Queueing

### How Concurrent Requests are Handled

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    REQUEST QUEUEING                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Incoming Messages (same moment)                                       │
│                                                                         │
│   User A ─────┐                                                         │
│               │                                                         │
│   User B ─────┼───▶ ┌─────────────────┐     ┌─────────────────┐        │
│               │     │  MESSAGE QUEUE  │────▶│  CLAWDBOT       │        │
│   User C ─────┤     │                 │     │  GATEWAY        │        │
│               │     │  [A] [B] [C]    │     │                 │        │
│   User D ─────┘     │  FIFO Order     │     │  Process 1-by-1 │        │
│                     └─────────────────┘     └─────────────────┘        │
│                                                                         │
│   Processing Order:                                                     │
│   ┌────────────────────────────────────────────────────────────┐       │
│   │ t=0s   User A message received → Processing                │       │
│   │ t=0s   User B message received → Queued (position 1)       │       │
│   │ t=0s   User C message received → Queued (position 2)       │       │
│   │ t=3s   User A response sent   → User B Processing          │       │
│   │ t=6s   User B response sent   → User C Processing          │       │
│   │ t=9s   User C response sent   → Queue empty                │       │
│   └────────────────────────────────────────────────────────────┘       │
│                                                                         │
│   ⚠️  During high load, users may wait 5-30 seconds                    │
│   ✅ "Typing" indicator shown while processing                         │
│   ✅ Messages never dropped, always queued                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Rate Limit Configuration

```json
{
  "rateLimits": {
    "perUser": {
      "messagesPerMinute": 10,
      "messagesPerHour": 60,
      "tokensPerDay": 100000
    },
    
    "global": {
      "concurrentRequests": 3,
      "requestsPerMinute": 30,
      "tokensPerMinute": 50000
    },
    
    "queueSettings": {
      "maxQueueSize": 50,
      "queueTimeout": "5m",
      "priorityUsers": ["admin-user-id"]
    }
  }
}
```

---

## User Identification

### How Clawdbot Identifies Team Members

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    USER IDENTIFICATION                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Platform          Identifier              Display Name                │
│   ─────────────────────────────────────────────────────────────────    │
│   Discord           User ID (snowflake)     Username#0000               │
│   Slack             User ID (U0XXXXXXX)     Display Name                │
│   WhatsApp          Phone Number            Contact Name                │
│   Telegram          User ID (numeric)       Username                    │
│   iMessage          Phone/Email             Contact Name                │
│                                                                         │
│   Example Log Entry:                                                    │
│   ┌─────────────────────────────────────────────────────────────┐      │
│   │ {                                                           │      │
│   │   "timestamp": "2026-01-27T10:30:00Z",                     │      │
│   │   "platform": "discord",                                    │      │
│   │   "userId": "123456789012345678",                          │      │
│   │   "username": "alice#1234",                                 │      │
│   │   "channel": "ask-claude",                                  │      │
│   │   "messageType": "question",                                │      │
│   │   "tokensUsed": 1500                                        │      │
│   │ }                                                           │      │
│   └─────────────────────────────────────────────────────────────┘      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### User Aliases Configuration

Map platform IDs to team member names for clearer logs:

```json
{
  "users": {
    "aliases": {
      "discord:123456789012345678": "Alice (Engineering)",
      "discord:987654321098765432": "Bob (Marketing)",
      "slack:U0ABCDEFG": "Carol (Product)",
      "whatsapp:+15551234567": "Dave (CEO)",
      "telegram:111222333": "Eve (Design)"
    },
    
    "teams": {
      "engineering": ["discord:123...", "slack:U0ABC..."],
      "leadership": ["whatsapp:+1555...", "telegram:111..."]
    }
  }
}
```

---

## Audit Logging

### Enable Comprehensive Logging for Teams

```json
{
  "logging": {
    "level": "info",
    
    "audit": {
      "enabled": true,
      "logFile": "~/.clawdbot/logs/audit.log",
      
      "logEvents": [
        "message_received",
        "message_sent",
        "tool_used",
        "error",
        "rate_limit_hit"
      ],
      
      "includeContent": false,
      "includeTokenCounts": true,
      "includeUserIdentity": true
    },
    
    "retention": {
      "days": 90,
      "maxSizeMB": 500
    }
  }
}
```

### Sample Audit Log Output

```
2026-01-27T10:30:00Z INFO  [audit] message_received platform=discord user=alice#1234 channel=ask-claude tokens=150
2026-01-27T10:30:03Z INFO  [audit] tool_used tool=web_search user=alice#1234
2026-01-27T10:30:05Z INFO  [audit] message_sent platform=discord user=alice#1234 tokens=1200 latency=5.2s
2026-01-27T10:30:10Z INFO  [audit] message_received platform=slack user=bob@acme.com channel=engineering tokens=80
2026-01-27T10:30:12Z WARN  [audit] rate_limit_hit user=charlie#5678 limit=messagesPerMinute
```

### Log Analysis Commands

```bash
# View today's usage by user
grep $(date +%Y-%m-%d) ~/.clawdbot/logs/audit.log | \
  grep message_sent | \
  awk '{print $5}' | sort | uniq -c | sort -rn

# Total tokens used this week
grep "message_sent" ~/.clawdbot/logs/audit.log | \
  grep "$(date +%Y-%m)" | \
  awk -F'tokens=' '{sum+=$2} END {print sum}'

# Find rate limit violations
grep "rate_limit_hit" ~/.clawdbot/logs/audit.log
```

---

## Cost Estimation

### API Cost Calculator for Teams

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    MONTHLY COST ESTIMATION                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Variables:                                                            │
│   • Team size: 10 users                                                 │
│   • Avg messages/user/day: 20                                           │
│   • Avg tokens/message: 2,000 (input + output)                          │
│   • Working days/month: 22                                              │
│                                                                         │
│   Calculation:                                                          │
│   ┌─────────────────────────────────────────────────────────────┐      │
│   │ 10 users × 20 msgs × 2,000 tokens × 22 days                │      │
│   │ = 8,800,000 tokens/month                                    │      │
│   │ = 8.8M tokens                                               │      │
│   │                                                             │      │
│   │ Claude Sonnet: ~$3/M input + $15/M output                   │      │
│   │ Assuming 30% input, 70% output:                             │      │
│   │   Input:  2.64M × $3  = $7.92                              │      │
│   │   Output: 6.16M × $15 = $92.40                             │      │
│   │   Total: ~$100/month                                        │      │
│   └─────────────────────────────────────────────────────────────┘      │
│                                                                         │
│   Cost Tiers:                                                           │
│   ┌─────────────────────────────────────────────────────────────┐      │
│   │ Light Use (10 msgs/user/day)     ~$50/month                │      │
│   │ Medium Use (20 msgs/user/day)    ~$100/month               │      │
│   │ Heavy Use (50 msgs/user/day)     ~$250/month               │      │
│   │ Power Use (100 msgs/user/day)    ~$500/month               │      │
│   └─────────────────────────────────────────────────────────────┘      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Cost Control Configuration

```json
{
  "costControls": {
    "monthlyBudget": 150,
    "warningThreshold": 0.8,
    
    "perUserLimits": {
      "dailyTokens": 50000,
      "monthlyTokens": 500000
    },
    
    "alerts": {
      "email": "admin@company.com",
      "slack": "#billing-alerts"
    },
    
    "onBudgetExceeded": "notify"
  }
}
```

---

## Platform-Specific Team Setup

### Discord Server Setup Checklist

- [ ] Create dedicated Discord server or use existing
- [ ] Create `#ask-claude` channel for AI queries
- [ ] Create `team-member` role
- [ ] Assign role to all 10 team members
- [ ] Invite Clawdbot to server with proper permissions
- [ ] Configure `allowedRoles` in clawdbot.json
- [ ] Enable `replyInThread` for organized conversations
- [ ] Test with each team member

### Slack Workspace Setup Checklist

- [ ] Create Slack app in workspace
- [ ] Install bot to workspace
- [ ] Create `#claude-assistant` channel
- [ ] Invite bot to allowed channels
- [ ] Configure channel allowlist
- [ ] Test @mentions and DMs

### WhatsApp Group Setup Checklist

- [ ] Collect phone numbers from all team members
- [ ] Add all numbers to `allowFrom` array
- [ ] Scan QR code to link WhatsApp
- [ ] Have each team member send test message
- [ ] Verify all can communicate with bot

---

## Quick Reference: Team of 10 Configuration

```json
{
  "gateway": {
    "bind": "lan",
    "port": 18789
  },
  
  "channels": {
    "discord": {
      "enabled": true,
      "guilds": {
        "YOUR_GUILD_ID": {
          "channelPolicy": "allowlist",
          "allowedChannels": ["ask-claude", "engineering"],
          "allowedRoles": ["team-member"],
          "mentionRequired": true,
          "replyInThread": true
        }
      }
    },
    "whatsapp": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [
        "+15551111111",
        "+15552222222",
        "+15553333333",
        "+15554444444",
        "+15555555555",
        "+15556666666",
        "+15557777777",
        "+15558888888",
        "+15559999999",
        "+15550000000"
      ]
    }
  },
  
  "context": {
    "threadIsolation": true,
    "persistAcrossSessions": true
  },
  
  "rateLimits": {
    "perUser": {
      "messagesPerMinute": 10,
      "messagesPerHour": 60
    }
  },
  
  "logging": {
    "audit": {
      "enabled": true,
      "includeUserIdentity": true
    }
  },
  
  "costControls": {
    "monthlyBudget": 150,
    "perUserLimits": {
      "dailyTokens": 50000
    }
  }
}
```

---

*Last Updated: January 2026*
*Part of Clawdbot Documentation: https://github.com/Organized-AI/claudebotready*
