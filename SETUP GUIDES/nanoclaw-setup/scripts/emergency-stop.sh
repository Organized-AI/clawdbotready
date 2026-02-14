#!/usr/bin/env bash
# NanoClaw Emergency Stop
# Force kills NanoClaw and prevents auto-restart
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.nanoclaw.plist"

echo "╔══════════════════════════════════════════════╗"
echo "║      NanoClaw EMERGENCY STOP                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Step 1: Unload service to prevent auto-restart
echo "→ Disabling auto-restart..."
if [[ -f "$PLIST" ]]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    echo "  ✅ Service unloaded"
else
    echo "  ⚠️  No plist found (service may not be installed)"
fi

# Step 2: Kill all NanoClaw processes
echo "→ Force killing NanoClaw processes..."
if pgrep -f "dist/index.js" &>/dev/null; then
    pkill -9 -f "dist/index.js" 2>/dev/null || true
    echo "  ✅ NanoClaw process killed"
else
    echo "  ✅ No NanoClaw process running"
fi

# Step 3: Kill any orphaned agent containers
echo "→ Killing agent containers..."
if command -v container &>/dev/null; then
    CONTAINERS=$(container ps -q 2>/dev/null || true)
    if [[ -n "$CONTAINERS" ]]; then
        echo "$CONTAINERS" | xargs container kill 2>/dev/null || true
        echo "  ✅ Containers killed"
    else
        echo "  ✅ No active containers"
    fi
elif command -v docker &>/dev/null; then
    CONTAINERS=$(docker ps -q --filter "ancestor=nanoclaw-agent" 2>/dev/null || true)
    if [[ -n "$CONTAINERS" ]]; then
        echo "$CONTAINERS" | xargs docker kill 2>/dev/null || true
        echo "  ✅ Containers killed"
    else
        echo "  ✅ No active containers"
    fi
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  NanoClaw has been emergency stopped."
echo ""
echo "  To restart: $(dirname "$0")/start.sh"
echo "════════════════════════════════════════════════"
