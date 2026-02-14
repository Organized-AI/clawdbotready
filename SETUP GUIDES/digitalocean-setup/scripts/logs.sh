#!/usr/bin/env bash
set -euo pipefail

# View live OpenClaw logs on DigitalOcean Droplet
# Usage: ./scripts/logs.sh [DROPLET_IP] [LINES]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/settings.env"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

DROPLET_IP="${1:-${DROPLET_IP:-}}"
LINES="${2:-50}"

if [[ -z "$DROPLET_IP" ]]; then
    echo "Usage: $0 <DROPLET_IP> [LINES]"
    echo "   Or set DROPLET_IP in config/settings.env"
    exit 1
fi

echo "=== OpenClaw Logs (last $LINES lines, then live) ==="
echo "Droplet: $DROPLET_IP"
echo "Press Ctrl+C to stop"
echo ""

ssh "root@${DROPLET_IP}" "journalctl -u openclaw -n ${LINES} -f"
