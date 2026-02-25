# Meta Marketing API — Endpoint Reference

Base URL: `https://graph.facebook.com/v21.0/`
Auth: `Authorization: Bearer {META_ACCESS_TOKEN}`
Budget: **CENTS** (integer) — $50.00 = 5000

## Account
```
GET /act_{id}?fields=name,account_status,currency,timezone_name,business,amount_spent,balance
GET /act_{id}/campaigns?fields=name,objective,status,daily_budget,lifetime_budget,created_time&limit=100
GET /act_{id}/adsets?fields=name,campaign_id,status,daily_budget,targeting,optimization_goal&limit=100
```

## Campaign CRUD
```json
POST /act_{id}/campaigns
{"name":"...","objective":"OUTCOME_SALES","status":"PAUSED","special_ad_categories":[],"bid_strategy":"LOWEST_COST_WITHOUT_CAP","daily_budget":5000,"campaign_budget_optimization":true}
```
Objectives: OUTCOME_AWARENESS, OUTCOME_TRAFFIC, OUTCOME_ENGAGEMENT, OUTCOME_LEADS, OUTCOME_APP_PROMOTION, OUTCOME_SALES
Bid strategies: LOWEST_COST_WITHOUT_CAP (default), LOWEST_COST_WITH_BID_CAP, COST_CAP, MINIMUM_ROAS
```
GET /{campaign_id}?fields=name,objective,status,effective_status,daily_budget,issues_info
POST /{campaign_id}  Body: {"status":"ACTIVE","daily_budget":7500}
DELETE /{campaign_id}
```

## Ad Set CRUD
```json
POST /act_{id}/adsets
{"name":"...","campaign_id":"...","status":"PAUSED","billing_event":"IMPRESSIONS","optimization_goal":"OFFSITE_CONVERSIONS","promoted_object":{"pixel_id":"...","custom_event_type":"PURCHASE"},"targeting":{FULL_SPEC},"start_time":"ISO8601","attribution_setting":"7d_click_1d_view","pacing_type":["standard"]}
```
Custom event types: PURCHASE, LEAD, COMPLETE_REGISTRATION, ADD_TO_CART, INITIATE_CHECKOUT, CONTENT_VIEW
Attribution: 7d_click_1d_view (default), 1d_click, 7d_click, 1d_click_1d_view

Manual placements (add to targeting): `"publisher_platforms":["facebook","instagram"],"facebook_positions":["feed","story","reels"],"instagram_positions":["stream","story","reels"]`
Omit for Advantage+ auto placements.

## Ad Creative CRUD

### Single Image
```json
POST /act_{id}/adcreatives
{"name":"Creative_Sales_Image_V1","object_story_spec":{"page_id":"PAGE_ID","link_data":{"link":"URL","message":"Primary text","name":"Headline","description":"Desc","image_hash":"HASH","call_to_action":{"type":"SHOP_NOW","value":{"link":"URL"}}}}}
```

### Video
```json
{"name":"Creative_Sales_Video_V1","object_story_spec":{"page_id":"PAGE_ID","video_data":{"video_id":"VID_ID","image_url":"THUMB_URL","title":"Headline","message":"Primary text","call_to_action":{"type":"SHOP_NOW","value":{"link":"URL"}}}}}
```

### Carousel
```json
{"name":"Creative_Sales_Carousel_V1","object_story_spec":{"page_id":"PAGE_ID","link_data":{"link":"URL","message":"Primary text","child_attachments":[{"link":"URL1","image_hash":"H1","name":"Headline1","call_to_action":{"type":"SHOP_NOW","value":{"link":"URL1"}}},{"link":"URL2","image_hash":"H2","name":"Headline2","call_to_action":{"type":"SHOP_NOW","value":{"link":"URL2"}}}]}}}
```

### DCO (Dynamic Creative)
Add `"asset_feed_spec":{"images":[{"hash":"H1"},{"hash":"H2"}],"bodies":[{"text":"A"},{"text":"B"}],"titles":[{"text":"A"},{"text":"B"}],"call_to_action_types":["SHOP_NOW","LEARN_MORE"]}`
Ad set must have `use_dynamic_creative: true`.

CTAs: SHOP_NOW, LEARN_MORE, SIGN_UP, SUBSCRIBE, DOWNLOAD, GET_OFFER, GET_QUOTE, CONTACT_US, APPLY_NOW, ORDER_NOW, BUY_NOW

## Ad CRUD
```json
POST /act_{id}/ads
{"name":"Ad_Persona_CreativeV1","adset_id":"...","creative":{"creative_id":"..."},"status":"PAUSED","tracking_specs":[{"action.type":["offsite_conversion"],"fb_pixel":["PIXEL_ID"]}]}
```
```
GET /{ad_id}?fields=name,effective_status,preview_shareable_link,issues_info
GET /{ad_id}/previews?ad_format=DESKTOP_FEED_STANDARD
POST /{ad_id}  Body: {"status":"ACTIVE"}
```

## Assets
```bash
# Image upload
POST /act_{id}/adimages  Body (multipart): filename=@image.jpg → returns image_hash

# Video upload
POST /act_{id}/advideos  Body (multipart): source=@video.mp4, title="Name" → returns video_id
# Poll: GET /{video_id}?fields=status → wait for status.video_status = "ready"
```

## Targeting Search
```
GET /act_{id}/targetingsearch?q=yoga&type=adinterest
GET /act_{id}/targetingsearch?q=engaged+shoppers&type=adbehavior
GET /search?type=adgeolocation&q=Austin&location_types=city
GET /act_{id}/delivery_estimate?targeting_spec={json}&optimization_goal=OFFSITE_CONVERSIONS
```

## Batch (up to 50 sub-requests in 1 call)
```json
POST /
{"batch":[{"method":"POST","relative_url":"act_123/adsets","body":"url_encoded_params"},{"method":"POST","relative_url":"act_123/adsets","body":"..."}]}
```

## Error Codes
| Code | Meaning | Fix |
|------|---------|-----|
| 100/1487390 | Invalid parameter | Check field names/types |
| 100/1885220 | Creative spec error | Verify image_hash, page_id, link |
| 190 | Auth error | Refresh token |
| 200 | Permissions | Check app scopes |
| 429 | Rate limited | Backoff 1s/4s/16s |
| 1487301 | Budget too low | Raise above minimum (in cents!) |
| 2446079 | Targeting too narrow | Broaden audience |
| 2635012 | Ad review rejected | Fix policy violation |

Rate limits: ~200/hour, ~60/min per account. Monitor `x-business-use-case-usage` header.
