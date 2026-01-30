#!/bin/bash
#===============================================================================
# Backup OpenClaw VM Configuration
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"
VM_USER="${VM_USER:-openclaw}"
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
BACKUP_DIR="${SCRIPT_DIR}/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Get VM IP
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
if [[ -z "$VM_IP" ]]; then
    VM_IP=$(lume get "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
fi

echo "==============================================="
echo "  OpenClaw VM Backup"
echo "==============================================="
echo ""
echo "Date: $DATE"
echo "VM: $VM_NAME"
echo "IP: ${VM_IP:-unknown}"
echo ""

# Check VM is accessible
if [[ -z "$VM_IP" ]]; then
    echo "Error: Cannot determine VM IP"
    exit 1
fi

if ! nc -z -w5 "$VM_IP" 22 &>/dev/null; then
    echo "Error: VM is not accessible via SSH"
    exit 1
fi

# Backup configuration files
echo "Backing up configuration files..."
ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" \
    "tar czf - ~/.openclaw /etc/ssh/sshd_config ~/monitoring 2>/dev/null" > \
    "${BACKUP_DIR}/config_${DATE}.tar.gz"

if [[ -f "${BACKUP_DIR}/config_${DATE}.tar.gz" ]]; then
    size=$(ls -lh "${BACKUP_DIR}/config_${DATE}.tar.gz" | awk '{print $5}')
    echo "  Config backup: ${BACKUP_DIR}/config_${DATE}.tar.gz ($size)"
else
    echo "  Warning: Config backup may have failed"
fi

# Create VM snapshot
echo "Creating VM snapshot..."
if lume snapshot "$VM_NAME" --name "backup-${DATE}" 2>/dev/null; then
    echo "  Snapshot: backup-${DATE}"
else
    echo "  Warning: Snapshot creation may have failed"
fi

# Cleanup old backups
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
echo ""
echo "Cleaning up backups older than $RETENTION_DAYS days..."

# Remove old config backups
find "$BACKUP_DIR" -name "config_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete 2>/dev/null

# Remove old snapshots (keep last 7)
lume snapshot list "$VM_NAME" 2>/dev/null | grep "backup-" | sort -r | tail -n +8 | while read snapshot; do
    lume snapshot delete "$VM_NAME" --name "$snapshot" 2>/dev/null || true
done

echo ""
echo "==============================================="
echo "  Backup Complete"
echo "==============================================="
echo ""
echo "Files:"
ls -lh "${BACKUP_DIR}"/config_*.tar.gz 2>/dev/null | tail -5

echo ""
echo "Snapshots:"
lume snapshot list "$VM_NAME" 2>/dev/null | grep "backup-" | tail -5

echo ""
echo "Restore with:"
echo "  Config: tar xzf ${BACKUP_DIR}/config_${DATE}.tar.gz -C /"
echo "  Snapshot: ./scripts/restore-vm.sh"
