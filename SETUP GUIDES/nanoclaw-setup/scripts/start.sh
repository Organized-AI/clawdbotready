#!/usr/bin/env bash
# NanoClaw Start Service
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.nanoclaw.plist"

if [[ ! -f "$PLIST" ]]; then
    echo "❌ Service not installed. Run install-service.sh first."
    exit 1
fi

echo "→ Starting NanoClaw service..."

if pgrep -f "dist/index.js" &>/dev/null; then
    echo "  ⚠️  NanoClaw is already running (PID: $(pgrep -f 'dist/index.js'))"
    exit 0
fi

launchctl load "$PLIST" 2>/dev/null || true
sleep 3

if pgrep -f "dist/index.js" &>/dev/null; then
    echo "  ✅ NanoClaw started (PID: $(pgrep -f 'dist/index.js'))"
else
    echo "  ⚠️  Service loaded but process not detected."
    echo "     Check: tail -f ~/nanoclaw/logs/nanoclaw.error.log"
fi
