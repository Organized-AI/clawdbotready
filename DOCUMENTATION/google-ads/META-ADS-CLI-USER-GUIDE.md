# Meta Ads CLI — User's Guide

Your AI assistant (Hermes) can manage your Meta/Facebook ad accounts directly through Telegram. Just ask in plain English and it will run the right commands for you.

You can also run commands yourself via SSH if you prefer.

---

## What You Can Do

### 1. List Ad Accounts

See all Meta ad accounts you have access to.

**Ask Hermes:**
> "Show me my Meta ad accounts"
> "List all Facebook ad accounts"

**Direct command:**
```bash
meta-ads-cli accounts
```

---

### 2. List Campaigns

See all campaigns in an account, with optional filtering.

**Ask Hermes:**
> "Show me all campaigns for account 123456789"
> "List active Meta campaigns"
> "Show paused campaigns"

**Direct command:**
```bash
meta-ads-cli campaigns --account-id 123456789
meta-ads-cli campaigns --account-id 123456789 --status ACTIVE
meta-ads-cli campaigns --account-id 123456789 --objective OUTCOME_SALES
```

---

### 3. Performance Report

Get a formatted summary of campaign performance with key metrics.

**Ask Hermes:**
> "Meta ads report for last 7 days"
> "How are my Facebook campaigns performing?"
> "Meta ads report for last 30 days"

**Direct command:**
```bash
meta-ads-cli report --account-id 123456789 --date last_7d
meta-ads-cli report --account-id 123456789 --date last_30d
meta-ads-cli report --account-id 123456789 --date yesterday
```

**Date range options:**
| Option         | What it covers          |
|----------------|------------------------|
| `today`        | Today so far            |
| `yesterday`    | Full previous day       |
| `last_7d`      | Past 7 days             |
| `last_30d`     | Past 30 days            |
| `this_month`   | Current month           |
| `last_month`   | Previous month          |
| `maximum`      | All available data      |

---

### 4. Get Detailed Insights

Drill into performance data with breakdowns and different levels.

**Ask Hermes:**
> "Show Meta ads performance by age group"
> "Breakdown of my Facebook ads by country"
> "Ad set level insights for last 30 days"

**Direct command:**
```bash
meta-ads-cli insights --object-id 123456789 --time-range last_7d
meta-ads-cli insights --object-id 123456789 --breakdown age --time-range last_30d
meta-ads-cli insights --object-id 123456789 --level adset --time-range this_month
```

---

### 5. Create a Campaign

Create a new campaign (always starts as PAUSED for safety).

**Ask Hermes:**
> "Create a Meta traffic campaign called 'Spring Sale'"
> "Set up a new Facebook leads campaign"

**Direct command:**
```bash
meta-ads-cli create-campaign --account-id 123456789 --name "Spring Sale" --objective OUTCOME_TRAFFIC
meta-ads-cli create-campaign --account-id 123456789 --name "Lead Gen Q1" --objective OUTCOME_LEADS --daily-budget 5000
```

**Available objectives:**
| Objective              | Use case                  |
|------------------------|--------------------------|
| OUTCOME_AWARENESS      | Brand awareness & reach   |
| OUTCOME_TRAFFIC        | Website visits            |
| OUTCOME_ENGAGEMENT     | Post engagement           |
| OUTCOME_LEADS          | Lead generation           |
| OUTCOME_SALES          | Conversions & purchases   |
| OUTCOME_APP_PROMOTION  | App installs              |

---

### 6. Update Campaign Status

Pause, activate, or archive campaigns.

**Ask Hermes:**
> "Pause the Spring Sale campaign"
> "Activate campaign 12345"
> "Turn off campaign 67890"

**Direct command:**
```bash
meta-ads-cli update-campaign --campaign-id 12345 --status PAUSED
meta-ads-cli update-campaign --campaign-id 12345 --status ACTIVE
```

---

### 7. Research Targeting

Find interests, locations, and estimate audience sizes.

**Ask Hermes:**
> "Search Meta interests for fitness"
> "How big is the audience for yoga in the US?"
> "Find locations near New York for targeting"

**Direct command:**
```bash
meta-ads-cli search-interests --query "fitness"
meta-ads-cli interest-suggestions --interests "yoga,meditation"
meta-ads-cli audience-size --account-id 123456789 --interests "fitness" --countries US
meta-ads-cli search-locations --query "New York"
```

---

### 8. Manage Creatives & Images

Upload images and create ad creatives.

**Direct command:**
```bash
# Upload an image
meta-ads-cli upload-image --account-id 123456789 --image-path /path/to/image.jpg

# Create a creative with the returned hash
meta-ads-cli create-creative --account-id 123456789 --name "Spring Ad" \
  --image-hash abc123 --page-id 999888777 \
  --link-url "https://example.com" \
  --message "Check out our spring sale!" \
  --headline "Spring Sale" --cta-type SHOP_NOW
```

---

## Tips

- **Just ask naturally.** Hermes understands context. "How are my Meta ads doing?" will get you a report.
- **Specify the account** if you have multiple. Include the account ID or name in your message.
- **All new campaigns start paused.** This prevents accidental spend. Activate when you're ready.
- **Use --json flag** to get raw JSON output for programmatic use.
- **Budget values are in cents** for the Meta API (e.g., $50/day = 5000 cents).

---

## Quick Reference

| What you want                 | Ask Hermes                              | Direct command shorthand                   |
|-------------------------------|-----------------------------------------|--------------------------------------------|
| See all accounts              | "List my Meta ad accounts"              | `accounts`                                 |
| See campaigns                 | "Show Meta campaigns"                   | `campaigns --account-id ID`                |
| Performance report            | "Meta ads report last 7 days"           | `report --account-id ID`                   |
| Detailed insights             | "Meta insights by age"                  | `insights --object-id ID --breakdown age`  |
| Create campaign               | "Create Meta traffic campaign"          | `create-campaign --account-id ID ...`      |
| Pause campaign                | "Pause Meta campaign 123"               | `update-campaign --campaign-id ID --status PAUSED` |
| Search interests              | "Search Meta interests for yoga"        | `search-interests --query yoga`            |
| Estimate audience             | "How big is the fitness audience?"      | `audience-size --account-id ID ...`        |

All direct commands can include `--json` for machine-readable output.
