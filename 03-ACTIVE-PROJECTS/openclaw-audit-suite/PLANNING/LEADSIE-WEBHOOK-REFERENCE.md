# Leadsie Webhook Reference

## Endpoint Configuration
Set in Leadsie Dashboard → Settings → Webhooks & API

**Your webhook URL:** `https://your-domain.com/webhooks/leadsie`

## Trigger
Fires when a client successfully connects (grants access to) one or more platform assets.

## Payload Structure

```json
{
  "user": "custom_user_id_or_generated",
  "customUserId": "org_123",
  "clientName": "Acme Corp",
  "requestUrl": "https://app.leadsie.com/connect/openclaw",
  "requestName": "OpenClaw Audit Access",
  "accessLevel": "admin",
  "status": "SUCCESS",
  "connectionAssets": [
    {
      "type": "Meta Ad Account",
      "name": "Acme Corp Ad Account",
      "id": "act_123456789",
      "success": true,
      "message": "",
      "timestamp": "2026-03-03T12:00:00Z",
      "platform": "meta",
      "permissions": ["ads_management", "ads_read"],
      "directLink": "https://business.facebook.com/adsmanager/..."
    },
    {
      "type": "Google Analytics Account",
      "name": "Acme Corp GA4",
      "id": "properties/123456",
      "success": true,
      "message": "",
      "timestamp": "2026-03-03T12:00:00Z",
      "platform": "google",
      "permissions": ["read"],
      "directLink": "https://analytics.google.com/..."
    }
  ]
}
```

## Status Values
| Status | Meaning |
|--------|---------|
| `SUCCESS` | All requested assets connected |
| `PARTIAL_SUCCESS` | Some assets connected, some failed |
| `FAILED` | No assets connected |

## Access Levels
| Level | Meaning |
|-------|---------|
| `view` | Read-only access to platform data |
| `admin` | Full management access (preferred for audit) |

## Supported Asset Types (25+)
Meta: Ad Account, Page, Pixel, Instagram Account, Catalog, Business Manager
Google: Ads Account, Analytics Property, Tag Manager Container, Search Console, YouTube Channel
Shopify: Store access
TikTok: Ad Account, Business Center
LinkedIn: Ad Account, Organization Page
Plus: HubSpot, WordPress, X (Twitter), and more

## Key Notes
- **No retry logic documented** — implement your own idempotency
- **No webhook signatures** — validate via customUserId matching
- **Non-expiring access** — tokens don't expire unless manually revoked
- **Custom user tracking** — append `?customUserId=org_123` to connect URL
- Track users by associating customUserId with your org records

## Integration Pattern
1. Generate connect URL: `app.leadsie.com/connect/openclaw?customUserId={orgId}`
2. Send to prospect (email, embed, or in-app)
3. Prospect clicks and grants access
4. Leadsie POSTs webhook to your endpoint
5. Parse connectionAssets → route to adapters → start audit pipeline
