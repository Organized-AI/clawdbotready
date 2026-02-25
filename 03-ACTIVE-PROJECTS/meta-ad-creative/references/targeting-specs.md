# Targeting Specs — Audience Resolution and Persona Builder

## Interest Resolution Process

For each interest keyword, resolve to a Meta interest ID:

```bash
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/targetingsearch?q=yoga&type=adinterest&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {id, name, audience_size}'
```

Steps: Search → Match by name (case-insensitive) → Verify audience_size > 100,000 → Store id+name → Group related into same flexible_spec (OR logic)

## Behavior Resolution

```bash
curl -s "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/targetingsearch?q=engaged+shoppers&type=adbehavior&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {id, name, audience_size}'
```

## Location Resolution

```bash
curl -s "https://graph.facebook.com/v21.0/search?type=adgeolocation&q=Austin&location_types=city&access_token=${META_ACCESS_TOKEN}" | jq '.data[] | {key, name, type, country_code, region}'
```

Format: `"geo_locations": {"countries": ["US"], "regions": [{"key": "4081"}], "cities": [{"key": "2420605"}], "zips": [{"key": "US:78701"}], "location_types": ["home", "recent"]}`

## Flexible Spec Logic (AND/OR)

- Items **WITHIN** same `flexible_spec` object → **OR** (match any)
- Items **ACROSS** different `flexible_spec` objects → **AND** (match all)

### (Yoga OR CrossFit) AND (Engaged Shoppers):
```json
{"flexible_spec": [
  {"interests": [{"id": "6003349442621", "name": "Yoga"}, {"id": "6003248099430", "name": "CrossFit"}]},
  {"behaviors": [{"id": "6002714895372", "name": "Engaged Shoppers"}]}
]}
```

### Broad interest stack (match any — single object):
```json
{"flexible_spec": [{"interests": [ID1, ID2, ID3, ID4]}]}
```

## Custom Audiences

```bash
# List
bash .claude/skills/meta-ad-creative/scripts/meta-api.sh list-audiences

# Include: "custom_audiences": [{"id": "AUDIENCE_ID"}]
# Exclude: "excluded_custom_audiences": [{"id": "AUDIENCE_ID"}]
```

### Lookalike (write to file, create via API):
```json
{"name": "LAL_Purchasers_1pct_US", "subtype": "LOOKALIKE", "origin_audience_id": "SOURCE_ID", "lookalike_spec": {"ratio": 0.01, "country": "US"}}
```

## Audience Sizing Rules

```bash
bash .claude/skills/meta-ad-creative/scripts/meta-api.sh estimate-audience /tmp/targeting_spec.json
```

| Size | Assessment | Action |
|------|-----------|--------|
| < 1,000 | Too narrow | Broaden interests/locations |
| 1K – 100K | Niche | Good for retargeting, risky for prospecting |
| 100K – 10M | Sweet spot | Ideal for prospecting |
| > 10M | Broad | Consider splitting into sub-personas |

## Pre-Built Personas

**Broad Prospecting**: `{"age_min":18,"age_max":65,"genders":[0],"geo_locations":{"countries":["US"]}}` — no detailed targeting, Advantage+ handles it

**Interest-Based**: Add `"flexible_spec":[{"interests":[RESOLVE_3_TO_5]}]` with age/gender filters

**Lookalike**: `"custom_audiences":[{"id":"LAL_ID"}]` — no other targeting needed

**Retargeting**: `"custom_audiences":[{"id":"VISITORS_ID"}], "excluded_custom_audiences":[{"id":"PURCHASERS_ID"}]`

## Complete Example: Fitness-Focused Millennial Women

```json
{
  "age_min": 25, "age_max": 39, "genders": [2],
  "geo_locations": {"countries": ["US"]},
  "flexible_spec": [
    {"interests": [
      {"id": "6003349442621", "name": "Yoga"},
      {"id": "6003248099430", "name": "CrossFit"},
      {"id": "6003384493821", "name": "Peloton"},
      {"id": "6003107902433", "name": "Lululemon"}
    ]},
    {"behaviors": [{"id": "6002714895372", "name": "Engaged Shoppers"}]}
  ],
  "excluded_custom_audiences": [{"id": "23851234567890"}]
}
```
