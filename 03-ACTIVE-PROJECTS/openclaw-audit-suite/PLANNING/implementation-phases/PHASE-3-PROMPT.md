# Phase 3: Business Platform Audit Engines

## Prerequisites
- Phase 2 complete
- OAuth access to Stripe, Gmail, Slack, Google Drive/Docs, WhatsApp

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- src/engines/base.ts
- src/engines/utils/ (scoring, benchmarks)

## Tasks

### Task 1: Stripe Audit Engine
Build `src/engines/stripe.engine.ts`:

**Revenue Saving Checks:**
- Failed payment recovery: involuntary churn from expired cards (no dunning)
- Refund patterns: products/plans with >5% refund rate
- Dispute rate: approaching 1% threshold (Stripe penalty zone)
- Fee optimization: not using optimal pricing (flat vs tiered vs graduated)
- Subscription downgrades: users downgrading without intervention

**Revenue Generating Opportunities:**
- Annual pricing gap: only monthly plans, no annual discount incentive
- Trial-to-paid conversion: trial users not getting onboarding nudges
- Expansion revenue: no usage-based pricing or add-on structure
- Payment method variety: only cards, no ACH/SEPA for B2B
- Price localization: single currency for multi-region customers

### Task 2: Gmail Audit Engine
Build `src/engines/gmail.engine.ts`:

**Revenue Saving Checks:**
- Lead response time: >4 hours avg response to inbound leads
- Follow-up gaps: leads contacted once then abandoned
- Email deliverability: high bounce rate on outbound
- Template stagnation: same templates used for >6 months

**Revenue Generating Opportunities:**
- Automation gaps: repetitive email patterns that could be templated
- Lead scoring signals: email engagement patterns indicating purchase intent
- Sequence gaps: no multi-touch follow-up sequences
- Segmentation: mass sends without personalization

### Task 3: Slack Audit Engine
Build `src/engines/slack.engine.ts`:

**Revenue Saving Checks:**
- Tool sprawl: >20 integrations, many unused
- Channel noise: channels with <1 message/week but 50+ members
- Workflow bottlenecks: channels where avg response time >2 hours
- License waste: users who haven't logged in >30 days

**Revenue Generating Opportunities:**
- Customer channel gaps: no shared channels with key accounts
- Automation potential: repetitive manual workflows in channels
- Knowledge capture: valuable discussions not being documented
- Integration gaps: CRM/helpdesk not connected to Slack

### Task 4: Google Drive Audit Engine
Build `src/engines/google-drive.engine.ts`:

**Revenue Saving Checks:**
- Oversharing: files shared with "anyone with link" containing sensitive data
- Storage waste: large files not accessed in 1+ year
- Orphaned files: files with no owner (departed employees)
- Version sprawl: "v2", "v3", "FINAL", "FINAL_FINAL" naming patterns

**Revenue Generating Opportunities:**
- SOP gaps: operational processes without documentation
- Template standardization: similar docs recreated repeatedly
- Client deliverable quality: inconsistent formatting/branding
- Knowledge base potential: tribal knowledge not documented

### Task 5: Google Docs Audit Engine
Build `src/engines/google-docs.engine.ts`:

**Revenue Saving Checks:**
- Outdated SOPs: documents not updated in 6+ months with active processes
- Brand inconsistency: documents using old logos, colors, or messaging
- Compliance gaps: policies not reviewed within required timeframes

**Revenue Generating Opportunities:**
- Content repurposing: internal docs that could become blog posts/guides
- SEO content gaps: topics with search volume not covered in docs
- Proposal templates: no standardized proposal/pitch templates
- Process automation: documented manual processes ripe for automation

### Task 6: WhatsApp Business Audit Engine
Build `src/engines/whatsapp.engine.ts`:

**Revenue Saving Checks:**
- Template rejection rate: high rejection rate wasting dev time
- Conversation cost: unnecessary 24hr window reopens
- Manual response overhead: messages that should be automated

**Revenue Generating Opportunities:**
- Catalog integration: WhatsApp catalog not connected to Shopify
- Abandoned cart flows: no WhatsApp recovery messages
- Post-purchase engagement: no review/upsell messages via WhatsApp
- Lead qualification: no chatbot for initial lead screening

### Task 7: Cross-Platform Pattern Detection
Build `src/engines/cross-platform.engine.ts`:
- **Data silos**: platforms not sharing data (e.g., Shopify events not in GA)
- **Attribution gaps**: Stripe revenue not matched to ad platform conversions
- **Communication-to-conversion**: Slack/email patterns that correlate with deals
- **Process disconnects**: manual handoffs between platforms that could be automated

### Task 8: Tests
- Each engine with realistic mock data
- Cross-platform detection with multi-platform data bundles
- Privacy-safe: ensure Gmail/Slack engines only analyze metadata

## Success Criteria
- [ ] All 6 business platform engines produce typed findings
- [ ] Cross-platform engine detects patterns across 3+ platform combinations
- [ ] Gmail and Slack engines are metadata-only (no message body access)
- [ ] Every finding maps to an OpenClaw agent capability
- [ ] All tests pass

## Completion
```bash
git add -A && git commit -m "Phase 3: Business platform audit engines (Stripe, Gmail, Slack, Drive, Docs, WhatsApp)"
```
