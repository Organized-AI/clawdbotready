# Phase 2: Watchdog + Auto-Recovery

**Project:** Fleet Status Fast v2 — Gateway Control API
**Dependencies:** Phase 1 complete
**Context Files:** Read PLANNING/IMPLEMENTATION-MASTER-PLAN.md, src/gateway.js

---

## Objective

Watchdog system that monitors gateway health and auto-restarts on failure. Sends Telegram alerts on every restart.

---

## Tasks

### Task 1: Create Watchdog Script (src/watchdog.js)
Standalone script via launchd timer. Checks health via Fleet Control API, increments failure counter, auto-restarts after 2 consecutive failures. State in ~/.fleet-control/watchdog-state.json.

### Task 2: Add Local Auth Bypass
Requests from 127.0.0.1 with X-Watchdog header bypass token auth.

### Task 3: Create Telegram Notifier (src/telegram.js)
POST to @SAMyosin_bot on every restart (auto or manual). Includes host, time, trigger type, method, result.

### Task 4: Create launchd Timer
`com.bht.fleet-watchdog.plist` — StartInterval: 60s.

### Task 5: Add /fleet/history Endpoint
Returns last 50 restart events from watchdog state.

### Task 6: Test — Stop gateway, wait 120s, verify auto-restart + Telegram alert.

---

## Success Criteria

- [ ] Detects gateway failure within 60s
- [ ] Auto-restart after 2 consecutive failures
- [ ] Telegram notification on every restart
- [ ] /fleet/history endpoint works
- [ ] Survives reboot via launchd
