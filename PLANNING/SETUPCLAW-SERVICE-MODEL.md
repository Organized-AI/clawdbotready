# SetupClaw Service Model

**Domain**: https://setupclaw.com/

## Executive Summary

SetupClaw is a **white-glove AI assistant deployment service** for business owners. We configure and ship ready-to-use Mac Mini hardware with a fully personalized Clawdbot instance. Customers plug in, log in, and their AI assistant is already running - named, trained, and configured exactly to their specifications.

---

## The Product

### What We Sell

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   🖥️ SETUPCLAW PACKAGE                                          │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  HARDWARE                                               │   │
│   │  • Apple Mac Mini (M2/M3/M4)                           │   │
│   │  • Pre-configured, secured, ready to deploy            │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  SOFTWARE                                               │   │
│   │  • Clawdbot (OpenClaw) instance                        │   │
│   │  • VM-isolated or Native install                        │   │
│   │  • PostHog analytics pre-configured                     │   │
│   │  • Security hardening applied                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  CONFIGURATION                                          │   │
│   │  • Named & personalized bot                            │   │
│   │  • Custom personality & voice                          │   │
│   │  • Business context loaded                             │   │
│   │  • Skills & integrations installed                     │   │
│   │  • Tested before shipping                              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  SERVICE                                                │   │
│   │  • White-glove setup consultation                      │   │
│   │  • Pre-ship testing & validation                       │   │
│   │  • Unboxing support call (optional)                    │   │
│   │  • Ongoing support & updates                           │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Customer Journey

### Phase 1: Discovery & Sales

```
Customer finds SetupClaw → Learns about the service → Books consultation
```

**Touchpoints**:
- setupclaw.com landing page
- Demo video showing plug-and-play experience
- Case studies from businesses using Clawdbot
- Pricing page with packages

### Phase 2: Configuration Session (Prebuild)

```
Consultation call → Prebuild wizard → Test drive → Approval
```

**This is where the Prebuild feature lives.**

The configuration session is either:
- **Guided**: You walk through the wizard with the customer on a call
- **Self-service**: Customer fills out prebuild wizard on their own (for simpler needs)
- **Hybrid**: Customer starts, you refine together

**What gets configured**:

| Category | Details |
|----------|---------|
| **Identity** | Bot name, greeting, avatar style, pronouns |
| **Personality** | Communication style, warmth, formality, emoji use |
| **Business Context** | Company info, products, brand voice, industry |
| **Capabilities** | Skills, plugins, hooks, integrations |
| **Boundaries** | Topics to avoid, escalation rules, hours |
| **Interface Points** | Where bot connects (iMessage, SMS, web, etc.) |

**Output**: `prebuild-config.json` + PDF summary for customer approval

### Phase 3: Build & Configure

```
Order hardware → Install base system → Apply prebuild config → Test
```

**Your workflow**:

1. **Hardware prep**
   - Mac Mini (appropriate tier based on customer needs)
   - macOS Sequoia + security updates

2. **Base installation**
   - Run `openclaw-vm-setup/setup.sh` OR `openclaw-native-setup/setup.sh`
   - Security hardening, SSH keys, firewall

3. **Apply prebuild configuration**
   - Import `prebuild-config.json`
   - Install selected skills & plugins
   - Configure integrations (PostHog, Moltbook, etc.)
   - Set up personality & business context in Clawdbot

4. **Pre-ship testing**
   - Run through test scenarios
   - Verify all integrations work
   - Confirm personality matches configuration
   - Security audit

5. **Create customer credentials**
   - macOS user account
   - Admin access (or limited, depending on package)
   - First-login instructions

### Phase 4: Delivery

```
Ship hardware → Customer receives → Plug in → Login → Bot is live
```

**The Magic Moment**: Customer opens box, connects Mac Mini to power and network, logs in, and their personalized AI assistant greets them by the name they chose.

**Included in box**:
- Mac Mini (pre-configured)
- Power cable
- Quick start card with:
  - Login credentials
  - First steps
  - Support contact
- Summary PDF of their configuration

### Phase 5: Onboarding Support

```
First-login call (optional) → Answer questions → Verify working → Celebrate
```

**Options**:
- **Self-service**: Customer follows quick start, contacts support if needed
- **Guided onboarding**: Scheduled call when they plug in, walk through together
- **VIP**: On-site setup (premium tier)

### Phase 6: Ongoing Relationship

```
Updates → Support → Optimizations → Expansion
```

**Ongoing services**:
- Software updates to Clawdbot
- Skill additions/modifications
- Personality tweaks based on feedback
- Analytics reviews (PostHog dashboards)
- Additional units for team expansion

---

## Prebuild Feature: The Configuration System

### Purpose in SetupClaw Context

The Prebuild feature is your **sales and configuration tool**:

1. **During sales call**: Walk customer through wizard, show them exactly what they're getting
2. **Configuration capture**: Generate machine-readable config you'll apply to hardware
3. **Customer approval**: PDF summary they can review and approve
4. **Build automation**: Config feeds directly into setup scripts

### Prebuild Data Collected

```json
{
  "customer": {
    "name": "Acme Solutions",
    "contact": "jane@acme.com",
    "industry": "saas"
  },
  "bot": {
    "name": "Alex",
    "greeting": "Hi, I'm Alex from Acme! How can I help?",
    "personality": {
      "style": "friendly",
      "warmth": 8,
      "formality": 4,
      "emoji_usage": "moderate"
    }
  },
  "business_context": {
    "company_name": "Acme Solutions",
    "description": "We help small businesses automate...",
    "products": ["Messaging Platform", "Analytics Dashboard"],
    "brand_keywords": ["innovative", "reliable", "simple"]
  },
  "capabilities": {
    "skills": ["ticket-triage", "sentiment-analysis"],
    "plugins": [],
    "hooks": [],
    "integrations": {
      "posthog": { "enabled": true, "api_key_env": "POSTHOG_API_KEY" },
      "imessage": { "enabled": true }
    }
  },
  "behavior": {
    "topics_to_avoid": ["competitor pricing"],
    "escalation_triggers": ["refund requests", "angry customers"],
    "can_make_promises": false,
    "hours": "business_hours",
    "after_hours_message": "Thanks for reaching out! We'll get back to you tomorrow."
  },
  "interface_points": {
    "primary": "imessage",
    "secondary": ["web_chat"]
  },
  "hardware": {
    "tier": "standard",
    "model": "mac_mini_m3"
  },
  "service": {
    "package": "professional",
    "onboarding": "guided"
  }
}
```

### Prebuild → Build Automation

The `prebuild-config.json` feeds into the setup process:

```bash
# During your build process:
./setup.sh all --prebuild-config ./orders/acme-solutions.json

# This automatically:
# - Sets bot name and personality
# - Loads business context
# - Installs selected skills
# - Configures integrations
# - Applies security settings
# - Creates customer user account
```

---

## Interface Points

### Where Clawdbot Connects

The business owner specifies during Prebuild where they want their bot to operate:

| Channel | Description | Setup Requirements |
|---------|-------------|-------------------|
| **iMessage** | Native Apple Messages | Apple ID (can be customer's or burner) |
| **SMS** | Text messaging | Twilio/carrier integration |
| **Web Chat** | Website widget | Embed code for their site |
| **WhatsApp** | WhatsApp Business | WhatsApp Business API |
| **Slack** | Team Slack workspace | Slack app installation |
| **Email** | Email responses | IMAP/SMTP configuration |
| **API** | Custom integrations | API keys and documentation |

**Primary Focus for v1**: iMessage (native Mac capability)

---

## Service Packages

### Starter Package
- Mac Mini M2 (8GB)
- Basic personality configuration
- 2 skills included
- Email support
- Self-service onboarding
- **$X,XXX one-time + $XXX/month**

### Professional Package
- Mac Mini M3 (16GB)
- Full personality configuration
- 5 skills included
- PostHog analytics
- Priority support
- Guided onboarding call
- **$X,XXX one-time + $XXX/month**

### Enterprise Package
- Mac Mini M4 Pro (24GB+)
- Full configuration + custom skills
- Unlimited skills
- Custom integrations
- Dedicated support
- On-site setup (optional)
- Multi-unit discounts
- **Custom pricing**

---

## Technology Stack

### On the Mac Mini

```
┌─────────────────────────────────────────────────────────────┐
│  macOS Sequoia (Apple Silicon)                              │
├─────────────────────────────────────────────────────────────┤
│  Option A: VM-Isolated                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Lume VM                                             │    │
│  │  ├── Clawdbot (OpenClaw Gateway)                    │    │
│  │  ├── PostHog agent                                  │    │
│  │  └── Configured skills & plugins                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  OR                                                         │
│                                                             │
│  Option B: Native Install                                   │
│  ├── Clawdbot (OpenClaw Gateway)                           │
│  ├── PostHog agent                                         │
│  └── Configured skills & plugins                           │
├─────────────────────────────────────────────────────────────┤
│  Common:                                                    │
│  ├── SSH hardened                                          │
│  ├── Firewall configured                                   │
│  ├── Monitoring & health checks                            │
│  ├── Automatic backups                                     │
│  └── Tailscale (optional, for remote management)           │
└─────────────────────────────────────────────────────────────┘
```

### Your Operations

```
┌─────────────────────────────────────────────────────────────┐
│  SetupClaw Operations                                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  setupclaw   │    │   Prebuild   │    │    Order     │  │
│  │  .com        │───▶│   Wizard     │───▶│   System     │  │
│  │  (Marketing) │    │   (Config)   │    │   (CRM)      │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                 │           │
│                                                 ▼           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Hardware   │◀───│    Build     │◀───│   Prebuild   │  │
│  │   Inventory  │    │   Station    │    │   Config     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                             │                               │
│                             ▼                               │
│                      ┌──────────────┐                       │
│                      │    Ship      │                       │
│                      │   & Track    │                       │
│                      └──────────────┘                       │
│                             │                               │
│                             ▼                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Support    │◀───│   Customer   │◀───│  Onboarding  │  │
│  │   Portal     │    │   Success    │    │    Call      │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## The "Plug In and Go" Experience

### What the Customer Experiences

1. **Receives package**
   - Opens box
   - Finds Mac Mini, cables, quick start card

2. **Physical setup** (2 minutes)
   - Connects power
   - Connects to network (Ethernet or WiFi)
   - Connects to display (first time only)

3. **First login** (1 minute)
   - Logs in with provided credentials
   - Sees personalized welcome screen
   - Bot is already running

4. **First interaction** (immediate)
   - Opens Messages app (or configured channel)
   - Sends test message
   - Bot responds with configured personality

```
┌─────────────────────────────────────────────────────────────┐
│  First Login Screen                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│            Welcome to your Clawdbot, Jane!                  │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                                                      │   │
│   │     🤖 Meet Alex                                     │   │
│   │     Your AI Assistant for Acme Solutions            │   │
│   │                                                      │   │
│   │     Alex is configured and ready to help.           │   │
│   │                                                      │   │
│   │     Skills: Ticket Triage, Sentiment Analysis       │   │
│   │     Personality: Friendly & Warm                    │   │
│   │     Hours: 9 AM - 5 PM PT                          │   │
│   │                                                      │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   To test: Open Messages and send "Hello" to Alex          │
│                                                             │
│   [Open Messages]  [View Dashboard]  [Get Help]            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### What's Pre-Configured

Before shipping, you've already:

- [x] Installed and secured macOS
- [x] Set up VM (if applicable)
- [x] Installed Clawdbot
- [x] Applied personality configuration
- [x] Loaded business context
- [x] Installed selected skills
- [x] Configured integrations
- [x] Set up PostHog tracking
- [x] Created customer user account
- [x] Customized welcome screen
- [x] Tested all scenarios
- [x] Created backup snapshot

---

## Remote Management (Optional)

For ongoing support and updates:

### Tailscale Integration
- Pre-installed Tailscale on each unit
- Connects to your admin tailnet
- Allows remote SSH access for maintenance
- Customer can disable if desired

### Remote Capabilities
- Push updates to Clawdbot
- Adjust configuration remotely
- Monitor health and uptime
- Troubleshoot issues without on-site visit

---

## Success Metrics

### For SetupClaw (Your Business)

| Metric | Target |
|--------|--------|
| Time from order to ship | < 5 business days |
| Setup time per unit | < 2 hours |
| Customer first-login success rate | > 95% |
| Support tickets in first week | < 1 per customer |
| Customer satisfaction (NPS) | > 60 |
| Renewal rate | > 80% |

### For Customers (Their Business)

| Metric | Target |
|--------|--------|
| Time from unbox to first message | < 10 minutes |
| Bot response accuracy | > 90% |
| Customer satisfaction with bot | > 4/5 stars |
| Messages handled per day | Varies by plan |
| Escalation rate | < 20% of conversations |

---

## Competitive Advantages

1. **Plug and play**: Competitors require extensive self-setup
2. **Personalized from day one**: Not a generic bot, it's THEIR bot
3. **Hardware included**: No "find your own server" complexity
4. **Test drive before buy**: See exactly what you're getting
5. **White glove service**: Human guidance through setup
6. **Apple ecosystem native**: iMessage support is unique
7. **Privacy-focused**: Runs on their hardware, not a cloud

---

## Next Steps

1. [ ] Build setupclaw.com landing page
2. [ ] Create Prebuild wizard web interface
3. [ ] Define hardware tiers and pricing
4. [ ] Create build automation scripts
5. [ ] Design first-login welcome experience
6. [ ] Set up Tailscale admin network
7. [ ] Create support documentation
8. [ ] Pilot with 3-5 early customers

---

*Document created: 2026-02-01*
*Status: PLANNING*
