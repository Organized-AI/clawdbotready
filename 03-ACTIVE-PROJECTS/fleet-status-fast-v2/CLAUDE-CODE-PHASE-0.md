# Fleet Status Fast v2 — Claude Code Quick Start

## Run This on the Mac Mini (openclaws-mac-mini / 100.66.145.48)

### Terminal Command
```bash
cd ~/fleet-control-api 2>/dev/null || mkdir -p ~/fleet-control-api && cd ~/fleet-control-api
claude --dangerously-skip-permissions
```

### Claude Code Web Environment Variables
```
ANTHROPIC_API_KEY=<your-key>
```

### Paste This Prompt Into Claude Code

```
Project: Fleet Status Fast v2 — Gateway Control API
Purpose: Remote OpenClaw gateway lifecycle management over HTTP
Target: This machine (openclaws-mac-mini, Tailscale IP 100.66.145.48)
Gateway: OpenClaw on port 18789, commands.restart=true

Build a zero-dependency Node.js HTTP server (built-in http module only) that:

1. Binds to 100.66.145.48:3847 (Tailscale interface only)
2. Bearer token auth (generate 64-char token, store in macOS Keychain as "fleet-control-token")
3. Endpoints:
   - GET /fleet/ping (no auth) → 200 "pong"
   - GET /fleet/health (auth) → gateway health check via HTTP to 127.0.0.1:18789 + PID check
   - POST /fleet/restart (auth, max 5/hour) → SIGUSR1 to gateway PID, fallback to `openclaw gateway restart`
   - GET /fleet/info (auth) → hostname, uptime, memory, CPU, gateway version, node version
4. Log all requests to /tmp/fleet-control-api.log with rotation at 5MB
5. Install as launchd service: com.bht.fleet-control-api (KeepAlive, RunAtLoad)
6. Git init and commit

Test all endpoints locally after building, then verify reachable from another Tailscale machine.
```

---

## After Phase 0+1: Test From MacBook Pro

```bash
# Quick test
curl http://100.66.145.48:3847/fleet/ping

# With auth (replace TOKEN with the generated token)
TOKEN="<paste-token-here>"
curl -H "Authorization: Bearer $TOKEN" http://100.66.145.48:3847/fleet/health
curl -H "Authorization: Bearer $TOKEN" http://100.66.145.48:3847/fleet/info
curl -X POST -H "Authorization: Bearer $TOKEN" http://100.66.145.48:3847/fleet/restart
```
