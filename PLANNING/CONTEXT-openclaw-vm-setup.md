# openclaw-vm-setup Implementation Context

**Created**: 2026-01-30
**Feature**: Phases 0-8 automated VM setup implementation
**Status**: Ready to implement

---

## Scope

### What's Included
- Phase 0: Environment verification (prerequisite checks)
- Phase 1: Lume hypervisor installation
- Phase 2: macOS VM creation and provisioning
- Phase 3: SSH hardening (Ed25519 keys, config lockdown)
- Phase 4: Host firewall configuration (pf rules)
- Phase 5: OpenClaw Gateway installation and configuration
- Phase 6: Monitoring and alerting system
- Phase 7: Automated backup system
- Phase 8: End-to-end verification and testing

### What's NOT Included (Deferred to v2)
- Interactive wizard (v1 uses settings.env for config)
- GUI interface (CLI only)
- Multi-VM orchestration
- Cloud deployment automation
- Automatic updates (manual only)

---

## Technical Decisions

### 1. Script Architecture

**Decision**: Monolithic master script with phase functions
**Rationale**:
- Easier state management (shared variables)
- Simpler dependency tracking
- Single entry point reduces user confusion
- Helper scripts in `scripts/` for daily operations only

**Implementation**:
```
setup.sh           → Master orchestrator with phase functions
scripts/           → Helper utilities for daily operations
  ├── connect.sh   → SSH connection
  ├── tunnel.sh    → Gateway tunnel
  ├── status.sh    → Health check
  ├── backup-vm.sh → Manual backup
  ├── restore-vm.sh
  ├── emergency-stop.sh
  └── restart-vm.sh
```

### 2. Configuration Strategy

**Decision**: Three-tier configuration system
**Rationale**: Separate concerns - user settings, security policy, runtime state

**Tier 1: User Configuration** (`config/settings.env`)
- VM resources (CPU, memory, disk)
- VM name and user account
- Backup retention settings
- User-customizable values only

**Tier 2: Security Policy** (`config/exec-approvals.json`)
- Command allowlist/denylist
- Immutable during runtime
- Version-controlled

**Tier 3: Runtime State** (root directory, gitignored)
- `.vm_ip` - VM IP address
- `.gateway_token` - Auth token
- `.ssh_key_path` - Path to SSH private key
- Ephemeral, recreated on each setup

### 3. Error Handling Strategy

**Decision**: Fail-fast with detailed logging and rollback procedures
**Implementation**:
```bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

# Logging
log() {
    local level="$1"  # INFO, WARN, ERROR
    shift
    echo "[$(date)] [$level] $*" | tee -a "$LOG_FILE"
}

# Error handler
trap 'error_handler $? $LINENO' ERR

error_handler() {
    log ERROR "Failed at line $2 with exit code $1"
    log ERROR "See rollback procedures in PHASE-X-PROMPT.md"
    exit "$1"
}
```

### 4. Idempotency Approach

**Decision**: Check-before-run with phase completion markers
**Rationale**: Safe to re-run, supports resume after failure

**Implementation**:
- Each phase checks for completion marker before running
- Markers stored in `PLANNING/PHASE-X-COMPLETE.md`
- `--force` flag to override and re-run

```bash
run_phase_1() {
    if [[ -f "PLANNING/PHASE-1-COMPLETE.md" ]] && [[ "${FORCE:-false}" != "true" ]]; then
        log INFO "Phase 1 already complete (use --force to re-run)"
        return 0
    fi

    # ... phase implementation ...

    # Mark complete
    echo "Phase 1 complete: $(date)" > PLANNING/PHASE-1-COMPLETE.md
}
```

### 5. Gateway Installation Method

**Decision**: Placeholder for now, document manual installation
**Rationale**: OpenClaw Gateway not yet publicly available

**v1 Implementation**:
- Phase 5 creates directory structure
- Logs instructions for manual Gateway installation
- Assumes user will install separately

**v2 Enhancement**:
- Download from official release URL
- Build from source with version pinning
- Package in Homebrew formula

### 6. Lume Installation Method

**Decision**: Use official installer script with verification
**Implementation**:
```bash
# Download installer
curl -fsSL https://lume.dev/install.sh -o /tmp/lume-install.sh

# Verify (checksum if available)
# TODO: Add checksum verification when Lume provides it

# Run installer
bash /tmp/lume-install.sh

# Verify installation
lume --version
```

### 7. SSH Key Management

**Decision**: Ed25519 keys stored in `~/.ssh/`, referenced in state file
**Implementation**:
```bash
# Generate key
ssh-keygen -t ed25519 \
    -f ~/.ssh/openclaw_vm_ed25519 \
    -N "" \
    -C "openclaw-vm@$(hostname)"

# Store path for scripts
echo "$HOME/.ssh/openclaw_vm_ed25519" > .ssh_key_path

# Secure permissions
chmod 600 ~/.ssh/openclaw_vm_ed25519
```

### 8. Firewall Configuration

**Decision**: pf rules file with localhost-only access
**Implementation**:
```bash
# Create pf rules
cat > /tmp/pf.openclaw.conf << 'EOF'
# Block all external access to VM
block in on en0 proto tcp from any to $vm_ip
block in on en0 proto udp from any to $vm_ip

# Allow localhost only
pass in on lo0 proto tcp from 127.0.0.1 to $vm_ip port {22, 8080}
EOF

# Load rules
sudo pfctl -f /tmp/pf.openclaw.conf
sudo pfctl -e
```

### 9. Monitoring Approach

**Decision**: Bash script with cron-based scheduling
**Rationale**: Simple, no dependencies, logs to files

**Monitors**:
- SSH authentication failures
- Suspicious process names (curl, wget, ssh, osascript)
- Disk space (alert at 90% full)
- Gateway process health

**Implementation**:
- `scripts/monitor.sh` runs every 5 minutes via cron
- Logs alerts to `logs/security-alerts.log`
- Email notifications (optional, v2)

### 10. Backup Strategy

**Decision**: Lume snapshots + config file backups
**Implementation**:
```bash
# Daily backup (cron)
# 1. Snapshot VM
lume snapshot openclaw-secure backup-$(date +%Y%m%d)

# 2. Backup configs
tar -czf backups/configs-$(date +%Y%m%d).tar.gz \
    config/ \
    .vm_ip \
    .gateway_token

# 3. Retention (keep 7 days)
find backups/ -name "configs-*.tar.gz" -mtime +7 -delete
```

---

## File Structure

```
openclaw-vm-setup/
├── setup.sh                       # Master script (all phases)
├── config/
│   ├── settings.env               # User-customizable values
│   └── exec-approvals.json        # Security allowlist
├── scripts/                       # Daily operation helpers
│   ├── connect.sh
│   ├── tunnel.sh
│   ├── status.sh
│   ├── backup-vm.sh
│   ├── restore-vm.sh
│   ├── emergency-stop.sh
│   ├── restart-vm.sh
│   └── monitor.sh                 # Monitoring daemon
├── logs/                          # Timestamped logs
│   ├── setup-YYYYMMDD_HHMMSS.log
│   └── security-alerts.log
├── backups/                       # Config backups
│   └── configs-YYYYMMDD.tar.gz
├── PLANNING/                      # Implementation docs
│   ├── PHASE-0-COMPLETE.md        # Phase markers
│   ├── PHASE-1-COMPLETE.md
│   └── ...
├── .vm_ip                         # Runtime state (gitignored)
├── .gateway_token                 # Runtime state (gitignored)
├── .ssh_key_path                  # Runtime state (gitignored)
└── README.md                      # User documentation
```

---

## Testing Strategy

### Phase 0 (Environment Verification)
- **Test**: Run on M4 Mac Mini
- **Verify**: All checks pass (arm64, macOS 15+, 70GB disk, network)
- **Failure case**: Missing prerequisites logged with instructions

### Phase 1 (Lume Installation)
- **Test**: Fresh system without Lume
- **Verify**: `lume --version` succeeds after installation
- **Idempotency**: Re-run detects existing installation

### Phase 2 (VM Creation)
- **Test**: Create VM with config from settings.env
- **Verify**: `lume list` shows VM, SSH port accessible
- **Rollback**: `lume delete openclaw-secure` works

### Phase 3 (SSH Hardening)
- **Test**: Password auth disabled, only Ed25519 keys work
- **Verify**: `ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw@$VM_IP` succeeds
- **Verify**: `ssh openclaw@$VM_IP` with password fails

### Phase 4 (Firewall)
- **Test**: External connections blocked, localhost allowed
- **Verify**: From another machine, cannot reach VM:22 or VM:8080
- **Verify**: From localhost, `nc -z $VM_IP 22` succeeds

### Phase 5 (Gateway Installation)
- **Test**: Directory structure created
- **Verify**: exec-approvals.json in place
- **Manual**: User installs Gateway, verifies it starts

### Phase 6 (Monitoring)
- **Test**: monitor.sh detects suspicious processes
- **Verify**: Alerts logged when test process spawned
- **Verify**: Cron job installed and runs every 5 minutes

### Phase 7 (Backups)
- **Test**: Manual backup creates snapshot + config tarball
- **Verify**: Restore from backup succeeds
- **Verify**: Retention policy deletes old backups

### Phase 8 (End-to-End Verification)
- **Test**: Full integration test
- **Verify**: All components working together
- **Verify**: Gateway accessible via SSH tunnel

---

## Edge Cases & Validation

### Disk Space Exhaustion
- **Check**: Before VM creation in Phase 2
- **Action**: Abort if < 70GB available
- **Message**: "Insufficient disk space. Need 70GB, have XGB"

### Network Failures
- **Check**: Phase 0, Phase 1 (download Lume)
- **Action**: Retry 3 times with backoff
- **Fallback**: Manual installation instructions

### Existing VM Conflict
- **Check**: Before creating VM in Phase 2
- **Action**: If VM name exists, prompt: delete, rename, or abort
- **Safety**: Never delete without explicit confirmation

### SSH Key Already Exists
- **Check**: Before generating in Phase 3
- **Action**: If key exists, ask: overwrite, use existing, or abort
- **Safety**: Backup existing key before overwrite

### Firewall Rules Conflict
- **Check**: Before loading pf rules in Phase 4
- **Action**: Backup existing pf.conf if present
- **Restoration**: Provide rollback script

### Gateway Not Available
- **Check**: Phase 5
- **Action**: Log instructions for manual installation
- **Verify**: Skip Gateway-dependent checks in Phase 8

---

## Open Questions

### ✅ Resolved
1. **Q**: How to distribute OpenClaw Gateway?
   **A**: Placeholder in v1, document manual installation

2. **Q**: Use individual phase scripts or monolithic?
   **A**: Monolithic setup.sh with functions

3. **Q**: Where to store runtime state?
   **A**: Gitignored files in project root

### ⏳ To Be Decided (Future)
1. **Q**: Email notifications for monitoring alerts?
   **A**: Defer to v2, logs-only for v1

2. **Q**: Slack/Discord webhook integration?
   **A**: v2 feature

3. **Q**: Automated Gateway updates?
   **A**: Manual only in v1, automate in v2

---

## Dependencies

### External
- Lume hypervisor (installed in Phase 1)
- macOS 15+ (Sequoia)
- Apple Silicon (arm64)
- Homebrew (optional, for future enhancements)

### Internal
- Phase order must be followed (dependencies in DAG)
- settings.env must exist before setup.sh runs
- exec-approvals.json template required for Phase 5

---

## Blockers

### Current
None - ready to implement

### Potential
1. Lume API changes (mitigation: pin version)
2. macOS pf syntax changes (mitigation: test on target OS)
3. OpenClaw Gateway availability (mitigation: manual placeholder)

---

## Next Steps

1. Complete setup.sh with all phase functions
2. Implement helper scripts in scripts/
3. Create config templates (settings.env, exec-approvals.json)
4. Write monitor.sh for security alerts
5. Test on M4 Mac Mini
6. Document any deviations from plan

---

*Last updated: 2026-01-30*
