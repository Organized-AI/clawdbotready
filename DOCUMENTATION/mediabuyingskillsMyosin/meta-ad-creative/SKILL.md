---
name: meta-ad-creative
description: Programmatic Meta Ads campaign trafficking via the Marketing API. Use when user asks to create, build, traffic, or launch Meta/Facebook/Instagram ad campaigns, ad sets, ads, or creatives through the API. Triggers on "create campaign", "build ad set", "traffic ads", "upload creative", "launch on Meta", "Meta API", "targeting spec", "ad set creation". Do NOT use for Google Ads, browser-based Ads Manager UI tasks, or analytics-only queries.
---

# Meta Ad Creative — Programmatic Campaign Trafficking

## Purpose

This plugin enables Claude Code to build complete Meta ad campaigns programmatically using `curl` and the Meta Marketing API. It solves the core limitation where CLI tools choke on complex targeting JSON by using **file-based payloads** instead of shell arguments.

## Critical Pattern: File-Based JSON Payloads

**NEVER pass complex JSON as shell arguments.** Instead:

```bash
# 1. Write the payload to a temp file
cat > /tmp/meta_adset_payload.json << 'EOF'
{
  "name": "FitMillennial_AllPlacements_Purchase",
  "campaign_id": "23851234567890123",
  "status": "PAUSED",
  "billing_event": "IMPRESSIONS",
  "optimization_goal": "OFFSITE_CONVERSIONS",
  "promoted_object": {
    "pixel_id": "9876543210",
    "custom_event_type": "PURCHASE"
  },
  "targeting": {
    "age_min": 25,
    "age_max": 39,
    "genders": [2],
    "geo_locations": {"countries": ["US"]},
    "flexible_spec": [
      {"interests": [{"id": "6003349442621", "name": "Yoga"}]}
    ]
  },
  "start_time": "2026-03-01T00:00:00-0600",
  "attribution_setting": "7d_click_1d_view",
  "pacing_type": ["standard"]
}
EOF

# 2. Send with curl using @file reference
curl -X POST "https://graph.facebook.com/v21.0/act_${AD_ACCOUNT_ID}/adsets" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @/tmp/meta_adset_payload.json
```

This bypasses all shell escaping issues with nested JSON.

## Environment Requirements

Before any API call, verify these are set:

```bash
# Required
echo "META_ACCESS_TOKEN: ${META_ACCESS_TOKEN:?'NOT SET — get from Business Manager > System Users'}"
echo "META_AD_ACCOUNT_ID: ${META_AD_ACCOUNT_ID:?'NOT SET — format: act_XXXXXXXXX'}"
echo "META_PAGE_ID: ${META_PAGE_ID:?'NOT SET — Facebook Page ID for ad identity'}"
echo "META_PIXEL_ID: ${META_PIXEL_ID:?'NOT SET — for conversion tracking'}"
```

If any are missing, prompt the user. Do not proceed without them.

## Trafficking Sequence

Execute in this exact order. Each step depends on the previous step completing successfully. **Never skip validation. Never tell the user to "go do it manually."**

### Phase 1: Validate Account Access

```bash
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}?fields=name,account_status,currency,timezone_name&access_token=${META_ACCESS_TOKEN}" | jq .
```

Verify: `account_status` = 1 (ACTIVE). If not, stop and report the issue.

### Phase 2: Upload Assets

See `references/creative-formats.md` for specs per format.

**Images:**
```bash
curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/adimages" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -F "filename=@/path/to/creative.jpg"
```
Store the returned `image_hash`.

**Videos:**
```bash
curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/advideos" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -F "source=@/path/to/video.mp4" \
  -F "title=Product Demo V1"
```
Poll `GET /{video_id}?fields=status` until `status.video_status` = "ready" (every 10s, timeout 10min).

### Phase 3: Create Campaign

Write payload to file, send with curl. See `references/api-endpoints.md` for full field reference.

Key rules:
- `daily_budget` is in **CENTS** ($50/day = 5000)
- Always create as `PAUSED` first
- `special_ad_categories` must be declared if applicable (housing, credit, employment)

### Phase 4: Create Ad Creative

Build `object_story_spec` using stored asset hashes/IDs. See `references/creative-formats.md` for format-specific payloads (single image, video, carousel, DCO).

### Phase 5: Create Ad Set

This is where the CLI always fails. The targeting spec is complex nested JSON — use the file-based pattern above.

For targeting resolution, see `references/targeting-specs.md` for:
- Interest/behavior ID resolution via targetingsearch API
- flexible_spec AND/OR logic
- Custom audience integration
- Audience sizing validation

### Phase 6: Create Ad

Link ad set + creative:

```bash
cat > /tmp/meta_ad_payload.json << 'EOF'
{
  "name": "Ad_FitMillennial_CreativeV1",
  "adset_id": "ADSET_ID_HERE",
  "creative": {"creative_id": "CREATIVE_ID_HERE"},
  "status": "PAUSED",
  "tracking_specs": [
    {"action.type": ["offsite_conversion"], "fb_pixel": ["PIXEL_ID_HERE"]}
  ]
}
EOF

curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/ads" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @/tmp/meta_ad_payload.json
```

### Phase 7: Validate and Activate

```bash
# Check all objects
for OBJ_ID in "$CAMPAIGN_ID" "$ADSET_ID" "$AD_ID"; do
  curl -s "https://graph.facebook.com/v21.0/${OBJ_ID}?fields=effective_status,issues_info&access_token=${META_ACCESS_TOKEN}" | jq .
done

# Get preview link
curl -s "https://graph.facebook.com/v21.0/${AD_ID}?fields=preview_shareable_link&access_token=${META_ACCESS_TOKEN}" | jq -r '.preview_shareable_link'
```

Present the preview link and status report. Only activate after user approval:

```bash
for OBJ_ID in "$CAMPAIGN_ID" "$ADSET_ID" "$AD_ID"; do
  curl -X POST "https://graph.facebook.com/v21.0/${OBJ_ID}" \
    -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
    -d '{"status":"ACTIVE"}'
done
```

## Naming Convention

Always auto-generate names using this pattern:

| Object | Pattern | Example |
|--------|---------|---------|
| Campaign | `{brand}_{objective}_{audience_type}_{YYYYMMDD}` | `Myosin_Sales_Prospecting_20260301` |
| Ad Set | `{persona}_{placement}_{optimization}` | `FitMillennial_AllPlacements_Purchase` |
| Creative | `Creative_{objective}_{format}_{variant}` | `Creative_Sales_Image_V1` |
| Ad | `Ad_{persona}_{creative_variant}` | `Ad_FitMillennial_CreativeV1` |

## Error Recovery

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 400 + subcode 1487390 | Invalid parameter | Check field names/types |
| 400 + subcode 1885220 | Creative spec error | Verify image_hash, page_id, link |
| 190 | Auth error | Token expired or invalid — re-check META_ACCESS_TOKEN |
| 200 | Permissions error | Check app scopes in Business Manager |
| 429 | Rate limited | Backoff: 1s, 4s, 16s retries (max 3) |
| 2446079 | Targeting too narrow | Broaden audience, remove exclusions |
| 2635012 | Ad review rejected | Fix copy/image policy violation |

For the cents bug specifically: if you get a budget error, verify the value is in cents (multiply dollars by 100).

## Reference Files

| File | When to Read |
|------|-------------|
| `references/api-endpoints.md` | Full CRUD endpoints for all Meta objects |
| `references/targeting-specs.md` | Interest resolution, flexible_spec logic, audience sizing |
| `references/creative-formats.md` | Asset specs, upload workflow, format-specific payloads |
| `references/orchestration.md` | State management, batch processing, monitoring |

## Helper Script

Use `scripts/meta-api.sh` for common operations:

```bash
# Verify account
bash scripts/meta-api.sh verify

# Search targeting interests
bash scripts/meta-api.sh search-interests "yoga"

# Estimate audience size
bash scripts/meta-api.sh estimate-audience /tmp/targeting_spec.json

# Create any object from JSON file
bash scripts/meta-api.sh create campaign /tmp/campaign_payload.json
bash scripts/meta-api.sh create adset /tmp/adset_payload.json
bash scripts/meta-api.sh create adcreative /tmp/creative_payload.json
bash scripts/meta-api.sh create ad /tmp/ad_payload.json
```
