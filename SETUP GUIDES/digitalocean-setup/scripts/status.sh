#!/usr/bin/env bash
set -euo pipefail

# Check DigitalOcean Droplet + OpenClaw service status
# Usage: ./scripts/status.sh [DROPLET_IP]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/settings.env"

# Load config if available
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

DROPLET_IP="${1:-${DROPLET_IP:-}}"

if [[ -z "$DROPLET_IP" ]]; then
    echo "Usage: $0 <DROPLET_IP>"
    echo "   Or set DROPLET_IP in config/settings.env"
    exit 1
fi

echo "=== DigitalOcean OpenClaw Status ==="
echo "Droplet: $DROPLET_IP"
echo ""

echo "--- SSH Connectivity ---"
if ssh -o ConnectTimeout=5 -o BatchMode=yes "root@${DROPLET_IP}" "echo 'SSH OK'" 2>/dev/null; then
    echo "SSH: Connected"
else
    echo "SSH: FAILED (check IP and SSH key)"
    exit 1
fi

echo ""
echo "--- OpenClaw Service ---"
ssh "root@${DROPLET_IP}" "systemctl status openclaw --no-pager 2>/dev/null || echo 'Service not found'"

echo ""
echo "--- Container Status ---"
ssh "root@${DROPLET_IP}" "docker ps --filter 'name=openclaw' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'Docker not running or no container'"

echo ""
echo "--- Gateway Health ---"
ssh "root@${DROPLET_IP}" "curl -sf http://127.0.0.1:18789/health 2>/dev/null && echo '' || echo 'Gateway not responding on port 18789'"

echo ""
echo "--- System Resources ---"
ssh "root@${DROPLET_IP}" "echo 'Memory:' && free -h | head -2 && echo '' && echo 'Disk:' && df -h / | tail -1"
