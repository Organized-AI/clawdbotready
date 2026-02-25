# Orchestration — State Management, Batch Processing, and Monitoring

## Table of Contents
- [State Tracking](#state-tracking)
- [Retry Logic](#retry-logic)
- [Rollback Logic](#rollback-logic)
- [Batch Processing](#batch-processing)
- [Post-Launch Monitoring](#post-launch-monitoring)
- [Pre-Flight Checklist](#pre-flight-checklist)

## State Tracking

Track every created object in a state file throughout the build:

```bash
# Initialize state file
cat > /tmp/meta_campaign_state.json << 'EOF'
{
  "job_id": "",
  "status": "validating",
  "ad_account_id": "",
  "assets": {"images": {}, "videos": {}},
  "campaign": {"id": null, "name": "", "status": ""},
  "ad_sets": [],
  "creatives": [],
  "ads": [],
  "errors": [],
  "warnings": []
}
EOF
```

Update after each API call:
```bash
# After campaign creation
jq '.campaign.id = "23851234567890123" | .campaign.name = "Myosin_Sales_Prospecting_20260301" | .status = "building"' /tmp/meta_campaign_state.json > /tmp/meta_campaign_state_tmp.json && mv /tmp/meta_campaign_state_tmp.json /tmp/meta_campaign_state.json
```

## Retry Logic

For transient errors (network timeouts, rate limits):

```
Max retries: 3
Backoff: exponential (1s, 4s, 16s)
Retry on: HTTP 429, HTTP 500/502/503, network timeout
Do NOT retry: HTTP 400 (bad request), HTTP 403 (permissions), HTTP 190 (auth)
```

Bash implementation:
```bash
meta_api_call() {
  local max_retries=3
  local retry=0
  local backoff=1

  while [ $retry -lt $max_retries ]; do
    RESPONSE=$(curl -s -w "\n%{http_code}" "$@")
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -n -1)

    case $HTTP_CODE in
      200|201) echo "$BODY"; return 0 ;;
      429|500|502|503)
        echo "Retrying in ${backoff}s (attempt $((retry+1))/${max_retries})..." >&2
        sleep $backoff
        backoff=$((backoff * 4))
        retry=$((retry + 1))
        ;;
      *)
        echo "$BODY" >&2
        return 1
        ;;
    esac
  done
  echo "Max retries exceeded" >&2
  return 1
}
```

## Rollback Logic

| Failure Point | Objects Exist | Action |
|---------------|--------------|--------|
| Campaign creation | None | No rollback needed |
| Creative assembly | Campaign (paused) | Leave campaign paused, retry creatives |
| Ad set creation | Campaign + creatives | Leave paused, fix targeting, retry |
| Ad creation | Campaign + creatives + ad sets | Leave paused, fix linking, retry |
| Activation | All objects (paused) | Fix blocking issue (usually ad review), retry activation |

Key principle: **Everything is created PAUSED.** This means partial failures leave recoverable state — just fix the issue and retry the failed step.

## Batch Processing

For building multiple ad sets or ads at scale:

```bash
cat > /tmp/meta_batch_payload.json << 'EOF'
{
  "access_token": "TOKEN_HERE",
  "batch": [
    {
      "method": "POST",
      "relative_url": "act_123/adsets",
      "body": "name=AdSet1&campaign_id=789&status=PAUSED&billing_event=IMPRESSIONS&optimization_goal=OFFSITE_CONVERSIONS&targeting=%7B%22age_min%22%3A25%7D&promoted_object=%7B%22pixel_id%22%3A%22123%22%2C%22custom_event_type%22%3A%22PURCHASE%22%7D"
    },
    {
      "method": "POST",
      "relative_url": "act_123/adsets",
      "body": "name=AdSet2&campaign_id=789&status=PAUSED&billing_event=IMPRESSIONS&optimization_goal=OFFSITE_CONVERSIONS&targeting=%7B%22age_min%22%3A35%7D&promoted_object=%7B%22pixel_id%22%3A%22123%22%2C%22custom_event_type%22%3A%22PURCHASE%22%7D"
    }
  ]
}
EOF

curl -X POST "https://graph.facebook.com/v21.0/" \
  -H "Content-Type: application/json" \
  -d @/tmp/meta_batch_payload.json
```

Rules:
- Max 50 sub-requests per batch
- Each batch = 1 rate limit call
- URL-encode the body parameter values
- Each sub-request returns its own HTTP status code

## Post-Launch Monitoring

After activation, check performance:

```bash
# Quick health check (run after 6 hours, then daily)
curl -s "https://graph.facebook.com/v21.0/${CAMPAIGN_ID}?fields=effective_status,insights{spend,impressions,actions}&access_token=${META_ACCESS_TOKEN}" | jq .
```

Alert thresholds:
| Signal | Threshold | Likely Cause |
|--------|-----------|-------------|
| effective_status changed from ACTIVE | — | Ad review rejection or budget exhausted |
| Spend = $0 after 6 hours | — | Delivery issue (targeting, billing, review) |
| CPM > 3x account average | — | Audience too narrow or highly competitive |
| CTR < 0.5% | — | Creative issue |
| No conversions after 3x target CPA in spend | — | Tracking or targeting issue |

## Pre-Flight Checklist

Run before every campaign launch:

```bash
#!/bin/bash
# Pre-flight validation
echo "=== Meta Campaign Pre-Flight Check ==="

# 1. Account active
ACCT=$(curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}?fields=account_status&access_token=${META_ACCESS_TOKEN}")
STATUS=$(echo "$ACCT" | jq -r '.account_status')
[ "$STATUS" = "1" ] && echo "✓ Account active" || echo "✗ Account status: $STATUS"

# 2. Token valid
TOKEN_CHECK=$(curl -s "https://graph.facebook.com/v21.0/debug_token?input_token=${META_ACCESS_TOKEN}&access_token=${META_APP_ID}|${META_APP_SECRET}")
VALID=$(echo "$TOKEN_CHECK" | jq -r '.data.is_valid')
[ "$VALID" = "true" ] && echo "✓ Token valid" || echo "✗ Token invalid"

# 3. Page accessible
PAGE_CHECK=$(curl -s "https://graph.facebook.com/v21.0/${META_PAGE_ID}?access_token=${META_ACCESS_TOKEN}")
PAGE_NAME=$(echo "$PAGE_CHECK" | jq -r '.name // "NOT FOUND"')
echo "✓ Page: ${PAGE_NAME}"

# 4. Pixel accessible
PIXEL_CHECK=$(curl -s "https://graph.facebook.com/v21.0/${META_PIXEL_ID}?access_token=${META_ACCESS_TOKEN}")
PIXEL_NAME=$(echo "$PIXEL_CHECK" | jq -r '.name // "NOT FOUND"')
echo "✓ Pixel: ${PIXEL_NAME}"

echo "=== Pre-Flight Complete ==="
```
