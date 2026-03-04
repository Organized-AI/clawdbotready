# Phase 5: React Dashboard + Reports

## Prerequisites
- Phase 4 complete (scoring engine produces AuditReport)

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- src/scoring/report-model.ts

## Tasks

### Task 1: React App Setup
```bash
cd src/dashboard
pnpm create vite@latest . -- --template react-ts
pnpm add recharts framer-motion @tanstack/react-query
pnpm add -D tailwindcss @tailwindcss/vite
```

### Task 2: Dashboard Layout
Build main dashboard with sections:
- **Hero Score**: Total opportunity ($X - $Y annually) with animated counter
- **Platform Grid**: Connected platform cards with health scores (red/yellow/green)
- **Opportunity Feed**: Scrollable list of findings sorted by priority
- **Revenue Split**: Donut chart — saving vs generating breakdown
- **Quick Wins**: Top 5 actionable items with "Let OpenClaw Handle This" CTAs

### Task 3: Platform Detail Views
For each connected platform, drill-down page showing:
- Platform health score with breakdown
- All findings with severity indicators
- Impact estimates per finding
- Recommended actions with OpenClaw agent mapping
- Before/after projections

### Task 4: Opportunity Detail Modal
Clicking any finding opens a modal with:
- Detailed explanation of the issue
- Evidence (data points, screenshots, metrics)
- Impact calculation methodology
- Recommended fix and effort estimate
- "Deploy OpenClaw Agent" CTA with agent details

### Task 5: Real-Time Audit Progress
WebSocket connection showing:
- Which platforms are being audited (progress bars)
- Findings appearing in real-time as engines complete
- Total opportunity updating as scores come in
- Estimated time remaining

### Task 6: Report Export
Build `src/reports/pdf-generator.ts`:
- Generate PDF from AuditReport data
- Executive summary page with total opportunity
- Per-platform breakdown pages
- Prioritized recommendations
- OpenClaw agent proposal appendix
- Branded with OpenClaw styling

### Task 7: Shareable Link
- Generate unique share URL per audit: `/audit/{auditId}`
- Optional password protection
- Auto-expire after 30 days
- Track views for sales follow-up

### Task 8: API Routes
Add Fastify routes:
- `GET /api/audit/:orgId` — Full audit report JSON
- `GET /api/audit/:orgId/platforms` — Platform list with scores
- `GET /api/audit/:orgId/opportunities` — Sorted opportunities
- `GET /api/audit/:orgId/export/pdf` — Download PDF
- `WS /ws/audit/:orgId` — Real-time audit progress

### Task 9: Tests
- Dashboard renders with mock AuditReport
- Platform cards show correct health colors
- Opportunity list is correctly sorted
- PDF export generates valid PDF
- WebSocket connection handles reconnection

## Success Criteria
- [ ] Dashboard loads and displays all sections
- [ ] Platform drill-down shows per-platform findings
- [ ] Real-time progress works via WebSocket
- [ ] PDF export produces professional report
- [ ] Share link works with auth
- [ ] All API routes return correct data
- [ ] Tests pass

## Completion
```bash
git add -A && git commit -m "Phase 5: React dashboard + PDF reports + share links"
```
