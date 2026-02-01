# Clawdbot Prebuild: Business Owner Onboarding Flow

## Overview

This document defines the step-by-step experience a business owner goes through when configuring their Clawdbot. The goal is to make setup feel like **tailoring a suit** or **configuring a vehicle to spec** - personal, intentional, and exciting.

---

## Design Principles

1. **Excitement, Not Overwhelm**: Each step should feel like progress, not paperwork
2. **Show, Don't Tell**: Preview responses immediately as they configure
3. **Opinionated Defaults**: Smart defaults based on industry/use case
4. **Test Before Commit**: Always let them experience before finalizing
5. **Shareable Output**: Generate something they can show stakeholders

---

## The Onboarding Journey

### Phase 0: Welcome (30 seconds)

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│                    Welcome to Clawdbot                         │
│                                                                │
│        You're about to configure your AI assistant.           │
│        In the next few minutes, you'll:                       │
│                                                                │
│        ✓ Name your assistant                                  │
│        ✓ Define their personality                             │
│        ✓ Tell them about your business                        │
│        ✓ Choose what they can do                              │
│        ✓ Test drive them before you launch                    │
│                                                                │
│        When you're done, your Clawdbot will be ready          │
│        to work the moment it's deployed.                      │
│                                                                │
│                     [Let's Get Started] →                     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

### Phase 1: Identity (2-3 minutes)

**Goal**: Give the bot a name and face

```
┌────────────────────────────────────────────────────────────────┐
│  Step 1 of 6: Give Your Assistant an Identity                 │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  What would you like to name your assistant?                  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Alex                                                     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  💡 Popular names: Luna, Max, Sage, Kai, Sam                  │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  How should Alex introduce themselves?                        │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Hi, I'm Alex! How can I help you today?                 │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  LIVE PREVIEW:                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  🤖 Alex                                                  │ │
│  │  "Hi, I'm Alex! How can I help you today?"               │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│                              [Continue] →                      │
└────────────────────────────────────────────────────────────────┘
```

**Fields**:
- Bot name (text input)
- Introduction/greeting (text input with templates)
- Optional: Avatar style selection

---

### Phase 2: Personality (3-4 minutes)

**Goal**: Define how the bot communicates

```
┌────────────────────────────────────────────────────────────────┐
│  Step 2 of 6: Define the Personality                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  How should Alex communicate?                                  │
│                                                                │
│  ○ Professional - Formal, polished, business-appropriate      │
│  ● Friendly - Warm, approachable, conversational              │
│  ○ Casual - Relaxed, informal, like texting a friend          │
│  ○ Concise - Brief, to-the-point, efficient                   │
│  ○ Empathetic - Understanding, patient, supportive            │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  Fine-tune the personality:                                   │
│                                                                │
│  Warmth      Reserved ├──────●──────┤ Very Warm               │
│  Formality   Casual   ├────●────────┤ Formal                  │
│  Enthusiasm  Subdued  ├──────●──────┤ Energetic               │
│  Detail      Brief    ├────●────────┤ Thorough                │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  Should Alex use emojis?    ○ Never  ● Sometimes  ○ Often     │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  LIVE PREVIEW - How Alex sounds in different situations:      │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │  Greeting a customer:                                     │ │
│  │  "Hey there! Thanks for reaching out. What can I         │ │
│  │   help you with today? 😊"                                │ │
│  │                                                           │ │
│  │  When something goes wrong:                               │ │
│  │  "Oh no, I'm really sorry about that! Let me see         │ │
│  │   what I can do to fix this for you."                    │ │
│  │                                                           │ │
│  │  Saying goodbye:                                          │ │
│  │  "Awesome, glad I could help! Let me know if you         │ │
│  │   need anything else. Have a great day!"                 │ │
│  │                                                           │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│                              [Continue] →                      │
└────────────────────────────────────────────────────────────────┘
```

**Key Feature**: Live preview updates as sliders change

---

### Phase 3: Business Context (2-3 minutes)

**Goal**: Teach the bot about the business

```
┌────────────────────────────────────────────────────────────────┐
│  Step 3 of 6: Tell Alex About Your Business                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  What's your company name?                                    │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Acme Solutions                                           │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  What industry are you in?                                    │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  SaaS / Software                               ▼         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  Describe your business in a sentence or two:                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  We help small businesses automate their customer        │ │
│  │  communications with AI-powered messaging tools.         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  What are your main products or services?                     │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  [Messaging Platform] [Analytics Dashboard] [+ Add]      │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  Words that describe your brand (pick 3-5):                   │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  [●Innovative] [●Reliable] [○Premium] [○Affordable]      │ │
│  │  [●Simple] [○Enterprise] [○Local] [○Sustainable]         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  LIVE PREVIEW - How Alex talks about Acme Solutions:          │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │  Customer: "What does your company do?"                   │ │
│  │                                                           │ │
│  │  Alex: "Great question! Acme Solutions helps small       │ │
│  │  businesses automate their customer communications.       │ │
│  │  Our main offerings are our Messaging Platform and        │ │
│  │  Analytics Dashboard. We focus on being innovative,       │ │
│  │  reliable, and keeping things simple. 😊"                 │ │
│  │                                                           │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│                              [Continue] →                      │
└────────────────────────────────────────────────────────────────┘
```

---

### Phase 4: Capabilities & Skills (3-4 minutes)

**Goal**: Choose what the bot can do

```
┌────────────────────────────────────────────────────────────────┐
│  Step 4 of 6: What Can Alex Do?                               │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  What's the primary purpose of Alex?                          │
│                                                                │
│  ● Customer Support - Answer questions, handle issues         │
│  ○ Sales Outreach - Follow up with leads, qualify prospects   │
│  ○ Internal Comms - Team notifications, coordination          │
│  ○ Custom - I'll configure from scratch                       │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  RECOMMENDED SKILLS for Customer Support:                     │
│                                                                │
│  [✓] Ticket Triage (Categorize & prioritize incoming)        │
│      └─ Auto-assign, SLA tracking, priority levels            │
│                                                                │
│  [✓] Sentiment Analysis (Detect customer mood)                │
│      └─ Escalate negative sentiment automatically             │
│                                                                │
│  [ ] Smart Reply v2 ⭐ NEW (AI-powered responses)             │
│      └─ Context-aware, tone-matched replies                   │
│                                                                │
│  [ ] Knowledge Base Search (Find answers fast)                │
│      └─ Connect your docs for instant answers                 │
│                                                                │
│  [ ] Escalation Rules (Hand off to humans)                    │
│      └─ Configurable triggers for human takeover              │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  INTEGRATIONS:                                                 │
│                                                                │
│  [✓] PostHog Analytics                                        │
│      └─ Track conversations, measure performance              │
│                                                                │
│  [ ] Moltbook Channels                                        │
│      └─ Connect to community knowledge                        │
│                                                                │
│  [ ] Slack Alerts                                             │
│      └─ Get notified when things need attention               │
│                                                                │
│                              [Continue] →                      │
└────────────────────────────────────────────────────────────────┘
```

---

### Phase 5: Boundaries & Rules (2-3 minutes)

**Goal**: Set guardrails for appropriate behavior

```
┌────────────────────────────────────────────────────────────────┐
│  Step 5 of 6: Set the Ground Rules                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Topics Alex should AVOID discussing:                         │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  [Competitor pricing] [Politics] [+ Add topic]           │ │
│  └──────────────────────────────────────────────────────────┘ │
│  💡 Common: pricing negotiations, legal advice, competitors   │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  Alex should ALWAYS escalate to a human when:                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  [Refund requests] [Angry customers] [+ Add rule]        │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  Can Alex make commitments on your behalf?                    │
│  ○ Yes - Alex can make promises (e.g., "We'll fix this")     │
│  ● No - Alex should say "I'll make sure the team sees this"  │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  Availability:                                                 │
│  ○ 24/7 - Always available                                   │
│  ● Business hours - 9 AM - 5 PM                              │
│  ○ Custom schedule                                            │
│                                                                │
│  After-hours message:                                         │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Thanks for reaching out! Our team is currently          │ │
│  │  offline, but we'll get back to you first thing          │ │
│  │  tomorrow morning. 🌙                                     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│                              [Continue] →                      │
└────────────────────────────────────────────────────────────────┘
```

---

### Phase 6: Test Drive (3-5 minutes)

**Goal**: Experience the configured bot before committing

```
┌────────────────────────────────────────────────────────────────┐
│  Step 6 of 6: Test Drive Alex                                 │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  🎉 Alex is configured! Let's take them for a spin.          │
│                                                                │
│  Choose a test scenario:                                      │
│                                                                │
│  [First Contact] [Frustrated Customer] [Product Question]     │
│  [After Hours] [Escalation] [Free Chat]                       │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  SCENARIO: First Contact                                      │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │  Customer: Hi, I have a question about your product      │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │ 🤖 Alex                                              │ │ │
│  │  │ Hey there! Thanks for reaching out. I'm Alex,       │ │ │
│  │  │ and I'm happy to help! What would you like to       │ │ │
│  │  │ know about our Messaging Platform or Analytics      │ │ │
│  │  │ Dashboard? 😊                                        │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  Customer: How much does it cost?                         │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │ 🤖 Alex                                              │ │ │
│  │  │ Great question! Our pricing depends on your needs.  │ │ │
│  │  │ I'd love to connect you with our team who can give  │ │ │
│  │  │ you accurate pricing based on your specific         │ │ │
│  │  │ situation. Want me to set that up?                  │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  How did that feel?                                           │
│  [👍 Perfect] [🔧 Needs Tweaking] [👎 Start Over]              │
│                                                                │
│                        [Finalize Configuration] →              │
└────────────────────────────────────────────────────────────────┘
```

**Free Chat Mode**: Business owner can type anything and see how Alex responds

---

### Phase 7: Review & Export

**Goal**: Final summary and shareable output

```
┌────────────────────────────────────────────────────────────────┐
│  Configuration Complete!                                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │     🤖 ALEX                                               │ │
│  │     Your Clawdbot for Acme Solutions                     │ │
│  │                                                           │ │
│  │     Personality: Friendly, warm, helpful                  │ │
│  │     Purpose: Customer Support                             │ │
│  │     Skills: Ticket Triage, Sentiment Analysis             │ │
│  │     Integrations: PostHog Analytics                       │ │
│  │     Hours: Business hours (9-5)                           │ │
│  │                                                           │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  What would you like to do?                                   │
│                                                                │
│  [📄 Download Config Summary (PDF)]                           │
│  [📧 Email to Team for Approval]                              │
│  [🚀 Deploy Now] (if ready)                                   │
│  [📋 Copy Configuration JSON]                                  │
│  [✏️ Make Changes]                                             │
│                                                                │
│  ────────────────────────────────────────────────────────────  │
│                                                                │
│  Your configuration has been saved. When your Clawdbot is     │
│  deployed, Alex will be ready to go - no additional setup     │
│  required.                                                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Timing Summary

| Phase | Name | Time |
|-------|------|------|
| 0 | Welcome | 30 sec |
| 1 | Identity | 2-3 min |
| 2 | Personality | 3-4 min |
| 3 | Business Context | 2-3 min |
| 4 | Capabilities | 3-4 min |
| 5 | Boundaries | 2-3 min |
| 6 | Test Drive | 3-5 min |
| 7 | Review | 1-2 min |
| **Total** | | **15-25 min** |

---

## Smart Defaults by Industry

When business owner selects their industry, pre-populate sensible defaults:

### E-commerce
- Personality: Friendly, moderate warmth
- Skills: Order tracking, Returns handling, Product search
- Boundaries: No price matching promises
- Hours: 24/7

### SaaS / Software
- Personality: Professional but approachable
- Skills: Ticket triage, Knowledge base, Bug reporting
- Boundaries: No roadmap commitments
- Hours: Business hours with after-hours acknowledgment

### Healthcare
- Personality: Empathetic, patient, careful
- Skills: Appointment scheduling, FAQ answering
- Boundaries: Never give medical advice, always escalate symptoms
- Hours: Business hours

### Professional Services
- Personality: Professional, thorough
- Skills: Meeting scheduling, Document requests, Intake
- Boundaries: No legal/financial advice
- Hours: Business hours

---

## Mobile-First Considerations

The onboarding should work on mobile devices:
- Single-column layout on mobile
- Large touch targets for personality sliders
- Voice samples playable inline
- Test drive chat works like normal messaging

---

## Save & Resume

Business owners should be able to:
- Save progress at any step
- Resume on different device
- Share in-progress config with stakeholders for input
- Duplicate a config to create variants

---

## Post-Configuration: The Handoff

Once configured, the business owner receives:

1. **Configuration File** (`prebuild-config.json`)
   - Machine-readable configuration for deployment

2. **Summary PDF**
   - Human-readable summary for stakeholders
   - Sample conversations
   - Capability overview

3. **Deployment Instructions**
   - What happens next
   - Timeline expectations
   - How to provide feedback post-launch

4. **Edit Link**
   - Unique URL to return and modify configuration
   - Version history of changes

---

## The Value Proposition

**For the Business Owner:**
> "I configured Alex exactly how I wanted, saw examples of how they'd respond, and when my Clawdbot was deployed, it worked perfectly from day one. No guessing, no back-and-forth, no 'that's not what I meant.'"

**For You (Selling This):**
> "Our Prebuild system lets customers design their AI assistant before deployment. They name it, shape its personality, define its boundaries, and test drive it. When they launch, it's exactly what they envisioned. This reduces support tickets, increases satisfaction, and creates genuine excitement about the product."
