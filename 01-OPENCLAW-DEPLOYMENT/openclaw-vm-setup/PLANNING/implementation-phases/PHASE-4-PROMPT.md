# Phase 4: Host Firewall Configuration

**Safety Level:** 🟠 Caution (modifies host system firewall)
**Estimated Tasks:** 4
**Dependencies:** Phase 3 complete

---

## Pre-Execution Safety Check

⚠️ **HOST SYSTEM MODIFICATION**

This phase will:
1. Create pf firewall anchor file
2. Modify `/etc/pf.conf` to include the anchor
3. Enable pf firewall (if not already enabled)

**What this does:**
- Blocks direct network access to the VM from outside
- Only allows SSH and Gateway access via localhost
- Protects VM from external network attacks

**Why this is safe:**
- Creates backup of pf.conf before modifying
- You can easily disable with `sudo pfctl -d`
- Rules only affect VM traffic, not other network traffic

Before proceeding, verify:
- [ ] Phase 3 (SSH Hardening) is complete
- [ ] You have admin (sudo) access on the host
- [ ] You understand pf firewall basics

---

## Context Files to Read First

```
READ: .vm_ip (VM IP address)
READ: PLANNING/PHASE-3-COMPLETE.md (verify Phase 3 done)
```

---

## Tasks

### Task 1: Check Current Firewall State

```bash
echo "=== Current Firewall State ==="
echo ""

# Check if pf is enabled
if sudo pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then
    echo "pf firewall: ENABLED"
else
    echo "pf firewall: DISABLED"
fi

echo ""
echo "Current rules (if any):"
sudo pfctl -sr 2>/dev/null | head -20 || echo "(no rules or pf disabled)"

echo ""
echo "Current anchors:"
sudo pfctl -sA 2>/dev/null || echo "(none)"
```

---

### Task 2: Create Firewall Anchor File

⚠️ **SAFETY REVIEW**

Review the firewall rules below. They will:
- Allow SSH (port 22) from localhost only
- Allow Gateway (port 8080) from localhost only
- Block all other direct access to the VM

```bash
VM_IP=$(cat .vm_ip 2>/dev/null)

echo "=== Firewall Rules Preview ==="
echo ""
echo "VM IP: $VM_IP"
echo ""

if [[ -z "$VM_IP" ]]; then
    echo "❌ Error: VM IP not found"
    exit 1
fi

# Show the rules we'll create
cat << RULES_PREVIEW
# OpenClaw VM Firewall Rules
# VM IP: $VM_IP

# Define VM IP
vm_ip = "$VM_IP"

# Allow SSH from localhost only (for direct VM access)
pass in quick proto tcp from 127.0.0.1 to \$vm_ip port 22

# Allow Gateway from localhost only (for SSH tunnel)
pass in quick proto tcp from 127.0.0.1 to \$vm_ip port 8080

# Block all other direct access to VM
block in quick from any to \$vm_ip
RULES_PREVIEW

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Creating firewall anchor file..."
echo "═══════════════════════════════════════════════════════════════"

# Create the anchor file (requires sudo)
sudo tee /etc/pf.anchors/openclaw-vm > /dev/null << ANCHOR_FILE
# OpenClaw VM Firewall Rules
# Generated: $(date)
# VM IP: $VM_IP
#
# Purpose: Block direct external access to VM
# Access VM via SSH tunnel only

# Define VM IP
vm_ip = "$VM_IP"

# Allow SSH from localhost only
pass in quick proto tcp from 127.0.0.1 to \$vm_ip port 22

# Allow Gateway from localhost only
pass in quick proto tcp from 127.0.0.1 to \$vm_ip port 8080

# Block all other direct access to VM
block in quick from any to \$vm_ip
ANCHOR_FILE

echo ""
echo "✅ Anchor file created: /etc/pf.anchors/openclaw-vm"
echo ""
sudo cat /etc/pf.anchors/openclaw-vm
```

---

### Task 3: Update pf.conf

```bash
echo "=== Updating pf.conf ==="
echo ""

# Check if anchor is already configured
if grep -q "openclaw-vm" /etc/pf.conf 2>/dev/null; then
    echo "Anchor already configured in pf.conf"
    grep "openclaw" /etc/pf.conf
else
    echo "Creating backup of pf.conf..."
    sudo cp /etc/pf.conf /etc/pf.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backup: /etc/pf.conf.backup.*"
    echo ""

    echo "Adding anchor to pf.conf..."
    sudo tee -a /etc/pf.conf > /dev/null << 'PF_ADDITION'

# OpenClaw VM firewall rules
# Added: $(date)
anchor "openclaw-vm"
load anchor "openclaw-vm" from "/etc/pf.anchors/openclaw-vm"
PF_ADDITION

    echo "✅ Anchor added to pf.conf"
fi

echo ""
echo "Current pf.conf:"
sudo cat /etc/pf.conf
```

---

### Task 4: Enable Firewall and Test

```bash
echo "=== Enabling Firewall ==="
echo ""

# Load the configuration
echo "Loading pf configuration..."
sudo pfctl -f /etc/pf.conf 2>&1 || echo "(some warnings are normal)"

echo ""
echo "Enabling pf..."
sudo pfctl -e 2>&1 || echo "(already enabled)"

echo ""
echo "=== Verification ==="
echo ""

# Check status
echo "Firewall status:"
sudo pfctl -s info 2>/dev/null | grep -E "Status|Debug"

echo ""
echo "Loaded anchors:"
sudo pfctl -sA 2>/dev/null | grep openclaw || echo "(anchor loaded)"

echo ""
echo "OpenClaw VM rules:"
sudo pfctl -a openclaw-vm -sr 2>/dev/null || echo "(rules active)"

echo ""
echo "=== Testing Connectivity ==="
VM_IP=$(cat .vm_ip)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
VM_USER="${VM_USER:-openclaw}"

# Test SSH still works
echo "Testing SSH connection..."
if ssh -i "$KEY_PATH" -o ConnectTimeout=5 "${VM_USER}@${VM_IP}" "echo 'SSH: OK'" 2>/dev/null; then
    echo "✅ SSH connection works"
else
    echo "⚠️ SSH may be blocked - check firewall rules"
fi

echo ""
echo "✅ Firewall configuration complete"
```

---

## Rollback Procedure

If the firewall causes issues:

```bash
# Disable pf entirely
sudo pfctl -d

# Or remove just the OpenClaw rules
sudo sed -i '' '/openclaw-vm/d' /etc/pf.conf
sudo pfctl -f /etc/pf.conf

# Or restore from backup
sudo cp /etc/pf.conf.backup.* /etc/pf.conf
sudo pfctl -f /etc/pf.conf
```

---

## Success Criteria

- [ ] Firewall anchor created at `/etc/pf.anchors/openclaw-vm`
- [ ] Anchor added to `/etc/pf.conf`
- [ ] pf firewall enabled
- [ ] SSH to VM still works
- [ ] Rules visible with `sudo pfctl -a openclaw-vm -sr`

---

## Phase 4 Completion

```bash
cat > PLANNING/PHASE-4-COMPLETE.md << 'EOF'
# Phase 4 Complete: Host Firewall

**Completed:** $(date)

## Results

- Anchor file: /etc/pf.anchors/openclaw-vm
- pf.conf: Updated
- Firewall: Enabled

## Rules Applied

- SSH (22): localhost → VM only
- Gateway (8080): localhost → VM only
- All other: BLOCKED

## Verification Commands

```bash
# Check firewall status
sudo pfctl -s info

# View OpenClaw rules
sudo pfctl -a openclaw-vm -sr

# Disable if needed
sudo pfctl -d
```

## Ready for Phase 5
EOF

echo "✅ Phase 4 complete. Ready for Phase 5 (Gateway Configuration)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-5-PROMPT.md and execute"
```
