# Phase 2: APNs Configuration

**Goal**: Set up Apple Push Notification service so the gateway can wake the iOS app (and by extension, relay to the Watch) even when backgrounded.

---

## Why APNs Matters

The v2026.2.19 release (#20332) added the ability to **wake disconnected iOS nodes via APNs** before `nodes.invoke`. Without APNs configured, the Watch companion won't receive notifications when the iPhone app is suspended or backgrounded.

```
Gateway needs to send message
        │
        ▼
Is iOS node connected? ──── YES ──→ Send via WebSocket
        │
        NO (app backgrounded)
        │
        ▼
Send APNs silent push ──→ iPhone wakes ──→ Reconnects WS ──→ Delivers message
                                                    │
                                                    ▼
                                            Relays to Watch via WCSession
```

## 2.1 Apple Developer Portal Configuration

Navigate to [developer.apple.com/account](https://developer.apple.com/account):

- Go to **Certificates, Identifiers & Profiles**
- Under **Keys**, create a new key:
  - Name: `OpenClaw APNs Key`
  - Enable **Apple Push Notifications service (APNs)**
  - Download the `.p8` key file — you'll need this for the gateway
  - Note your **Key ID** and **Team ID**

## 2.2 Configure Gateway for APNs

On your gateway machine, set up the APNs credentials:

```bash
# Configure APNs on the gateway
openclaw configure

# When prompted for push notification settings:
# - APNs Key File: /path/to/AuthKey_XXXXXXXXXX.p8
# - Key ID: (from Apple Developer Portal)
# - Team ID: (from Apple Developer Portal)
# - Bundle ID: (the iOS app's bundle identifier)
```

Alternatively, set via environment variables:

```bash
# Add to your gateway's .env or shell profile
export OPENCLAW_APNS_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"
export OPENCLAW_APNS_KEY_ID="YOUR_KEY_ID"
export OPENCLAW_APNS_TEAM_ID="YOUR_TEAM_ID"
export OPENCLAW_APNS_BUNDLE_ID="ai.openclaw.app"  # verify actual bundle ID
```

## 2.3 Register iOS Device for Push

On the iPhone, ensure the OpenClaw app has push notification permissions:

- iPhone Settings → Notifications → OpenClaw → Allow Notifications
- In the OpenClaw iOS app → Settings → Push Notifications → Enable

The app will register its device token with the gateway automatically (PR #20308).

## 2.4 Validate APNs Delivery

Use the new push-test pipeline (PR #20307):

```bash
# Test APNs delivery to your paired iPhone
openclaw push-test --device <your-device-id>

# Expected output:
# ✓ APNs credentials valid
# ✓ Device token found for <device-id>
# ✓ Push sent successfully
# ✓ Device acknowledged wake
```

If the test fails:

```bash
# Check APNs configuration
openclaw doctor

# Verify device token is registered
openclaw devices list --verbose
```

## 2.5 Gateway Auth Cleanup

The v2026.2.19 release also fixed stale device-auth tokens (#18201). If you had a previous pairing that went stale:

```bash
# Re-pair to clear stale tokens
openclaw devices remove <device-id>
openclaw devices pair
```

---

## Troubleshooting

**"APNs credentials invalid"**: Double-check the .p8 file path and that the Key ID matches. Keys expire if revoked in the Apple Developer Portal.

**"Device token not found"**: The iOS app hasn't registered for push yet. Open the app, ensure notifications are enabled, and wait for it to sync with the gateway.

**"Push sent but device didn't wake"**: Check that iOS Background App Refresh is enabled for OpenClaw. Also verify the iPhone isn't in Low Power Mode (which throttles background activity).

---

**Previous**: [Phase 1 — iOS Build & Pair](PHASE-1-IOS-BUILD-AND-PAIR.md)
**Next**: [Phase 3 — Watch Companion](PHASE-3-WATCH-COMPANION.md)
