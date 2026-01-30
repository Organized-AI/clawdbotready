# Phase 7: Backup Configuration

**Safety Level:** 🟢 Safe (creates backup scripts, optional cron)
**Estimated Tasks:** 4
**Dependencies:** Phase 6 complete (recommended)

---

## Pre-Execution Safety Check

This phase will:
1. Create automated backup script
2. Create restore script
3. Configure backup retention
4. Optionally set up scheduled backups

**This is SAFE because:**
- Only creates scripts and directories
- Backups are non-destructive (creates new files)
- Restore requires manual confirmation

Before proceeding, verify:
- [ ] VM is running and accessible
- [ ] Have sufficient disk space for backups (~5GB per backup)

---

## Context Files to Read First

```
READ: .vm_ip (VM IP address)
READ: config/settings.env (backup settings)
```

---

## Tasks

### Task 1: Create Backup Script

```bash
echo "=== Creating Backup Script ==="
echo ""

mkdir -p scripts backups

cat > scripts/backup-vm.sh << 'BACKUP_SCRIPT'
#!/bin/bash
#===============================================================================
# OpenClaw VM Backup Script
#===============================================================================
# Creates:
#   1. Configuration backup (tar.gz of ~/.openclaw, /etc/ssh/sshd_config)
#   2. Lume VM snapshot
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
BACKUP_DIR="${SCRIPT_DIR}/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo "  OpenClaw VM Backup"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Date: $DATE"
echo "VM: $VM_NAME"
echo "IP: ${VM_IP:-unknown}"
echo "Retention: $RETENTION_DAYS days"
echo ""

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------
if [[ -z "$VM_IP" ]]; then
    echo "❌ Error: VM IP not found"
    echo "   Make sure VM is running and .vm_ip exists"
    exit 1
fi

if ! nc -z -w5 "$VM_IP" 22 &>/dev/null; then
    echo "❌ Error: Cannot connect to VM"
    echo "   Make sure VM is running and SSH is accessible"
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 1: Backup Configuration Files
#-------------------------------------------------------------------------------
echo "--- Step 1: Backup Configuration ---"
echo ""

CONFIG_BACKUP="${BACKUP_DIR}/config_${DATE}.tar.gz"

echo "Creating configuration backup..."
ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" \
    "tar czf - ~/.openclaw /etc/ssh/sshd_config ~/monitoring ~/bin 2>/dev/null" > "$CONFIG_BACKUP"

if [[ -f "$CONFIG_BACKUP" ]]; then
    SIZE=$(ls -lh "$CONFIG_BACKUP" | awk '{print $5}')
    echo "✅ Config backup created: $CONFIG_BACKUP ($SIZE)"
else
    echo "⚠️ Config backup may have failed"
fi

#-------------------------------------------------------------------------------
# Step 2: Create VM Snapshot
#-------------------------------------------------------------------------------
echo ""
echo "--- Step 2: Create VM Snapshot ---"
echo ""

SNAPSHOT_NAME="backup-${DATE}"
echo "Creating snapshot: $SNAPSHOT_NAME"

if lume snapshot "$VM_NAME" --name "$SNAPSHOT_NAME" 2>/dev/null; then
    echo "✅ Snapshot created: $SNAPSHOT_NAME"
else
    echo "⚠️ Snapshot creation may have failed (check Lume)"
fi

#-------------------------------------------------------------------------------
# Step 3: Cleanup Old Backups
#-------------------------------------------------------------------------------
echo ""
echo "--- Step 3: Cleanup Old Backups ---"
echo ""

# Remove old config backups
old_configs=$(find "$BACKUP_DIR" -name "config_*.tar.gz" -mtime "+${RETENTION_DAYS}" 2>/dev/null)
if [[ -n "$old_configs" ]]; then
    echo "Removing old config backups:"
    echo "$old_configs" | while read f; do
        echo "  Removing: $f"
        rm -f "$f"
    done
else
    echo "No old config backups to remove"
fi

# List and remove old snapshots (keep last 7)
echo ""
echo "Checking snapshots..."
old_snapshots=$(lume snapshot list "$VM_NAME" 2>/dev/null | grep "backup-" | sort -r | tail -n +8)
if [[ -n "$old_snapshots" ]]; then
    echo "Removing old snapshots:"
    echo "$old_snapshots" | while read snap; do
        echo "  Removing: $snap"
        lume snapshot delete "$VM_NAME" --name "$snap" 2>/dev/null || true
    done
else
    echo "No old snapshots to remove"
fi

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Backup Complete"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Config Backups:"
ls -lh "$BACKUP_DIR"/config_*.tar.gz 2>/dev/null | tail -5 || echo "  (none)"

echo ""
echo "VM Snapshots:"
lume snapshot list "$VM_NAME" 2>/dev/null | grep "backup-" | tail -5 || echo "  (none)"

echo ""
echo "Restore Commands:"
echo "  Config: tar xzf ${CONFIG_BACKUP} -C /"
echo "  VM: ./scripts/restore-vm.sh"
BACKUP_SCRIPT

chmod +x scripts/backup-vm.sh

echo "Backup script created: scripts/backup-vm.sh"
```

---

### Task 2: Create Restore Script

```bash
echo "=== Creating Restore Script ==="
echo ""

cat > scripts/restore-vm.sh << 'RESTORE_SCRIPT'
#!/bin/bash
#===============================================================================
# OpenClaw VM Restore Script
#===============================================================================
# Restores VM from a Lume snapshot
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"

echo "═══════════════════════════════════════════════════════════════"
echo "  OpenClaw VM Restore"
echo "═══════════════════════════════════════════════════════════════"
echo ""

#-------------------------------------------------------------------------------
# List Available Snapshots
#-------------------------------------------------------------------------------
echo "Available snapshots:"
echo ""
lume snapshot list "$VM_NAME" 2>/dev/null | nl || echo "(no snapshots found)"

echo ""
read -p "Enter snapshot name to restore (or 'cancel'): " snapshot_name

if [[ "$snapshot_name" == "cancel" ]] || [[ -z "$snapshot_name" ]]; then
    echo "Restore cancelled."
    exit 0
fi

#-------------------------------------------------------------------------------
# Confirm Restore
#-------------------------------------------------------------------------------
echo ""
echo "⚠️  WARNING: This will restore VM to snapshot: $snapshot_name"
echo ""
echo "This will:"
echo "  1. Stop the VM if running"
echo "  2. Restore to the selected snapshot"
echo "  3. LOSE all changes made after the snapshot"
echo ""
read -p "Type 'RESTORE' to confirm: " confirm

if [[ "$confirm" != "RESTORE" ]]; then
    echo "Restore cancelled."
    exit 0
fi

#-------------------------------------------------------------------------------
# Perform Restore
#-------------------------------------------------------------------------------
echo ""
echo "Stopping VM..."
lume stop "$VM_NAME" 2>/dev/null || true

echo "Restoring snapshot: $snapshot_name"
if lume snapshot restore "$VM_NAME" --name "$snapshot_name"; then
    echo ""
    echo "✅ Restore complete!"
    echo ""
    echo "Start VM with: ./scripts/restart-vm.sh"
else
    echo ""
    echo "❌ Restore failed"
    exit 1
fi
RESTORE_SCRIPT

chmod +x scripts/restore-vm.sh

echo "Restore script created: scripts/restore-vm.sh"
```

---

### Task 3: Test Backup Script

```bash
echo "=== Testing Backup Script ==="
echo ""

# Run the backup
./scripts/backup-vm.sh

echo ""
echo "=== Backup Test Complete ==="
```

---

### Task 4: Optional - Schedule Automated Backups

```bash
echo "=== Automated Backup Scheduling ==="
echo ""
echo "To enable automated daily backups, add this cron job on your HOST:"
echo ""
echo "  crontab -e"
echo "  # Add this line (backup at 2 AM daily):"
echo "  0 2 * * * $(pwd)/scripts/backup-vm.sh >> $(pwd)/logs/backup.log 2>&1"
echo ""

read -p "Add automated backup cron job now? [y/N]: " add_cron

if [[ "$add_cron" =~ ^[Yy] ]]; then
    # Add cron job
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    (crontab -l 2>/dev/null | grep -v "backup-vm.sh"; echo "0 2 * * * ${SCRIPT_PATH}/scripts/backup-vm.sh >> ${SCRIPT_PATH}/logs/backup.log 2>&1") | crontab -

    echo ""
    echo "✅ Cron job added. Current crontab:"
    crontab -l | grep backup-vm
else
    echo ""
    echo "Skipped. You can add it manually later."
fi
```

---

## Rollback Procedure

```bash
# Remove cron job
crontab -l | grep -v "backup-vm.sh" | crontab -

# Remove backup scripts
rm -f scripts/backup-vm.sh scripts/restore-vm.sh

# Remove backups (be careful!)
# rm -rf backups/
```

---

## Success Criteria

- [ ] Backup script created and tested
- [ ] Restore script created
- [ ] At least one backup exists in `backups/`
- [ ] At least one snapshot exists (check `lume snapshot list`)
- [ ] Optional: Cron job configured

---

## Phase 7 Completion

```bash
cat > PLANNING/PHASE-7-COMPLETE.md << 'EOF'
# Phase 7 Complete: Backup Configuration

**Completed:** $(date)

## Results

- Backup script: scripts/backup-vm.sh
- Restore script: scripts/restore-vm.sh
- Backup directory: backups/
- Retention: 7 days

## Backups Created

### Config Backups
$(ls -lh backups/config_*.tar.gz 2>/dev/null | tail -3 || echo "(none)")

### VM Snapshots
$(lume snapshot list ${VM_NAME:-openclaw-secure} 2>/dev/null | grep "backup-" | tail -3 || echo "(none)")

## Commands

```bash
# Manual backup
./scripts/backup-vm.sh

# Restore from snapshot
./scripts/restore-vm.sh

# List backups
ls -la backups/
lume snapshot list openclaw-secure
```

## Ready for Phase 8
EOF

echo "✅ Phase 7 complete. Ready for Phase 8 (Final Verification)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-8-PROMPT.md and execute"
```
