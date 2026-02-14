#!/usr/bin/env bash
set -euo pipefail

# Remove the OpenClaw DigitalOcean deployment
# WARNING: This destroys the Droplet and all data on it
# Usage: ./scripts/teardown.sh [DROPLET_ID]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/settings.env"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

DROPLET_ID="${1:-}"

if ! command -v doctl &>/dev/null; then
    echo "Error: doctl CLI not installed."
    echo "Install: brew install doctl"
    echo ""
    echo "Alternative: Delete via DigitalOcean web console:"
    echo "  Droplets → Your Droplet → Destroy → Destroy this Droplet"
    exit 1
fi

if [[ -z "$DROPLET_ID" ]]; then
    echo "Current Droplets:"
    doctl compute droplet list --format ID,Name,PublicIPv4,Status
    echo ""
    read -rp "Enter Droplet ID to destroy: " DROPLET_ID
fi

if [[ -z "$DROPLET_ID" ]]; then
    echo "Error: No Droplet ID provided."
    exit 1
fi

echo ""
echo "WARNING: This will permanently destroy Droplet $DROPLET_ID and ALL data on it."
echo ""
read -rp "Type 'DESTROY' to confirm: " CONFIRM

if [[ "$CONFIRM" != "DESTROY" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Destroying Droplet $DROPLET_ID..."
doctl compute droplet delete "$DROPLET_ID" --force

echo "Droplet destroyed."
echo "Note: Snapshots are preserved. Delete them manually if no longer needed:"
echo "  doctl compute snapshot list"
