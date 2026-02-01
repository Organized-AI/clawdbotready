#!/bin/bash
#===============================================================================
# Quick Connect to OpenClaw VM
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

# Apply unified naming if INSTANCE_NAME is set
INSTANCE_NAME="${INSTANCE_NAME:-}"
VM_NAME="${VM_NAME:-openclaw-secure}"
VM_USER="${VM_USER:-openclaw}"

# Derive key path from instance name
if [[ -n "$INSTANCE_NAME" ]]; then
    KEY_PATH="$HOME/.ssh/openclaw_${INSTANCE_NAME}_ed25519"
    # Also update VM_NAME and VM_USER if using defaults
    [[ "$VM_NAME" == "openclaw-secure" ]] && VM_NAME="${INSTANCE_NAME}-vm"
    [[ "$VM_USER" == "openclaw" || "$VM_USER" == "clawuser" ]] && VM_USER="$INSTANCE_NAME"
else
    KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
fi

# Get VM IP
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
if [[ -z "$VM_IP" ]]; then
    VM_IP=$(lume get "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
fi

if [[ -z "$VM_IP" ]]; then
    echo "Error: Cannot determine VM IP. Is the VM running?"
    echo "Start VM with: lume run $VM_NAME"
    exit 1
fi

echo "Connecting to $VM_NAME at $VM_IP..."
ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" "$@"
