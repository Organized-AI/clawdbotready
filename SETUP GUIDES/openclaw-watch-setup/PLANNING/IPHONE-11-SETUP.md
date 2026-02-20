# 🦞📱 OpenClaw iOS Setup (iPhone 11)

**Status**: 🧪 Super-Alpha (Build from Source)
**Device**: iPhone 11 (A13 Bionic, 4GB RAM)
**iOS**: iOS 26 (minimum required for watchOS 26 pairing)
**Source**: [openclaw/openclaw/apps/ios](https://github.com/openclaw/openclaw/tree/main/apps/ios)

---

## iPhone 11 Compatibility Assessment

### What Works ✅
- **iOS 26 supported** — iPhone 11 is the oldest model compatible with iOS 26
- **watchOS 26 pairing** — iPhone 11 with iOS 26 can pair with Apple Watch Series 6+
- **APNs push delivery** — Silent push wake works on all iOS 26 devices
- **WCSession** — Watch Connectivity framework works on iPhone 11
- **OpenClaw node registration** — A13 Bionic meets minimum requirements

### Known Limitations ⚠️
- **4GB RAM** — The iPhone 11 has 4GB vs 6GB+ on iPhone 13 and later. iOS will kill backgrounded apps more aggressively. The APNs silent push wake (PR #20332) compensates for this, but expect more frequent app suspensions.
- **No Apple Intelligence** — Requires A17 Pro+. Irrelevant for OpenClaw since AI processing happens on the gateway.
- **Foreground-first** — The OpenClaw iOS README states "foreground use is the only reliable mode right now." On a 4GB device, this caveat is amplified.
- **Battery** — A 2019 device will have degraded battery. Running OpenClaw + gateway WebSocket + APNs will drain faster than a newer phone.
- **No ProMotion** — 60Hz display. Purely cosmetic, doesn't affect OpenClaw functionality.

### Verdict
**iPhone 11 will work for this experiment.** It's on the edge of compatibility, but since OpenClaw's heavy lifting happens on the gateway (not the phone), the iPhone is just a relay and notification surface. The 4GB RAM means you'll want to keep the app in the foreground when actively using it, and rely on APNs wake for background delivery.

---

## Architecture: iPhone 11 as OpenClaw Node

```
┌────────────────────────────────────────────────────────────┐
│                     iPhone 11 (A13 Bionic)                 │
│                                                            │
│  ┌──────────────────────────────┐                          │
│  │   OpenClaw iOS App           │                          │
│  │   (role: node)               │                          │
│  │                              │                          │
│  │   • Gateway WebSocket client │◄──── APNs silent push    │
│  │   • Chat UI                  │      (wakes app when     │
│  │   • Share Extension          │       backgrounded)      │
│  │   • Voice Wake               │                          │
│  │   • Canvas rendering         │                          │
│  │   • WCSession relay ─────────┼──► Apple Watch           │
│  │                              │                          │
│  └──────────────────────────────┘                          │
│                                                            │
│  Key iPhone 11 Constraints:                                │
│  • 4GB RAM → aggressive background kill                    │
│  • A13 Bionic → no Apple Intelligence                      │
│  • Battery: 3110 mAh (likely degraded)                     │
│                                                            │
└───────────────────────────┬────────────────────────────────┘
                            │
                     WebSocket / APNs
                            │
                   ┌────────▼─────────┐
                   │  OpenClaw Gateway │
                   │  (Mac Studio /   │
                   │   Mac Mini / VPS) │
                   └──────────────────┘
```

---

## Phased Implementation

### Phase 0: iPhone 11 Preparation

**Before touching OpenClaw, get the iPhone ready.**

- [ ] **Check battery health**: Settings → Battery → Battery Health & Charging. If Maximum Capacity is below 80%, consider a battery replacement ($89 at Apple) — a dying battery will make this experiment miserable.
- [ ] **Update to iOS 26**: Settings → General → Software Update. Must be iOS 26 for watchOS 26 pairing.
- [ ] **Free up storage**: OpenClaw + Xcode artifacts need space. Aim for 5GB+ free.
- [ ] **Enable Background App Refresh**: Settings → General → Background App Refresh → ON for OpenClaw (once installed).
- [ ] **Disable Low Power Mode**: LPM throttles background activity and APNs delivery.

### Phase 1: Install Xcode & Build Environment

On your Mac (MacBook M1 Pro or Mac Mini M4):

```bash
# Ensure Xcode 16+ is installed from Mac App Store
xcode-select --install

# Clone OpenClaw
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Install dependencies
pnpm install

# Configure iOS signing
./scripts/ios-configure-signing.sh

# Generate Xcode project
cd apps/ios
xcodegen generate
open OpenClaw.xcodeproj
```

### Phase 2: Configure Signing for iPhone 11

Per the OpenClaw iOS README:

```bash
# Copy the example local signing config
cp apps/ios/LocalSigning.xcconfig.example apps/ios/LocalSigning.xcconfig
```

Edit `LocalSigning.xcconfig`:
```
OPENCLAW_DEVELOPMENT_TEAM = YOUR_APPLE_TEAM_ID
PRODUCT_BUNDLE_IDENTIFIER = com.yourname.openclaw
```

In Xcode:
- Select the OpenClaw target
- Signing & Capabilities → Select your personal team
- Change the bundle identifier to something unique (free accounts can't use the real bundle ID)
- Connect your iPhone 11 via USB
- Select it as the run destination
- Build (⌘+B) to verify signing works

### Phase 3: Build & Deploy to iPhone 11

```bash
# Build and run (⌘+R in Xcode)
# OR command line:
xcodebuild -scheme OpenClaw -destination 'platform=iOS,name=iPhone 11' build
```

After the app installs:
- On iPhone 11: Settings → General → VPN & Device Management → Trust your developer certificate
- Launch the OpenClaw app
- It will request notification permissions — **Allow** (critical for APNs)

### Phase 4: Pair with Gateway

On your gateway machine (Mac Studio or Mac Mini):

```bash
# Verify gateway version
openclaw version  # Must be 2026.2.19+

# Initiate device pairing
openclaw devices pair
```

On the iPhone 11:
- Open OpenClaw app → Settings → Gateway Connection
- Enter the pairing code or scan QR
- Wait for "Connected" status

Verify from gateway:
```bash
openclaw devices list
# Should show your iPhone 11 as a paired node

openclaw nodes list
# Should show iPhone 11 as active
```

### Phase 5: Configure APNs

See the [APNs Configuration Guide](PHASE-2-APNS-CONFIGURATION.md) in the Watch setup for full details. The iPhone 11 APNs setup is identical — the Watch just adds a relay layer on top.

### Phase 6: Test iPhone-Only (Before Watch)

Before adding the Watch complication, verify the iPhone works standalone:

```bash
# Send a test message
openclaw message send --to self --text "Testing iPhone 11 node 🦞"

# Test APNs wake (lock the iPhone first)
openclaw push-test --device <your-device-id>

# Check logs for iPhone 11 specific issues
openclaw logs --filter "ios\|node\|apns" --follow
```

**iPhone 11-specific things to watch for:**
- Does the app get killed after X minutes in background?
- Does APNs silent push reliably wake it?
- How fast does battery drain with WebSocket open?
- Does the Share Extension work (share URLs/text to OpenClaw from Safari)?

---

## Battery & Performance Tips for iPhone 11

Since the iPhone 11 is a 2019 device, optimize for longevity:

- **Keep OpenClaw in foreground** when actively using it — don't rely on background mode
- **Use APNs wake** as the primary background delivery mechanism
- **Disable unnecessary channels** — if you only need Telegram relay, don't configure all channels
- **Wi-Fi over cellular** — WebSocket over Wi-Fi uses less power
- **Plug in when at desk** — treat it as a semi-tethered relay device

---

## If It Doesn't Work

If the iPhone 11 proves too unreliable as a node (background kills, memory pressure, battery):

- **iPhone 12 mini** ($150-200 used) — 4GB RAM but A14 Bionic, better power efficiency
- **iPhone 13 mini** ($200-250 used) — **6GB RAM**, A15 Bionic, significant upgrade for background reliability
- **iPhone SE 3rd Gen** ($180-220 used) — A15 Bionic, 4GB RAM, but smaller/lighter

The iPhone 13 series is the sweet spot where Apple bumped to 6GB RAM, which makes a real difference for background app survival.

---

*Created: 2026-02-20*
*Based on: OpenClaw v2026.2.19 + iOS app super-alpha README*
