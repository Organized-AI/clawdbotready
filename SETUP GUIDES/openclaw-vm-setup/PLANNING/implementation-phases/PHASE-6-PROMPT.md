# Phase 6: Monitoring Setup

**Safety Level:** 🟢 Safe (creates monitoring scripts, cron jobs)
**Estimated Tasks:** 4
**Dependencies:** Phase 5 complete

---

## Pre-Execution Safety Check

This phase will:
1. Create security monitoring script in VM
2. Set up cron job for automated checks
3. Create host-side monitoring script
4. Configure alert logging

**This is SAFE because:**
- Only creates monitoring/logging infrastructure
- No system modifications beyond cron entries
- All scripts are read-only operations

Before proceeding, verify:
- [ ] Phase 5 (Gateway) is complete
- [ ] VM is running and SSH accessible

---

## Context Files to Read First

```
READ: .vm_ip (VM IP address)
READ: PLANNING/PHASE-5-COMPLETE.md (verify Phase 5 done)
```

---

## Tasks

### Task 1: Create VM Security Monitor

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Creating VM Security Monitor ==="
echo ""

ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << 'REMOTE_MONITOR'
# Create monitoring directory
mkdir -p ~/monitoring

# Create the security monitor script
cat > ~/monitoring/security-monitor.sh << 'MONITOR_SCRIPT'
#!/bin/bash
#===============================================================================
# OpenClaw VM Security Monitor
# Runs every 5 minutes via cron
#===============================================================================

LOG_DIR=~/monitoring
ALERT_LOG="$LOG_DIR/alerts.log"
STATUS_LOG="$LOG_DIR/status.log"

mkdir -p "$LOG_DIR"

# Timestamp
TS=$(date '+%Y-%m-%d %H:%M:%S')

#-------------------------------------------------------------------------------
# Check 1: SSH Failed Attempts
#-------------------------------------------------------------------------------
ssh_failures=$(grep -c "sshd.*Failed" /var/log/system.log 2>/dev/null || echo "0")
if [[ "$ssh_failures" -gt 10 ]]; then
    echo "$TS [ALERT] High SSH failures: $ssh_failures" >> "$ALERT_LOG"
fi

#-------------------------------------------------------------------------------
# Check 2: Suspicious Processes
#-------------------------------------------------------------------------------
suspicious=$(ps aux | grep -E "(nc |ncat|netcat|socat|curl.*\||wget.*\|)" | grep -v grep)
if [[ -n "$suspicious" ]]; then
    echo "$TS [ALERT] Suspicious process detected:" >> "$ALERT_LOG"
    echo "$suspicious" >> "$ALERT_LOG"
fi

#-------------------------------------------------------------------------------
# Check 3: Disk Usage
#-------------------------------------------------------------------------------
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [[ "$disk_usage" -gt 80 ]]; then
    echo "$TS [WARN] Disk usage high: ${disk_usage}%" >> "$ALERT_LOG"
fi

#-------------------------------------------------------------------------------
# Check 4: Memory Usage
#-------------------------------------------------------------------------------
mem_pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $NF}' | tr -d '%')
if [[ -n "$mem_pressure" ]] && [[ "$mem_pressure" -lt 20 ]]; then
    echo "$TS [WARN] Low memory: ${mem_pressure}% free" >> "$ALERT_LOG"
fi

#-------------------------------------------------------------------------------
# Check 5: Unexpected Network Connections
#-------------------------------------------------------------------------------
unexpected_conns=$(netstat -an 2>/dev/null | grep ESTABLISHED | grep -v "127.0.0.1" | grep -v "::1" | wc -l | tr -d ' ')
if [[ "$unexpected_conns" -gt 5 ]]; then
    echo "$TS [WARN] Multiple external connections: $unexpected_conns" >> "$ALERT_LOG"
fi

#-------------------------------------------------------------------------------
# Check 6: exec-approvals Violations
#-------------------------------------------------------------------------------
if [[ -f ~/.openclaw/logs/exec-approvals.log ]]; then
    recent_denials=$(grep -c "DENIED" ~/.openclaw/logs/exec-approvals.log 2>/dev/null || echo "0")
    if [[ "$recent_denials" -gt 0 ]]; then
        echo "$TS [WARN] exec-approvals denials: $recent_denials" >> "$ALERT_LOG"
    fi
fi

#-------------------------------------------------------------------------------
# Log Status Summary
#-------------------------------------------------------------------------------
echo "$TS SSH_fails=$ssh_failures Disk=${disk_usage}% Conns=$unexpected_conns" >> "$STATUS_LOG"

# Trim logs if too large (keep last 10000 lines)
if [[ -f "$ALERT_LOG" ]] && [[ $(wc -l < "$ALERT_LOG") -gt 10000 ]]; then
    tail -5000 "$ALERT_LOG" > "$ALERT_LOG.tmp" && mv "$ALERT_LOG.tmp" "$ALERT_LOG"
fi
if [[ -f "$STATUS_LOG" ]] && [[ $(wc -l < "$STATUS_LOG") -gt 10000 ]]; then
    tail -5000 "$STATUS_LOG" > "$STATUS_LOG.tmp" && mv "$STATUS_LOG.tmp" "$STATUS_LOG"
fi
MONITOR_SCRIPT

chmod +x ~/monitoring/security-monitor.sh

echo "Security monitor created: ~/monitoring/security-monitor.sh"

# Test the script
echo ""
echo "Testing monitor script..."
~/monitoring/security-monitor.sh
echo ""
echo "Status log:"
cat ~/monitoring/status.log 2>/dev/null || echo "(first run)"
REMOTE_MONITOR

echo ""
echo "✅ VM security monitor created"
```

---

### Task 2: Setup Cron Job in VM

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Setting Up Cron Job ==="
echo ""

ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << 'REMOTE_CRON'
# Check current crontab
echo "Current crontab:"
crontab -l 2>/dev/null || echo "(empty)"

# Add monitoring cron job (every 5 minutes)
(crontab -l 2>/dev/null | grep -v "security-monitor"; echo "*/5 * * * * ~/monitoring/security-monitor.sh") | crontab -

echo ""
echo "Updated crontab:"
crontab -l

echo ""
echo "✅ Cron job configured to run every 5 minutes"
REMOTE_CRON

echo ""
echo "✅ Cron job set up in VM"
```

---

### Task 3: Create Host Monitoring Script

```bash
echo "=== Creating Host Monitor ==="
echo ""

# Create host monitoring script
cat > scripts/host-monitor.sh << 'HOST_MONITOR'
#!/bin/bash
#===============================================================================
# OpenClaw Host-Side Monitor
# Checks VM health from the host machine
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
LOG_FILE="${SCRIPT_DIR}/logs/host-monitor.log"

mkdir -p "${SCRIPT_DIR}/logs"

TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== OpenClaw Host Monitor ===" | tee -a "$LOG_FILE"
echo "Time: $TS" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

#-------------------------------------------------------------------------------
# Check 1: VM Running
#-------------------------------------------------------------------------------
echo -n "VM Status: " | tee -a "$LOG_FILE"
if [[ -n "$VM_IP" ]] && ping -c 1 -W 2 "$VM_IP" &>/dev/null; then
    echo "RUNNING ($VM_IP)" | tee -a "$LOG_FILE"
else
    echo "NOT RESPONDING" | tee -a "$LOG_FILE"
    echo "$TS [ALERT] VM not responding" >> "$LOG_FILE"
    exit 1
fi

#-------------------------------------------------------------------------------
# Check 2: SSH Accessible
#-------------------------------------------------------------------------------
echo -n "SSH: " | tee -a "$LOG_FILE"
if nc -z -w5 "$VM_IP" 22 &>/dev/null; then
    echo "OK" | tee -a "$LOG_FILE"
else
    echo "BLOCKED/DOWN" | tee -a "$LOG_FILE"
    echo "$TS [ALERT] SSH not accessible" >> "$LOG_FILE"
fi

#-------------------------------------------------------------------------------
# Check 3: Fetch VM Alerts
#-------------------------------------------------------------------------------
echo "" | tee -a "$LOG_FILE"
echo "Recent VM Alerts:" | tee -a "$LOG_FILE"
if ssh -i "$KEY_PATH" -o ConnectTimeout=10 "${VM_USER}@${VM_IP}" \
    "tail -10 ~/monitoring/alerts.log 2>/dev/null" 2>/dev/null; then
    :
else
    echo "(could not fetch)" | tee -a "$LOG_FILE"
fi

#-------------------------------------------------------------------------------
# Check 4: Host Firewall Status
#-------------------------------------------------------------------------------
echo "" | tee -a "$LOG_FILE"
echo -n "Host Firewall: " | tee -a "$LOG_FILE"
if sudo pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then
    echo "ENABLED" | tee -a "$LOG_FILE"
else
    echo "DISABLED" | tee -a "$LOG_FILE"
    echo "$TS [WARN] Host firewall disabled" >> "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== Monitor Complete ===" | tee -a "$LOG_FILE"
HOST_MONITOR

chmod +x scripts/host-monitor.sh

echo "Host monitor created: scripts/host-monitor.sh"
echo ""
echo "Testing host monitor..."
echo ""
./scripts/host-monitor.sh
```

---

### Task 4: Create Alert Viewer

```bash
echo "=== Creating Alert Viewer ==="
echo ""

# Create alert viewer script
cat > scripts/view-alerts.sh << 'ALERT_VIEWER'
#!/bin/bash
#===============================================================================
# View OpenClaw Alerts
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "═══════════════════════════════════════════════════════════════"
echo "  OpenClaw Security Alerts"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Host alerts
echo "--- Host Alerts ---"
if [[ -f "${SCRIPT_DIR}/logs/host-monitor.log" ]]; then
    grep -E "\[ALERT\]|\[WARN\]" "${SCRIPT_DIR}/logs/host-monitor.log" | tail -20
else
    echo "(no host alerts)"
fi

echo ""
echo "--- VM Alerts ---"
if ssh -i "$KEY_PATH" -o ConnectTimeout=10 "${VM_USER}@${VM_IP}" \
    "cat ~/monitoring/alerts.log 2>/dev/null | tail -30" 2>/dev/null; then
    :
else
    echo "(could not connect to VM)"
fi

echo ""
echo "--- VM Status (last 10 entries) ---"
if ssh -i "$KEY_PATH" -o ConnectTimeout=10 "${VM_USER}@${VM_IP}" \
    "tail -10 ~/monitoring/status.log 2>/dev/null" 2>/dev/null; then
    :
else
    echo "(could not connect to VM)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
ALERT_VIEWER

chmod +x scripts/view-alerts.sh

echo "Alert viewer created: scripts/view-alerts.sh"
```

---

## Rollback Procedure

```bash
# Remove cron job in VM
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw@$(cat .vm_ip) \
    "crontab -l | grep -v security-monitor | crontab -"

# Remove monitoring scripts in VM
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw@$(cat .vm_ip) \
    "rm -rf ~/monitoring"

# Remove host scripts
rm -f scripts/host-monitor.sh scripts/view-alerts.sh
```

---

## Success Criteria

- [ ] VM security monitor created at `~/monitoring/security-monitor.sh`
- [ ] Cron job running every 5 minutes
- [ ] Host monitor script working
- [ ] Alert viewer script working
- [ ] Logs being generated

---

## Phase 6 Completion

```bash
cat > PLANNING/PHASE-6-COMPLETE.md << 'EOF'
# Phase 6 Complete: Monitoring Setup

**Completed:** $(date)

## Results

### VM Monitoring
- Script: ~/monitoring/security-monitor.sh
- Cron: Every 5 minutes
- Logs: ~/monitoring/alerts.log, ~/monitoring/status.log

### Host Monitoring
- Script: scripts/host-monitor.sh
- Alert viewer: scripts/view-alerts.sh
- Logs: logs/host-monitor.log

## Checks Performed

1. SSH failed attempts
2. Suspicious processes
3. Disk usage (>80% alert)
4. Memory pressure
5. Unexpected network connections
6. exec-approvals violations

## Commands

```bash
# View alerts
./scripts/view-alerts.sh

# Run host monitor
./scripts/host-monitor.sh

# View VM logs directly
./scripts/connect.sh "tail -f ~/monitoring/alerts.log"
```

## Ready for Phase 7
EOF

echo "✅ Phase 6 complete. Ready for Phase 7 (Backups)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-7-PROMPT.md and execute"
```
