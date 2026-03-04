# Phase 1: Platform Adapters

## Prerequisites
- Phase 0 complete
- OAuth credentials for: Stripe, Google (Drive/Docs/Gmail), Slack, WhatsApp Business

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- src/connectors/adapters/base.ts
- src/connectors/leadsie/types.ts

## Tasks

### Task 1: Leadsie-Native Adapters
Build adapters that use Leadsie-granted access for platforms Leadsie handles natively:

**src/connectors/adapters/meta-ads.adapter.ts**
- Uses Meta Marketing API with Leadsie-granted access
- `pullData()` → campaigns, ad sets, ads, audiences, pixels, spend data (last 90 days)
- Rate limiting: respect Meta API rate limits with exponential backoff

**src/connectors/adapters/google-ads.adapter.ts**
- Uses Google Ads API with Leadsie-granted access
- `pullData()` → campaigns, ad groups, keywords, quality scores, spend (last 90 days)
- GAQL query builder for flexible data pulls

**src/connectors/adapters/google-analytics.adapter.ts**
- GA4 Data API with Leadsie-granted access
- `pullData()` → events, conversions, user properties, traffic sources (last 90 days)
- Detect if UA vs GA4, flag migration status

**src/connectors/adapters/gtm.adapter.ts**
- GTM API with Leadsie-granted access
- `pullData()` → containers, tags, triggers, variables, versions
- Extract tag firing rules and consent configuration

**src/connectors/adapters/shopify.adapter.ts**
- Shopify Admin API with Leadsie-granted access
- `pullData()` → orders, products, customers, abandoned carts, discount codes (last 90 days)
- Revenue metrics and product performance

### Task 2: OAuth Adapters
Build adapters that need custom OAuth flows (Leadsie doesn't cover these natively):

**src/connectors/adapters/stripe.adapter.ts**
- Stripe Connect OAuth flow
- `pullData()` → charges, subscriptions, refunds, disputes, failed payments (last 90 days)
- Revenue metrics, churn signals, payment failure patterns

**src/connectors/adapters/google-drive.adapter.ts**
- Google OAuth2 with Drive scope
- `pullData()` → file inventory, sharing permissions, activity logs
- Identify orphaned files, oversharing, process documentation

**src/connectors/adapters/google-docs.adapter.ts**
- Google OAuth2 with Docs scope
- `pullData()` → document inventory, content analysis, collaboration metrics
- Flag outdated SOPs, brand inconsistencies

**src/connectors/adapters/gmail.adapter.ts**
- Google OAuth2 with Gmail readonly scope
- `pullData()` → email volume, response times, label distribution (metadata only, no body)
- Lead follow-up time analysis, template usage

**src/connectors/adapters/slack.adapter.ts**
- Slack OAuth with channels:history, users:read scopes
- `pullData()` → channel activity, integration inventory, workflow usage
- Communication pattern analysis, tool sprawl detection

**src/connectors/adapters/whatsapp.adapter.ts**
- WhatsApp Cloud API
- `pullData()` → message templates, conversation metrics, automation rules
- Response rate analysis, template performance

### Task 3: Adapter Registry
Build `src/connectors/adapters/registry.ts`:
```typescript
export class AdapterRegistry {
  private adapters: Map<PlatformType, PlatformAdapter<any, any>>;
  register(adapter: PlatformAdapter<any, any>): void;
  get(platform: PlatformType): PlatformAdapter<any, any>;
  getConnected(orgId: string): Promise<PlatformAdapter<any, any>[]>;
}
```

### Task 4: Parallel Data Pull Orchestrator
Build `src/connectors/orchestrator.ts`:
- Given an orgId, get all connected platforms from Leadsie
- Pull data from all connected adapters in parallel (Promise.allSettled)
- Aggregate results into unified `AuditDataBundle`
- Handle partial failures gracefully — audit what we can

### Task 5: Token Management
Build `src/connectors/token-vault.ts`:
- Encrypted storage for OAuth tokens (AES-256-GCM)
- Auto-refresh for Google OAuth tokens
- Stripe webhook for token refresh
- Leadsie tokens don't expire (no refresh needed)

### Task 6: Tests
- Unit tests for each adapter with mocked API responses
- Integration test for orchestrator with 3+ adapters
- Token encryption/decryption round-trip test

## Success Criteria
- [ ] All 11 adapters implement `PlatformAdapter` interface
- [ ] Adapter registry correctly resolves connected platforms
- [ ] Parallel orchestrator pulls from 3+ adapters simultaneously
- [ ] Token vault encrypts/decrypts correctly
- [ ] Partial failures don't crash the pipeline
- [ ] All tests pass

## Completion
```bash
git add -A && git commit -m "Phase 1: 11 platform adapters + orchestrator"
```
