#!/usr/bin/env bash
# NanoClaw Log Viewer
set -euo pipefail

NANOCLAW_ROOT="${NANOCLAW_ROOT:-$HOME/nanoclaw}"
LOG_DIR="$NANOCLAW_ROOT/logs"

MODE="${1:---stdout}"

case "$MODE" in
    --error|-e)
        echo "→ Tailing error log (Ctrl+C to stop)..."
        echo ""
        tail -f "$LOG_DIR/nanoclaw.error.log"
        ;;
    --all|-a)
        echo "→ Tailing all logs (Ctrl+C to stop)..."
        echo ""
        tail -f "$LOG_DIR/nanoclaw.log" "$LOG_DIR/nanoclaw.error.log"
        ;;
    --stdout|*)
        echo "→ Tailing stdout log (Ctrl+C to stop)..."
        echo ""
        tail -f "$LOG_DIR/nanoclaw.log"
        ;;
esac
