# Phase 1: Fleet Control API

**Project:** Fleet Status Fast v2 — Gateway Control API
**Dependencies:** Phase 0 complete
**Context Files:** Read PLANNING/IMPLEMENTATION-MASTER-PLAN.md, config/default.json

---

## Objective

Build a lightweight HTTP server with authenticated endpoints for gateway health, restart, and system info. Zero external dependencies — Node.js built-in modules only (http, child_process, os, fs, crypto).

---

## Tasks

### Task 1: Create Logger Module (src/logger.js)
Append-only log, format: `[ISO_TIMESTAMP] [LEVEL] [SOURCE_IP] message`, rotate at 5MB.

### Task 2: Create Auth Module (src/auth.js)
Read token from macOS Keychain (`security find-generic-password`), cache in memory, validate Bearer header, log failed auth attempts.

### Task 3: Create Gateway Control Module (src/gateway.js)
- `getHealth()` → HTTP GET to 127.0.0.1:18789 with 5s timeout, returns status/responseTime/pid
- `restart()` → SIGUSR1 to PID (preferred), fallback to `openclaw gateway restart`, verify health after
- `getGatewayPid()` → Read from ~/.openclaw/gateway.pid or pgrep

### Task 4: Create System Info Module (src/system.js)
Returns hostname, uptime, memory, CPU, tailscaleIp, gatewayVersion, nodeVersion, fleetControlVersion.

### Task 5: Create Rate Limiter
In-memory, track restart requests by IP, max 5/hour, return 429 when exceeded.

### Task 6: Create HTTP Server (src/server.js)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /fleet/ping | No | Returns 200 "pong" |
| GET | /fleet/health | Yes | Gateway health + response time |
| POST | /fleet/restart | Yes | Restart gateway (rate limited) |
| GET | /fleet/info | Yes | Full system info |

Bind to Tailscale IP only (100.66.145.48:3847). JSON responses with `{ok, data, timestamp}` shape.

### Task 7: Test All Endpoints
Local and remote (via Tailscale) testing.

### Task 8: Create launchd Service
`~/Library/LaunchAgents/com.bht.fleet-control-api.plist` — RunAtLoad, KeepAlive.

### Task 9: Git Commit

---

## Success Criteria

- [ ] GET /fleet/ping returns 200 without auth
- [ ] GET /fleet/health returns gateway health with response time
- [ ] POST /fleet/restart successfully restarts gateway
- [ ] GET /fleet/info returns full system information
- [ ] 401 on unauthorized, 429 on rate limit exceeded
- [ ] API binds ONLY to Tailscale IP
- [ ] launchd service survives reboot
- [ ] Reachable from MacBook Pro via Tailscale
