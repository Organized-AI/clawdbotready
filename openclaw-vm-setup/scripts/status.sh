#!/bin/bash
#===============================================================================
# OpenClaw VM Status Check
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"
VM_USER="${VM_USER:-openclaw}"
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "==============================================="
echo "  OpenClaw VM Status"
echo "==============================================="
echo ""

# Check if VM exists
echo -n "VM exists: "
if lume list 2>/dev/null | grep -q "$VM_NAME"; then
    echo -e "${GREEN}YES${NC}"
else
    echo -e "${RED}NO${NC}"
    exit 1
fi

# Get VM IP
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
if [[ -z "$VM_IP" ]]; then
    VM_IP=$(lume get "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
fi

echo "VM IP: ${VM_IP:-unknown}"

# Check VM is running
echo -n "VM running: "
if [[ -n "$VM_IP" ]] && ping -c 1 -W 2 "$VM_IP" &>/dev/null; then
    echo -e "${GREEN}YES${NC}"
else
    echo -e "${RED}NO${NC}"
    echo ""
    echo "Start VM with: lume run $VM_NAME"
    exit 1
fi

# Check SSH
echo -n "SSH accessible: "
if nc -z -w5 "$VM_IP" 22 &>/dev/null; then
    echo -e "${GREEN}YES${NC}"
else
    echo -e "${RED}NO${NC}"
fi

# Check SSH key auth
echo -n "SSH key auth: "
if ssh -i "$KEY_PATH" -o PasswordAuthentication=no -o ConnectTimeout=5 \
    "${VM_USER}@${VM_IP}" "echo ok" &>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}NEEDS KEY${NC}"
fi

# Check Gateway (if tunnel exists)
echo -n "Gateway (via tunnel): "
if curl -sk --connect-timeout 2 https://localhost:8080/health &>/dev/null; then
    echo -e "${GREEN}ACCESSIBLE${NC}"
else
    echo -e "${YELLOW}No tunnel or not running${NC}"
fi

echo ""
echo "-----------------------------------------------"
echo "VM Details"
echo "-----------------------------------------------"

# Get VM details from lume
lume get "$VM_NAME" 2>/dev/null || echo "Could not retrieve VM details"

# If we can SSH, get more info
if ssh -i "$KEY_PATH" -o PasswordAuthentication=no -o ConnectTimeout=5 \
    "${VM_USER}@${VM_IP}" "echo" &>/dev/null 2>&1; then

    echo ""
    echo "-----------------------------------------------"
    echo "VM System Info"
    echo "-----------------------------------------------"

    ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << 'REMOTE_EOF'
echo "macOS Version: $(sw_vers -productVersion)"
echo "Uptime: $(uptime | awk -F'( |,|:)+' '{print $6,$7",",$8,"hours,",$9,"minutes"}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5 " used of " $2}')"
echo "Memory: $(vm_stat | awk '/Pages free/ {free=$3} /Pages active/ {active=$3} END {printf "%.0f MB free\n", free*4096/1048576}')"

if [[ -f ~/.openclaw/logs/gateway.log ]]; then
    echo ""
    echo "Last 5 Gateway log entries:"
    tail -5 ~/.openclaw/logs/gateway.log 2>/dev/null || echo "  (no entries)"
fi

if [[ -f ~/monitoring/alerts.log ]]; then
    alert_count=$(wc -l < ~/monitoring/alerts.log 2>/dev/null | tr -d ' ')
    if [[ "$alert_count" -gt 0 ]]; then
        echo ""
        echo "⚠️  Security Alerts: $alert_count"
        echo "  View with: ./scripts/connect.sh 'cat ~/monitoring/alerts.log'"
    fi
fi
REMOTE_EOF

fi

echo ""
echo "==============================================="
echo "Quick Commands"
echo "==============================================="
echo "  Connect:     ./scripts/connect.sh"
echo "  Tunnel:      ./scripts/tunnel.sh"
echo "  Backup:      ./scripts/backup-vm.sh"
echo "  View logs:   ./scripts/connect.sh 'tail -f ~/.openclaw/logs/gateway.log'"
