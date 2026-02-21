## google-ads-mcp (MCP Server)

Google Ads management with full read AND write access to the Google Ads API. Supports **multiple ad accounts** under the MCC (Manager Customer Center). You can view data, analyze performance, AND make changes to ANY accessible account including creating campaigns, updating budgets, adding keywords, and managing ads.

### Multi-Account Access

All tools accept an optional `customerId` parameter. If omitted, the default account is used.

**Workflow: Discover accounts → target specific account**

1. Call `list_accessible_customers` to see ALL accounts under the MCC
2. Note the `id` of the account you want to work with
3. Pass that `id` as `customerId` to any other tool

Example: To list campaigns for account 1234567890:
```json
{ "customerId": "1234567890" }
```

If `customerId` is omitted, all tools operate on the default account (GOOGLE_ADS_CUSTOMER_ID env var).

### READ Operations (View & Analyze)

#### Account Discovery
- `list_accessible_customers` — List ALL Google Ads accounts under the MCC. Call this FIRST to discover account IDs.
- `get_account_hierarchy` — Show manager/client relationships
- `get_account_info` — Detailed info for a specific account (requires `customerId`)
- `list_manager_accounts` — List MCC relationships

#### Campaigns
- `list_campaigns` — List all campaigns with metrics. Optional: `customerId`, `limit`, `dateRange`
- `get_campaign` — Get specific campaign by ID. Required: `campaignId`

#### Ad Groups
- `list_ad_groups` — List ad groups. Optional: `customerId`, `campaignId`, `limit`
- `get_ad_group` — Get specific ad group. Required: `adGroupId`

#### Ads
- `list_ads` — List ads with metrics. Optional: `customerId`, `adGroupId`, `campaignId`
- `get_ad_performance` — Ad performance. Required: `adId`, `adGroupId`

#### Keywords
- `list_keywords` — List keywords with metrics. Optional: `customerId`, `campaignId`, `adGroupId`
- `get_keyword_performance` — Keyword performance. Required: `keywordId`, `adGroupId`

#### Performance Reports
- `get_account_performance` — Account-level metrics. Optional: `customerId`, `dateRange`, `segmentByDate`
- `get_campaign_performance` — Campaign metrics. Required: `campaignId`
- `get_ad_group_performance` — Ad group metrics. Optional: `customerId`, `campaignId`
- `get_search_terms_report` — Search terms report. Optional: `customerId`, `campaignId`

#### Analytics
- `get_top_bottom_keywords` — Best/worst keywords by metric. Required: `metric`
- `get_keyword_opportunities` — Keyword suggestions based on search terms
- `get_campaign_comparison` — Compare all campaigns side-by-side

#### Conversions
- `list_conversion_actions` — List all conversion actions
- `get_conversion_stats` — Conversion statistics

#### Shopping
- `get_product_performance` — Product metrics for shopping campaigns
- `get_product_partition_performance` — Partition metrics. Required: `adGroupId`
- `get_top_bottom_products` — Best/worst products. Required: `metric`

### WRITE Operations (Create & Modify)

You ARE authorized to use these write tools. They make real changes to the Google Ads account.

All write tools also accept optional `customerId` to target a specific account.

#### Create Campaigns
`create_campaign` — Creates a new campaign.
- Required: `name`, `budget`, `advertisingChannelType`
- Default status is **PAUSED** so it won't spend money until explicitly enabled.

#### Update Campaigns
`update_campaign` — Change name, status, or budget.
- Required: `campaignId`
- Optional: `name`, `status` (ENABLED/PAUSED/REMOVED), `budget`

#### Create Ad Groups
`create_ad_group` — Create a new ad group.
- Required: `campaignId`, `name`
- Optional: `cpcBidMicros`, `status`

#### Update Ad Groups
`update_ad_group` — Change name, status, or bids.
- Required: `adGroupId`

#### Create Ads
`create_responsive_search_ad` — Create a responsive search ad.
- Required: `adGroupId`, `headlines` (3-15), `descriptions` (2-4), `finalUrls`

#### Update Ads
`update_ad` — Change ad status.
- Required: `adId`, `adGroupId`

#### Add Keywords
`add_keywords` — Add keywords to an ad group.
- Required: `adGroupId`, `keywords` (array with `text` and `matchType`)

#### Add Negative Keywords
`add_negative_keywords` — Add negative keywords.
- Required: `keywords`
- One of: `campaignId` or `adGroupId`

#### Update Keywords
`update_keyword` — Change keyword status or bid.
- Required: `keywordId`, `adGroupId`

#### Create Conversion Actions
`create_conversion_action` — Set up conversion tracking.
- Required: `name`, `category`

#### Update Conversion Actions
`update_conversion_action` — Modify conversion action settings.
- Required: `conversionActionId`

### Important Notes

- **Multi-account**: Call `list_accessible_customers` first, then pass `customerId` to target any account
- New campaigns are created in **PAUSED** status by default (safe — won't spend money)
- All write operations take effect immediately on the Google Ads account
- Budget values are in the account's currency (e.g., USD)
- Match types for keywords: EXACT, PHRASE, BROAD
- CPC bid values are in micros (1,000,000 = $1.00)
