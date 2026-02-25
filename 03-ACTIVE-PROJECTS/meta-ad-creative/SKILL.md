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
echo "META_ACCESS_TOKEN: ${META_ACCESS_TOKEN:?'NOT SET'}"
echo "META_AD_ACCOUNT_ID: ${META_AD_ACCOUNT_ID:?'NOT SET'}"
echo "META_PAGE_ID: ${META_PAGE_ID:?'NOT SET'}"
echo "META_PIXEL_ID: ${META_PIXEL_ID:?'NOT SET'}"
```

## Trafficking Sequence

Execute in this exact order. Each step depends on the previous. **Never skip validation. Never tell the user to go do it manually.**

### Phase 1: Validate Account Access
```bash
bash .claude/skills/meta-ad-creative/scripts/meta-api.sh verify
```

### Phase 2: Upload Assets
See `references/creative-formats.md` for specs.
```bash
bash .claude/skills/meta-ad-creative/scripts/meta-api.sh upload-image /path/to/creative.jpg
bash .claude/skills/meta-ad-creative/scripts/meta-api.sh upload-video /path/to/video.mp4
```

### Phase 3: Create Campaign
Write payload to file, send with helper. Budget in **CENTS** ($50/day = 5000). Always create PAUSED.

### Phase 4: Create Ad Creative
Build `object_story_spec` using stored asset hashes. See `references/creative-formats.md`.

### Phase 5: Create Ad Set
This is where CLI fails. Use file-based pattern. See `references/targeting-specs.md` for interest resolution and flexible_spec logic.

### Phase 6: Create Ad
Link ad set + creative. See `references/api-endpoints.md`.

### Phase 7: Validate and Activate
Present preview links. Only activate after user approval.

## Naming Convention

| Object | Pattern | Example |
|--------|---------|---------|
| Campaign | `{brand}_{objective}_{audience_type}_{YYYYMMDD}` | `Myosin_Sales_Prospecting_20260301` |
| Ad Set | `{persona}_{placement}_{optimization}` | `FitMillennial_AllPlacements_Purchase` |
| Creative | `Creative_{objective}_{format}_{variant}` | `Creative_Sales_Image_V1` |
| Ad | `Ad_{persona}_{creative_variant}` | `Ad_FitMillennial_CreativeV1` |

## Error Recovery

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 400 + 1487390 | Invalid parameter | Check field names/types |
| 400 + 1885220 | Creative spec error | Verify image_hash, page_id, link |
| 190 | Auth error | Re-check META_ACCESS_TOKEN |
| 429 | Rate limited | Backoff: 1s, 4s, 16s (max 3 retries) |
| 2446079 | Targeting too narrow | Broaden audience |
| 2635012 | Ad review rejected | Fix policy violation |

## Reference Files

| File | When to Read |
|------|-------------|
| `references/api-endpoints.md` | Full CRUD endpoints for all Meta objects |
| `references/targeting-specs.md` | Interest resolution, flexible_spec AND/OR, audience sizing |
| `references/creative-formats.md` | Asset specs, upload workflows, format payloads |
| `references/orchestration.md` | State management, batch processing, monitoring |

## Helper Script

```bash
bash .claude/skills/meta-ad-creative/scripts/meta-api.sh <command> [args]
```

Commands: verify, search-interests, search-behaviors, search-locations, estimate-audience, list-audiences, list-campaigns, list-images, create, status, activate, preview, upload-image, upload-video
