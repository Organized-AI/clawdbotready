# Meta Marketing API — Endpoint Reference

## Table of Contents
- [Base Configuration](#base-configuration)
- [Account Operations](#account-operations)
- [Campaign CRUD](#campaign-crud)
- [Ad Set CRUD](#ad-set-crud)
- [Ad Creative CRUD](#ad-creative-crud)
- [Ad CRUD](#ad-crud)
- [Asset Management](#asset-management)
- [Targeting Search](#targeting-search)
- [Custom Audiences](#custom-audiences)
- [Batch Requests](#batch-requests)
- [Rate Limits](#rate-limits)
- [Error Codes](#error-codes)

## Base Configuration

```
Base URL: https://graph.facebook.com/v21.0/
Auth Header: Authorization: Bearer {META_ACCESS_TOKEN}
Content-Type: application/json (for JSON bodies)
Budget Unit: CENTS (integer) — $50.00 = 5000
```

Required permissions on System User token:
ads_management, ads_read, business_management, pages_read_engagement, pages_manage_ads, catalog_management (optional), leads_retrieval (optional)

## Account Operations

```bash
# Verify account access
GET /act_{ad_account_id}?fields=name,account_status,currency,timezone_name,business,amount_spent,balance

# List campaigns
GET /act_{ad_account_id}/campaigns?fields=name,objective,status,daily_budget,lifetime_budget,created_time&limit=100

# List ad sets
GET /act_{ad_account_id}/adsets?fields=name,campaign_id,status,daily_budget,targeting,optimization_goal,billing_event&limit=100
```

## Campaign CRUD

### Create

```json
POST /act_{ad_account_id}/campaigns

{
  "name": "{brand}_{objective}_{audience_type}_{YYYYMMDD}",
  "objective": "OUTCOME_SALES",
  "status": "PAUSED",
  "special_ad_categories": [],
  "bid_strategy": "LOWEST_COST_WITHOUT_CAP",
  "daily_budget": 5000,
  "campaign_budget_optimization": true
}
```

Objective options:
| Objective | Optimization Goals |
|-----------|-------------------|
| OUTCOME_AWARENESS | REACH, IMPRESSIONS, AD_RECALL_LIFT, THRUPLAY |
| OUTCOME_TRAFFIC | LINK_CLICKS, LANDING_PAGE_VIEWS, REACH |
| OUTCOME_ENGAGEMENT | POST_ENGAGEMENT, VIDEO_VIEWS, THRUPLAY |
| OUTCOME_LEADS | LEAD_GENERATION, OFFSITE_CONVERSIONS, LINK_CLICKS |
| OUTCOME_APP_PROMOTION | APP_INSTALLS, APP_EVENTS, VALUE |
| OUTCOME_SALES | OFFSITE_CONVERSIONS, VALUE, LINK_CLICKS |

Bid strategies:
| Strategy | When |
|----------|------|
| LOWEST_COST_WITHOUT_CAP | Default — max results, no bid limit |
| LOWEST_COST_WITH_BID_CAP | Strict CPA target |
| COST_CAP | Maintain average CPA over time |
| MINIMUM_ROAS | E-commerce ROAS optimization |

### Read / Update / Delete

```bash
GET /{campaign_id}?fields=name,objective,status,effective_status,daily_budget,lifetime_budget,spend_cap,bid_strategy,issues_info
POST /{campaign_id}  # Body: {"name": "New Name", "status": "ACTIVE", "daily_budget": 7500}
DELETE /{campaign_id}
```

## Ad Set CRUD

### Create

```json
POST /act_{ad_account_id}/adsets

{
  "name": "{persona}_{placement}_{optimization}",
  "campaign_id": "{campaign_id}",
  "status": "PAUSED",
  "billing_event": "IMPRESSIONS",
  "optimization_goal": "OFFSITE_CONVERSIONS",
  "promoted_object": {
    "pixel_id": "{pixel_id}",
    "custom_event_type": "PURCHASE"
  },
  "targeting": {
    "age_min": 25,
    "age_max": 39,
    "genders": [2],
    "geo_locations": {
      "countries": ["US"],
      "regions": [{"key": "4081"}],
      "cities": [{"key": "2420605"}],
      "zips": [{"key": "US:78701"}],
      "location_types": ["home", "recent"]
    },
    "flexible_spec": [
      {
        "interests": [
          {"id": "6003349442621", "name": "Yoga"},
          {"id": "6003248099430", "name": "CrossFit"}
        ]
      },
      {
        "behaviors": [
          {"id": "6002714895372", "name": "Engaged Shoppers"}
        ]
      }
    ],
    "excluded_custom_audiences": [
      {"id": "23851234567890"}
    ]
  },
  "start_time": "2026-03-01T00:00:00-0600",
  "end_time": "2026-03-31T23:59:59-0600",
  "attribution_setting": "7d_click_1d_view",
  "pacing_type": ["standard"]
}
```

Placement configuration (for manual placements, add to targeting):
```json
{
  "publisher_platforms": ["facebook", "instagram"],
  "facebook_positions": ["feed", "story", "reels"],
  "instagram_positions": ["stream", "story", "reels"],
  "device_platforms": ["mobile", "desktop"]
}
```

Omit publisher_platforms for Advantage+ (auto) placements — this is the default.

Attribution windows: 7d_click_1d_view (default), 1d_click, 7d_click, 1d_click_1d_view

Custom event types for promoted_object: PURCHASE, LEAD, COMPLETE_REGISTRATION, ADD_TO_CART, INITIATE_CHECKOUT, ADD_PAYMENT_INFO, SEARCH, CONTENT_VIEW

### Read / Update / Delete

```bash
GET /{adset_id}?fields=name,campaign_id,status,effective_status,daily_budget,targeting,optimization_goal,promoted_object,billing_event,attribution_setting,issues_info
POST /{adset_id}  # Body: {"daily_budget": 7500, "targeting": {...}}
DELETE /{adset_id}
```

## Ad Creative CRUD

### Single Image

```json
POST /act_{ad_account_id}/adcreatives

{
  "name": "Creative_Sales_Image_V1",
  "object_story_spec": {
    "page_id": "{page_id}",
    "link_data": {
      "link": "https://brand.com/offer?utm_source=meta&utm_medium=paid",
      "message": "Primary text above the image.",
      "name": "Headline Below Image",
      "description": "Supporting description.",
      "image_hash": "{image_hash}",
      "call_to_action": {
        "type": "SHOP_NOW",
        "value": {"link": "https://brand.com/offer"}
      }
    }
  }
}
```

### Video

```json
{
  "name": "Creative_Sales_Video_V1",
  "object_story_spec": {
    "page_id": "{page_id}",
    "video_data": {
      "video_id": "{video_id}",
      "image_url": "{thumbnail_url}",
      "title": "Headline",
      "message": "Primary text.",
      "call_to_action": {
        "type": "SHOP_NOW",
        "value": {"link": "https://brand.com/offer"}
      }
    }
  }
}
```

### Carousel

```json
{
  "name": "Creative_Sales_Carousel_V1",
  "object_story_spec": {
    "page_id": "{page_id}",
    "link_data": {
      "link": "https://brand.com",
      "message": "Primary text shared across all cards.",
      "child_attachments": [
        {
          "link": "https://brand.com/product1",
          "image_hash": "{hash_1}",
          "name": "Product 1 Headline",
          "description": "Product 1 description",
          "call_to_action": {"type": "SHOP_NOW", "value": {"link": "https://brand.com/product1"}}
        },
        {
          "link": "https://brand.com/product2",
          "image_hash": "{hash_2}",
          "name": "Product 2 Headline",
          "description": "Product 2 description",
          "call_to_action": {"type": "SHOP_NOW", "value": {"link": "https://brand.com/product2"}}
        }
      ]
    }
  }
}
```

### DCO (Dynamic Creative Optimization)

```json
{
  "name": "DCO_Sales_Test",
  "object_story_spec": {
    "page_id": "{page_id}",
    "link_data": {
      "link": "https://brand.com/offer",
      "image_hash": "{hash_1}"
    }
  },
  "asset_feed_spec": {
    "images": [{"hash": "{hash_1}"}, {"hash": "{hash_2}"}, {"hash": "{hash_3}"}],
    "bodies": [{"text": "Variant A"}, {"text": "Variant B"}],
    "titles": [{"text": "Headline A"}, {"text": "Headline B"}],
    "descriptions": [{"text": "Desc A"}, {"text": "Desc B"}],
    "call_to_action_types": ["SHOP_NOW", "LEARN_MORE"],
    "link_urls": [{"website_url": "https://brand.com/offer"}]
  }
}
```
Ad set must have `use_dynamic_creative: true` for DCO.

CTA options: SHOP_NOW, LEARN_MORE, SIGN_UP, SUBSCRIBE, DOWNLOAD, GET_OFFER, GET_QUOTE, BOOK_TRAVEL, CONTACT_US, APPLY_NOW, ORDER_NOW, BUY_NOW, WATCH_MORE, SEND_MESSAGE

### Read / Delete

```bash
GET /{creative_id}?fields=name,object_story_spec,effective_object_story_id,thumbnail_url,status
DELETE /{creative_id}
```

## Ad CRUD

### Create

```json
POST /act_{ad_account_id}/ads

{
  "name": "Ad_{persona}_{creative_variant}",
  "adset_id": "{adset_id}",
  "creative": {"creative_id": "{creative_id}"},
  "status": "PAUSED",
  "tracking_specs": [
    {
      "action.type": ["offsite_conversion"],
      "fb_pixel": ["{pixel_id}"]
    }
  ]
}
```

### Read / Preview / Update / Delete

```bash
GET /{ad_id}?fields=name,adset_id,creative,status,effective_status,preview_shareable_link,issues_info
GET /{ad_id}/previews?ad_format=DESKTOP_FEED_STANDARD
POST /{ad_id}  # Body: {"status": "ACTIVE"}
DELETE /{ad_id}
```

Preview formats: DESKTOP_FEED_STANDARD, MOBILE_FEED_STANDARD, INSTAGRAM_STANDARD, INSTAGRAM_STORY, MARKETPLACE_MOBILE

## Asset Management

### Image Upload

```bash
# Multipart upload
POST /act_{ad_account_id}/adimages
Body (multipart): filename=@image.jpg

# Response
{"images": {"image.jpg": {"hash": "abc123...", "url": "https://scontent..."}}}
```

### Video Upload

```bash
# Single upload (under 1GB)
POST /act_{ad_account_id}/advideos
Body (multipart): source=@video.mp4, title="Video Name"

# Poll status
GET /{video_id}?fields=status
# Wait for: status.video_status = "ready"

# Chunked upload (over 1GB)
POST /act_{ad_account_id}/advideos  Body: {"upload_phase": "start", "file_size": BYTES}
POST /act_{ad_account_id}/advideos  Body: upload_phase=transfer, upload_session_id=ID, start_offset=N, video_file_chunk=BINARY
POST /act_{ad_account_id}/advideos  Body: {"upload_phase": "finish", "upload_session_id": "ID", "title": "Name"}
```

### List / Delete Images

```bash
GET /act_{ad_account_id}/adimages?fields=hash,url,name,width,height,created_time
DELETE /act_{ad_account_id}/adimages  Body: {"hash": "image_hash"}
```

## Targeting Search

```bash
# Interests
GET /act_{ad_account_id}/targetingsearch?q=yoga&type=adinterest

# Behaviors
GET /act_{ad_account_id}/targetingsearch?q=engaged+shoppers&type=adbehavior

# Demographics
GET /act_{ad_account_id}/targetingsearch?q=college+graduate&type=addemographic

# Locations
GET /search?type=adgeolocation&q=Austin&location_types=city

# Suggestions (based on existing targeting)
GET /act_{ad_account_id}/targetingsuggestions?targeting_list=[{"type":"interests","id":"6003349442621"}]

# Delivery estimate
GET /act_{ad_account_id}/delivery_estimate?targeting_spec={json}&optimization_goal=OFFSITE_CONVERSIONS
```

## Custom Audiences

```bash
# List
GET /act_{ad_account_id}/customaudiences?fields=id,name,subtype,approximate_count,data_source

# Create website audience
POST /act_{ad_account_id}/customaudiences
Body: {"name": "Website Visitors 30d", "subtype": "WEBSITE", "rule": {...}}

# Create lookalike
POST /act_{ad_account_id}/customaudiences
Body: {"name": "LAL 1% Purchasers US", "subtype": "LOOKALIKE", "origin_audience_id": "{id}", "lookalike_spec": {"ratio": 0.01, "country": "US"}}
```

## Batch Requests

Send up to 50 API calls in one request:

```json
POST /

{
  "batch": [
    {"method": "POST", "relative_url": "act_123/adsets", "body": "...url_encoded_params..."},
    {"method": "POST", "relative_url": "act_123/adsets", "body": "...url_encoded_params..."}
  ]
}
```

Each batch = 1 rate limit call regardless of sub-request count.

## Rate Limits

| Tier | Per Hour | Per Minute |
|------|----------|------------|
| Development/Standard | 200/account | 60/account |
| Business Use Case | Higher (apply through Meta) | Higher |

Monitor via `x-business-use-case-usage` response header.

## Error Codes

| Code | Subcode | Meaning | Fix |
|------|---------|---------|-----|
| 100 | 1487390 | Invalid parameter | Check field names and value types |
| 100 | 1885220 | Creative spec error | Verify image_hash, page_id, link format |
| 190 | 463 | Token expired | Refresh token |
| 190 | 460 | Invalid token | Re-authenticate |
| 200 | — | Permissions error | Check app scopes |
| 368 | — | Account disabled | Contact Meta support |
| 429 | — | Rate limited | Exponential backoff (1s, 4s, 16s) |
| 1487301 | — | Budget too low | Raise above minimum |
| 2446079 | — | Targeting too narrow | Broaden audience |
| 2635012 | — | Ad review rejected | Fix policy violation in copy/image |
