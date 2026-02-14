# Moltworker Implementation Master Plan

## Project Metadata

- **Name:** OpenClaw on Cloudflare Workers (Moltworker)
- **Target:** Cloudflare Workers with Sandbox containers
- **Platform:** Cloud (any machine with Node.js)
- **Runtime:** Cloudflare Workers + Sandbox (Linux container)
- **Source:** https://github.com/cloudflare/moltworker

## Overview

Deploy OpenClaw as a Cloudflare Worker running inside a sandboxed container. This is the **cloud deployment option** — no physical hardware required, always-on, globally accessible.

### When to Use This Option

- You want cloud-hosted, always-on deployment
- You don't need iMessage (requires macOS)
- You want built-in browser automation (CDP)
- You prefer managed infrastructure over self-hosting
- Budget: ~$35-40/month

### When NOT to Use This Option

- You need iMessage support → use VM or Native macOS
- You need zero ongoing cost → use VM or Native macOS
- You need full macOS capabilities → use VM or Native macOS
- You need production-grade stability → moltworker is experimental

## Phase Overview

| Phase | Name | Safety | Dependencies | Estimated Time |
|-------|------|--------|--------------|----------------|
| 0 | Prerequisites Verification | 🟢 Safe | None | 2 min |
| 1 | Clone and Configure | 🟡 Review | Phase 0 | 5 min |
| 2 | Cloudflare Access | 🟡 Review | Phase 1 | 5 min |
| 3 | Deploy to Workers | 🟠 Caution | Phase 2 | 3 min |
| 4 | R2 + Chat Channels | 🟡 Review | Phase 3 | 5 min |
| 5 | Verify + Pair Devices | 🟢 Safe | Phase 4 | 3 min |

**Total estimated time: ~15-20 minutes**

## Safety Verification Legend

- 🟢 **Safe** — Read-only operations, no system changes
- 🟡 **Review** — Downloads/installs software, sets secrets
- 🟠 **Caution** — Deploys to production, creates cloud resources
- 🔴 **Critical** — Not used (no destructive operations in this plan)

## Phase Dependencies

```
Phase 0 (Prerequisites)
    │
    ▼
Phase 1 (Clone + Secrets)
    │
    ▼
Phase 2 (CF Access)
    │
    ▼
Phase 3 (Deploy) ─────────┐
    │                       │
    ▼                       │
Phase 4 (R2 + Channels)    │  Can skip Phase 2 if
    │                       │  you accept unprotected
    ▼                       │  admin UI
Phase 5 (Verify + Pair) ◀──┘
```

## Rollback Procedures

| Phase | Rollback |
|-------|----------|
| 0 | Nothing to rollback (read-only) |
| 1 | `rm -rf <moltworker-dir>` to remove clone |
| 2 | Remove CF Access app from Zero Trust dashboard |
| 3 | `npx wrangler delete moltworker` or `./scripts/teardown.sh` |
| 4 | Secrets are overwritten on next deploy; R2 bucket needs manual deletion |
| 5 | Nothing to rollback (read-only) |

## Cost Model

### Always-On (~$34.50/month)
- Workers Paid: $5
- Container (4 GiB RAM, 0.5 vCPU, 8 GB disk): ~$29.50

### With Sleep Timer (~$10-15/month)
- Set `SANDBOX_SLEEP_AFTER=10m`
- Pay only for active minutes
- Cold start: 1-2 minutes

### Free Tier Components
- Cloudflare Access: Free (up to 50 users)
- R2 Storage: Free (up to 10 GB/month)
- AI Gateway: Free tier available
- Browser Rendering: Included with Workers Paid

## Git Commit Strategy

After completing setup, commit the configuration (without secrets):

```bash
git add "SETUP GUIDES/moltworker-setup/"
git commit -m "feat: add Cloudflare Workers deployment option (moltworker)"
```

## Quick Start

```bash
cd "SETUP GUIDES/moltworker-setup"
chmod +x setup.sh scripts/*.sh
./setup.sh all
```

Or phase by phase:

```bash
./setup.sh 0    # Check prerequisites
./setup.sh 1    # Clone + configure
./setup.sh 2    # Cloudflare Access
./setup.sh 3    # Deploy
./setup.sh 4    # R2 + channels
./setup.sh 5    # Verify
```
