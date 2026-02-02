#!/bin/bash
# Host-side monitoring for OpenClaw VM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
LOG_FILE="${SCRIPT_DIR}/logs/host-monitor.log"

# Check VM is running
if ! ping -c 1 -W 2 "$VM_IP" &>/dev/null; then
    echo "$(date): ALERT - VM not responding" >> "$LOG_FILE"
    exit 1
fi

# Check SSH is accessible
if ! nc -z -w5 "$VM_IP" 22 &>/dev/null; then
    echo "$(date): ALERT - SSH not accessible" >> "$LOG_FILE"
    exit 1
fi

# Fetch and display VM alerts
ssh -i "$KEY_PATH" -o ConnectTimeout=10 "${VM_USER:-openclaw}@${VM_IP}" \
    "tail -20 ~/monitoring/alerts.log 2>/dev/null" >> "$LOG_FILE"

echo "$(date): Host monitor check complete" >> "$LOG_FILE"
