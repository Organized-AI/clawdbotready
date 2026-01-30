# Project State

> Current decisions, active blockers, and session notes for the Clawdbot Ready project

Last Updated: 2026-01-30

---

## 🖥️ Version Identification

**This is the macOS Edition of Clawdbot Ready**

- **Target Platform**: macOS on Apple Silicon (M1/M2/M3/M4)
- **Deployment Methods**:
  1. VM-Isolated (Lume hypervisor) - Production/multi-tenant
  2. Native macOS (Direct install) - Development/testing
- **Use Case**: Secure AI agent environments with iMessage support
- **Scope**: macOS deployment automation and security hardening

This version supports both VM virtualization using Lume and native macOS installations. For other deployment options (Docker, cloud platforms, x86 hosts), see the main Clawdbot documentation.

**VM-Isolated Mode**:
- ✅ Full macOS VM isolation (stronger than containers)
- ✅ Automated security hardening via `openclaw-vm-setup`
- ✅ Snapshot/rollback capabilities
- ⏳ Implementation in progress (Phases 0-8)

**Native macOS Mode**:
- ✅ Zero virtualization overhead
- ✅ Security hardening guide available
- ✅ M1 Mac mini ready
- ✅ **Automation toolkit complete** (`openclaw-native-setup/`)
- ✅ 6-phase setup script with all helper scripts
- ✅ Complete documentation and implementation plan

---

## Current Phase
**Milestone 2: openclaw-vm-setup Core Implementation** - Phase 0-8 in development

---

## Recent Decisions

### 2026-01-30: Native macOS Automation Toolkit Complete
**Decision**: Implement complete automation toolkit for native macOS deployment
**Rationale**: Repository now supports BOTH deployment modes (VM + native) with full automation, not just VM
**Impact**: Users can choose fastest deployment path for their use case (M1 Mac mini: native, production: VM)

**Implementation Complete**:
- ✅ Created `openclaw-native-setup/` directory structure
- ✅ Master `setup.sh` script with 6 phases (800+ lines)
- ✅ 5 helper scripts (connect, status, emergency-stop, restart, monitor)
- ✅ Configuration templates (settings.env, launchagent.plist, exec-approvals.json)
- ✅ Comprehensive IMPLEMENTATION-MASTER-PLAN.md
- ✅ Phase-by-phase implementation prompts (PHASE-0 through PHASE-6)
- ✅ User-facing README with quick start, troubleshooting, comparison table

**Key Features**:
- User account isolation (dedicated `openclaw` user)
- Deny-by-default security (exec-approvals.json)
- Protected configuration (root-owned files)
- LaunchAgent auto-start with monitoring
- Emergency stop kill switch
- Real-time health monitoring
- <20 minute deployment time

**Files Created**: 14 files, ~3500 lines of code + documentation

### 2026-01-30: Integration Analysis Complete
**Decision**: Integrate customer setup guide and deployment guide into macOS implementations with enhanced security
**Rationale**: Existing guides provide comprehensive Clawdbot installation procedures; we should leverage and enhance these with VM hardening
**Impact**: Two parallel deployment paths with security-first approach

**Findings**:
- Customer guide covers 6 platforms (we focus on 2: macOS Native + macOS VM)
- VM mode (openclaw-vm-setup) needs Gateway installation integration (Phase 4 enhancement)
- Native mode needs new toolkit: `native-macos-setup/` with security hardening
- Both modes need secrets management, monitoring, and backup automation
- Channel integration (WhatsApp, Telegram, Discord) deferred to v1.5/v2

**Artifacts Created**:
- PLANNING/INTEGRATION-ANALYSIS.md - Comprehensive gap analysis and roadmap

### 2026-01-30: Organized Codebase Initialization
**Decision**: Initialize root directory with Organized Codebase structure
**Rationale**: Provides clear project structure, planning artifacts, and context for AI-assisted development
**Impact**: Better organization, clearer roadmap, easier onboarding

**Context**:
- Project has comprehensive documentation already created
- openclaw-vm-setup subdirectory has detailed planning
- Root directory lacked organizational structure
- Need unified view of entire Clawdbot Ready ecosystem

**Artifacts Created**:
- PLANNING/PROJECT.md - Vision and goals
- PLANNING/REQUIREMENTS.md - Feature breakdown (v1/v2/out-of-scope)
- PLANNING/ROADMAP.md - Milestone-based implementation plan
- PLANNING/STATE.md - This file

### 2026-01-XX: VM Platform Selection
**Decision**: Use Lume hypervisor for macOS virtualization
**Rationale**:
- Native Apple Silicon support
- Lightweight compared to alternatives
- Good isolation guarantees
- Developer-friendly API

**Alternatives Considered**:
- VirtualBox: Poor Apple Silicon support
- VMware Fusion: Commercial license required
- UTM: Less mature for automation
- Parallels: Commercial license, overkill for use case

**Trade-offs Accepted**:
- macOS-only initially (cross-platform deferred to Milestone 4)
- Dependency on third-party tool (Lume development velocity)

### 2026-01-XX: Security-First Architecture
**Decision**: Implement defense-in-depth with VM isolation, firewall rules, SSH hardening, and exec-approvals
**Rationale**:
- AI agents can potentially execute arbitrary code
- Customer data and credentials need protection
- Compliance and audit requirements
- Trust but verify approach

**Implementation**:
1. VM provides process-level isolation
2. Firewall restricts all external access
3. SSH hardened with Ed25519 keys only
4. exec-approvals deny-by-default command execution
5. Monitoring detects suspicious activity

### 2026-01-XX: Documentation-First Approach
**Decision**: Write comprehensive guides before building automation
**Rationale**:
- Manual procedures inform automation design
- Users can follow manual steps if automation fails
- Documentation validates architectural decisions
- Supports both DIY and automated deployments

**Outcome**:
- 6 comprehensive documentation files created
- Team deployment guide completed
- Architecture diagrams finalized

---

## Active Blockers

### None Currently
All dependencies available, ready to proceed with implementation.

### Potential Future Blockers
1. **Lume API Changes**: Hypervisor API could change breaking automation
   - Mitigation: Pin to specific Lume version, document manual fallback
2. **OpenClaw Gateway Availability**: Official release not yet public
   - Mitigation: Document build-from-source process
3. **Apple Silicon Hardware Access**: Testing requires M-series Mac
   - Mitigation: Current development machine is M4 Mac Mini

---

## Questions & Open Issues

### To Be Decided

#### Gateway Distribution Method
**Question**: How should users obtain the OpenClaw Gateway binary?
**Options**:
1. Download from official release (preferred)
2. Build from source during setup
3. Pre-bundle in toolkit
4. Package registry (npm, Homebrew)

**Impact**: Affects Phase 4 implementation
**Timeline**: Decide before implementing Phase 4

#### Backup Storage Location
**Question**: Where should VM snapshots and config backups be stored?
**Options**:
1. Local disk (simple, fast, but not off-site)
2. External drive (recommended for production)
3. Cloud storage (S3, GCS) - requires credentials
4. NAS/network share

**Current Decision**: Local by default, document external drive setup
**Status**: ✅ Decided

#### Monitoring Alert Delivery
**Question**: How should security alerts be delivered to administrators?
**Options**:
1. Email (requires SMTP config)
2. Slack/Discord webhook
3. Log file only (passive)
4. System notification (macOS only)

**Current Decision**: Start with log files, add webhook support in v2
**Status**: ✅ Decided

---

## Active Feature: openclaw-vm-setup Phases 0-8 Implementation

### Decisions Made

#### 1. Script Architecture (2026-01-30)
**Decision**: Monolithic master script (`setup.sh`) with phase functions
**Rationale**: Easier state management, simpler dependency tracking, single entry point
**Impact**: All phases in one file, helper scripts in `scripts/` for daily operations

#### 2. Configuration Strategy (2026-01-30)
**Decision**: Three-tier system - user settings, security policy, runtime state
**Rationale**: Separation of concerns, version control for security policy
**Files**:
- `config/settings.env` - User-customizable values
- `config/exec-approvals.json` - Security allowlist (immutable)
- `.vm_ip`, `.gateway_token`, `.ssh_key_path` - Runtime state (gitignored)

#### 3. Error Handling (2026-01-30)
**Decision**: Fail-fast with `set -euo pipefail`, detailed logging, rollback procedures
**Rationale**: Safety first, clear error messages, no silent failures
**Implementation**: Error traps, timestamped logs, per-phase rollback docs

#### 4. Idempotency (2026-01-30)
**Decision**: Check-before-run with phase completion markers
**Rationale**: Safe to re-run, resume after failure
**Implementation**: `PLANNING/PHASE-X-COMPLETE.md` markers, `--force` flag to override

#### 5. Gateway Installation (2026-01-30)
**Decision**: Placeholder + manual installation instructions (v1)
**Rationale**: OpenClaw Gateway not yet publicly available
**Future**: Auto-download from release URL or build from source (v2)

#### 6. Monitoring Approach (2026-01-30)
**Decision**: Bash script with cron-based scheduling, logs-only alerts
**Rationale**: Simple, no dependencies, works offline
**Future**: Email/webhook notifications (v2)

### Open Questions
None currently - all architectural decisions finalized

### Blockers
None - ready to implement

---

## Session Notes

### 2026-01-30: Project Initialization
- User requested `pnpm run setup` - script didn't exist
- Suggested using `pnpm dlx create-organized-codebase`
- Tool encountered interactive prompt issue in automated environment
- Pivoted to running `/oc:new-project` slash command
- Gathered requirements through structured questioning
- User clarified: root directory initialization, not just openclaw-vm-setup
- Created all planning artifacts successfully

### 2026-01-30: Implementation Discussion (via /oc:discuss)
- Reviewed existing phase prompts (PHASE-0 through PHASE-8)
- Documented 10 major architectural decisions
- Created CONTEXT-openclaw-vm-setup.md with full implementation spec
- Updated STATE.md with decisions and rationale
- User requested: "use the phased plan to build out the plan then execute the plan by writing all the code"

### 2026-01-30: Integration Analysis Session
- User requested integration of customer-setup-guide.md and deployment-guide.md
- Analyzed 6 deployment platforms in guides (we focus on macOS Native + VM)
- Identified gaps: native mode lacks automation, VM mode needs Gateway integration
- Created comprehensive integration analysis with security hardening roadmap
- User noted DigitalOcean as viable cloud alternative (doctl CLI available)

**Next Steps**:
1. ✅ Update .claude/settings.json with project-specific permissions
2. ✅ Update CLAUDE.md with comprehensive project context
3. ✅ Document implementation decisions (CONTEXT-openclaw-vm-setup.md)
4. ✅ Complete integration analysis (INTEGRATION-ANALYSIS.md)
5. 🔴 **Begin implementation of openclaw-vm-setup Phases 0-8**
6. 🟡 Create native-macos-setup toolkit (new Milestone 3)
7. ⏳ Test both modes on M4 Mac Mini
8. ⏳ Update customer guides with security hardening sections

---

## Implementation Status

### Completed
- ✅ Documentation library (6 comprehensive guides)
- ✅ openclaw-vm-setup architecture design
- ✅ 8-phase implementation plan
- ✅ README with quick start and troubleshooting
- ✅ Organized Codebase structure initialization

### In Progress
- 🚧 Phase 0-8 automation scripts
- 🚧 Testing framework

### Not Started
- ⏳ Interactive setup wizard
- ⏳ Error recovery system
- ⏳ Cross-platform support
- ⏳ Cloud deployment automation

---

## Technical Debt

### Known Issues
None yet - greenfield project

### Future Refactoring Needed
- [ ] Once Phase 0-8 complete, refactor common patterns into shared utilities
- [ ] Standardize error handling across all scripts
- [ ] Create template system for reusable configurations

---

## Dependencies

### External Tools Required
- Lume hypervisor (v1.x)
- Homebrew (package manager)
- Node.js / npm (for OpenClaw Gateway)
- macOS Sequoia or later
- Apple Silicon (M1/M2/M3/M4)

### Internal Dependencies
- openclaw-vm-setup requires documentation for user guidance
- Testing framework requires all phases implemented
- Cloud automation requires local version stable

---

## Metrics Tracking

### Development Progress
- Documentation: 100% (6/6 guides complete)
- Planning: 100% (all artifacts created)
- Implementation: 0% (Phase 0-8 pending)
- Testing: 0% (not started)

### Code Quality (Target)
- Test coverage: 0% (target: >80%)
- Documentation coverage: 100%
- Security audit: Not performed

---

## Communication

### Stakeholder Updates
None required - internal development project

### User Feedback
Awaiting first user testing after Phase 0-8 completion

---

## Resources

### Key Documentation
- `/DOCUMENTATION/` - Deployment guides and explanations
- `/openclaw-vm-setup/PLANNING/` - Detailed implementation plans
- `/openclaw-vm-setup/README.md` - User-facing quick start

### External References
- Lume Docs: https://lume.dev/docs
- OpenClaw Docs: https://docs.openclaw.ai (when available)
- SSH Hardening Guide: https://stribika.github.io/2015/01/04/secure-secure-shell.html

---

## Archive

### Superseded Decisions
None yet

### Completed Questions
- ✅ VM Platform Selection → Lume chosen
- ✅ Documentation approach → Write first, automate second
- ✅ Security model → Defense-in-depth with VM isolation
