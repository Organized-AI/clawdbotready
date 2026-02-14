# Phase 8: Testing & Validation

## Objective
End-to-end verification that NanoClaw is fully operational.

## Steps

### 1. Run Health Check
```bash
"SETUP GUIDES/nanoclaw-setup/scripts/health-check.sh"
```
All checks should pass (green).

### 2. Test Message Delivery

**From your phone:**
1. Open WhatsApp
2. Go to your main channel (self-chat) or a registered group
3. Send: `@Andy hello, are you working?`
4. Wait for response (may take 10-30 seconds on first message)

**Verify in logs:**
```bash
tail -f ~/nanoclaw/logs/nanoclaw.log
# Should see message received, container spawned, response sent
```

### 3. Test Container Isolation

From a non-main group:
```
@Andy run "ls /workspace" in bash
```
Should only see: `group/`, `global/`, `extra/`, `ipc/`, `env-dir/`

```
@Andy run "whoami" in bash
```
Should return `node` (not root).

### 4. Test Scheduled Tasks

From main channel:
```
@Andy schedule a one-time task: say "test complete" in 2 minutes
```
Wait 2 minutes, verify the message arrives.

### 5. Test Group Isolation

If you have two registered groups:
1. In Group A: `@Andy remember that the secret code is 42`
2. In Group B: `@Andy what is the secret code?`
3. Group B should NOT know the answer (isolated memory)

### 6. Verify Service Persistence

```bash
# Kill the process
pkill -f "dist/index.js"

# Wait 15 seconds for launchd to restart it
sleep 15

# Verify it restarted
pgrep -f "dist/index.js" && echo "Auto-restart works!"
```

### 7. Review Error Log

```bash
# Should be empty or have only startup messages
cat ~/nanoclaw/logs/nanoclaw.error.log
```

## Success Criteria
- [ ] Health check passes all checks
- [ ] WhatsApp message triggers Claude response
- [ ] Container runs in isolation (non-root, limited filesystem)
- [ ] Scheduled tasks execute and send notifications
- [ ] Group memory is isolated
- [ ] Service auto-restarts after crash
- [ ] Error log is clean

## Post-Setup

After all tests pass:

1. **Bookmark helper scripts** for ongoing management
2. **Set up backups** for `data/`, `groups/`, `store/auth/`
3. **Customize** via Claude Code skills (`/customize`, `/add-telegram`, etc.)
4. **Monitor** with periodic health checks or the status script

Congratulations — NanoClaw is deployed!
