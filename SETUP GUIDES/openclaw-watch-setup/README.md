# 🦞⌚ OpenClaw Apple Watch Setup

**Status**: 🧪 MVP (Experimental — shipped v2026.2.19)
**Platform**: Apple Watch (companion to OpenClaw iOS app)
**Release**: [v2026.2.19 Changelog](https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md#2026219)

---

## What Shipped in v2026.2.19

The Apple Watch companion is an MVP that extends OpenClaw to your wrist. Key PRs from this release:

- **iOS/Watch** (#20054): Apple Watch companion MVP — watch inbox UI, watch notification relay handling, and gateway command surfaces for watch status/send flows
- **iOS/Gateway** (#20332): Wake disconnected iOS nodes via APNs before `nodes.invoke` + auto-reconnect gateway sessions on silent push wake
- **Gateway/CLI** (#20057): Paired-device hygiene flows — `device.pair.remove`, `openclaw devices remove`, `openclaw devices clear --yes [--pending]`
- **iOS/APNs** (#20308): Push registration and notification-signing configuration for node delivery
- **Gateway/APNs** (#20307): Push-test pipeline for APNs delivery validation in gateway flows

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                    OPENCLAW WATCH + iOS STACK                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────┐         ┌──────────────────┐                     │
│   │ Apple Watch  │◄───────►│   iPhone App     │                     │
│   │              │  WCSession│  (OpenClaw iOS) │                     │
│   │ • Inbox UI   │ Relay   │                  │                     │
│   │ • Quick Reply│         │ • Full Chat UI   │                     │
│   │ • Status     │         │ • Share Extension │                     │
│   │ • Notifs     │         │ • Background Wake │                     │
│   └──────────────┘         └────────┬─────────┘                     │
│                                     │                                │
│                              APNs Push / WS                          │
│                                     │                                │
│                            ┌────────▼─────────┐                     │
│                            │  OpenClaw Gateway │                     │
│                            │  (Mac/VPS/Cloud)  │                     │
│                            │                   │                     │
│                            │ • Device Pairing  │                     │
│                            │ • APNs Delivery   │                     │
│                            │ • Node Management │                     │
│                            │ • Session Routing  │                     │
│                            └────────┬─────────┘                     │
│                                     │                                │
│               ┌─────────────────────┼─────────────────────┐         │
│               │                     │                     │         │
│        ┌──────▼──────┐    ┌────────▼────────┐   ┌───────▼───────┐ │
│        │  AI Models  │    │  Messaging      │   │  Tools &      │ │
│        │  Claude/GPT │    │  WhatsApp/TG/   │   │  Skills       │ │
│        │  Ollama     │    │  Slack/Discord  │   │  Memory       │ │
│        └─────────────┘    └─────────────────┘   └───────────────┘ │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Requirements

### Hardware
- Apple Watch Series 6 or later (for watchOS 26 — see [HARDWARE-SOURCING-GUIDE.md](HARDWARE-SOURCING-GUIDE.md) for secondhand buying advice)
- iPhone 11 or later with iOS 26 (required for watchOS 26 pairing — iPhone 11 is the oldest compatible model)
- Mac with Xcode 16+ and Apple Silicon (for building from source — no App Store release yet)
- Running OpenClaw Gateway (Mac Mini, Mac Studio, VPS, or cloud)

### Software
- OpenClaw Gateway v2026.2.19 or later (`openclaw@latest`)
- Xcode 16+ with watchOS SDK
- Apple Developer Account (free tier works for personal device signing)
- Git + Node.js 20+ (for gateway management)

### Accounts & Access
- Apple Developer Account (for code signing + APNs configuration)
- OpenClaw GitHub access (to clone and build iOS project)
- Existing OpenClaw Gateway already configured with at least one channel

---

## Phased Implementation

| Phase | Focus | Description |
|-------|-------|-------------|
| **Phase 0** | Prerequisites | Hardware check, software install, accounts setup |
| **Phase 1** | iOS Build & Pair | Build OpenClaw iOS from source, pair with gateway |
| **Phase 2** | APNs Configuration | Push notification setup for background wake + delivery |
| **Phase 3** | Watch Companion | Deploy watchOS companion app, configure WCSession relay |
| **Phase 4** | Testing & Validation | End-to-end test notification delivery, inbox, quick reply |
| **Phase 5** | Channel Integration | Wire Watch notifications into existing Clawdbot channels |

See [`PLANNING/`](PLANNING/) for detailed phase documentation.

### Additional Guides
- [**HARDWARE-SOURCING-GUIDE.md**](HARDWARE-SOURCING-GUIDE.md) — Which Apple Watch to buy secondhand, iPhone compatibility matrix, total cost
- [**PLANNING/IPHONE-11-SETUP.md**](PLANNING/IPHONE-11-SETUP.md) — Specific guide for using iPhone 11 as the OpenClaw iOS node

---

## Quick Start (Once All Phases Complete)

```bash
# Verify gateway is running v2026.2.19+
openclaw version

# Check paired devices
openclaw devices list

# Test APNs delivery to your iPhone
openclaw push-test --device <your-device-id>

# Send a test message that should relay to Watch
openclaw message send --to self --text "🦞 Hello from your wrist!"
```

---

## Current Limitations (MVP)

- **No App Store release**: Must build from source via Xcode
- **TestFlight**: Limited beta access — most users self-compile
- **Watch inbox is read-only-ish**: MVP supports viewing + quick replies, not full conversation management
- **Requires iPhone nearby**: Watch app is a companion, not standalone (no direct gateway connection)
- **APNs required**: Background wake relies on Apple Push Notification service configuration
- **iPhone 11 caveat**: 4GB RAM means more aggressive background kills — APNs silent push compensates but foreground use is most reliable
- **Super-alpha iOS app**: OpenClaw iOS README states foreground use is the only reliable mode right now

---

## Related Guides

- [OpenClaw Native Setup](../openclaw-native-setup/) — Direct macOS install
- [OpenClaw VM Setup](../openclaw-vm-setup/) — Lume hypervisor isolation
- [Clawdbot Customer Setup Guide](../clawdbot-customer-setup-guide.md) — All messaging platforms
- [Clawdbot Deployment Guide](../clawdbot-deployment-guide.md) — Platform comparison

---

*Created: 2026-02-20*
*Based on: OpenClaw v2026.2.19 release*
*Built for: Organized AI managed services*
