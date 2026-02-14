# ClawHost Setup Guide — Clawdbot Ready (Tier 1: VPS)

> **Source:** [github.com/bfzli/clawhost](https://github.com/bfzli/clawhost)
> **Website:** [clawhost.cloud](https://clawhost.cloud)
> **License:** MIT
> **Stack:** TypeScript monorepo (Turborepo + pnpm), Hono.js API, React + Vite frontend

---

## What Is ClawHost?

ClawHost is an open-source, self-hostable cloud hosting platform that deploys OpenClaw on a dedicated VPS in under a minute. It automates server provisioning, DNS (Cloudflare), SSL (Let's Encrypt), and firewall configuration — zero manual infrastructure work.

## Why It Fits Clawdbot Ready

ClawHost maps directly to **Tier 1 (VPS)** of the Clawdbot Ready product line:

| Tier | Hardware | Deployment Method | Target Customer |
|------|----------|------------------|-----------------|
| **Tier 1** | Hetzner VPS | **ClawHost (one-click)** | Budget / remote-first users |
| Tier 2 | Mac Mini | Pre-configured + shipped | Power users / small business |
| Tier 3 | Mac Studio | Pre-configured + local models | Enterprise / developers |

ClawHost eliminates the need to manually provision VPS instances for Tier 1 customers. They click, pay, and get a running OpenClaw instance with full root access.

## Key Features

- **One-Click Deploy** — Server selection → payment → OpenClaw live
- **Dedicated VPS** — Real servers with full root access (not shared containers)
- **Automatic SSL** — HTTPS via Let's Encrypt, zero config
- **Cloudflare DNS** — Automatic subdomain creation (e.g., `abc1234.yourdomain.com`)
- **6 Global Regions** — US, Europe, Asia coverage
- **SSH Key Management** — Store and assign keys for passwordless access
- **Persistent Storage** — Attach additional volumes to any instance
- **Fully Open Source** — MIT licensed, fork and white-label for Clawdbot Ready branding

## Architecture

```
clawhost/
├── apps/
│   ├── api/          # Hono.js backend API
│   └── web/          # React + Vite frontend (static SPA)
├── packages/
│   ├── shared/       # @openclaw/shared — HTTP client utility
│   └── i18n/         # @openclaw/i18n — Internationalization
├── scripts/
│   └── cloud-init.yaml   # Server initialization template
├── turbo.json             # Turborepo build orchestration
└── pnpm-workspace.yaml    # Workspace definition
```

## Integration Points for Clawdbot Ready

### 1. White-Label the Frontend
The React + Vite frontend builds to `apps/web/dist/` as a static SPA. Deploy under `vps.clawdbotready.com` or similar with Clawdbot Ready branding.

### 2. Custom cloud-init for Clawdbot Ready Stack
Modify `scripts/cloud-init.yaml` to pre-install the Clawdbot Ready stack:
- OpenClaw with curated AgentSkills
- claude-mem for persistent memory
- just-bash sandbox layer (when ready)
- Pre-configured channel integrations (Telegram, Discord, WhatsApp)

### 3. Pricing Tier Configuration
The default pricing markup on Hetzner base prices is configurable in the plans controller. Set Tier 1 margins here.

### 4. Custom Domain Support
Instances get subdomains like `abc1234.yourdomain.com`. Update the Cloudflare zone configuration for `clawdbotready.com` subdomains.

### 5. Internationalization
All UI text managed through `@openclaw/i18n` in `packages/i18n/src/langs/en.ts`. Add Clawdbot Ready terminology.

## Prerequisites

- Node.js >= 20
- pnpm 9.14+
- TypeScript (strict mode)
- Hetzner API key (for VPS provisioning)
- Cloudflare API key (for DNS automation)

## Local Development

```bash
# Clone
git clone https://github.com/bfzli/clawhost.git
cd clawhost

# Install dependencies
pnpm install

# Start dev
pnpm dev
```

## Deployment Notes

- SSL certificates may take 1-2 minutes to provision after server boot
- cloud-init script includes retry logic for certificate generation
- Static SPA can be deployed to any hosting provider (Vercel, Cloudflare Pages, etc.)

## Security Considerations for Tier 1

Since Tier 1 customers are on shared VPS infrastructure (vs dedicated hardware in Tier 2/3):
- **just-bash sandbox** should be the default execution layer (InMemoryFs only)
- **Network allow-lists** should restrict which external APIs the agent can call
- **Gateway auth tokens** must be required (no open loopback)
- **Automatic backups** via Hetzner snapshots before any OpenClaw updates

## Related Clawdbot Ready Features

- [Just-Bash Integration](../PLANNING/features/just-bash/) — Sandboxed execution for Tier 1
- [claude-mem](../PLANNING/features/claude-mem/) — Persistent memory across sessions

---

*Added: February 2026*
*Status: Evaluation / Integration Planning*
