#!/usr/bin/env bash
# NanoClaw Restart Service
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════════╗"
echo "║      NanoClaw Restart                        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

"$SCRIPT_DIR/stop.sh"
echo ""
sleep 2
"$SCRIPT_DIR/start.sh"
