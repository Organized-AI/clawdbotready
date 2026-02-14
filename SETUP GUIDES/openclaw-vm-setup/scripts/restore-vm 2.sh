#!/bin/bash
# Restore OpenClaw VM from snapshot

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"

echo "Available snapshots:"
lume snapshot list "$VM_NAME"

echo ""
read -p "Enter snapshot name to restore: " snapshot_name

if [[ -z "$snapshot_name" ]]; then
    echo "No snapshot specified"
    exit 1
fi

echo "WARNING: This will restore VM to snapshot: $snapshot_name"
read -p "Continue? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy] ]]; then
    lume snapshot restore "$VM_NAME" --name "$snapshot_name"
    echo "Restore complete"
else
    echo "Restore cancelled"
fi
