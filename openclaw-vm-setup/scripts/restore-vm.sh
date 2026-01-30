#!/bin/bash
#===============================================================================
# Restore OpenClaw VM from Snapshot
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"

echo "==============================================="
echo "  Restore OpenClaw VM from Snapshot"
echo "==============================================="
echo ""

# Check if VM exists
if ! lume list 2>/dev/null | grep -q "$VM_NAME"; then
    echo "Error: VM '$VM_NAME' does not exist"
    exit 1
fi

# List available snapshots
echo "Available snapshots:"
echo ""
lume snapshot list "$VM_NAME" 2>/dev/null | nl
echo ""

read -p "Enter snapshot name to restore (or 'list' to see more): " snapshot_name

if [[ "$snapshot_name" == "list" ]]; then
    lume snapshot list "$VM_NAME" 2>/dev/null
    exit 0
fi

if [[ -z "$snapshot_name" ]]; then
    echo "No snapshot specified. Aborting."
    exit 1
fi

echo ""
echo "WARNING: This will:"
echo "  1. Stop the VM if running"
echo "  2. Restore to snapshot: $snapshot_name"
echo "  3. All changes since the snapshot will be LOST"
echo ""
read -p "Type 'RESTORE' to confirm: " confirm

if [[ "$confirm" != "RESTORE" ]]; then
    echo "Aborted."
    exit 1
fi

# Stop VM if running
echo "Stopping VM..."
lume stop "$VM_NAME" 2>/dev/null || true

# Restore snapshot
echo "Restoring snapshot: $snapshot_name"
if lume snapshot restore "$VM_NAME" --name "$snapshot_name"; then
    echo ""
    echo "Restore complete!"
    echo ""
    echo "Start VM with: ./scripts/restart-vm.sh"
else
    echo ""
    echo "Error: Restore failed"
    exit 1
fi
