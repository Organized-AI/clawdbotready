# Clawdbot Ready - macOS Edition

## 🖥️ Version Identification
**This is the macOS Edition** of Clawdbot Ready. It supports both VM-isolated and native macOS deployments on Apple Silicon.

- **Platform**: macOS Sequoia+ on Apple Silicon (M1/M2/M3/M4)
- **Deployment Methods**:
  1. **VM-Isolated** (Primary): Lume hypervisor virtualization - `openclaw-vm-setup` toolkit
  2. **Native macOS** (Alternative): Direct installation - manual setup with security guides
- **Key Features**: VM-level isolation OR native performance, both with iMessage support

This version does NOT cover Docker, cloud, or x86 deployments - those are separate implementations in the broader Clawdbot ecosystem.

---

## Project Vision
A comprehensive deployment toolkit and documentation hub that makes Clawdbot (AI-powered messaging gateway) deployment accessible to server administrators regardless of their technical expertise.

**Primary Goal**: Eliminate the knowledge barrier for deploying secure, isolated AI agent environments on macOS.

## Tech Stack
- **Runtime**: Node.js / Bash shell scripts
- **Language**: TypeScript (for tooling) + Shell scripts (for automation)
- **Virtualization**: Lume hypervisor (macOS/Apple Silicon)
- **Networking**: SSH tunneling, Tailscale (optional)
- **Deployment Target**: OpenClaw Gateway (AI agent runtime)
- **Package Manager**: pnpm

## Project Structure
```
/
├── PLANNING/                      → Project planning artifacts
│   ├── PROJECT.md                 → Vision, goals, success metrics
│   ├── REQUIREMENTS.md            → v1/v2 feature breakdown
│   ├── ROADMAP.md                 → Milestone-based implementation plan
│   └── STATE.md                   → Current decisions and blockers
├── DOCUMENTATION/                 → Comprehensive deployment guides
│   ├── clawdbot-deployment-explained.md
│   ├── ssh-tunnels-explained.md
│   ├── tailscale-explained.md
│   └── team-deployment-guide.md
├── openclaw-vm-setup/             → **PRIMARY FOCUS**: VM automation toolkit
│   ├── README.md                  → User-facing quick start
│   ├── setup.sh                   → Master orchestration script
│   ├── config/                    → Configuration templates
│   │   ├── settings.env           → VM and system settings
│   │   └── exec-approvals.json    → Security command allowlist
│   ├── scripts/                   → Helper utilities
│   │   ├── connect.sh             → SSH into VM
│   │   ├── tunnel.sh              → Create Gateway tunnel
│   │   ├── status.sh              → VM health check
│   │   ├── backup-vm.sh           → Backup configs and snapshots
│   │   ├── restore-vm.sh          → Restore from backup
│   │   ├── emergency-stop.sh      → Kill switch for compromised VMs
│   │   └── restart-vm.sh          → Recovery restart
│   └── PLANNING/                  → Implementation phase plans
│       ├── IMPLEMENTATION-MASTER-PLAN.md
│       └── implementation-phases/ → Phase 0-8 detailed prompts
├── .claude/                       → Claude Code configuration
│   ├── settings.json              → Permissions and project config
│   └── commands/                  → Custom slash commands (if any)
└── CLAUDE.md                      → This file (AI context)
```

## Current Focus
**Milestone 2: openclaw-vm-setup Core Implementation**

Working on Phase 0-8 automation:
- Phase 0: Prerequisites validation
- Phase 1: Lume + VM provisioning
- Phase 2: SSH hardening
- Phase 3: Host firewall (pf rules)
- Phase 4: Gateway installation
- Phase 5: Monitoring system
- Phase 6: Backup automation
- Phase 7: Helper scripts
- Phase 8: Testing & validation

## Code Conventions

### Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use functions for reusable logic
- Validate all inputs and dependencies
- Provide clear error messages with exit codes
- Log important actions to `logs/` directory
- Make scripts idempotent (safe to re-run)

### TypeScript (if used for tooling)
- Use strict mode in tsconfig.json
- Prefer `async/await` over callbacks
- No `any` types - use proper typing
- Keep functions under 50 lines
- Use descriptive variable names

### Git Conventions
- Use conventional commits: `feat/fix/docs/refactor/test/chore`
- Write clear, descriptive commit messages
- Reference issue numbers if applicable
- Keep commits atomic (one logical change per commit)

### Documentation
- Write documentation BEFORE automation
- Include architecture diagrams (ASCII art is fine)
- Provide troubleshooting sections
- Add "Why" explanations, not just "How"
- Keep docs up-to-date with code changes

## Security Principles

### Defense in Depth
1. **VM Isolation**: Full process isolation from host
2. **Firewall Rules**: Localhost-only access to VM
3. **SSH Hardening**: Ed25519 keys, no passwords, limited retries
4. **exec-approvals**: Deny-by-default command execution
5. **Monitoring**: Continuous security checks

### Secrets Management
- Never commit credentials, tokens, or keys
- Store secrets in:
  - `~/.ssh/openclaw_vm_ed25519` (SSH key)
  - `.vm_ip` (VM address)
  - `.gateway_token` (Gateway auth)
- Add to .gitignore if not already present

### Safe Defaults
- Always opt for more restrictive settings
- Require explicit opt-in for risky operations
- Fail closed (deny on error)
- Log all security-relevant actions

## DO NOT

### Code
- Never use `any` type in TypeScript
- Never skip error handling in shell scripts
- Never run commands without validating inputs
- Never trust user input without sanitization
- Never disable security features for convenience

### Git
- Never commit with failing tests
- Never force push to main/master
- Never commit secrets or credentials
- Never use `--dangerously-skip-permissions`
- Never rewrite published history

### Deployment
- Never skip prerequisites checks
- Never run as root unless absolutely required
- Never expose VM directly to internet
- Never disable firewall rules
- Never use weak SSH keys (RSA < 4096, DSA, ECDSA)

## Verification Requirements

### For Shell Scripts
Before considering a phase complete:
1. Test on clean macOS installation (or VM)
2. Verify idempotency (safe to re-run)
3. Check error handling (test failure scenarios)
4. Validate all outputs and side effects
5. Run shellcheck if available: `shellcheck script.sh`
6. Document what the script does in comments

### For Documentation
Before marking docs complete:
1. Have someone unfamiliar read and follow it
2. Verify all commands actually work
3. Test on target platform (macOS Sequoia + Apple Silicon)
4. Include troubleshooting for common errors
5. Add "Next steps" or "What's next" section

### For Features
Before marking a milestone complete:
1. All phases implemented and tested
2. Integration tests pass
3. Documentation updated
4. Security audit performed
5. User acceptance testing completed

## Key Decisions & Context

### Why VM instead of Docker?
- Full OS-level isolation (stronger than containers)
- Separate Apple ID possible (burner accounts)
- Easy snapshot/rollback for recovery
- Simulates production environment better
- AI agents can run native macOS apps

### Why Lume specifically?
- Native Apple Silicon support
- Lightweight (compared to Parallels, VMware)
- Good automation API
- Free and open source
- Developer-friendly

### Why deny-by-default exec-approvals?
- AI agents can potentially execute arbitrary commands
- Allowlist approach prevents zero-day exploits
- Easier to audit what's permitted
- Forces explicit security decisions
- Fail-safe if agent is compromised

### Why SSH tunneling instead of direct exposure?
- Zero attack surface from internet
- No need for complex firewall rules
- Easy to monitor and audit
- Works with existing SSH infrastructure
- Compatible with bastion host patterns

## Implementation Guidelines

### Adding New Features
1. Check PLANNING/REQUIREMENTS.md - is it in scope?
2. Update PLANNING/STATE.md with decision rationale
3. Write documentation first (explain the "why")
4. Implement with security in mind
5. Test thoroughly (including failure cases)
6. Update ROADMAP.md with progress

### Debugging Issues
1. Check logs in `openclaw-vm-setup/logs/`
2. Review recent changes in git history
3. Test manually to reproduce
4. Add logging if needed
5. Fix root cause, not symptoms
6. Add regression test

### When Stuck
1. Read the existing documentation in DOCUMENTATION/
2. Check openclaw-vm-setup/PLANNING/ for design decisions
3. Review similar implementations in the codebase
4. Ask clarifying questions before implementing
5. Document your decision in PLANNING/STATE.md

## Quick References

### Common Commands
```bash
# Check VM status
cd openclaw-vm-setup && ./scripts/status.sh

# Connect to VM
./scripts/connect.sh

# Create SSH tunnel to Gateway
./scripts/tunnel.sh

# Run full setup
./setup.sh all

# Run specific phase
./setup.sh 1  # Just Phase 1
```

### File Locations
- VM config: `openclaw-vm-setup/config/settings.env`
- Security allowlist: `openclaw-vm-setup/config/exec-approvals.json`
- Logs: `openclaw-vm-setup/logs/`
- Backups: `openclaw-vm-setup/backups/`

### Important Links
- Lume Docs: https://lume.dev/docs
- OpenClaw Docs: https://docs.openclaw.ai (when available)
- Project Planning: See PLANNING/ROADMAP.md

## Notes for AI Assistants

When working on this project:
1. **Security first**: Always consider security implications
2. **Idempotency**: Scripts should be safe to re-run
3. **Error handling**: Fail fast with clear messages
4. **Documentation**: Update docs when changing behavior
5. **Testing**: Verify on actual hardware when possible
6. **Context**: Reference PLANNING/ docs for design decisions
7. **Incremental**: Implement phase by phase, don't skip ahead
8. **User focus**: Remember the target user is not a DevOps expert

---
*Initialized with Organized Codebase v0.1.0 on 2026-01-30*
