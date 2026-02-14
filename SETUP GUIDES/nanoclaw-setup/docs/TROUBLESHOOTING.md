# NanoClaw Troubleshooting Guide

Quick reference for diagnosing and fixing common NanoClaw issues.

---

## Diagnostic Commands

Run these first to understand the current state:

```bash
# Full health check
./scripts/health-check.sh

# Service status
./scripts/status.sh

# Process running?
pgrep -f "dist/index.js"

# Recent logs
tail -50 ~/nanoclaw/logs/nanoclaw.log

# Recent errors
tail -20 ~/nanoclaw/logs/nanoclaw.error.log

# Active containers
container ps            # Apple Container
docker ps               # Docker
```

---

## WhatsApp Issues

### QR Code Won't Appear

**Symptoms**: `npm run auth` hangs or shows errors before displaying QR.

**Fixes**:
```bash
# Clear old session data
rm -rf ~/nanoclaw/store/auth

# Retry
npm run auth
```

If still failing, check Node.js version (must be 20+):
```bash
node --version
```

### WhatsApp Keeps Disconnecting

**Symptoms**: Bot responds for a while then stops. Logs show "connection closed" or "logout".

**Causes**:
- WhatsApp limits linked devices (max 4)
- Phone was offline for too long
- Another linked device was removed

**Fixes**:
```bash
# Check how many linked devices you have
# (On phone: Settings → Linked Devices)
# Remove unused devices to free a slot

# Then re-authenticate
rm -rf ~/nanoclaw/store/auth
npm run auth

# Restart service
./scripts/restart.sh
```

### Bot Doesn't Respond to Messages

**Symptoms**: Messages sent in WhatsApp but no response.

**Check**:
1. Is the trigger word correct? Check `ASSISTANT_NAME` in the plist or env.
2. Is the group registered? Check the database:
   ```bash
   sqlite3 ~/nanoclaw/data/nanoclaw.db "SELECT * FROM groups;"
   ```
3. Is the process running?
   ```bash
   pgrep -f "dist/index.js"
   ```
4. Check logs for the message arriving:
   ```bash
   grep "message" ~/nanoclaw/logs/nanoclaw.log | tail -10
   ```

### Bot Responds to Wrong Groups

**Symptoms**: NanoClaw responds in unregistered groups.

**Fix**: Only registered groups should trigger responses. Verify:
```bash
sqlite3 ~/nanoclaw/data/nanoclaw.db "SELECT name, jid FROM groups;"
```

Remove unwanted groups or re-register.

---

## Container Issues

### Container Build Fails

**Symptoms**: `./container/build.sh` exits with errors.

**Common fixes**:
```bash
# Ensure Apple Container is running
container --version

# Purge stale build cache
container builder stop && container builder rm && container builder start

# Retry build
./container/build.sh
```

**Disk space issue**:
```bash
df -h /
# Need at least 5GB free for container image layers
```

### Container Hangs / Times Out

**Symptoms**: Agent starts but never returns a response. Hits 30-minute timeout.

**Diagnosis**:
```bash
# List running containers
container ps

# Kill stuck containers
container kill $(container ps -q)
```

**Common cause**: Claude authentication failed inside the container.
```bash
# Verify env file
cat ~/nanoclaw/data/env/env
# Must contain valid CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY
```

### "No Such Image" Error

**Symptoms**: Logs show container spawn fails with image not found.

**Fix**:
```bash
# Verify image exists
container images | grep nanoclaw-agent

# If missing, rebuild
./container/build.sh
```

### Container Builds But Agent Fails

**Symptoms**: Container starts but Claude returns errors.

**Test manually**:
```bash
echo '{"prompt":"hello","groupFolder":"test","chatJid":"test@g.us","isMain":false}' | \
  container run -i --rm nanoclaw-agent:latest
```

Check the output for auth errors, missing dependencies, or TypeScript compilation issues.

---

## Service Issues

### launchd Won't Load

**Symptoms**: `launchctl load` fails or service doesn't appear.

**Diagnosis**:
```bash
# Validate plist syntax
plutil -lint ~/Library/LaunchAgents/com.nanoclaw.plist

# Check for duplicate labels
launchctl list | grep nanoclaw

# View detailed error
launchctl print gui/$(id -u)/com.nanoclaw
```

**Fix**: Regenerate the plist:
```bash
./scripts/install-service.sh
```

### Process Starts Then Immediately Dies

**Symptoms**: `launchctl` shows service loaded but process exits.

**Check**:
```bash
# View error log immediately after start
tail -50 ~/nanoclaw/logs/nanoclaw.error.log

# Common causes:
# - TypeScript not built (run: npm run build)
# - Missing dependencies (run: npm install)
# - Port conflict
# - Database locked
```

### Service Doesn't Auto-Start on Login

**Check**: Plist must be in `~/Library/LaunchAgents/` with `RunAtLoad` true:
```bash
plutil -p ~/Library/LaunchAgents/com.nanoclaw.plist | grep RunAtLoad
# Should show: "RunAtLoad" => true
```

---

## Database Issues

### SQLite Errors / Corruption

**Symptoms**: Errors mentioning "database is locked" or "malformed".

**Diagnosis**:
```bash
sqlite3 ~/nanoclaw/data/nanoclaw.db "PRAGMA integrity_check;"
```

**Fix if corrupt**:
```bash
# Stop service
./scripts/stop.sh

# Backup the corrupted database
cp ~/nanoclaw/data/nanoclaw.db ~/nanoclaw/data/nanoclaw.db.corrupt

# Remove it (NanoClaw recreates on start)
rm ~/nanoclaw/data/nanoclaw.db

# Restart (will create fresh database — loses message history)
./scripts/start.sh
```

### "Database Is Locked"

**Symptoms**: Multiple processes trying to write to SQLite.

**Fix**: Ensure only one NanoClaw process is running:
```bash
pkill -f "dist/index.js"
./scripts/start.sh
```

---

## Authentication Issues

### Claude Auth Token Expired

**Symptoms**: Containers fail with authentication errors.

**Fix**:
```bash
# Re-authenticate
claude setup-token

# Update the env file
mkdir -p ~/nanoclaw/data/env
echo "CLAUDE_CODE_OAUTH_TOKEN=$(claude auth token)" > ~/nanoclaw/data/env/env

# Restart
./scripts/restart.sh
```

### API Key Not Working

**Symptoms**: "Invalid API key" errors in container output.

**Fix**:
```bash
# Verify key format
cat ~/nanoclaw/data/env/env
# Should start with: ANTHROPIC_API_KEY=sk-ant-

# Test the key directly
curl -H "x-api-key: $(grep ANTHROPIC_API_KEY ~/nanoclaw/data/env/env | cut -d= -f2)" \
     -H "anthropic-version: 2023-06-01" \
     https://api.anthropic.com/v1/messages \
     -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```

---

## Performance Issues

### High Memory Usage

**Symptoms**: NanoClaw process consuming excessive RAM.

**Diagnosis**:
```bash
ps -p $(pgrep -f "dist/index.js") -o rss,vsz,%mem
# rss = resident set size in KB
```

**Fixes**:
- Reduce `MAX_CONCURRENT_CONTAINERS` in config
- Restart the service (clears accumulated memory)
- Check for runaway containers: `container ps`

### Slow Responses

**Symptoms**: 30+ seconds for simple queries.

**Causes**:
- Container cold start (first message after restart)
- High concurrency (many groups active simultaneously)
- Network latency to Anthropic API
- Large container image (rebuild with `--clean` if bloated)

---

## Nuclear Options

When all else fails:

### Full Reset (Preserves Data)
```bash
./scripts/emergency-stop.sh
cd ~/nanoclaw
npm install
npm run build
container builder stop && container builder rm && container builder start
./container/build.sh
./scripts/install-service.sh
```

### Complete Reinstall (Preserves Nothing)
```bash
./scripts/emergency-stop.sh
launchctl unload ~/Library/LaunchAgents/com.nanoclaw.plist 2>/dev/null
rm ~/Library/LaunchAgents/com.nanoclaw.plist
rm -rf ~/.config/nanoclaw
cd ~
rm -rf nanoclaw
# Then start fresh from Phase 1
```

### Complete Reinstall (Preserves Auth and Memory)
```bash
# Save critical data
mkdir -p /tmp/nanoclaw-backup
cp -r ~/nanoclaw/store/auth /tmp/nanoclaw-backup/
cp -r ~/nanoclaw/groups /tmp/nanoclaw-backup/
cp -r ~/nanoclaw/data/env /tmp/nanoclaw-backup/
cp ~/.config/nanoclaw/mount-allowlist.json /tmp/nanoclaw-backup/ 2>/dev/null

# Fresh install
./scripts/emergency-stop.sh
cd ~
rm -rf nanoclaw
git clone https://github.com/qwibitai/nanoclaw.git
cd nanoclaw
npm install

# Restore data
cp -r /tmp/nanoclaw-backup/auth store/
cp -r /tmp/nanoclaw-backup/groups .
mkdir -p data
cp -r /tmp/nanoclaw-backup/env data/

# Rebuild and start
./container/build.sh
npm run build
./scripts/install-service.sh
```
