## meta-ads-cli

Meta/Facebook Marketing API CLI tool. Manages ad accounts, campaigns, ad sets, ads, creatives, insights, and targeting research.

### Account Commands
- `meta-ads-cli accounts` — List all ad accounts
- `meta-ads-cli account-info --account-id ID` — Detailed account info
- `meta-ads-cli account-pages --account-id ID` — Pages for an account

### Campaign Commands
- `meta-ads-cli campaigns --account-id ID [--status ACTIVE|PAUSED] [--limit N]` — List campaigns
- `meta-ads-cli campaign-details --campaign-id ID` — Single campaign details
- `meta-ads-cli create-campaign --account-id ID --name NAME --objective OBJ [--daily-budget CENTS] [--status PAUSED]` — Create campaign
  - Objectives: OUTCOME_AWARENESS, OUTCOME_TRAFFIC, OUTCOME_ENGAGEMENT, OUTCOME_LEADS, OUTCOME_SALES, OUTCOME_APP_PROMOTION
- `meta-ads-cli update-campaign --campaign-id ID [--name N] [--status S] [--daily-budget CENTS]` — Update campaign

### Ad Set Commands
- `meta-ads-cli adsets --account-id ID [--campaign-id CID] [--limit N]` — List ad sets
- `meta-ads-cli adset-details --adset-id ID` — Single ad set details
- `meta-ads-cli create-adset --account-id ID --campaign-id CID --name N --optimization-goal GOAL --billing-event EVENT [--daily-budget CENTS] [--targeting JSON]` — Create ad set
- `meta-ads-cli update-adset --adset-id ID [--status S] [--daily-budget CENTS]` — Update ad set

### Ad Commands
- `meta-ads-cli ads --account-id ID [--campaign-id CID] [--adset-id AID] [--limit N]` — List ads
- `meta-ads-cli ad-details --ad-id ID` — Single ad details
- `meta-ads-cli creatives --ad-id ID` — Creative details for an ad
- `meta-ads-cli create-ad --account-id ID --name N --adset-id AID --creative-id CID [--status PAUSED]` — Create ad
- `meta-ads-cli update-ad --ad-id ID [--status S]` — Update ad

### Creative & Image Commands
- `meta-ads-cli upload-image --account-id ID --image-path PATH [--name N]` — Upload image, get hash
- `meta-ads-cli create-creative --account-id ID --name N --image-hash H --page-id PID --link-url URL --message MSG [--headline HL] [--cta-type CTA]` — Create creative

### Insights & Reporting
- `meta-ads-cli insights --object-id ID [--time-range RANGE] [--breakdown TYPE] [--level LEVEL]` — Performance metrics
  - Time ranges: today, yesterday, last_7d, last_30d, this_month, last_month, maximum, or YYYY-MM-DD:YYYY-MM-DD
  - Breakdowns: age, gender, country, device_platform, publisher_platform
  - Levels: account, campaign, adset, ad
- `meta-ads-cli report --account-id ID [--date RANGE]` — Formatted performance report

### Targeting Research
- `meta-ads-cli search-interests --query Q [--limit N]` — Search interest targeting
- `meta-ads-cli interest-suggestions --interests "a,b,c" [--limit N]` — Related interests
- `meta-ads-cli audience-size --account-id ID [--interests LIST] [--countries US,GB] [--age-min N] [--age-max N]` — Estimate audience size
- `meta-ads-cli search-locations --query Q [--type city|region|country] [--limit N]` — Search locations

### Auth
- `meta-ads-cli login [--app-id ID] [--app-secret SECRET]` — Run OAuth flow
- `meta-ads-cli token-status` — Check token validity

### Global Options
- `--json` — Output raw JSON instead of formatted tables
- `--verbose` — Show detailed output

### Notes
- Budget amounts are in cents (e.g., $50/day = 5000)
- All create commands default to PAUSED status for safety
- Account IDs are auto-prefixed with act_ if needed
- Add `--json` for machine-readable output
