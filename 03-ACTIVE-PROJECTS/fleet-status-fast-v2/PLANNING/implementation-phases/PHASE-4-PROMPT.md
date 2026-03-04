# Phase 4: Telegram Integration + Hardening

**Project:** Fleet Status Fast v2 — Gateway Control API
**Dependencies:** Phase 2 and Phase 3 complete
**Context Files:** Read PLANNING/IMPLEMENTATION-MASTER-PLAN.md, src/telegram.js

---

## Objective

Telegram bot commands for gateway management + system hardening.

---

## Tasks

### Task 1: Telegram Bot Commands
Long-polling mode. /restart, /status, /info commands. Authorized user IDs only.

### Task 2: Request Dashboard
/fleet/dashboard endpoint — last 100 requests, summary stats, restart counts.

### Task 3: Graceful Error Handling
try/catch everywhere, child process timeouts, crash handler, unhandled rejection handler.

### Task 4: Startup Self-Test
Verify Keychain token, OpenClaw CLI, gateway process, Tailscale interface, Telegram bot.

### Task 5: IP Allowlist (Optional)
Config-based allowlist for Tailscale IPs. 403 for others.

### Task 6: Log Rotation
5MB max, keep 3 rotated files.

### Task 7: README
Architecture, installation, API docs, troubleshooting, security model.

### Task 8: Final Integration Test
All restart paths (API, Shortcut, Telegram, Watchdog), reboot survival.

### Task 9: Git tag v2.0.0

---

## Success Criteria

- [ ] Telegram /restart works from authorized account
- [ ] /fleet/dashboard returns request history
- [ ] Startup self-test validates all dependencies
- [ ] No unhandled exceptions
- [ ] Log rotation working
- [ ] Full integration test passes
- [ ] System survives reboot completely
