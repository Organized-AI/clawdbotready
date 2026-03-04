# Phase 4: Opportunity Scoring & Revenue Engine

## Prerequisites
- Phase 2-3 complete (all audit engines functional)

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- src/engines/base.ts (OpportunityScore interface)
- src/engines/utils/scoring.ts

## Tasks

### Task 1: Revenue Impact Calculator
Build `src/scoring/impact-calculator.ts`:
- Input: platform data + finding type
- Output: low/mid/high USD annual impact estimate
- Use actual spend data, conversion rates, and industry benchmarks
- **Revenue Saving**: calculate based on current waste × recovery rate
- **Revenue Generating**: calculate based on TAM × conversion lift × probability

Example calculations:
```
Wasted ad spend: $X spend with 0 conversions → saving = $X × 0.7 (recoverable %)
Quality Score gaps: keywords at QS 3→7 = ~30% CPC reduction → saving = current spend × 0.3
Abandoned cart recovery: AOV × abandoned carts × 10-15% recovery rate → revenue
Lookalike expansion: current ROAS × additional budget capacity → revenue
```

### Task 2: Effort Estimator
Build `src/scoring/effort-estimator.ts`:
- Maps each finding type to implementation effort
- Considers whether OpenClaw already has the agent capability (from Omni gap analysis)
- Categories: `quick_win` (<1 sprint), `moderate` (1-2 sprints), `significant` (3+ sprints)
- Factors: existing coverage %, API complexity, custom build required

### Task 3: Priority Ranker
Build `src/scoring/priority-ranker.ts`:
- Composite score: `(impact_mid × confidence × urgency) / effort_weight`
- Urgency factors: compliance deadlines, seasonal revenue, competitive risk
- Output: ranked list of opportunities sorted by ROI
- Group into: "Quick Wins", "High Impact", "Strategic", "Nice to Have"

### Task 4: Opportunity Aggregator
Build `src/scoring/aggregator.ts`:
- Combine findings across all engines
- Deduplicate overlapping opportunities (e.g., GA tracking gap = GTM fix)
- Calculate total portfolio: "Your audit found $X-$Y in annual opportunity"
- Split into revenue saving vs generating totals

### Task 5: OpenClaw Agent Mapper
Build `src/scoring/agent-mapper.ts`:
- Map every opportunity type to the specific OpenClaw agent/plugin that solves it
- Reference the Omni x OpenClaw gap analysis coverage %
- For each opportunity, output:
  ```typescript
  {
    agentName: 'Campaign Orchestrator',
    pluginName: 'meta-campaign-plugin',
    coverage: 0.80,
    needsToBuild: ['Campaign Sync'],
    estimatedDeployment: 'quick_win' | 'moderate' | 'significant'
  }
  ```

### Task 6: Audit Report Model
Build `src/scoring/report-model.ts`:
```typescript
export interface AuditReport {
  orgId: string;
  connectedPlatforms: PlatformType[];
  auditedAt: Date;
  totalOpportunity: { low: number; mid: number; high: number };
  revenueSaving: { total: number; findings: ScoredFinding[] };
  revenueGenerating: { total: number; findings: ScoredFinding[] };
  quickWins: ScoredFinding[];
  highImpact: ScoredFinding[];
  platformScores: Map<PlatformType, PlatformHealthScore>;
  agentProposals: AgentProposal[];
}
```

### Task 7: Tests
- Impact calculator with known inputs → expected range
- Priority ranker ordering is correct
- Aggregator deduplication works across platforms
- Agent mapper covers all finding types

## Success Criteria
- [ ] Revenue impact calculator produces ranges for all finding types
- [ ] Priority ranker correctly orders by composite ROI score
- [ ] Aggregator produces a single unified AuditReport
- [ ] Agent mapper connects every finding to an OpenClaw capability
- [ ] Total opportunity estimate is defensible (based on real data)
- [ ] All tests pass

## Completion
```bash
git add -A && git commit -m "Phase 4: Opportunity scoring & revenue engine"
```
