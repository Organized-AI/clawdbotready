# Phase 0: Environment Verification

**Safety Level:** 🟢 Safe (read-only operations only)
**Estimated Tasks:** 5
**Dependencies:** None

---

## Pre-Execution Safety Check

Before running this phase, verify:

- [ ] You are on the M4 Mac Mini (jordaaan)
- [ ] You have admin access
- [ ] You want to set up OpenClaw in a VM

**This phase only READS information. It does NOT modify anything.**

---

## Context Files to Read First

```
READ: config/settings.env
READ: README.md
```

---

## Tasks

### Task 1: Verify Machine Identity

```bash
# Check which machine we're on
echo "=== Machine Identity ==="
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Home: $HOME"

# Verify Apple Silicon
echo ""
echo "=== Hardware ==="
uname -m  # Should be arm64
system_profiler SPHardwareDataType | grep -E "(Chip|Model|Memory)"
```

**Expected Output:**
- `arm64` for Apple Silicon
- M4 chip or similar
- Sufficient RAM (8GB+)

---

### Task 2: Check macOS Version

```bash
echo "=== macOS Version ==="
sw_vers

# Verify Sequoia or later
version=$(sw_vers -productVersion | cut -d. -f1)
if [[ "$version" -ge 15 ]]; then
    echo "✅ macOS version OK (Sequoia or later)"
else
    echo "⚠️ macOS 15+ (Sequoia) recommended for Lume"
fi
```

**Expected:** macOS 15.x (Sequoia) or later

---

### Task 3: Check Disk Space

```bash
echo "=== Disk Space ==="
df -h /

# Check available space
available_gb=$(df -g / | awk 'NR==2 {print $4}')
echo ""
echo "Available: ${available_gb}GB"

if [[ "$available_gb" -ge 70 ]]; then
    echo "✅ Disk space OK (70GB+ available)"
else
    echo "❌ Need at least 70GB free (VM requires ~60GB)"
fi
```

**Required:** 70GB+ free space

---

### Task 4: Check for Existing Lume Installation

```bash
echo "=== Lume Status ==="
if command -v lume &>/dev/null; then
    echo "Lume is installed:"
    lume --version 2>/dev/null || echo "(version unknown)"
    echo ""
    echo "Existing VMs:"
    lume list 2>/dev/null || echo "(none)"
else
    echo "Lume is NOT installed"
    echo "Phase 1 will install it"
fi
```

---

### Task 5: Check Network Connectivity

```bash
echo "=== Network Check ==="

# Test internet connectivity
if ping -c 1 -W 5 google.com &>/dev/null; then
    echo "✅ Internet: Connected"
else
    echo "❌ Internet: No connection"
fi

# Test Lume download site
if curl -sI https://lume.dev/install.sh | head -1 | grep -q "200\|301\|302"; then
    echo "✅ Lume site: Accessible"
else
    echo "⚠️ Lume site: May be blocked"
fi

# Test Apple software update (for IPSW downloads)
if curl -sI https://updates.cdn-apple.com | head -1 | grep -q "200\|301\|302\|403"; then
    echo "✅ Apple CDN: Accessible"
else
    echo "⚠️ Apple CDN: May have issues"
fi
```

---

## Success Criteria

- [ ] Machine is Apple Silicon (arm64)
- [ ] macOS 15+ (Sequoia or later)
- [ ] 70GB+ disk space available
- [ ] Internet connectivity working
- [ ] Lume site accessible

---

## Phase 0 Completion

After verifying all checks pass, create the completion marker:

```bash
# Create completion marker
cat > PLANNING/PHASE-0-COMPLETE.md << 'EOF'
# Phase 0 Complete: Environment Verification

**Completed:** $(date)

## Results

- Machine: [verified arm64]
- macOS: [version]
- Disk: [available]GB
- Network: OK

## Ready for Phase 1
EOF

echo "✅ Phase 0 complete. Ready for Phase 1 (Lume Installation)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-1-PROMPT.md and execute"
```
