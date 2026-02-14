# OpenClaw VM Setup - Claude Code Quick Start

## How to Use This Project

Copy this entire folder to your M4 Mac Mini, then use Claude Code to execute each phase.

---

## Prerequisites

1. M4 Mac Mini (or any Apple Silicon Mac)
2. macOS Sequoia or later
3. 70GB+ free disk space
4. Admin access

---

## Claude Code Commands

### Start Claude Code

```bash
cd /Users/jordaaan/Projects/openclaw-vm-setup
claude --dangerously-skip-permissions
```

### Execute Phases One at a Time

Copy and paste these prompts into Claude Code:

---

### Phase 0: Environment Verification
```
Read PLANNING/implementation-phases/PHASE-0-PROMPT.md and execute all tasks. This is a read-only verification phase - no changes will be made.
```

---

### Phase 1: Lume Installation
```
Read PLANNING/implementation-phases/PHASE-1-PROMPT.md and execute all tasks. IMPORTANT: Show me the installer script contents and wait for my approval before running the install.
```

---

### Phase 2: VM Creation
```
Read PLANNING/implementation-phases/PHASE-2-PROMPT.md and execute all tasks. Note: This phase requires manual interaction with the VM Setup Assistant. Pause and wait for me to complete the GUI steps.
```

---

### Phase 3: SSH Hardening
```
Read PLANNING/implementation-phases/PHASE-3-PROMPT.md and execute all tasks. Show me the SSH configuration that will be applied and verify key authentication works before disabling passwords.
```

---

### Phase 4: Host Firewall
```
Read PLANNING/implementation-phases/PHASE-4-PROMPT.md and execute all tasks. Show me the firewall rules before applying them. This modifies the host system firewall.
```

---

### Phase 5: Gateway Configuration
```
Read PLANNING/implementation-phases/PHASE-5-PROMPT.md and execute all tasks. Generate auth token and configure Gateway in the VM.
```

---

### Phase 6: Monitoring Setup
```
Read PLANNING/implementation-phases/PHASE-6-PROMPT.md and execute all tasks. Create monitoring scripts and cron jobs.
```

---

### Phase 7: Backup Configuration
```
Read PLANNING/implementation-phases/PHASE-7-PROMPT.md and execute all tasks. Create backup scripts and test a backup.
```

---

### Phase 8: Final Verification
```
Read PLANNING/implementation-phases/PHASE-8-PROMPT.md and execute all tasks. This is a read-only verification phase that generates a final report.
```

---

## Safety Verification at Each Phase

Each phase includes:

1. **Pre-execution checklist** - What the phase will do
2. **Safety level indicator** - 🟢 Safe, 🟡 Review, 🟠 Caution
3. **Command preview** - See commands before they run
4. **Rollback procedure** - How to undo if needed
5. **Success criteria** - Verify completion

---

## Environment Variables for Claude Code Web

If using Claude Code Web, set these environment variables:

```bash
export VM_NAME="openclaw-secure"
export VM_CPU="4"
export VM_MEMORY="8192"
export VM_DISK="60G"
export VM_USER="openclaw"
```

---

## After Completion

Once all phases are complete, use these commands:

```bash
# Check VM status
./scripts/status.sh

# Connect to VM
./scripts/connect.sh

# Create Gateway tunnel
./scripts/tunnel.sh

# View security alerts
./scripts/view-alerts.sh

# Backup VM
./scripts/backup-vm.sh

# Emergency stop (if needed)
./scripts/emergency-stop.sh
```

---

## Troubleshooting

### VM won't start
```bash
lume list
lume stop openclaw-secure
lume run openclaw-secure
```

### Can't SSH to VM
```bash
# Check VM IP
lume get openclaw-secure

# Test connectivity
ping $(cat .vm_ip)
nc -z $(cat .vm_ip) 22
```

### Firewall issues
```bash
# Check firewall status
sudo pfctl -s info

# Temporarily disable
sudo pfctl -d

# Re-enable
sudo pfctl -e
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `setup.sh` | Master setup script (alternative to phases) |
| `PLANNING/IMPLEMENTATION-MASTER-PLAN.md` | Overview of all phases |
| `PLANNING/implementation-phases/PHASE-X-PROMPT.md` | Individual phase prompts |
| `config/settings.env` | VM configuration |
| `config/exec-approvals.json` | Security allowlist |
| `scripts/*.sh` | Utility scripts |

---

## Git Workflow

After each successful phase:

```bash
git add -A
git commit -m "Phase X complete: [description]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

After all phases:

```bash
git push origin main
```
