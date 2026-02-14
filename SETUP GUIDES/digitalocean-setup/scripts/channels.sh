#!/usr/bin/env bash
set -euo pipefail

# Add or manage messaging channels on the DigitalOcean Droplet
# Usage: ./scripts/channels.sh [DROPLET_IP]

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

echo "=== OpenClaw Channel Management ==="
echo "Droplet: $DROPLET_IP"
echo ""
echo "This will open an interactive SSH session to add channels."
echo "The OpenClaw CLI will guide you through the setup."
echo ""

ssh -t "root@${DROPLET_IP}" "/opt/openclaw-cli.sh channels add"
