#!/bin/bash
# Backup OpenClaw VM configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_NAME="openclaw-secure"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
BACKUP_DIR="${SCRIPT_DIR}/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Starting backup: $DATE"

# Backup VM configuration files
echo "Backing up VM configs..."
ssh -i "$KEY_PATH" "clawuser@${VM_IP}"     "tar czf - ~/.openclaw /etc/ssh/sshd_config 2>/dev/null" >     "${BACKUP_DIR}/config_${DATE}.tar.gz"

# Create VM snapshot
echo "Creating VM snapshot..."
lume snapshot "$VM_NAME" --name "backup-$DATE"

# Cleanup old backups (keep last 7)
ls -t "${BACKUP_DIR}"/config_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null

echo "Backup complete: $DATE"
echo "  Config: ${BACKUP_DIR}/config_${DATE}.tar.gz"
echo "  Snapshot: backup-$DATE"
