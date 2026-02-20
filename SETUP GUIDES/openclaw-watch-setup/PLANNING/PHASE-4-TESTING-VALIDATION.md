# Phase 4: Testing & Validation

**Goal**: End-to-end testing of the full Watch pipeline — gateway → APNs → iPhone → Watch.

---

## 4.1 Test Matrix

Run through each scenario to validate the full chain:

### Notification Delivery Tests

| Test | Action | Expected Result | Status |
|------|--------|-----------------|--------|
| **Basic push** | `openclaw push-test --device <id>` | iPhone receives silent push, reconnects | ☐ |
| **Message relay** | Send Telegram message to Clawdbot | Watch shows notification + inbox entry | ☐ |
| **Quick reply** | Reply from Watch notification | Reply routes through gateway to original channel | ☐ |
| **Background wake** | Lock iPhone, send message | APNs wakes app, Watch still gets notification | ☐ |
| **Multi-channel** | Messages from Telegram + WhatsApp | Both appear in Watch inbox, correctly labeled | ☐ |

### Device Management Tests

| Test | Action | Expected Result | Status |
|------|--------|-----------------|--------|
| **Device list** | `openclaw devices list` | Shows iPhone with watch: paired | ☐ |
| **Device remove** | `openclaw devices remove <id>` | Device removed, Watch stops receiving | ☐ |
| **Re-pair** | `openclaw devices pair` after remove | Pairing restored, Watch resumes | ☐ |
| **Stale token cleanup** | Restart gateway after re-pair | No auth token mismatch errors | ☐ |

### Edge Cases

| Test | Action | Expected Result | Status |
|------|--------|-----------------|--------|
| **iPhone off** | Power off iPhone, send message | Message queues, delivers when iPhone powers on | ☐ |
| **Watch out of range** | Walk away from iPhone with Watch | Notifications stop; resume when back in range | ☐ |
| **Low Power Mode** | Enable LPM on iPhone | APNs may be throttled — document behavior | ☐ |
| **Gateway restart** | `openclaw gateway restart` | iOS node auto-reconnects, Watch resumes | ☐ |

## 4.2 Monitoring Commands

```bash
# Watch gateway logs for iOS/Watch events
openclaw logs --filter "ios\|watch\|apns" --follow

# Check node health
openclaw nodes list --health

# Verify APNs delivery stats
openclaw push-test --device <id> --verbose
```

## 4.3 Success Criteria

All of the following must pass before considering the setup production-ready:

- [ ] Push notifications reliably wake backgrounded iPhone
- [ ] Watch inbox displays messages within 5 seconds of gateway delivery
- [ ] Quick reply from Watch arrives at the correct channel within 3 seconds
- [ ] Device pairing survives gateway restart
- [ ] No stale auth token errors in gateway logs after 24 hours
- [ ] Battery impact on iPhone is acceptable (< 5% additional daily drain)

---

**Previous**: [Phase 3 — Watch Companion](PHASE-3-WATCH-COMPANION.md)
**Next**: [Phase 5 — Channel Integration](PHASE-5-CHANNEL-INTEGRATION.md)
