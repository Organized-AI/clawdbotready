# 🦔 PostHog: Cloud vs Self-Hosted

> A comprehensive comparison for Clawdbot deployments

---

## Quick Decision Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WHICH POSTHOG DEPLOYMENT?                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   START HERE                                                                │
│       │                                                                     │
│       ▼                                                                     │
│   ┌───────────────────────────────────┐                                    │
│   │ Do you need complete data         │                                    │
│   │ sovereignty (HIPAA, regulated)?   │                                    │
│   └───────────────┬───────────────────┘                                    │
│                   │                                                         │
│         ┌────────┴────────┐                                                │
│         │                 │                                                │
│        YES               NO                                                │
│         │                 │                                                │
│         ▼                 ▼                                                │
│   ┌───────────┐    ┌───────────────────────────────┐                      │
│   │SELF-HOST  │    │ Will you exceed 1M events/mo? │                      │
│   │(See below)│    └───────────────┬───────────────┘                      │
│   └───────────┘                    │                                       │
│                          ┌─────────┴─────────┐                             │
│                          │                   │                             │
│                         YES                 NO                             │
│                          │                   │                             │
│                          ▼                   ▼                             │
│                    ┌───────────┐      ┌─────────────┐                     │
│                    │CLOUD PAID │      │ CLOUD FREE  │                     │
│                    │  TIER     │      │   TIER ⭐    │                     │
│                    └───────────┘      └─────────────┘                     │
│                                                                             │
│   ⭐ RECOMMENDED FOR MOST CLAWDBOT USERS                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Comparison

| Factor | PostHog Cloud | Self-Hosted (Hobby) |
|--------|---------------|---------------------|
| **Setup Time** | 5 minutes | 30-60 minutes |
| **Setup Complexity** | ⭐ Sign up and go | ⭐⭐⭐ Requires VPS + Docker |
| **Monthly Cost** | Free (1M events) | $5-15/mo server costs |
| **Event Limit** | 1M free, then pay | ~100k recommended max |
| **Data Location** | US or EU (your choice) | Wherever you host |
| **Data Ownership** | PostHog manages | You own everything |
| **Compliance** | SOC 2 Type II, GDPR | Full control (you manage) |
| **Scaling** | Automatic | Manual (your responsibility) |
| **Maintenance** | Zero | You handle updates |
| **Support** | Community + Paid tiers | Community only |
| **Uptime SLA** | 99.9% (paid tiers) | Depends on your infra |
| **Backups** | Automatic | You configure |
| **SSL/HTTPS** | Automatic | You configure |

---

## PostHog Cloud (Recommended)

### Free Tier Includes

```
┌─────────────────────────────────────────────────────────────────┐
│                    POSTHOG CLOUD FREE TIER                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📊 Product Analytics        1,000,000 events/month            │
│  🎬 Session Replay           5,000 recordings/month            │
│  🚩 Feature Flags            1,000,000 API requests/month      │
│  🧪 A/B Testing              1,000,000 API requests/month      │
│  📋 Surveys                  250 responses/month               │
│  🗄️ Data Warehouse           1,000,000 rows synced/month       │
│                                                                 │
│  Hosting Options:                                               │
│  • US Cloud (us.posthog.com)                                   │
│  • EU Cloud (eu.posthog.com) - GDPR compliant                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Setup (5 Minutes)

```bash
# 1. Sign up at posthog.com
# 2. Create project, get API key

# 3. Install SDK
npm install posthog-node

# 4. Initialize
import { PostHog } from 'posthog-node';
const posthog = new PostHog('phc_YOUR_API_KEY', {
  host: 'https://us.posthog.com'  // or eu.posthog.com
});

# 5. Track events
posthog.capture({
  distinctId: 'user-123',
  event: 'gateway_started'
});
```

### When to Use Cloud

✅ Most Clawdbot deployments  
✅ Getting started quickly  
✅ Under 1M events/month  
✅ Don't want infrastructure overhead  
✅ Need reliability without maintenance  
✅ GDPR compliance (use EU cloud)  

---

## Self-Hosted (Hobby Deployment)

### Requirements

```
┌─────────────────────────────────────────────────────────────────┐
│                 SELF-HOSTED REQUIREMENTS                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  MINIMUM SPECS (Hobby/Development):                             │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  • 4 vCPU                                                 │ │
│  │  • 16 GB RAM (minimum, 8GB may work with limitations)     │ │
│  │  • 30+ GB storage (SSD recommended)                       │ │
│  │  • Ubuntu 22.04 LTS                                       │ │
│  │  • Docker & Docker Compose                                │ │
│  │  • Domain with DNS A record                               │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  RECOMMENDED VPS OPTIONS:                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Hetzner CPX31     €15/mo    4 vCPU, 8GB RAM, 160GB      │ │
│  │  Hetzner CPX41     €28/mo    8 vCPU, 16GB RAM, 240GB ⭐   │ │
│  │  DigitalOcean      $48/mo    4 vCPU, 8GB RAM, 160GB      │ │
│  │  AWS t3.xlarge     ~$120/mo  4 vCPU, 16GB RAM            │ │
│  │  GCP n2-standard-4 ~$100/mo  4 vCPU, 16GB RAM            │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  EVENT VOLUME LIMIT:                                            │
│  • Recommended max: ~100,000 events/month                      │
│  • Beyond this, PostHog recommends Cloud due to complexity     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### One-Line Deploy

```bash
# SSH into your VPS
ssh root@your-server-ip

# Run the hobby deployment script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/posthog/posthog/HEAD/bin/deploy-hobby)"

# You'll be prompted for:
# - Release tag (use 'latest' or check DockerHub for specific version)
# - Domain name (e.g., analytics.yourdomain.com)

# Wait 5-10 minutes for:
# - Containers to start
# - Migrations to complete
# - SSL certificate to be issued

# Access at https://analytics.yourdomain.com
```

### Upgrade Self-Hosted

```bash
# Run upgrade script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/posthog/posthog/HEAD/bin/upgrade-hobby)"
```

### Docker Compose Overview

The hobby deployment runs these services:

```
┌─────────────────────────────────────────────────────────────────┐
│                 SELF-HOSTED ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    POSTHOG STACK                        │   │
│  │                                                         │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐          │   │
│  │  │  PostHog  │  │  PostHog  │  │  PostHog  │          │   │
│  │  │    Web    │  │  Worker   │  │  Plugins  │          │   │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘          │   │
│  │        │              │              │                 │   │
│  │        └──────────────┼──────────────┘                 │   │
│  │                       │                                │   │
│  │  ┌────────────────────┼────────────────────┐          │   │
│  │  │                    │                    │          │   │
│  │  ▼                    ▼                    ▼          │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐          │   │
│  │  │ClickHouse │  │ PostgreSQL│  │   Redis   │          │   │
│  │  │(Analytics)│  │ (Metadata)│  │  (Cache)  │          │   │
│  │  └───────────┘  └───────────┘  └───────────┘          │   │
│  │                       │                                │   │
│  │                       ▼                                │   │
│  │                 ┌───────────┐                          │   │
│  │                 │   Kafka   │                          │   │
│  │                 │ (Events)  │                          │   │
│  │                 └───────────┘                          │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  CADDY (Reverse Proxy + Auto SSL)                              │
│  └─▶ https://analytics.yourdomain.com                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use Self-Hosted

✅ Full data sovereignty required  
✅ HIPAA or strict compliance needs  
✅ Air-gapped environments  
✅ <100k events/month  
✅ Have DevOps resources for maintenance  
✅ Cost optimization for low volume  

### Self-Hosted Limitations

⚠️ **No official support** - Community help only  
⚠️ **MIT licensed without guarantee** - You assume all risk  
⚠️ **You manage everything** - Updates, backups, scaling  
⚠️ **~100k events/month limit** - Beyond this, Cloud recommended  
⚠️ **Single project only** - Hobby deployment is limited  

---

## Integration with Clawdbot Deployments

### Clawdbot + PostHog Cloud (Recommended)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   CLAWDBOT (Any Deployment)                                     │
│   ┌───────────────────────────────────────────────────────────┐│
│   │  macOS Local │ Docker │ Fly.io │ Hetzner │ GCP           ││
│   └───────────────────────────────────────────────────────────┘│
│                           │                                     │
│                           │ HTTPS (posthog-node SDK)           │
│                           ▼                                     │
│   ┌───────────────────────────────────────────────────────────┐│
│   │               POSTHOG CLOUD                               ││
│   │         https://us.posthog.com (or eu.)                   ││
│   └───────────────────────────────────────────────────────────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Environment Variables:**
```bash
POSTHOG_API_KEY=phc_your_project_api_key
POSTHOG_HOST=https://us.posthog.com
```

### Clawdbot + PostHog Self-Hosted (Enterprise)

For customers needing full data control, co-locate PostHog with Clawdbot:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTERPRISE VPS                               │
│                    (Hetzner/GCP/AWS)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────┐    ┌─────────────────────┐           │
│   │   CLAWDBOT          │    │   POSTHOG           │           │
│   │   GATEWAY           │───▶│   SELF-HOSTED       │           │
│   │                     │    │                     │           │
│   │   Port 18789        │    │   Port 8000         │           │
│   └─────────────────────┘    └─────────────────────┘           │
│                                                                 │
│   Tailscale VPN for secure remote access                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Environment Variables:**
```bash
POSTHOG_API_KEY=phc_your_selfhosted_key
POSTHOG_HOST=https://analytics.yourdomain.com
```

---

## Cost Comparison

| Scenario | Cloud Cost | Self-Hosted Cost | Winner |
|----------|------------|------------------|--------|
| 50k events/mo | $0 | $15/mo (VPS) | ☁️ Cloud |
| 500k events/mo | $0 | $28/mo (VPS) | ☁️ Cloud |
| 1M events/mo | $0 | $28/mo (VPS) | ☁️ Cloud |
| 2M events/mo | ~$100/mo | Not recommended | ☁️ Cloud |
| Full data sovereignty | N/A | $28/mo | 🏠 Self-Host |

---

## Migration Paths

### Cloud → Self-Hosted

PostHog provides export tools, but this is rarely needed.

### Self-Hosted → Cloud

Recommended path if you outgrow hobby deployment:

1. Export data from self-hosted instance
2. Create PostHog Cloud account
3. Use historical import tools
4. Update `POSTHOG_HOST` in Clawdbot config
5. Decommission self-hosted instance

---

## Recommendation Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    FINAL RECOMMENDATION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   FOR MOST CLAWDBOT USERS:                                      │
│   ════════════════════════                                      │
│                                                                 │
│   ⭐ START WITH POSTHOG CLOUD (FREE TIER)                       │
│                                                                 │
│   • Instant setup (5 minutes)                                  │
│   • Zero maintenance                                           │
│   • 1M events/month free                                       │
│   • Automatic scaling                                          │
│   • EU hosting for GDPR                                        │
│                                                                 │
│   ─────────────────────────────────────────────────────────────│
│                                                                 │
│   FOR ENTERPRISE/REGULATED CUSTOMERS:                           │
│   ═══════════════════════════════════                          │
│                                                                 │
│   🏠 SELF-HOST ON HETZNER CPX41 (~€28/mo)                       │
│                                                                 │
│   • Full data sovereignty                                      │
│   • Air-gapped deployment option                               │
│   • HIPAA/compliance control                                   │
│   • Keep under 100k events/month                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Resources

- [PostHog Cloud Signup](https://posthog.com/signup)
- [Self-Host Documentation](https://posthog.com/docs/self-host)
- [Hobby Deployment Script](https://github.com/PostHog/posthog/blob/HEAD/bin/deploy-hobby)
- [Environment Variables](https://posthog.com/docs/self-host/configure/environment-variables)
- [Troubleshooting Guide](https://posthog.com/docs/self-host/deploy/troubleshooting)

---

*Last Updated: January 2026*
*Project: Clawdbot Ready - clawdbot.organizedai.vip*
