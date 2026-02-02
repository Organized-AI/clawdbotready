#!/bin/bash
#===============================================================================
# Restart OpenClaw VM after emergency stop
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"

echo "==============================================="
echo "  Restart OpenClaw VM"
echo "==============================================="
echo ""

# Check if VM exists
if ! lume list 2>/dev/null | grep -q "$VM_NAME"; then
    echo "Error: VM '$VM_NAME' does not exist"
    exit 1
fi

# Remove network block if exists
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
if [[ -n "$VM_IP" ]] && [[ -f /etc/pf.anchors/openclaw-blocked ]]; then
    echo "Removing network block..."
    sudo sed -i '' "/$VM_IP/d" /etc/pf.anchors/openclaw-blocked 2>/dev/null || true
    sudo pfctl -f /etc/pf.conf 2>/dev/null || true
fi

# Start VM
echo "Starting VM..."
lume run "$VM_NAME" &

# Wait for VM to be ready
echo "Waiting for VM to boot..."
max_attempts=60
attempt=0

while [[ $attempt -lt $max_attempts ]]; do
    new_ip=$(lume get "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    if [[ -n "$new_ip" ]] && nc -z -w5 "$new_ip" 22 &>/dev/null; then
        echo "$new_ip" > "${SCRIPT_DIR}/.vm_ip"
        echo ""
        echo "VM is ready!"
        echo "  IP: $new_ip"
        echo ""
        echo "Connect: ./scripts/connect.sh"
        echo "Tunnel:  ./scripts/tunnel.sh"
        exit 0
    fi
    ((attempt++))
    echo -n "."
    sleep 5
done

echo ""
echo "Warning: VM may not be fully ready. Check status with:"
echo "  ./scripts/status.sh"
