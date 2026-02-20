# Phase 1: iOS Build & Gateway Pairing

**Goal**: Build the OpenClaw iOS app from source and pair it with your gateway.

---

## 1.1 Clone the OpenClaw Repository

```bash
# Clone the full repo (includes iOS project)
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Checkout the release tag
git checkout v2026.2.19
```

## 1.2 Build the iOS App with Xcode

The iOS project lives inside the OpenClaw monorepo. The build system uses `xcodegen` or the included `.xcodeproj`.

```bash
# Navigate to iOS project directory
cd packages/openclaw-ios  # or apps/ios — check repo structure

# Install iOS dependencies
pnpm install

# Generate Xcode project (if using xcodegen)
pnpm run generate:xcode
```

Open the project in Xcode:

```bash
open OpenClaw.xcodeproj  # or OpenClaw.xcworkspace
```

### Configure Signing

Per PR #19993, local auto-selected signing works via `.local-signing.xcconfig`:

- In Xcode → Project Settings → Signing & Capabilities
- Select your personal team (Apple Developer Account)
- Xcode should auto-resolve signing with `OPENCLAW_DEVELOPMENT_TEAM`
- If prompted, create a `.local-signing.xcconfig` with your team ID:
  ```
  OPENCLAW_DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE
  ```

### Build & Install

- Select your physical iPhone as the build target (not Simulator)
- Build and run (⌘+R)
- Trust the developer certificate on iPhone: Settings → General → VPN & Device Management
- The OpenClaw app should launch on your iPhone

## 1.3 Pair iPhone with Gateway

Once the iOS app is installed and running:

```bash
# On your gateway machine — initiate pairing
openclaw devices pair

# The CLI will show a pairing code or QR code
# Enter this in the iOS app's Settings → Gateway Connection
```

Verify the pairing:

```bash
# List paired devices
openclaw devices list

# You should see your iPhone listed with status: paired
```

### Device Management Commands (New in v2026.2.19)

```bash
# Remove a specific paired device
openclaw devices remove <device-id>

# Clear all paired devices (requires confirmation)
openclaw devices clear --yes

# Clear only pending pairing requests
openclaw devices clear --yes --pending
```

## 1.4 Verify iOS Node Connectivity

The iOS app registers as a "node" in the OpenClaw gateway. Verify it's connected:

```bash
# Check node status
openclaw nodes list

# You should see your iPhone as an active node
# The iOS app should show "Connected" in its status bar
```

Test basic message delivery:

```bash
# Send a test message to the iOS node
openclaw message send --to self --text "Testing iOS pairing 🦞"
```

---

## Troubleshooting

**Xcode signing errors**: Ensure you have a valid Apple Developer account and your device is registered. Free accounts can only sign to 3 devices.

**Pairing timeout**: Make sure your iPhone and gateway are on the same network, or connected via Tailscale. The iOS app needs to reach the gateway WebSocket endpoint.

**Node not showing**: Force-quit and reopen the iOS app. Check that background refresh is enabled in iOS Settings → OpenClaw.

---

**Previous**: [Phase 0 — Prerequisites](PHASE-0-PREREQUISITES.md)
**Next**: [Phase 2 — APNs Configuration](PHASE-2-APNS-CONFIGURATION.md)
