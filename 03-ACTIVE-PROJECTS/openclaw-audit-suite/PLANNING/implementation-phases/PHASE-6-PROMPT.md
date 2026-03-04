# Phase 6: Agent Proposal Builder + Sales Flow

## Prerequisites
- Phase 5 complete (dashboard + reports functional)

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- src/scoring/agent-mapper.ts
- Omni x OpenClaw Gap Analysis PDF (reference for agent coverage)

## Tasks

### Task 1: Proposal Generator
Build `src/proposals/generator.ts`:
- Given AuditReport, generate tailored OpenClaw deployment proposal
- Group opportunities by agent:
  - Campaign Orchestrator (80% ready) → immediate deployment
  - Attribution Engine (50% ready) → phased deployment
  - Analytics & Reporting (45% ready) → build required
  - Budget Optimizer (25% ready) → significant build
  - etc.
- Calculate total implementation scope vs total opportunity

### Task 2: ROI Projection Model
Build `src/proposals/roi-projection.ts`:
- Month-by-month ROI projection based on phased deployment
- Account for ramp-up time per agent
- Show cumulative savings + revenue vs implementation cost
- Breakeven point calculation
- Conservative / moderate / aggressive scenarios

### Task 3: Agent Deployment Plans
Build `src/proposals/deployment-plans.ts`:
For each recommended agent, generate:
```typescript
{
  agentName: string;
  currentCoverage: number;      // from gap analysis
  buildRequired: string[];      // new plugins needed
  opportunitiesAddressed: ScoredFinding[];
  estimatedROI: { monthly: number; annual: number };
  prerequisites: string[];
  deploymentOrder: number;
}
```

### Task 4: Interactive Proposal Dashboard
Add to React dashboard:
- "Your Custom OpenClaw Plan" section
- Agent deployment timeline (Gantt-style)
- ROI curve visualization
- "Start with Quick Wins" → immediate agent deployment
- "Full Suite" → complete OpenClaw deployment
- "Custom" → pick and choose agents

### Task 5: Sales Handoff
Build `src/proposals/sales-handoff.ts`:
- Generate CRM-ready lead data:
  - Company name, platforms connected, total opportunity
  - Top 3 quick wins with dollar amounts
  - Recommended deployment tier (Starter/Growth/Enterprise)
  - Audit engagement score (how much they explored the dashboard)
- Webhook to push to CRM (HubSpot/Salesforce compatible)

### Task 6: "I Don't Know the Use Case" Responder
Build `src/proposals/use-case-generator.ts`:
- For each connected platform, generate specific use case narrative:
  ```
  "Your Meta Ads account is spending $X/mo with 23% going to audiences
  that overlap by >40%. OpenClaw's Campaign Orchestrator can automatically
  deduplicate audiences and redirect $Y/mo to your best-performing segments,
  projected to generate an additional $Z in revenue."
  ```
- Personalized to their actual data, not generic
- Each use case links to the specific finding and agent

### Task 7: Tests
- Proposal generator produces valid proposals for various audit profiles
- ROI projection math is correct
- Use case generator produces personalized narratives
- Sales handoff formats data correctly

## Success Criteria
- [ ] Proposals are generated from real audit data
- [ ] ROI projections include month-by-month breakdown
- [ ] Each opportunity maps to a specific agent deployment
- [ ] Use case narratives reference actual customer metrics
- [ ] Sales handoff pushes to CRM webhook
- [ ] Tests pass

## Completion
```bash
git add -A && git commit -m "Phase 6: Agent proposal builder + sales flow + use case generator"
```
