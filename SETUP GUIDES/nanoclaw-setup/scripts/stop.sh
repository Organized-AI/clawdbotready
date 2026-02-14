#!/usr/bin/env bash
# NanoClaw Stop Service (graceful)
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.nanoclaw.plist"

echo "→ Stopping NanoClaw service..."

if [[ -f "$PLIST" ]]; then
    launchctl unload "$PLIST" 2>/dev/null || true
fi

# Wait for graceful shutdown
for i in {1..10}; do
    if ! pgrep -f "dist/index.js" &>/dev/null; then
        echo "  ✅ NanoClaw stopped"
        exit 0
    fi
    sleep 1
done

# Still running
if pgrep -f "dist/index.js" &>/dev/null; then
    echo "  ⚠️  Process still running after 10s."
    echo "     Use emergency-stop.sh to force kill."
else
    echo "  ✅ NanoClaw stopped"
fi
