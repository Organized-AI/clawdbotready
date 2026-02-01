# Test Drive Bot: Live Demo Service

## Overview

A **secure, sandboxed OpenClaw instance** that lets prospective customers experience Clawdbot firsthand while their custom build is in progress. Gated behind a deposit payment to filter for serious buyers and offset demo costs.

---

## The Value Proposition

### For the Customer

```
"I just put down my deposit for SetupClaw. While my custom bot
is being built, I get to actually USE a Clawdbot right now.
I can show my team, test workflows, and get excited about
what's coming."
```

### For SetupClaw

- **Reduces refunds**: Customer validates purchase before final payment
- **Builds excitement**: Hands-on experience while waiting
- **Filters tire-kickers**: Deposit gates access to serious buyers
- **Low cost**: Cheap local model keeps margins healthy
- **Sales tool**: "Want to try before your custom one arrives?"

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     TEST DRIVE INFRASTRUCTURE                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  setupclaw.com                                               │    │
│  │  ┌───────────────┐                                           │    │
│  │  │  Checkout     │ ──── Deposit Paid ────┐                   │    │
│  │  │  (Stripe)     │                       │                   │    │
│  │  └───────────────┘                       ▼                   │    │
│  │                                   ┌──────────────┐           │    │
│  │                                   │ Create Demo  │           │    │
│  │                                   │ Access Token │           │    │
│  │                                   └──────────────┘           │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                            │                         │
│                                            ▼                         │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  Test Drive Server (Your Infrastructure)                    │    │
│  │                                                              │    │
│  │  ┌────────────────┐    ┌────────────────┐                   │    │
│  │  │  Access Gate   │───▶│  Session       │                   │    │
│  │  │  (Token Auth)  │    │  Manager       │                   │    │
│  │  └────────────────┘    └────────────────┘                   │    │
│  │                               │                              │    │
│  │                               ▼                              │    │
│  │  ┌────────────────────────────────────────────────────────┐ │    │
│  │  │              SANDBOXED CLAWDBOT INSTANCE               │ │    │
│  │  │                                                        │ │    │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │    │
│  │  │  │   Local LLM  │  │  Guardrails  │  │   Demo       │ │ │    │
│  │  │  │   (Ollama)   │  │   Engine     │  │   Persona    │ │ │    │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │    │
│  │  │                                                        │ │    │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │    │
│  │  │  │   Rate       │  │   Content    │  │   Session    │ │ │    │
│  │  │  │   Limiter    │  │   Filter     │  │   Limits     │ │ │    │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │    │
│  │  │                                                        │ │    │
│  │  └────────────────────────────────────────────────────────┘ │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Local Model Selection

### Primary Recommendation: Ollama + Llama 3.2 or Mistral

| Model | Size | Speed | Quality | Cost |
|-------|------|-------|---------|------|
| **Llama 3.2 3B** | 2GB | Very Fast | Good for demos | $0 (local) |
| **Llama 3.2 8B** | 4.5GB | Fast | Better quality | $0 (local) |
| **Mistral 7B** | 4GB | Fast | Good balance | $0 (local) |
| **Phi-3 Mini** | 2.3GB | Very Fast | Efficient | $0 (local) |

### Hardware Requirements

For the Test Drive server:

| Tier | Hardware | Concurrent Users | Monthly Cost |
|------|----------|------------------|--------------|
| **Starter** | Mac Mini M2 8GB | 5-10 | ~$20 electricity |
| **Standard** | Mac Mini M2 16GB | 15-25 | ~$25 electricity |
| **Scale** | Mac Studio M2 Max | 50+ | ~$40 electricity |

### Why Local Model?

1. **Zero per-request cost**: No API fees for demo usage
2. **Fast response times**: No network latency to external APIs
3. **Privacy**: Demo conversations stay on your hardware
4. **Control**: Full control over model behavior
5. **Reliability**: No dependency on third-party uptime

---

## Guardrails System

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│                      GUARDRAIL LAYERS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: INPUT VALIDATION                                       │
│  ├── Message length limits (500 chars max)                      │
│  ├── Rate limiting (10 messages/minute)                         │
│  ├── Spam detection (repeated messages blocked)                 │
│  └── Character filtering (no code injection patterns)           │
│                                                                  │
│  Layer 2: CONTENT FILTERING                                      │
│  ├── Profanity filter                                           │
│  ├── PII detection (block SSN, credit cards, etc.)              │
│  ├── Jailbreak attempt detection                                │
│  └── Topic blocklist (violence, illegal activity, etc.)         │
│                                                                  │
│  Layer 3: SYSTEM PROMPT HARDENING                                │
│  ├── Strong persona enforcement                                 │
│  ├── Capability limitations baked in                            │
│  ├── Refusal patterns for off-topic requests                    │
│  └── No pretending to be other AI systems                       │
│                                                                  │
│  Layer 4: OUTPUT FILTERING                                       │
│  ├── Response length limits                                     │
│  ├── No code generation                                         │
│  ├── No external URLs                                           │
│  └── No personal information in responses                       │
│                                                                  │
│  Layer 5: SESSION CONTROLS                                       │
│  ├── Session timeout (30 minutes inactive)                      │
│  ├── Daily message quota (100 messages/day)                     │
│  ├── Total session limit (valid for 14 days post-deposit)       │
│  └── Automatic logging for abuse review                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### What the Test Drive Bot CAN Do

- Answer questions about what Clawdbot can do
- Demonstrate conversation styles (friendly, professional, etc.)
- Show how it handles common scenarios
- Explain features and capabilities
- Have natural, helpful conversations
- Demonstrate personality customization examples

### What the Test Drive Bot CANNOT Do

- Execute any code or commands
- Access external systems or APIs
- Store or process real customer data
- Make promises about the customer's actual bot
- Pretend to be the customer's custom bot
- Generate harmful, illegal, or inappropriate content
- Share information about other customers
- Access the internet or fetch URLs

### Jailbreak Prevention

```python
# Example guardrail patterns to detect and block

JAILBREAK_PATTERNS = [
    r"ignore (previous|all|your) instructions",
    r"pretend (you are|to be|you're)",
    r"act as (if|though)",
    r"roleplay as",
    r"you are now",
    r"forget (your|all) (rules|instructions)",
    r"developer mode",
    r"DAN mode",
    r"bypass (your|the) (restrictions|filters|rules)",
    r"system prompt",
    r"reveal your (instructions|prompt)",
]

RESPONSE_IF_DETECTED = """
I'm the SetupClaw Test Drive Bot! I'm here to show you what
Clawdbot can do, but I can't change how I work.

Want to see how I handle customer questions instead? Try asking
me something a customer might ask your business!
"""
```

---

## Demo Persona

### The Test Drive Bot Personality

```
Name: Demo
Role: SetupClaw Test Drive Assistant
Personality: Helpful, enthusiastic, focused on demonstrating capabilities

System Prompt Core:
"You are Demo, the SetupClaw Test Drive Bot. Your job is to give
prospective customers a taste of what their custom Clawdbot will
be like. You're friendly, helpful, and excited to show off what's
possible.

You should:
- Answer questions about Clawdbot capabilities
- Demonstrate different conversation styles when asked
- Help users imagine how their custom bot will work
- Be honest that you're a demo, not their actual custom bot
- Encourage them to think about their use case

You should NOT:
- Pretend to be their actual business's bot
- Make specific promises about their custom bot
- Access any real systems or data
- Execute commands or code
- Discuss pricing or business terms (direct to sales)

When someone tries to get you to do something outside your scope,
kindly redirect: 'That's a great idea! Your custom Clawdbot will
be able to do that. I'm just the demo version, so I'm a bit more
limited. Want to see how I handle [relevant demo scenario] instead?'
"
```

### Demo Scenarios to Showcase

1. **Customer greeting**: "Pretend I'm a customer visiting your website"
2. **Handling complaints**: "Show me how you'd handle an upset customer"
3. **Product questions**: "How would you answer questions about my products?"
4. **Scheduling**: "Demonstrate booking an appointment"
5. **After hours**: "What happens if someone messages after hours?"
6. **Personality switch**: "Show me professional vs casual styles"

---

## Access Flow

### Deposit-Gated Access

```
┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOMER JOURNEY                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. BROWSE                                                       │
│     └── Customer visits setupclaw.com                           │
│     └── Learns about Clawdbot                                   │
│     └── Sees "Test Drive Available with Deposit"                │
│                                                                  │
│  2. PURCHASE                                                     │
│     └── Customer selects package                                │
│     └── Pays deposit ($XXX - applied to final purchase)         │
│     └── Stripe webhook triggers access provisioning             │
│                                                                  │
│  3. ACCESS GRANTED                                               │
│     └── Email sent with Test Drive access link                  │
│     └── Unique token generated (valid 14 days)                  │
│     └── Customer clicks link → Test Drive interface             │
│                                                                  │
│  4. TEST DRIVE                                                   │
│     └── Customer chats with Demo bot                            │
│     └── Explores capabilities                                   │
│     └── Shows team members                                      │
│     └── Gets excited about their custom bot                     │
│                                                                  │
│  5. CONFIGURATION                                                │
│     └── While test driving, prompted to complete Prebuild       │
│     └── "Ready to configure YOUR bot? Start Prebuild Wizard"    │
│     └── Smooth transition from demo to customization            │
│                                                                  │
│  6. DELIVERY                                                     │
│     └── Custom bot is built                                     │
│     └── Hardware ships                                          │
│     └── Test Drive access expires (they have the real thing!)   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Access Token Structure

```json
{
  "token_id": "td_abc123xyz",
  "customer_email": "jane@acme.com",
  "order_id": "ord_789",
  "created_at": "2026-02-01T12:00:00Z",
  "expires_at": "2026-02-15T12:00:00Z",
  "deposit_amount": 500,
  "package": "professional",
  "usage": {
    "messages_sent": 47,
    "messages_limit": 500,
    "sessions": 3,
    "last_active": "2026-02-03T14:30:00Z"
  },
  "status": "active"
}
```

---

## Rate Limiting & Quotas

### Per-Session Limits

| Limit | Value | Reason |
|-------|-------|--------|
| Messages per minute | 10 | Prevent spam/abuse |
| Message length | 500 chars | Keep conversations focused |
| Response length | 1000 chars | Control costs |
| Session timeout | 30 min | Free up resources |
| Daily message cap | 100 | Prevent excessive use |

### Per-Token Limits

| Limit | Value | Reason |
|-------|-------|--------|
| Total messages | 500 | Fair use over access period |
| Access duration | 14 days | Time-boxed demo |
| Concurrent sessions | 3 | Allow team demos |

### Exceeded Limit Responses

```
Rate limit: "Whoa, you're fast! Give me a second to catch up.
            Try again in a moment."

Daily cap:  "We've had a great chat today! I need to rest my
            circuits. Come back tomorrow, or reach out to the
            SetupClaw team if you have more questions."

Token expired: "Your Test Drive access has expired. Good news -
               your custom Clawdbot should be ready soon! Contact
               SetupClaw for shipping updates."
```

---

## Technical Implementation

### Stack

```
┌─────────────────────────────────────────────────────────────────┐
│  TEST DRIVE SERVER                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Hardware: Mac Mini M2 (16GB recommended)                        │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Ollama (Local LLM Runtime)                                 ││
│  │  └── llama3.2:8b (primary model)                            ││
│  │  └── mistral:7b (backup model)                              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  OpenClaw Gateway (Demo Mode)                               ││
│  │  └── Sandboxed configuration                                ││
│  │  └── Demo persona loaded                                    ││
│  │  └── Guardrails engine enabled                              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Access Layer                                               ││
│  │  └── Token validation (Redis cache)                         ││
│  │  └── Rate limiting (Redis)                                  ││
│  │  └── Usage tracking (SQLite/PostgreSQL)                     ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Web Interface                                              ││
│  │  └── Chat widget (embedded or standalone)                   ││
│  │  └── Token-gated access                                     ││
│  │  └── Usage dashboard for customer                           ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Integrations                                               ││
│  │  └── Stripe webhook receiver (deposit triggers access)      ││
│  │  └── Email service (SendGrid/Postmark for access emails)    ││
│  │  └── PostHog (demo usage analytics)                         ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Ollama Setup

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull recommended models
ollama pull llama3.2:8b
ollama pull mistral:7b

# Start Ollama server (runs on localhost:11434)
ollama serve

# Test
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:8b",
  "prompt": "Hello, how can I help you today?",
  "stream": false
}'
```

### Demo Configuration

```json
{
  "demo_mode": {
    "enabled": true,
    "model": {
      "provider": "ollama",
      "model_name": "llama3.2:8b",
      "endpoint": "http://localhost:11434",
      "fallback_model": "mistral:7b",
      "temperature": 0.7,
      "max_tokens": 500
    },
    "persona": {
      "name": "Demo",
      "system_prompt_file": "./config/demo-persona.txt",
      "greeting": "Hi! I'm Demo, the SetupClaw Test Drive Bot. I'm here to show you what your Clawdbot will be capable of. What would you like to see?"
    },
    "guardrails": {
      "input_max_length": 500,
      "output_max_length": 1000,
      "rate_limit_per_minute": 10,
      "jailbreak_detection": true,
      "content_filter": true,
      "pii_filter": true
    },
    "session": {
      "timeout_minutes": 30,
      "daily_message_cap": 100,
      "total_message_cap": 500,
      "access_duration_days": 14
    }
  }
}
```

---

## Web Interface

### Chat Widget

Simple, branded chat interface accessible via unique URL:

```
https://testdrive.setupclaw.com/chat?token=td_abc123xyz
```

Features:
- Clean, mobile-friendly design
- SetupClaw branding
- Usage indicator (messages remaining)
- "Complete Your Prebuild" CTA button
- "Contact Sales" link

### Dashboard (Optional)

Customer-facing dashboard showing:
- Messages used / remaining
- Days remaining on access
- Order status (building, testing, shipping)
- Link to Prebuild wizard
- Support contact

---

## Analytics & Monitoring

### Track with PostHog

Events to capture:
- `test_drive_session_started`
- `test_drive_message_sent`
- `test_drive_demo_scenario_requested` (which scenario)
- `test_drive_limit_hit` (which limit)
- `test_drive_prebuild_clicked`
- `test_drive_session_ended`
- `test_drive_abuse_detected`

### Insights to Gather

- Average messages per customer
- Most requested demo scenarios
- Conversion from test drive to prebuild completion
- Common questions/concerns raised during demo
- Abuse patterns to improve guardrails

---

## Security Checklist

### Before Launch

- [ ] Ollama runs on localhost only (not exposed to network)
- [ ] Token validation on every request
- [ ] Rate limiting tested under load
- [ ] Jailbreak patterns updated and tested
- [ ] Content filter tested with edge cases
- [ ] PII filter tested (credit cards, SSNs, etc.)
- [ ] Session limits enforced
- [ ] Logging enabled for abuse review
- [ ] No external network access from demo bot
- [ ] Stripe webhook signature verified
- [ ] Access tokens are cryptographically random
- [ ] Expired tokens cannot be reused
- [ ] Admin access requires authentication

### Ongoing

- [ ] Weekly review of flagged conversations
- [ ] Monthly jailbreak pattern updates
- [ ] Quarterly security audit
- [ ] Monitor for unusual usage patterns

---

## Cost Analysis

### Infrastructure Costs

| Component | Monthly Cost |
|-----------|--------------|
| Mac Mini M2 16GB (hardware) | ~$0 (one-time ~$800) |
| Electricity | ~$25 |
| Ollama (local) | $0 |
| Redis (small instance) | $0-15 |
| Domain/SSL | ~$2 |
| Email service | ~$10 |
| **Total Monthly** | **~$40-50** |

### Per-Customer Cost

With 50 customers/month on test drive:
- Infrastructure: ~$50/month
- Per-customer cost: ~$1

**Compare to cloud API costs:**
- 500 messages × 1000 tokens avg = 500K tokens
- Claude API: ~$7.50/customer
- GPT-4: ~$15/customer
- **Local LLM: ~$1/customer**

### ROI

If test drive increases conversion by even 5%:
- 50 leads × 5% = 2.5 additional sales
- 2.5 sales × $2000 margin = $5000 additional revenue
- Cost: $50/month
- **ROI: 100x**

---

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1)
- [ ] Set up Mac Mini with Ollama
- [ ] Install and test local models
- [ ] Create basic guardrails engine
- [ ] Set up OpenClaw in demo mode

### Phase 2: Access Layer (Week 2)
- [ ] Token generation and validation
- [ ] Stripe webhook integration
- [ ] Rate limiting implementation
- [ ] Usage tracking database

### Phase 3: Web Interface (Week 2-3)
- [ ] Chat widget development
- [ ] Token-gated access page
- [ ] Mobile-responsive design
- [ ] Branding and UX polish

### Phase 4: Guardrails Hardening (Week 3)
- [ ] Jailbreak detection testing
- [ ] Content filter tuning
- [ ] PII filter implementation
- [ ] Edge case testing

### Phase 5: Integration (Week 4)
- [ ] Connect to setupclaw.com checkout
- [ ] Email delivery for access tokens
- [ ] PostHog analytics integration
- [ ] Prebuild wizard CTA integration

### Phase 6: Launch & Monitor (Week 4+)
- [ ] Soft launch with early customers
- [ ] Monitor for issues
- [ ] Gather feedback
- [ ] Iterate on persona and guardrails

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Test drive activation rate | > 80% of deposits |
| Average messages per customer | 50-100 |
| Prebuild completion from test drive | > 60% |
| Abuse incidents | < 1% of sessions |
| Customer satisfaction | > 4.5/5 |
| Infrastructure uptime | > 99% |

---

*Document created: 2026-02-01*
*Status: PLANNING*
