#!/usr/bin/env bash
set -euo pipefail

# Restart the OpenClaw service on the DigitalOcean Droplet
# Usage: ./scripts/restart.sh [DROPLET_IP]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/settings.env"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

DROPLET_IP="${1:-${DROPLET_IP:-}}"

if [[ -z "$DROPLET_IP" ]]; then
    echo "Usage: $0 <DROPLET_IP>"
    echo "   Or set DROPLET_IP in config/settings.env"
    exit 1
fi

echo "=== Restarting OpenClaw ==="
echo "Droplet: $DROPLET_IP"
echo ""

ssh "root@${DROPLET_IP}" "systemctl restart openclaw"

echo "Waiting 5 seconds for service to start..."
sleep 5

echo ""
ssh "root@${DROPLET_IP}" "systemctl status openclaw --no-pager"

echo ""
echo "Checking gateway health..."
ssh "root@${DROPLET_IP}" "curl -sf http://127.0.0.1:18789/health 2>/dev/null && echo 'Gateway: OK' || echo 'Gateway: Not responding (may need more time)'"
