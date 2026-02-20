# Phase 5: Channel Integration with Clawdbot

**Goal**: Wire the Apple Watch notifications into your existing Clawdbot managed service channels and configure per-client Watch delivery preferences.

---

## 5.1 Channel-to-Watch Routing

Not every channel message should buzz your wrist. Configure selective routing:

### Gateway Configuration

In your OpenClaw config (`~/.openclaw/config.yaml` or via `openclaw configure`):

```yaml
# Example: Only relay Telegram and priority WhatsApp to Watch
watch:
  relay:
    enabled: true
    channels:
      - telegram:
          enabled: true
          filter: "all"  # or "mentions" for @-mentions only
      - whatsapp:
          enabled: true
          filter: "priority"  # only priority-flagged messages
      - discord:
          enabled: false  # too noisy for wrist
      - slack:
          enabled: false
    quiet_hours:
      enabled: true
      start: "22:00"
      end: "07:00"
      timezone: "America/Chicago"  # Austin timezone
```

### Per-Agent Watch Behavior

If you run multiple agents (e.g., client-specific Clawdbots), you can configure Watch relay per agent:

```yaml
agents:
  kevin-clawdbot:
    watch_relay: true      # Kevin's messages relay to Watch
  internal-ops:
    watch_relay: false     # Internal ops stays on desktop only
```

## 5.2 Integration with Existing Clawdbot Deployment

Your current Clawdbot Ready infrastructure already has multiple setup paths. Here's how Watch fits in:

```
EXISTING INFRASTRUCTURE
├── Mac Studio M3 Ultra (Hub)
│   └── OpenClaw Gateway (v2026.2.19+)
│       ├── Telegram Channel ──→ Watch relay ✓
│       ├── WhatsApp Channel ──→ Watch relay ✓ (priority only)
│       ├── Discord Channel  ──→ Watch relay ✗ (too noisy)
│       └── iMessage Channel ──→ Watch relay ✓
│
├── Mac Mini (Client Edge - Kevin)
│   └── OpenClaw Gateway
│       └── Client channels ──→ Watch relay for alerts only
│
NEW ADDITION
└── iPhone + Apple Watch (Your Personal Device)
    ├── OpenClaw iOS app (paired to Mac Studio gateway)
    └── Watch Companion (WCSession relay from iPhone)
```

## 5.3 Managed Service Considerations

If offering Watch integration as part of Organized AI managed services:

### For Tier 2+ Clients

The Watch companion could be a premium add-on:

- Build and distribute via TestFlight for select clients
- Configure per-client APNs delivery
- Set up dedicated notification channels that only relay high-priority alerts
- Include in the client's exec-approvals config for Watch-specific command surfaces

### Security Notes

- Watch receives message previews — ensure client data sensitivity is considered
- Quick replies from Watch go through the same gateway auth as regular messages
- APNs payloads should NOT include sensitive content in the notification body — use silent pushes with app-side content fetch
- Device pairing tokens should be included in your security rotation schedule

## 5.4 Cron & Heartbeat Integration

OpenClaw cron jobs and heartbeats (also improved in v2026.2.19) can target Watch delivery:

```bash
# Set up a daily summary that pushes to Watch
openclaw cron add \
  --name "daily-summary" \
  --schedule "0 8 * * *" \
  --agent default \
  --message "Give me a 2-sentence summary of overnight messages" \
  --watch-relay true
```

This ensures your morning summary hits your wrist at 8 AM even if your phone is on the nightstand.

---

## 5.5 What's Next After MVP

The Watch companion is currently MVP. Future releases will likely add:

- Standalone Watch connectivity (direct gateway WS over cellular)
- Complications for live gateway status
- Siri integration for voice commands to OpenClaw
- Watch-native voice memo transcription
- Rich notification categories with inline actions

Keep an eye on the [OpenClaw changelog](https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md) for updates.

---

**Previous**: [Phase 4 — Testing & Validation](PHASE-4-TESTING-VALIDATION.md)
