#!/bin/bash
#===============================================================================
# EMERGENCY: Stop OpenClaw VM Immediately
#===============================================================================
# Use this if you suspect the agent has been compromised or is misbehaving
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}===============================================${NC}"
echo -e "${RED}  EMERGENCY STOP - OpenClaw VM${NC}"
echo -e "${RED}===============================================${NC}"
echo ""
echo "This will:"
echo "  1. Force stop the VM"
echo "  2. Create a forensic snapshot"
echo "  3. Block all network traffic to/from VM IP"
echo ""
echo -e "${YELLOW}Warning: The VM will be completely stopped.${NC}"
echo ""
read -p "Type 'STOP' to confirm: " confirm

if [[ "$confirm" != "STOP" ]]; then
    echo "Aborted."
    exit 1
fi

# Get VM IP before stopping
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)

echo ""
echo "$(date): EMERGENCY STOP initiated" | tee -a "${SCRIPT_DIR}/logs/emergency.log"

# 1. Create forensic snapshot
echo "Creating forensic snapshot..."
SNAPSHOT_NAME="forensic-$(date +%Y%m%d_%H%M%S)"
lume snapshot "$VM_NAME" --name "$SNAPSHOT_NAME" 2>/dev/null || true
echo "  Snapshot: $SNAPSHOT_NAME"

# 2. Force stop VM
echo "Stopping VM..."
lume stop "$VM_NAME" --force 2>/dev/null || true

# 3. Block network (if we have the IP)
if [[ -n "$VM_IP" ]]; then
    echo "Blocking network for $VM_IP..."
    # Add to pf blocklist
    echo "block quick from $VM_IP" | sudo tee -a /etc/pf.anchors/openclaw-blocked >/dev/null 2>&1 || true
    echo "block quick to $VM_IP" | sudo tee -a /etc/pf.anchors/openclaw-blocked >/dev/null 2>&1 || true
    sudo pfctl -f /etc/pf.conf 2>/dev/null || true
fi

# 4. Log the incident
cat >> "${SCRIPT_DIR}/logs/emergency.log" << EOF
---
Timestamp: $(date)
VM Name: $VM_NAME
VM IP: ${VM_IP:-unknown}
Snapshot: $SNAPSHOT_NAME
Operator: $(whoami)
---
EOF

echo ""
echo -e "${RED}===============================================${NC}"
echo -e "${RED}  VM STOPPED${NC}"
echo -e "${RED}===============================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Review logs: ${SCRIPT_DIR}/logs/"
echo "  2. Investigate snapshot: lume run $VM_NAME --snapshot $SNAPSHOT_NAME --no-network"
echo "  3. If compromise confirmed:"
echo "     - Rotate all credentials"
echo "     - Delete VM: lume delete $VM_NAME"
echo "     - Rebuild: ./setup.sh all"
echo ""
echo "To restart (only after investigation):"
echo "  ./scripts/restart-vm.sh"
