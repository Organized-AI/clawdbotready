# Phase 2: Ad Platform Audit Engines

## Prerequisites
- Phase 1 complete (all adapters functional)
- Read existing Data Audit Skill patterns from Clawdbot Ready

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- src/engines/base.ts
- src/connectors/adapters/ (all adapters)

## Tasks

### Task 1: Meta Ads Audit Engine
Build `src/engines/meta-ads.engine.ts`:

**Revenue Saving Checks:**
- Wasted spend detection: ads with spend > $50 and 0 conversions (last 30d)
- Audience overlap: campaigns targeting >40% overlapping audiences
- Creative fatigue: ads with >3x frequency and declining CTR
- Broad targeting waste: ad sets with <1% CTR on broad audiences
- Placement waste: placements with CPA >2x average
- Dayparting gaps: hours with spend but zero conversions

**Revenue Generating Opportunities:**
- Lookalike expansion: high-ROAS audiences without lookalike variants
- Retargeting gaps: website visitors not in any retargeting audience
- Catalog ads: product catalog connected but no DPA campaigns
- Advantage+ opportunities: accounts without ASC campaigns
- Creative format gaps: only using static when video performs 2x better

### Task 2: Google Ads Audit Engine
Build `src/engines/google-ads.engine.ts`:

**Revenue Saving Checks:**
- Quality Score gaps: keywords with QS < 5 consuming >10% of budget
- Negative keyword gaps: search terms with >$100 spend and 0 conversions
- Bid waste: CPC > industry benchmark with no conversion lift
- Network waste: Search Partners or Display with CPA >3x Search
- Match type waste: broad match terms with poor conversion rates
- Device bid gaps: devices with CPA >2x average without bid adjustments

**Revenue Generating Opportunities:**
- PMax migration: eligible campaigns not using Performance Max
- RLSA gaps: high-intent audiences not applied to search campaigns
- Extension gaps: missing sitelinks, callouts, structured snippets
- Conversion action gaps: micro-conversions not being tracked
- Smart bidding: manual CPC campaigns that could use tROAS/tCPA

### Task 3: Google Analytics Audit Engine
Build `src/engines/google-analytics.engine.ts`:

**Revenue Saving Checks:**
- Broken events: events configured but not firing (last 7d)
- Attribution gaps: conversions without source attribution (direct > 40%)
- Data quality: high bounce rate pages (>80%) indicating UX issues
- Referral spam: suspicious traffic sources inflating metrics

**Revenue Generating Opportunities:**
- Audience creation: high-value segments not exported to Google Ads
- Enhanced ecommerce gaps: purchase funnel stages not tracked
- Engagement signals: engaged users not in remarketing lists
- Cross-domain tracking: multi-domain journeys not stitched

### Task 4: GTM Audit Engine
Build `src/engines/gtm.engine.ts`:

**Revenue Saving Checks:**
- Redundant tags: duplicate GA/Meta/conversion tags
- Performance drag: tags without proper trigger conditions (fire on all pages)
- Consent violations: tags firing before consent grant
- Broken triggers: triggers referencing removed dataLayer variables
- Version bloat: unpublished workspace changes >30 days old

**Revenue Generating Opportunities:**
- Server-side migration: client-side tags that should move to sGTM
- Enhanced conversions: not sending hashed user data
- Consent mode v2: not implemented (required for EU)
- Custom event gaps: form submissions/scroll depth not tracked

### Task 5: Shopify Audit Engine
Build `src/engines/shopify.engine.ts`:

**Revenue Saving Checks:**
- Abandoned cart recovery: no automated recovery emails/flows
- Discount abuse: codes used >100x or stacking patterns
- Dead inventory: products with 0 sales in 90 days still active
- Shipping cost leaks: free shipping thresholds below AOV

**Revenue Generating Opportunities:**
- Upsell/cross-sell: no post-purchase offers configured
- Subscription opportunity: repeat purchases without subscription option
- Bundle pricing: frequently co-purchased items not bundled
- Loyalty gaps: no points/rewards program

### Task 6: Shared Audit Utilities
Build `src/engines/utils/`:
- `benchmarks.ts` — Industry benchmark data for comparison
- `scoring.ts` — Standardized opportunity scoring (implements OpportunityScore)
- `formatters.ts` — Currency, percentage, metric formatters
- `thresholds.ts` — Configurable alert thresholds per platform

### Task 7: Tests
- Each engine with realistic mock data
- Verify findings are correctly categorized (saving vs generating)
- Verify impact estimates are reasonable
- Edge cases: empty data, partial data, API errors

## Success Criteria
- [ ] All 5 ad/commerce platform engines produce typed findings
- [ ] Each finding has category, confidence, estimated impact, effort, and agent mapping
- [ ] Engines handle empty/partial data gracefully
- [ ] Benchmarks are sourced and documented
- [ ] All tests pass

## Completion
```bash
git add -A && git commit -m "Phase 2: Ad platform audit engines (Meta, Google, GA, GTM, Shopify)"
```
