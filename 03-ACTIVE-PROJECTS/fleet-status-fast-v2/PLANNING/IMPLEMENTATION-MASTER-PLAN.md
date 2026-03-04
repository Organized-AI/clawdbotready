# Fleet Status Fast v2 — Implementation Master Plan

**Created:** 2026-02-28
**Project Path:** ~/Organized AI/Windsurf/fleet-status-fast-v2
**Runtime:** Node.js (Gateway Control API) + Apple Shortcuts (Client)
**Target Device:** openclaws-mac-mini (100.66.145.48)
**Gateway Port:** 18789

---

## Problem Statement

Cannot remotely restart the OpenClaw gateway on `100.66.145.48` because:
1. SSH keys from MacBook Pro are not authorized on the Mac Mini
2. VNC/Screen Sharing is disabled
3. No HTTP-based restart mechanism exists
4. Fleet Status Fast v1 can read status but cannot trigger actions

The gateway is reachable over Tailscale via HTTP (port 18789 returns 200), but there's no authenticated API endpoint for lifecycle management.

---

## Architecture: Gateway Control API + Apple Shortcuts

```
┌─────────────────────────────────────────────────────────────┐
│  Apple Devices (iPhone / Watch / Mac)                       │
│  ┌─────────────────────────────────────┐                    │
│  │  Fleet Status Fast v2 (Shortcut)    │                    │
│  │  • GET  /fleet/health  → Status     │                    │
│  │  • POST /fleet/restart → Restart    │                    │
│  │  • GET  /fleet/info    → System     │                    │
│  └──────────────┬──────────────────────┘                    │
│                 │ HTTPS (Tailscale)                          │
├─────────────────┼───────────────────────────────────────────┤
│  openclaws-mac-mini (100.66.145.48)                         │
│                 │                                            │
│  ┌──────────────▼──────────────────────┐                    │
│  │  Fleet Control API (port 3847)      │                    │
│  │  • Bearer token auth                │                    │
│  │  • Binds to Tailscale interface     │                    │
│  │  • Runs as launchd service          │                    │
│  └──────────────┬──────────────────────┘                    │
│                 │                                            │
│  ┌──────────────▼──────────────────────┐                    │
│  │  OpenClaw Gateway (port 18789)      │                    │
│  │  • SIGUSR1 for in-process restart   │                    │
│  │  • `openclaw gateway restart` CLI   │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  ┌─────────────────────────────────────┐                    │
│  │  Watchdog (launchd timer)           │                    │
│  │  • Health check every 60s           │                    │
│  │  • Auto-restart after 2 failures    │                    │
│  │  • Telegram alert on restart        │                    │
│  └─────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Pre-Implementation Checklist

### Existing Infrastructure
| Component | Status | Notes |
|-----------|--------|-------|
| OpenClaw Gateway | ✅ Running | Port 18789, HTTP 200 confirmed |
| Tailscale Mesh | ✅ Active | 100.66.145.48 reachable |
| commands.restart | ✅ Enabled | Set to true in openclaw.json |
| Fleet Status Fast v1 | ✅ Working | Read-only status checks |
| Telegram Bot | ✅ Active | @SAMyosin_bot |
| Node.js on Mac Mini | ✅ Available | OpenClaw requires it |

### To Build
| Component | Phase | Status |
|-----------|-------|--------|
| SSH key authorization | Phase 0 | ⏳ |
| Fleet Control API server | Phase 1 | ⏳ |
| Watchdog health checker | Phase 2 | ⏳ |
| Fleet Status Fast v2 Shortcut | Phase 3 | ⏳ |
| Telegram restart command | Phase 4 | ⏳ |

---

## Implementation Phases Overview

| Phase | Name | Key Deliverables | Dependencies |
|-------|------|-----------------|--------------|
| 0 | SSH Access Fix + Project Setup | Authorized keys, repo, deps | Physical/remote access to Mac Mini |
| 1 | Fleet Control API | HTTP server with health/restart/info endpoints | Phase 0 |
| 2 | Watchdog + Auto-Recovery | launchd timer, auto-restart, Telegram alerts | Phase 1 |
| 3 | Fleet Status Fast v2 Shortcut | Apple Shortcut with restart action for iOS/Watch/Mac | Phase 1 |
| 4 | Telegram Integration + Hardening | Bot restart command, rate limiting, logging | Phase 2, 3 |

---

## Success Criteria (Overall)

- [ ] Can restart OpenClaw gateway remotely from iPhone/Apple Watch via HTTP
- [ ] Bearer token authentication on all control endpoints
- [ ] API binds only to Tailscale interface (not 0.0.0.0)
- [ ] Watchdog auto-restarts gateway within 120s of failure
- [ ] Telegram notification on every restart (manual or auto)
- [ ] SSH access fixed from MacBook Pro to Mac Mini
- [ ] Fleet Status Fast v2 shortcut works on iOS, watchOS, and macOS
- [ ] All services survive Mac Mini reboot (launchd persistence)

---

## Security Model

- **Auth:** Bearer token (64-char random, stored in macOS Keychain)
- **Network:** API binds to Tailscale IP only (100.66.145.48)
- **Rate limiting:** Max 5 restart requests per hour
- **Logging:** All restart attempts logged with timestamp, source IP, result
- **No public exposure:** Zero inbound ports on public network
