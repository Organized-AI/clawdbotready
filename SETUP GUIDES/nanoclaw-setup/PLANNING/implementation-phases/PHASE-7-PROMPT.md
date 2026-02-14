# Phase 7: Service Installation

## Objective
Build TypeScript, generate launchd plist, and start NanoClaw as a persistent macOS service.

## Steps

### 1. Build TypeScript
```bash
cd ~/nanoclaw
npm run build
```

### 2. Install the Service

**Using the helper script:**
```bash
"SETUP GUIDES/nanoclaw-setup/scripts/install-service.sh"
```

**Or manually:**

```bash
# Set variables
NODE_PATH=$(which node)
PROJECT_ROOT="$HOME/nanoclaw"
ASSISTANT_NAME="${ASSISTANT_NAME:-Andy}"

# Generate plist from template
sed \
    -e "s|{{NODE_PATH}}|$NODE_PATH|g" \
    -e "s|{{PROJECT_ROOT}}|$PROJECT_ROOT|g" \
    -e "s|{{HOME}}|$HOME|g" \
    -e "s|{{ASSISTANT_NAME}}|$ASSISTANT_NAME|g" \
    "SETUP GUIDES/nanoclaw-setup/config/com.nanoclaw.plist.template" \
    > ~/Library/LaunchAgents/com.nanoclaw.plist

# Validate plist
plutil -lint ~/Library/LaunchAgents/com.nanoclaw.plist

# Load and start
launchctl load ~/Library/LaunchAgents/com.nanoclaw.plist
```

### 3. Verify Service is Running

```bash
# Check process
pgrep -f "dist/index.js"

# Check launchd
launchctl print gui/$(id -u)/com.nanoclaw

# Check logs
tail -20 ~/nanoclaw/logs/nanoclaw.log
```

## Service Behavior
- **RunAtLoad**: Starts automatically when you log in
- **KeepAlive**: Restarts automatically if the process crashes
- **ThrottleInterval**: 10 second delay between restart attempts
- **Logs**: stdout → `logs/nanoclaw.log`, stderr → `logs/nanoclaw.error.log`

## Managing the Service

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.nanoclaw.plist

# Start
launchctl load ~/Library/LaunchAgents/com.nanoclaw.plist

# Or use helper scripts:
"SETUP GUIDES/nanoclaw-setup/scripts/stop.sh"
"SETUP GUIDES/nanoclaw-setup/scripts/start.sh"
"SETUP GUIDES/nanoclaw-setup/scripts/restart.sh"
```

## Success Criteria
- [ ] TypeScript builds without errors
- [ ] Plist validates with `plutil -lint`
- [ ] `launchctl print` shows service loaded
- [ ] Process is running (`pgrep -f dist/index.js`)
- [ ] Logs are being written to `logs/`
