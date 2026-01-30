# OpenClaw macOS VM Security Setup - Implementation Master Plan

**Created:** January 30, 2026
**Project Path:** `/Users/jordaaan/Projects/openclaw-vm-setup`
**Target Machine:** M4 Mac Mini (jordaaan)
**Runtime:** Bash/Shell Scripts

---

## Security-First Execution Protocol

⚠️ **IMPORTANT: This plan includes SAFETY VERIFICATION at each phase.**

Before each phase:
1. Read the phase prompt completely
2. Review all commands that will be executed
3. Verify you understand what each command does
4. Confirm you want to proceed

After each phase:
1. Review what was done
2. Verify success criteria
3. Create checkpoint before continuing

---

## Pre-Implementation Checklist

### ✅ Documentation (Complete)
| Component | Location | Status |
|-----------|----------|--------|
| VM Security Guide | `openclaw-macos-vm-security-hardening-guide.md` | ✅ |
| Native Security Guide | `openclaw-native-macos-lockdown-guide.md` | ✅ |
| Setup Scripts | `openclaw-vm-setup/` | ✅ |
| README | `openclaw-vm-setup/README.md` | ✅ |

### ⏳ Implementation (To Execute)
| Component | Phase | Status |
|-----------|-------|--------|
| Environment Verification | 0 | ⏳ |
| Lume Installation | 1 | ⏳ |
| VM Creation | 2 | ⏳ |
| SSH Hardening | 3 | ⏳ |
| Host Firewall | 4 | ⏳ |
| Gateway Configuration | 5 | ⏳ |
| Monitoring Setup | 6 | ⏳ |
| Backup Configuration | 7 | ⏳ |
| Final Verification | 8 | ⏳ |

---

## Implementation Phases Overview

| Phase | Name | What It Does | Safety Level |
|-------|------|--------------|--------------|
| 0 | Environment Check | Verify machine, disk space, prerequisites | 🟢 Safe (read-only) |
| 1 | Lume Installation | Download and install Lume hypervisor | 🟡 Review installer |
| 2 | VM Creation | Create sandboxed macOS VM | 🟢 Safe (isolated) |
| 3 | SSH Hardening | Generate keys, harden SSH config | 🟡 Modifies VM only |
| 4 | Host Firewall | Configure pf rules on host | 🟠 Modifies host firewall |
| 5 | Gateway Config | Install OpenClaw in VM | 🟢 VM only |
| 6 | Monitoring | Setup alerts and logging | 🟢 Safe |
| 7 | Backups | Configure automated backups | 🟢 Safe |
| 8 | Verification | Test complete setup | 🟢 Safe (read-only) |

---

## Safety Verification Legend

- 🟢 **Safe** — Read-only or isolated operations
- 🟡 **Review** — Modifies system but reversible
- 🟠 **Caution** — Modifies host system, review carefully
- 🔴 **Critical** — Irreversible, requires explicit confirmation

---

## Phase Dependencies

```
Phase 0 (Verify) ─────────────────────────────────────────┐
       │                                                  │
       ▼                                                  │
Phase 1 (Lume) ───────────────────────────────────────────┤
       │                                                  │
       ▼                                                  │
Phase 2 (VM) ─────────────────────────────────────────────┤
       │                                                  │
       ▼                                                  │
Phase 3 (SSH) ────────────────────────────────────────────┤
       │                                                  │
       ├──────────┬───────────────────────────────────────┤
       ▼          ▼                                       │
Phase 4 (FW)  Phase 5 (Gateway) ──────────────────────────┤
       │          │                                       │
       └────┬─────┘                                       │
            ▼                                             │
Phase 6 (Monitor) ────────────────────────────────────────┤
            │                                             │
            ▼                                             │
Phase 7 (Backup) ─────────────────────────────────────────┤
            │                                             │
            ▼                                             │
Phase 8 (Verify) ◄────────────────────────────────────────┘
```

---

## Rollback Procedures

Each phase includes rollback instructions. If something goes wrong:

| Phase | Rollback Method |
|-------|-----------------|
| 1 | `brew uninstall lume` or remove manually |
| 2 | `lume delete openclaw-secure` |
| 3 | Restore `sshd_config.backup` in VM |
| 4 | `sudo pfctl -d` to disable firewall |
| 5 | Delete `~/.openclaw/` in VM |
| 6 | Remove cron jobs, delete monitoring scripts |
| 7 | Remove backup scripts and cron entries |

---

## Quick Start Commands

```bash
# Navigate to project
cd /Users/jordaaan/Projects/openclaw-vm-setup

# Start Claude Code with permissions
claude --dangerously-skip-permissions

# In Claude Code, execute phases one at a time:
"Read PLANNING/implementation-phases/PHASE-0-PROMPT.md and execute"
```

---

## Git Commit Strategy

After each successful phase:

```bash
git add -A
git commit -m "Phase X complete: [description]

- [Key change 1]
- [Key change 2]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```
