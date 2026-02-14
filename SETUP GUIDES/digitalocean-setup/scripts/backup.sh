#!/usr/bin/env bash
set -euo pipefail

# Create a DigitalOcean Droplet snapshot backup
# Requires: doctl CLI installed and authenticated
# Usage: ./scripts/backup.sh [DROPLET_ID]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/settings.env"
LOG_DIR="${SCRIPT_DIR}/../logs"

mkdir -p "$LOG_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

DROPLET_ID="${1:-}"
SNAPSHOT_NAME="openclaw-backup-$(date +%F-%H%M)"

# Check doctl is available
if ! command -v doctl &>/dev/null; then
    echo "Error: doctl CLI not installed."
    echo "Install: brew install doctl"
    echo "Auth:    doctl auth init"
    echo ""
    echo "Alternative: Create a snapshot via the DigitalOcean web console:"
    echo "  Droplets → Your Droplet → Snapshots → Take Snapshot"
    exit 1
fi

# Find Droplet ID if not provided
if [[ -z "$DROPLET_ID" ]]; then
    echo "Looking for OpenClaw Droplets..."
    doctl compute droplet list --format ID,Name,PublicIPv4,Status --no-header | while read -r line; do
        echo "  $line"
    done
    echo ""
    read -rp "Enter Droplet ID to snapshot: " DROPLET_ID
fi

if [[ -z "$DROPLET_ID" ]]; then
    echo "Error: No Droplet ID provided."
    exit 1
fi

echo "=== Creating Snapshot ==="
echo "Droplet ID: $DROPLET_ID"
echo "Snapshot name: $SNAPSHOT_NAME"
echo ""

doctl compute droplet-action snapshot "$DROPLET_ID" --snapshot-name "$SNAPSHOT_NAME" --wait

echo ""
echo "Snapshot '$SNAPSHOT_NAME' created successfully."
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") Snapshot: $SNAPSHOT_NAME (Droplet: $DROPLET_ID)" >> "${LOG_DIR}/backups.log"
