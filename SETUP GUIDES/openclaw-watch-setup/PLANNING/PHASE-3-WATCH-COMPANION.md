# Phase 3: Watch Companion Deployment

**Goal**: Build and deploy the watchOS companion app, configure WCSession notification relay.

---

## How the Watch App Works

The Apple Watch companion (PR #20054) is a **WatchKit extension** that communicates with the iPhone app via `WCSession` (Watch Connectivity). It does NOT connect directly to the gateway.

```
Gateway ──APNs──→ iPhone (wakes) ──WCSession──→ Apple Watch
                      │                              │
                      │                              ├── Inbox UI
                      │                              ├── Notification display
                      │                              └── Quick reply actions
                      │
                      └── Full chat UI, Share Extension, Settings
```

## 3.1 Build the Watch App

The watchOS target is included in the same Xcode project from Phase 1:

```bash
cd openclaw/packages/openclaw-ios  # or wherever the iOS project lives
open OpenClaw.xcodeproj
```

In Xcode:

- You should see multiple targets including `OpenClaw Watch` or `OpenClawKit Watch`
- Select the **Watch App** scheme from the scheme selector
- Ensure signing is configured for the Watch target too (same Team ID)
- Select your paired Apple Watch as the run destination
  - Your iPhone must be selected as the companion device
  - Xcode → Window → Devices and Simulators to verify Watch is listed

### Build & Deploy

- Select the Watch scheme
- Build and run (⌘+R)
- Xcode will install both the updated iPhone app and the Watch extension
- The Watch app should appear on your Apple Watch home screen

## 3.2 Configure Notification Relay

The Watch companion relies on WCSession for message relay. On the iPhone app:

- Open OpenClaw iOS → Settings → Watch Integration
- Enable **Notification Relay** — this forwards gateway messages to the Watch
- Configure which channels relay to Watch (you probably don't want ALL channels buzzing your wrist)

### Notification Types on Watch

The MVP supports these notification surfaces:

| Notification | Description |
|-------------|-------------|
| **Message received** | New message from any configured channel |
| **Agent status** | Agent completion, errors, tool approvals |
| **Quick reply** | Pre-set reply options from Watch |
| **Status check** | Gateway health / node status at a glance |

## 3.3 Watch Inbox UI

The Watch inbox shows recent messages from your OpenClaw channels:

- Open the OpenClaw app on Apple Watch
- The inbox displays the most recent messages
- Tap a message to see full content (truncated for Watch display)
- Use the **quick reply** actions to respond directly from your wrist

## 3.4 Gateway Command Surfaces

The v2026.2.19 release added gateway command surfaces for Watch-specific flows:

```bash
# Check Watch status from the gateway CLI
openclaw watch status

# Send a message specifically through the Watch relay
openclaw watch send --text "Quick update from CLI"
```

These commands interact with the paired iPhone node, which relays to the Watch via WCSession.

## 3.5 Verify Watch Connectivity

```bash
# On the gateway, verify the iOS node shows Watch capability
openclaw devices list --verbose

# Expected: Device should show "watch: paired" in capabilities

# Send a test notification
openclaw push-test --device <your-device-id> --watch-relay
```

On the Watch itself:

- You should see the notification appear
- Tapping it should open the Watch inbox
- Quick reply should send back through the gateway

---

## Troubleshooting

**Watch app not installing**: Ensure the iPhone and Watch are paired in the Apple Watch app. Xcode needs both devices to be recognized.

**No notifications on Watch**: Check iPhone → Watch app → Notifications → OpenClaw is enabled. Also verify the relay setting in the OpenClaw iOS app.

**WCSession not connecting**: Force-quit both the iPhone and Watch apps, then reopen. WCSession can be finicky after first install.

**"Watch: not paired" in device list**: The iPhone app needs to run at least once after the Watch extension is installed to register Watch capability with the gateway.

---

**Previous**: [Phase 2 — APNs Configuration](PHASE-2-APNS-CONFIGURATION.md)
**Next**: [Phase 4 — Testing & Validation](PHASE-4-TESTING-VALIDATION.md)
