# Phase 5: Verify Deployment and Pair Devices

**Safety Level:** 🟢 Safe (verification and testing only)
**Estimated Tasks:** 5
**Dependencies:** Phase 3 complete (Phase 4 recommended)

---

## Pre-Execution Safety Check

This phase will:
1. Verify the worker is responding correctly
2. Test the Control UI
3. Test the Admin UI
4. Walk through device pairing
5. Send a test message

**This phase only TESTS the deployment. It does NOT modify anything.**

---

## Context Files to Read First

```
READ: PLANNING/PHASE-3-COMPLETE.md
READ: .worker_url
READ: .gateway_token
```

---

## Tasks

### Task 1: Verify Worker Health

```bash
WORKER_URL=$(cat .worker_url)
echo "Testing: $WORKER_URL"

# Basic health
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "$WORKER_URL/")
echo "Root:   HTTP $HTTP_CODE"

# Admin endpoint
ADMIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$WORKER_URL/_admin/")
echo "Admin:  HTTP $ADMIN_CODE"

if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]]; then
    echo ""
    echo "Worker is healthy!"
else
    echo ""
    echo "Worker may still be starting (cold start: 1-2 min)"
    echo "Wait and retry."
fi
```

---

### Task 2: Test Control UI

Open in your browser:

```
https://your-worker.workers.dev/?token=YOUR_GATEWAY_TOKEN
```

**Expected:**
- You should see the OpenClaw Control UI
- It should load without errors
- The gateway status should show "connected" (may take a moment)

---

### Task 3: Test Admin UI

Open in your browser:

```
https://your-worker.workers.dev/_admin/
```

**Expected (with Cloudflare Access):**
- Redirected to Cloudflare Access login
- After authenticating, see the admin dashboard
- R2 status shown (if configured)
- Device pairing queue (initially empty)

**Expected (without Cloudflare Access):**
- Direct access to admin dashboard
- Warning: anyone with the URL can access this

---

### Task 4: Pair a Device

1. **Send a message to your bot** (Telegram, Discord, or Slack)
2. The message will be held pending — the device needs approval
3. Go to the **Admin UI** (`/_admin/`)
4. You should see a pending device pairing request
5. Click **Approve** (or "Approve All")
6. The device is now permanently paired

```bash
echo "=== Device Pairing ==="
echo ""
echo "1. Send a test message to your bot"
echo "2. Open: $(cat .worker_url)/_admin/"
echo "3. Approve the pending device"
echo "4. Send another message — it should get a response"
echo ""
echo "Note: Device list takes 10-15 seconds to load"
```

---

### Task 5: Verify R2 Persistence (If Configured)

```bash
echo "=== R2 Verification ==="
echo ""
echo "1. Open the Admin UI: $(cat .worker_url)/_admin/"
echo "2. Check the R2 section for:"
echo "   - Status: Connected"
echo "   - Last backup: [timestamp]"
echo "3. Click 'Backup Now' to trigger manual sync"
echo "4. Wait 5 minutes, refresh — backup timestamp should update"
echo ""
echo "If R2 shows 'Not configured':"
echo "  Run: ./setup.sh 4  (to configure R2)"
```

---

## Success Criteria

- [ ] Worker responds to HTTP requests
- [ ] Control UI loads with gateway token
- [ ] Admin UI accessible (with or without CF Access)
- [ ] At least one device paired successfully
- [ ] Test message sent and response received
- [ ] R2 backup status showing (if configured)

---

## Troubleshooting

### Control UI shows "disconnected"
- Container may be sleeping. Send a request to wake it.
- Check `./scripts/logs.sh` for errors.

### Admin UI returns 403
- Cloudflare Access not configured correctly
- Check CF_ACCESS_TEAM_DOMAIN and CF_ACCESS_AUD secrets
- Verify your email is in the Access allow list

### Device not appearing in pairing queue
- Wait 10-15 seconds and refresh
- Check the bot token is correct
- Check `./scripts/logs.sh` for connection errors

### Bot responds slowly
- First response takes 1-2 min (cold start)
- Subsequent responses should be fast
- If consistently slow, check AI provider (Anthropic) status

---

## Phase 5 Completion

```bash
WORKER_URL=$(cat .worker_url 2>/dev/null || echo "unknown")
cat > PLANNING/PHASE-5-COMPLETE.md << EOF
# Phase 5 Complete — Deployment Verified

**Completed:** $(date)

## Deployment Summary
- **Worker URL:** $WORKER_URL
- **Control UI:** $WORKER_URL/?token=<saved-in-.gateway_token>
- **Admin UI:** $WORKER_URL/_admin/
- **Platform:** Cloudflare Workers + Sandbox

## Configured Features
- [x] OpenClaw Gateway running
- [ ] R2 persistent storage  ← check/uncheck
- [ ] Cloudflare Access       ← check/uncheck
- [ ] Telegram channel         ← check/uncheck
- [ ] Discord channel          ← check/uncheck
- [ ] Slack channel            ← check/uncheck
- [ ] Browser automation (CDP) ← check/uncheck

## Operations
- Status:   ./scripts/status.sh
- Deploy:   ./scripts/deploy.sh
- Logs:     ./scripts/logs.sh
- Backup:   ./scripts/backup.sh
- Restart:  ./scripts/restart.sh
- Teardown: ./scripts/teardown.sh
EOF

echo ""
echo "=== SETUP COMPLETE ==="
echo ""
echo "Your OpenClaw instance is running on Cloudflare Workers."
echo "Use ./scripts/status.sh anytime to check the deployment."
```

---

## What's Next

- **Monitor:** Use `./scripts/logs.sh` to watch live activity
- **Add channels:** Run `./setup.sh 4` to add more chat channels
- **Cost optimization:** Set `SANDBOX_SLEEP_AFTER=10m` in settings.env
- **Browser automation:** Configure CDP for screenshots and video
- **Custom skills:** Deploy skills into the container via the admin UI
