# Phase 0: Prerequisites

**Goal**: Ensure all hardware, software, and accounts are ready before building.

---

## Hardware Checklist

- [ ] Apple Watch Series 6 or later (must support watchOS 26 — see [HARDWARE-SOURCING-GUIDE.md](../HARDWARE-SOURCING-GUIDE.md))
- [ ] iPhone 11 or later with iOS 26 — paired with the Apple Watch (iPhone 11 is the oldest compatible model)
- [ ] Mac with Apple Silicon (M1+) — for Xcode builds
- [ ] Running OpenClaw Gateway on one of:
  - Mac Studio / Mac Mini (local)
  - Hetzner VPS (cloud)
  - DigitalOcean (cloud)

## Software Checklist

- [ ] macOS Sequoia or later
- [ ] Xcode 16+ installed from Mac App Store (includes watchOS SDK)
- [ ] Xcode Command Line Tools: `xcode-select --install`
- [ ] Node.js 20+ and pnpm: `brew install node pnpm`
- [ ] OpenClaw Gateway updated to v2026.2.19+:
  ```bash
  pnpm add -g openclaw@latest
  openclaw version  # Should show 2026.2.19 or later
  ```
- [ ] Git configured with SSH key for GitHub access

## Accounts Checklist

- [ ] Apple Developer Account (developer.apple.com) — free tier is sufficient for personal device signing
- [ ] GitHub account with access to `openclaw/openclaw` repository
- [ ] At least one messaging channel already configured in OpenClaw (Telegram, WhatsApp, etc.)

## Gateway Pre-Flight

Verify your gateway is healthy before proceeding:

```bash
# Check gateway status
openclaw status

# Verify at least one channel is active
openclaw channels list

# Confirm you're on the right version
openclaw version
```

If your gateway is not running v2026.2.19+, upgrade first:

```bash
# Update OpenClaw
pnpm add -g openclaw@latest

# Restart gateway
openclaw gateway restart
```

---

## Environment Variables Reference

These will be needed in later phases:

| Variable | Description | Where |
|----------|-------------|-------|
| `OPENCLAW_DEVELOPMENT_TEAM` | Apple Developer Team ID | Xcode signing |
| `OPENCLAW_HOME` | Gateway data directory | Gateway host |
| `OPENCLAW_GATEWAY_URL` | Gateway WebSocket endpoint | iOS app config |

---

**Next**: [Phase 1 — iOS Build & Pair](PHASE-1-IOS-BUILD-AND-PAIR.md)
