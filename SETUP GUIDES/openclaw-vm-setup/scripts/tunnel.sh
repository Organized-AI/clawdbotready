#!/bin/bash
#===============================================================================
# Create SSH Tunnel to OpenClaw Gateway
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"
VM_USER="${VM_USER:-openclaw}"
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
GATEWAY_PORT="${GATEWAY_PORT:-8080}"

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

echo "Creating SSH tunnel to Gateway..."
echo "  Local: localhost:${GATEWAY_PORT}"
echo "  Remote: ${VM_IP}:${GATEWAY_PORT}"
echo ""
echo "Gateway will be accessible at: https://localhost:${GATEWAY_PORT}"
echo ""

# Load auth token if available
if [[ -f "${SCRIPT_DIR}/.gateway_token" ]]; then
    echo "Auth token: $(cat ${SCRIPT_DIR}/.gateway_token)"
fi

echo ""
echo "Press Ctrl+C to close tunnel"
echo ""

ssh -i "$KEY_PATH" \
    -L "${GATEWAY_PORT}:127.0.0.1:${GATEWAY_PORT}" \
    -N \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    "${VM_USER}@${VM_IP}"
