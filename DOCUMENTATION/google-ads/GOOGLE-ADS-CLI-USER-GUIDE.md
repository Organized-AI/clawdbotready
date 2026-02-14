# Google Ads CLI v2 — User's Guide

Your AI assistant (Hermes) can manage your Google Ads accounts directly through Telegram. Just ask in plain English and it will run the right commands for you.

You can also run commands yourself via SSH if you prefer.

To see this guide anytime, ask Hermes: **"Show me the Google Ads guide"** or run `google-ads-cli guide`.

---

## Your Accounts

| Account Name                        | Customer ID  |
|-------------------------------------|-------------|
| **Blade** (default)                 | 1741833734  |
| Advanced Muscle Mechanics           | 7375860000  |
| Amour de Moi Skin                   | 6347162444  |
| BiOptimizers - Gallant Seto Account | 7994854565  |
| Civics Unplugged                    | 9134716978  |
| Dirty Saint                         | 4066741641  |
| Essence                             | 6193843225  |
| Heather Rae Essentials              | 4925579831  |
| Myosin - Foundation Law             | 6111060860  |
| Myosin - MVA Funnel                 | 1729599101  |
| Myosin - Mass Tort Law              | 6650090207  |
| Myosin Wonder Video Temp            | 5059244248  |
| RTT (Marisa Peer)                   | 2290369257  |
| Teleios Health                      | 6890103064  |

If you don't specify an account, **Blade** is used by default.

---

## What You Can Do

### 1. List Campaigns

See all campaigns in an account, optionally filtered by name.

**Ask Hermes:**
> "Show me all Blade campaigns"
> "List active campaigns for Teleios Health"
> "Show PMAX campaigns"

**Direct command:**
```bash
google-ads-cli campaigns --customer-id 1741833734
google-ads-cli campaigns --customer-id 1741833734 --filter PMAX
google-ads-cli campaigns --customer-id 1741833734 --active-only
```

Use `--active-only` to show only running campaigns (hides paused ones).
Use `--json` for machine-readable output.

---

### 2. Get CPA Metrics

Check cost-per-acquisition performance across your campaigns.

**Ask Hermes:**
> "What's the CPA for Blade today?"
> "Show me Blade CPA for the last 7 days"
> "Teleios Health CPA last 30 days"
> "CPA for active campaigns only"

**Direct command:**
```bash
google-ads-cli cpa --customer-id 1741833734 --date TODAY
google-ads-cli cpa --customer-id 1741833734 --date LAST_7_DAYS --active-only
google-ads-cli cpa --customer-id 1741833734 --date LAST_30_DAYS --json
```

**Date range options:**
| Option         | What it covers         |
|----------------|------------------------|
| `TODAY`        | Today so far           |
| `YESTERDAY`    | Full previous day      |
| `LAST_7_DAYS`  | Past 7 days            |
| `LAST_30_DAYS` | Past 30 days           |

---

### 3. Generate a Performance Report

Get a formatted summary of campaign performance with key metrics.

**Ask Hermes:**
> "Generate a report for Blade last 7 days"
> "Performance report for active campaigns"
> "Weekly report for Teleios Health"

**Direct command:**
```bash
google-ads-cli report --customer-id 1741833734 --date LAST_7_DAYS
google-ads-cli report --customer-id 1741833734 --active-only
google-ads-cli report --customer-id 6890103064 --date YESTERDAY --json
```

The default date range is `LAST_7_DAYS` if you don't specify one.

---

### 4. Update a Campaign Budget

Change the daily budget for a specific campaign. Amounts are in **dollars**.

**Ask Hermes:**
> "Set the BLADE_PMAX_USA budget to $500 per day"
> "Change the airport transfers campaign budget to $300"

**Direct command:**
```bash
# Preview the change first (recommended)
google-ads-cli budget --customer-id 1741833734 --campaign-id 21446287821 --amount 500 --dry-run

# Apply it
google-ads-cli budget --customer-id 1741833734 --campaign-id 21446287821 --amount 500
```

The `--amount` flag takes **dollars** (not micros). `--amount 500` means $500/day.

Use `--dry-run` first to preview changes before applying them.

---

### 5. Pause or Enable a Campaign

Control whether a campaign is running or paused.

**Ask Hermes:**
> "Pause the BLADE_PMAX_HPN campaign"
> "Enable the BLADEone Performance Max campaign"
> "Turn off the airport transfers campaign"

**Direct command:**
```bash
# Pause a campaign
google-ads-cli manage pause --customer-id 1741833734 --campaign-id 23168756345

# Re-enable a campaign
google-ads-cli manage enable --customer-id 1741833734 --campaign-id 23168756345
```

You need the campaign ID — run `campaigns` first if you don't have it.

---

### 6. Show This Guide

**Ask Hermes:**
> "Show me the Google Ads guide"
> "Google Ads help"

**Direct command:**
```bash
google-ads-cli guide
```

---

## Global Flags

These work with any command:

| Flag            | What it does                                  |
|-----------------|-----------------------------------------------|
| `--customer-id` | Specify which account to use                  |
| `--active-only` | Show only ENABLED campaigns (hide paused)     |
| `--json`        | Output machine-readable JSON                  |
| `--verbose`     | Show the raw API queries for debugging        |

---

## Tips

- **Just ask naturally.** Hermes understands context. "How are my Blade campaigns doing?" will get you a report.
- **Name the account** if it's not Blade. Say "for Teleios Health" or "for RTT" and Hermes will use the right customer ID.
- **Use "active only"** to filter out paused campaigns. Blade has 300+ total but only ~6 are active.
- **Filter by name** to narrow results. "Show me PMAX campaigns" or "CPA for brand campaigns" works.
- **Always preview budget changes** with `--dry-run` before applying when running commands directly.
- **Campaign IDs** are the long numbers (like 21446287821). You'll see them in the campaigns list output.

---

## Quick Reference

| What you want                  | Ask Hermes                                | Direct command shorthand |
|-------------------------------|-------------------------------------------|--------------------------|
| See all campaigns             | "List Blade campaigns"                    | `campaigns`              |
| Active campaigns only         | "Show active campaigns"                   | `campaigns --active-only`|
| Filter campaigns              | "Show PMAX campaigns"                     | `campaigns --filter PMAX`|
| Today's CPA                   | "Blade CPA today"                         | `cpa --date TODAY`       |
| Last week's CPA               | "CPA last 7 days"                         | `cpa --date LAST_7_DAYS` |
| Weekly performance report     | "Weekly report for Blade"                 | `report`                 |
| Change budget                 | "Set PMAX USA budget to $500"             | `budget --campaign-id ID --amount 500` |
| Pause a campaign              | "Pause the HPN campaign"                  | `manage pause --campaign-id ID` |
| Enable a campaign             | "Turn on the HPN campaign"                | `manage enable --campaign-id ID` |
| Get JSON output               | "List campaigns as JSON"                  | `campaigns --json`       |
| Show this guide               | "Google Ads help"                         | `guide`                  |

All direct commands require `--customer-id` (e.g., `--customer-id 1741833734` for Blade).
