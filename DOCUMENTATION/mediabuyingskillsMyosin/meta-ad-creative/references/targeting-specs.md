# Targeting Specs — Audience Resolution and Persona Builder

## Table of Contents
- [Persona Input Template](#persona-input-template)
- [Interest Resolution Process](#interest-resolution-process)
- [Behavior Resolution](#behavior-resolution)
- [Location Resolution](#location-resolution)
- [Flexible Spec Logic (AND/OR)](#flexible-spec-logic-andor)
- [Custom Audience Integration](#custom-audience-integration)
- [Audience Sizing Rules](#audience-sizing-rules)
- [Pre-Built Persona Library](#pre-built-persona-library)
- [Complete Targeting Spec Example](#complete-targeting-spec-example)

## Persona Input Template

When the user describes a target audience, extract these fields:

```
Persona Name: [label for naming convention]
Age: [min]-[max] (minimum 18, maximum 65)
Gender: All (0) | Male (1) | Female (2)
Location: [Countries, states, cities, or zips]
Interests: [Comma-separated topics]
Behaviors: [Purchase behaviors, device usage, travel]
Life Events: [Recently moved, newly engaged, new job]
Exclusions: [Custom audiences to exclude]
Funnel Stage: [Top | Middle | Bottom]
```

## Interest Resolution Process

For each interest keyword from the persona, resolve to a Meta interest ID:

```bash
# Step 1: Search for the interest
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/targetingsearch?q=yoga&type=adinterest&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {id, name, audience_size}'

# Step 2: Match by name (case-insensitive, closest match)
# Step 3: Verify audience_size > 100,000 (below this = unreliable)
# Step 4: Store the id + name pair
# Step 5: Group related interests into same flexible_spec entry (OR logic)
```

Always resolve IDs before building the targeting spec. Never use hardcoded IDs without verifying they still exist.

## Behavior Resolution

Same process, different type parameter:

```bash
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/targetingsearch?q=engaged+shoppers&type=adbehavior&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {id, name, audience_size}'
```

Common behavior categories:
- Purchase: Engaged Shoppers, Online Buyers
- Device: Facebook access (mobile), WiFi users
- Travel: Frequent travelers, Returned from travel 1 week ago
- Digital: Small business owners, Technology early adopters

## Location Resolution

Resolve location names to Meta geo keys:

```bash
curl -s "https://graph.facebook.com/v21.0/search?type=adgeolocation&q=Austin&location_types=city&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {key, name, type, country_code, region}'
```

Location types: country, region, city, zip, geo_market, electoral_district

Format for targeting spec:
```json
{
  "geo_locations": {
    "countries": ["US"],
    "regions": [{"key": "4081"}],
    "cities": [{"key": "2420605"}],
    "zips": [{"key": "US:78701"}],
    "location_types": ["home", "recent"]
  }
}
```

`location_types` values: "home" (lives there), "recent" (recently in area), "travel_in" (traveling through)

## Flexible Spec Logic (AND/OR)

This is the most important targeting concept:

- Items **WITHIN** the same `flexible_spec` object → **OR** (match any)
- Items **ACROSS** different `flexible_spec` objects → **AND** (match all)

### Example: (Yoga OR CrossFit) AND (Engaged Shoppers)

```json
{
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
  ]
}
```

### Example: Broad interest stack (match any — single object)

```json
{
  "flexible_spec": [
    {
      "interests": [
        {"id": "6003349442621", "name": "Yoga"},
        {"id": "6003248099430", "name": "CrossFit"},
        {"id": "6003384493821", "name": "Peloton"},
        {"id": "6003107902433", "name": "Lululemon"}
      ]
    }
  ]
}
```

### Example: Narrow (must match interest AND behavior AND demographic)

```json
{
  "flexible_spec": [
    {
      "interests": [{"id": "6003349442621", "name": "Yoga"}]
    },
    {
      "behaviors": [{"id": "6002714895372", "name": "Engaged Shoppers"}]
    },
    {
      "education_statuses": [3]
    }
  ]
}
```

## Custom Audience Integration

### List existing audiences

```bash
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/customaudiences?fields=id,name,approximate_count,subtype&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {id, name, approximate_count, subtype}'
```

### Use in targeting (include)

```json
{
  "custom_audiences": [
    {"id": "23851234567890"}
  ]
}
```

### Use in targeting (exclude)

```json
{
  "excluded_custom_audiences": [
    {"id": "23851234567890"}
  ]
}
```

### Create lookalike

```bash
cat > /tmp/meta_lal_payload.json << 'EOF'
{
  "name": "LAL_Purchasers_1pct_US",
  "subtype": "LOOKALIKE",
  "origin_audience_id": "{source_audience_id}",
  "lookalike_spec": {
    "ratio": 0.01,
    "country": "US"
  }
}
EOF

curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/customaudiences" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @/tmp/meta_lal_payload.json
```

Lookalike ratio: 0.01 = top 1% (tightest), 0.10 = top 10% (broadest)

## Audience Sizing Rules

Before finalizing targeting, check estimated reach:

```bash
# URL-encode the targeting_spec JSON
TARGETING_JSON=$(cat /tmp/targeting_spec.json | jq -c .)
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/delivery_estimate?targeting_spec=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${TARGETING_JSON}'))")&optimization_goal=OFFSITE_CONVERSIONS&access_token=${META_ACCESS_TOKEN}" | jq .
```

Sizing rules:
| Audience Size | Assessment | Action |
|---------------|-----------|--------|
| < 1,000 | Too narrow | Broaden interests or locations |
| 1,000 – 100,000 | Niche | Good for retargeting, risky for prospecting |
| 100,000 – 10,000,000 | Sweet spot | Ideal for most prospecting campaigns |
| > 10,000,000 | Broad | Consider splitting into sub-personas |

## Pre-Built Persona Library

### Broad Prospecting (Advantage+)
```json
{
  "age_min": 18, "age_max": 65,
  "genders": [0],
  "geo_locations": {"countries": ["US"]}
}
```
No detailed targeting — Meta's algorithm finds the audience. Use with Advantage+ Shopping Campaigns.

### Interest-Based Prospecting
```json
{
  "age_min": 25, "age_max": 54,
  "genders": [2],
  "geo_locations": {"countries": ["US"]},
  "flexible_spec": [
    {"interests": [RESOLVE_3_TO_5_RELEVANT_INTERESTS]}
  ]
}
```

### Lookalike Prospecting
```json
{
  "age_min": 18, "age_max": 65,
  "genders": [0],
  "geo_locations": {"countries": ["US"]},
  "custom_audiences": [{"id": "LOOKALIKE_AUDIENCE_ID"}]
}
```

### Retargeting (Website Visitors)
```json
{
  "age_min": 18, "age_max": 65,
  "genders": [0],
  "geo_locations": {"countries": ["US"]},
  "custom_audiences": [{"id": "WEBSITE_VISITORS_AUDIENCE_ID"}],
  "excluded_custom_audiences": [{"id": "PURCHASERS_30D_AUDIENCE_ID"}]
}
```

### Retargeting (Cart Abandoners)
```json
{
  "age_min": 18, "age_max": 65,
  "genders": [0],
  "geo_locations": {"countries": ["US"]},
  "custom_audiences": [{"id": "ADD_TO_CART_7D_AUDIENCE_ID"}],
  "excluded_custom_audiences": [{"id": "PURCHASERS_14D_AUDIENCE_ID"}]
}
```

## Complete Targeting Spec Example

Persona: "Fitness-Focused Millennial Women" for DTC e-commerce

```json
{
  "age_min": 25,
  "age_max": 39,
  "genders": [2],
  "geo_locations": {
    "countries": ["US"]
  },
  "flexible_spec": [
    {
      "interests": [
        {"id": "6003349442621", "name": "Yoga"},
        {"id": "6003248099430", "name": "CrossFit"},
        {"id": "6003384493821", "name": "Peloton"},
        {"id": "6003107902433", "name": "Lululemon"},
        {"id": "6003370250981", "name": "Whole Foods Market"}
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
}
```

This targets women 25-39 in the US who like (Yoga OR CrossFit OR Peloton OR Lululemon OR Whole Foods) AND (are Engaged Shoppers), excluding existing customers.
