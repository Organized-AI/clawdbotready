# Phase 1: Lume Installation

**Safety Level:** 🟡 Review (downloads and installs software)
**Estimated Tasks:** 4
**Dependencies:** Phase 0 complete

---

## Pre-Execution Safety Check

⚠️ **SAFETY VERIFICATION REQUIRED**

This phase will:
1. Download the Lume installer script
2. Show you the script contents for review
3. Ask for confirmation before installing
4. Install Lume to your system

**What is Lume?**
- Open-source macOS VM manager for Apple Silicon
- Creates isolated macOS VMs using Apple's Virtualization.framework
- Similar to UTM but optimized for macOS guests
- Source: https://github.com/trycua/lume

Before proceeding, verify:
- [ ] You understand Lume will be installed on your host Mac
- [ ] You have reviewed the Lume project (optional but recommended)
- [ ] You want to proceed with installation

---

## Context Files to Read First

```
READ: PLANNING/PHASE-0-COMPLETE.md (verify Phase 0 done)
```

---

## Tasks

### Task 1: Download Installer for Review

```bash
# Create logs directory
mkdir -p logs

# Download installer WITHOUT running it
echo "Downloading Lume installer for review..."
curl -fsSL https://lume.dev/install.sh -o logs/lume-install.sh

# Show file size and hash
echo ""
echo "=== Installer Details ==="
ls -la logs/lume-install.sh
echo "SHA256: $(shasum -a 256 logs/lume-install.sh | awk '{print $1}')"
```

---

### Task 2: Review Installer Script (SAFETY CHECK)

```bash
echo "=== INSTALLER SCRIPT CONTENTS ==="
echo ""
echo "Reviewing for safety..."
echo ""

# Show the full script
cat logs/lume-install.sh

echo ""
echo "=== END OF INSTALLER ==="
```

**🔍 MANUAL REVIEW CHECKPOINT**

Before continuing, verify the script:
- [ ] Only downloads from known/trusted sources
- [ ] Does not contain suspicious commands (rm -rf /, curl | bash chains, etc.)
- [ ] Installs to expected locations
- [ ] Does not modify system files unexpectedly

**If anything looks suspicious, STOP and investigate.**

---

### Task 3: Confirm and Install Lume

⚠️ **CONFIRMATION REQUIRED**

Only proceed if you reviewed the script and it looks safe.

```bash
echo "=== LUME INSTALLATION ==="
echo ""
echo "This will install Lume to your system."
echo ""

# User confirmation (in Claude Code, this will proceed)
# In manual execution, you'd add: read -p "Install Lume? [y/N]: " confirm

echo "Installing Lume..."
bash logs/lume-install.sh

echo ""
echo "Installation complete."
```

---

### Task 4: Verify Installation

```bash
echo "=== VERIFICATION ==="
echo ""

# Check Lume is installed
if command -v lume &>/dev/null; then
    echo "✅ Lume installed successfully"
    echo ""
    echo "Version:"
    lume --version 2>/dev/null || echo "(version command not available)"
    echo ""
    echo "Location:"
    which lume
    echo ""
    echo "Help:"
    lume --help 2>/dev/null | head -20
else
    echo "❌ Lume installation failed"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check logs/lume-install.sh output"
    echo "2. Try manual installation from https://lume.dev"
    exit 1
fi
```

---

## Rollback Procedure

If you need to uninstall Lume:

```bash
# Method 1: If installed via Homebrew
brew uninstall lume 2>/dev/null

# Method 2: Manual removal
sudo rm -f /usr/local/bin/lume
rm -rf ~/.lume

echo "Lume removed"
```

---

## Success Criteria

- [ ] Installer script reviewed and approved
- [ ] Lume installed successfully
- [ ] `lume --version` or `lume --help` works
- [ ] No errors during installation

---

## Phase 1 Completion

```bash
cat > PLANNING/PHASE-1-COMPLETE.md << 'EOF'
# Phase 1 Complete: Lume Installation

**Completed:** $(date)

## Results

- Lume installed: ✅
- Location: $(which lume)
- Installer hash: $(shasum -a 256 logs/lume-install.sh | awk '{print $1}')

## Notes

Installer was reviewed before execution.

## Ready for Phase 2
EOF

echo "✅ Phase 1 complete. Ready for Phase 2 (VM Creation)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-2-PROMPT.md and execute"
```
