# Google Ads CLI v3.0.0 — Full CRUD (Meta Ads Parity)

**22 commands** across 9 source files. Zero TypeScript errors.

## Command Reference

### Account Commands (`accounts.ts`)

| Command | Alias | Type | Meta Equivalent |
|---------|-------|------|-----------------|
| `account-info` | `info` | Read | `account-info` |
| `list-accounts` | `accounts` | Read | `accounts` |
| `account-summary` | `summary` | Read | `report` |

### Campaign Commands (`list-campaigns.ts`, `manage-campaign.ts`, `update-budget.ts`)

| Command | Alias | Type | Meta Equivalent |
|---------|-------|------|-----------------|
| `list-campaigns` | `campaigns` | Read | `campaigns` |
| `create-campaign` | `create` | Write | `create-campaign` |
| `update-campaign` | - | Write | `update-campaign` |
| `pause-campaign` | `pause` | Write | (part of update-campaign) |
| `enable-campaign` | `enable` | Write | (part of update-campaign) |
| `update-budget` | `budget` | Write | (part of update-campaign) |

### Reporting Commands (`get-cpa-metrics.ts`, `generate-report.ts`)

| Command | Alias | Type | Meta Equivalent |
|---------|-------|------|-----------------|
| `get-cpa-metrics` | `cpa` | Read | `insights` |
| `generate-report` | `report` | Read | `report` |

### Ad Group Commands (`adgroups.ts`) — Meta = Ad Sets

| Command | Alias | Type | Meta Equivalent |
|---------|-------|------|-----------------|
| `list-adgroups` | `adgroups` | Read | `adsets` |
| `adgroup-details` | - | Read | `adset-details` |
| `create-adgroup` | - | Write | `create-adset` |
| `update-adgroup` | - | Write | `update-adset` |

### Ad Commands (`ads.ts`) — Meta = Ads

| Command | Alias | Type | Meta Equivalent |
|---------|-------|------|-----------------|
| `list-ads` | `ads` | Read | `ads` |
| `ad-details` | - | Read | `ad-details` |
| `create-rsa` | - | Write | `create-ad` |
| `update-ad` | - | Write | `update-ad` |

### Keyword Commands (`keywords.ts`) — Meta = Targeting

| Command | Alias | Type | Meta Equivalent |
|---------|-------|------|-----------------|
| `list-keywords` | `keywords` | Read | (targeting in adset) |
| `add-keyword` | - | Write | (part of create-adset) |
| `add-keywords` | - | Write | (bulk targeting) |
| `remove-keyword` | - | Write | (part of update-adset) |

---

## Parity Comparison

| Feature Area | Meta Ads CLI | Google Ads CLI | Notes |
|-------------|-------------|----------------|-------|
| Accounts | 3 commands | 3 commands | Parity |
| Campaigns | 4 commands | 6 commands | Google has dedicated pause/enable/budget |
| Ad Sets / Ad Groups | 4 commands | 4 commands | Parity |
| Ads | 4 commands | 4 commands | Google uses RSA instead of creative+ad |
| Targeting / Keywords | 4 commands | 4 commands | Different paradigm (keywords vs interests) |
| Insights / Reports | 2 commands | 2 commands | Parity |
| Creatives / Assets | 3 commands | - | Not ported (Google embeds creatives in ads) |
| Auth | 2 commands | - | Google uses config file, Meta uses OAuth flow |
| **Total** | **26** | **22** | Missing: creatives (N/A), auth (config-based) |

---

## File Structure

```
src/
├── index.ts                  # CLI entry point — 22 commands registered
├── lib/
│   ├── client.ts             # Google Ads API wrapper (OAuth2, GAQL)
│   └── format.ts             # Output formatting (tables, headers, currency)
└── commands/
    ├── accounts.ts           # Account info, list, summary
    ├── list-campaigns.ts     # List campaigns with filtering
    ├── get-cpa-metrics.ts    # CPA metrics with date ranges
    ├── generate-report.ts    # Full performance report
    ├── update-budget.ts      # Budget mutations with --dry-run
    ├── manage-campaign.ts    # Create, update, pause, enable campaigns
    ├── adgroups.ts           # Ad group CRUD
    ├── ads.ts                # Ad CRUD (responsive search ads)
    └── keywords.ts           # Keyword add/remove/list
```

## Deployment

```bash
# Copy to Mac Mini
scp -r src/ dist/ package.json tsconfig.json openclaw@100.66.145.48:~/google-ads-cli/

# Install and build on Mac Mini
ssh openclaw@100.66.145.48 'cd ~/google-ads-cli && npm install && npm run build && npm link'

# Verify
ssh openclaw@100.66.145.48 'google-ads-cli --help'
```
