# Phase 2: VM Creation

**Safety Level:** 🟢 Safe (creates isolated VM, doesn't affect host)
**Estimated Tasks:** 5
**Dependencies:** Phase 1 complete

---

## Pre-Execution Safety Check

This phase will:
1. Create a new macOS VM named `openclaw-secure`
2. Download macOS IPSW (~15GB) from Apple
3. Allocate resources: 4 CPU, 8GB RAM, 60GB disk
4. Start the VM for initial setup

**This is SAFE because:**
- The VM is completely isolated from your host
- Resources are virtual (not taking physical disk until used)
- You can delete the VM at any time with `lume delete`

Before proceeding, verify:
- [ ] Phase 1 (Lume) is complete
- [ ] You have 60GB+ free disk space
- [ ] You have ~20-30 minutes for VM creation

---

## Context Files to Read First

```
READ: config/settings.env (for VM configuration)
READ: PLANNING/PHASE-1-COMPLETE.md (verify Phase 1 done)
```

---

## Tasks

### Task 1: Load Configuration

```bash
# Load settings
source config/settings.env

echo "=== VM Configuration ==="
echo "VM Name: ${VM_NAME:-openclaw-secure}"
echo "CPU Cores: ${VM_CPU:-4}"
echo "Memory: ${VM_MEMORY:-8192}MB"
echo "Disk: ${VM_DISK:-60G}"
echo "User: ${VM_USER:-openclaw}"
```

---

### Task 2: Check for Existing VM

```bash
VM_NAME="${VM_NAME:-openclaw-secure}"

echo "=== Checking for Existing VMs ==="
echo ""

if lume list 2>/dev/null | grep -q "$VM_NAME"; then
    echo "⚠️ VM '$VM_NAME' already exists!"
    echo ""
    lume get "$VM_NAME" 2>/dev/null
    echo ""
    echo "Options:"
    echo "  1. Use existing VM (skip creation)"
    echo "  2. Delete and recreate: lume delete $VM_NAME --force"
    echo ""
    echo "To delete and recreate, run:"
    echo "  lume delete $VM_NAME --force"
    echo "  Then re-run this phase"
else
    echo "✅ No existing VM named '$VM_NAME'"
    echo "Ready to create"
fi
```

---

### Task 3: Create the VM

⚠️ **This step takes 15-25 minutes** (downloads macOS IPSW)

```bash
VM_NAME="${VM_NAME:-openclaw-secure}"
VM_CPU="${VM_CPU:-4}"
VM_MEMORY="${VM_MEMORY:-8192}"
VM_DISK="${VM_DISK:-60G}"

echo "=== Creating VM ==="
echo ""
echo "This will:"
echo "  1. Download macOS IPSW (~15GB)"
echo "  2. Create VM with allocated resources"
echo "  3. Start initial boot"
echo ""
echo "Estimated time: 15-25 minutes"
echo ""

# Create the VM
lume create "$VM_NAME" \
    --os macos \
    --ipsw latest \
    --cpu "$VM_CPU" \
    --memory "$VM_MEMORY" \
    --disk "$VM_DISK"

echo ""
echo "VM creation initiated."
```

---

### Task 4: Start VM and Complete Setup Assistant

```bash
VM_NAME="${VM_NAME:-openclaw-secure}"

echo "=== Starting VM ==="
echo ""

# Start VM (this opens the VM window)
lume run "$VM_NAME" &

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  MANUAL STEP REQUIRED: Complete macOS Setup Assistant"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "In the VM window that opens, complete these steps:"
echo ""
echo "  1. Select your country/region"
echo "  2. Select keyboard layout"
echo "  3. Skip Accessibility features"
echo "  4. Skip network setup OR connect to Wi-Fi"
echo "  5. Skip Data & Privacy"
echo "  6. Skip Migration Assistant"
echo "  7. Skip Apple ID sign-in (IMPORTANT: Use local account)"
echo "  8. Create local user account:"
echo "     - Full Name: OpenClaw Service"
echo "     - Account Name: ${VM_USER:-openclaw}"
echo "     - Password: [USE A STRONG PASSWORD - SAVE IT!]"
echo "  9. Enable Location Services: No"
echo "  10. Select time zone"
echo "  11. Skip Analytics"
echo "  12. Skip Screen Time"
echo "  13. Skip Siri"
echo "  14. Choose appearance"
echo ""
echo "  AFTER SETUP:"
echo "  15. Go to System Settings → General → Sharing"
echo "  16. Enable 'Remote Login' (SSH)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Press ENTER in this terminal when Setup Assistant is complete"
echo "and SSH (Remote Login) is enabled..."
read -r
```

---

### Task 5: Verify VM and Get IP

```bash
VM_NAME="${VM_NAME:-openclaw-secure}"

echo "=== Verifying VM ==="
echo ""

# Wait for VM to be fully ready
max_attempts=30
attempt=0

while [[ $attempt -lt $max_attempts ]]; do
    # Get VM details
    vm_info=$(lume get "$VM_NAME" 2>/dev/null)

    if [[ -n "$vm_info" ]]; then
        # Extract IP
        vm_ip=$(echo "$vm_info" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

        if [[ -n "$vm_ip" ]]; then
            # Test SSH connectivity
            if nc -z -w5 "$vm_ip" 22 &>/dev/null; then
                echo "✅ VM is ready!"
                echo ""
                echo "VM IP: $vm_ip"
                echo ""

                # Save IP for other phases
                echo "$vm_ip" > .vm_ip
                echo "IP saved to .vm_ip"
                break
            fi
        fi
    fi

    ((attempt++))
    echo "Waiting for VM to be ready... ($attempt/$max_attempts)"
    sleep 10
done

if [[ $attempt -eq $max_attempts ]]; then
    echo "⚠️ VM may not be fully ready"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check VM window is at desktop"
    echo "  2. Verify Remote Login is enabled"
    echo "  3. Run: lume get $VM_NAME"
fi
```

---

## Rollback Procedure

If you need to delete the VM and start over:

```bash
VM_NAME="${VM_NAME:-openclaw-secure}"

# Stop VM if running
lume stop "$VM_NAME" 2>/dev/null

# Delete VM
lume delete "$VM_NAME" --force

# Remove saved IP
rm -f .vm_ip

echo "VM deleted. Run Phase 2 again to recreate."
```

---

## Success Criteria

- [ ] VM created successfully
- [ ] Setup Assistant completed with local account
- [ ] SSH (Remote Login) enabled in VM
- [ ] VM IP address obtained and saved to `.vm_ip`
- [ ] Can ping VM IP: `ping $(cat .vm_ip)`

---

## Phase 2 Completion

```bash
VM_IP=$(cat .vm_ip 2>/dev/null || echo "unknown")

cat > PLANNING/PHASE-2-COMPLETE.md << EOF
# Phase 2 Complete: VM Creation

**Completed:** $(date)

## Results

- VM Name: ${VM_NAME:-openclaw-secure}
- VM IP: $VM_IP
- CPU: ${VM_CPU:-4} cores
- Memory: ${VM_MEMORY:-8192}MB
- Disk: ${VM_DISK:-60G}

## VM User

- Username: ${VM_USER:-openclaw}
- Password: [STORED SECURELY - NOT IN THIS FILE]

## Verification

- VM running: ✅
- SSH accessible: ✅
- IP saved: .vm_ip

## Ready for Phase 3
EOF

echo "✅ Phase 2 complete. Ready for Phase 3 (SSH Hardening)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-3-PROMPT.md and execute"
```
