# Integration Analysis: Customer Setup Guide → macOS Implementations

> Analysis of how to integrate comprehensive setup guides into our macOS native and VM deployment paths

**Date**: 2026-01-30
**Status**: Planning
**Purpose**: Ensure both deployment methods (VM-isolated and native macOS) incorporate all capabilities from the customer setup guide with enhanced security hardening

---

## Executive Summary

The customer setup guide and deployment guide provide comprehensive coverage of 6 deployment platforms:
1. macOS Native
2. Docker (Local)
3. Fly.io
4. Hetzner VPS
5. GCP Compute Engine
6. macOS VM (Lume)

**Additional Platform Identified**: DigitalOcean (doctl CLI available) - viable cloud alternative similar to Hetzner

**Our Focus**: Extract and enhance **macOS Native** (#1) and **macOS VM (Lume)** (#6) with security hardening best practices. Cloud platforms (Fly.io, Hetzner, GCP, DigitalOcean) are documented but out of scope for v1 automation.

---

## Gap Analysis: What's Missing from Our Current Implementation

### 1. macOS Native Deployment (Currently Undocumented in openclaw-vm-setup)

#### From Customer Setup Guide
The guide provides:
- ✅ Installation via npm global package: `npm install -g clawdbot@latest`
- ✅ Interactive onboarding: `clawdbot onboard --install-daemon`
- ✅ launchd daemon installation (auto-start on boot)
- ✅ Health checks: `clawdbot status`, `clawdbot gateway health`
- ✅ Token management: `clawdbot gateway token`
- ✅ Log access: `clawdbot logs`
- ✅ Configuration location: `~/.clawdbot/clawdbot.json`
- ✅ Control UI access: `http://127.0.0.1:18789`

#### Missing from Our Implementation
- ❌ No automated native macOS setup script
- ❌ No security hardening for native deployments
- ❌ No firewall configuration for native mode
- ❌ No monitoring/alerting for native mode
- ❌ No backup automation for native mode
- ❌ No exec-approvals integration for native mode
- ❌ No SSH hardening (not applicable for local-only)

#### Proposed: Native macOS Security Hardening
We should create `native-macos-setup/` parallel to `openclaw-vm-setup/`:

```
native-macos-setup/
├── README.md                       → Quick start for native deployment
├── setup.sh                        → One-command native setup
├── config/
│   ├── settings.env                → Native-specific settings
│   └── exec-approvals.json         → Same deny-by-default policy
├── scripts/
│   ├── install-gateway.sh          → Gateway installation
│   ├── harden-firewall.sh          → macOS pf rules (localhost-only)
│   ├── setup-monitoring.sh         → Local monitoring daemon
│   ├── backup-configs.sh           → Config + session backups
│   └── status.sh                   → Health check
└── PLANNING/
    └── NATIVE-IMPLEMENTATION-PLAN.md
```

**Security Hardening for Native Mode**:
1. **Application Firewall**: Enable macOS Application Firewall for Gateway process
2. **Network Binding**: Force Gateway to bind to `127.0.0.1` only (no LAN access)
3. **File Permissions**: Lock down `~/.clawdbot/` to user-only (chmod 700)
4. **Secrets Protection**: Secure token storage with keychain integration
5. **Process Monitoring**: Detect unexpected child processes from Gateway
6. **Disk Encryption**: Validate FileVault is enabled before installation
7. **exec-approvals**: Same deny-by-default allowlist as VM mode

---

### 2. macOS VM (Lume) Deployment

#### From Customer Setup Guide
The guide provides:
- ✅ Lume installation script
- ✅ VM creation: `lume create clawdbot --os macos --ipsw latest`
- ✅ VNC setup for initial macOS configuration
- ✅ SSH enablement in VM
- ✅ IP discovery: `lume get clawdbot`
- ✅ Headless operation: `lume run clawdbot --no-display`
- ✅ Gateway installation inside VM (same as native)

#### Already in Our openclaw-vm-setup
- ✅ Phase 0: Prerequisites validation
- ✅ Phase 1: Lume + VM provisioning
- ✅ Phase 2: SSH hardening (Ed25519)
- ✅ Phase 3: Host firewall (pf rules)
- ✅ Phase 4: Gateway installation (placeholder)
- ✅ Phase 5: Monitoring system
- ✅ Phase 6: Backup automation
- ✅ Phase 7: Helper scripts
- ✅ Phase 8: Testing framework

#### Gaps in VM Implementation
- ❌ No VNC automation (user must manually complete Setup Assistant)
- ❌ No integration with Clawdbot's `onboard` command
- ❌ No channel integration (WhatsApp, Telegram, Discord, Slack)
- ❌ No model configuration (Anthropic/OpenAI keys)
- ❌ No Tailscale setup automation
- ❌ No advanced firewall rules for channel-specific traffic

#### Enhancements Needed for VM Mode

**Phase 4 Enhancement: Gateway Installation**
Currently a placeholder. Should integrate:
1. Download/build Clawdbot Gateway
2. Run `clawdbot onboard` interactively or with answers file
3. Configure API keys (prompt user or read from host environment)
4. Set up exec-approvals.json
5. Install launchd plist inside VM
6. Validate startup and health checks

**New Phase 9: Channel Integration** (v1.5 or v2)
Support messaging platform setup:
1. WhatsApp: QR code scanning workflow
2. Telegram: Bot token configuration
3. Discord: Application setup + bot invite
4. Slack: Workspace integration
5. iMessage: BlueBubbles bridge (macOS VM only)

**New Phase 10: Remote Access** (v1.5 or v2)
Automate secure remote access:
1. Tailscale installation (optional)
2. SSH tunnel helper scripts (already in Phase 7)
3. MagicDNS configuration
4. VPN integration guides

---

## Comparison Matrix: Customer Guide vs. Our Implementation

| Feature | Customer Guide | openclaw-vm-setup | native-macos-setup | Priority |
|---------|----------------|-------------------|---------------------|----------|
| **VM Provisioning** | Manual Lume commands | ✅ Automated (Phase 1) | N/A | ✅ Done |
| **SSH Hardening** | Not covered | ✅ Automated (Phase 2) | N/A | ✅ Done |
| **Firewall Rules** | Not covered | ✅ Automated (Phase 3) | ❌ Missing | 🔴 High |
| **Gateway Install** | Manual npm + onboard | ⚠️ Placeholder (Phase 4) | ❌ Missing | 🔴 High |
| **exec-approvals** | Not mentioned | ✅ Planned (Phase 4) | ❌ Missing | 🔴 High |
| **Monitoring** | `clawdbot logs` only | ✅ Automated (Phase 5) | ❌ Missing | 🟡 Medium |
| **Backups** | Not covered | ✅ Automated (Phase 6) | ❌ Missing | 🟡 Medium |
| **Helper Scripts** | Individual commands | ✅ Automated (Phase 7) | ❌ Missing | 🟢 Low |
| **Channel Setup** | Detailed guides | ❌ Not implemented | ❌ Missing | 🟡 Medium |
| **Tailscale Setup** | Detailed guide | ❌ Not automated | ❌ Missing | 🟢 Low |
| **Multi-device** | Conceptual diagram | ❌ Out of scope (v1) | ❌ Out of scope | ⚪ v2 |
| **Cloud Deploy** | 3 platforms covered | ❌ Out of scope | ❌ Out of scope | ⚪ v2 |
| **Docker** | docker-compose provided | ❌ Out of scope | ❌ Out of scope | ⚪ v2 |

---

## Security Hardening Enhancements

### VM Mode Security (Enhancements to openclaw-vm-setup)

#### Current Security Posture
✅ Already implemented:
- VM-level process isolation
- Host firewall (pf rules) restricting access to localhost
- SSH hardening with Ed25519 keys
- exec-approvals deny-by-default
- Monitoring and alerting

#### Additional Hardening (Add to Phase 3 or new Phase 3.5)
1. **Network Segmentation**
   - Separate VLAN for VM traffic (if supported by Lume)
   - Block all egress except essential services (apt, npm, claude.ai)
   - DNS filtering to prevent data exfiltration

2. **Intrusion Detection**
   - Monitor `/var/log/auth.log` for suspicious patterns
   - Detect port scanning attempts
   - Alert on unexpected network connections

3. **Resource Limits**
   - cgroups/limits.conf for CPU/memory caps
   - Prevent fork bombs and resource exhaustion
   - Disk quota enforcement

4. **Audit Logging**
   - Enable auditd for all exec() calls
   - Log all file access in Gateway workspace
   - Tamper-proof log forwarding to host

5. **Secrets Management**
   - Encrypt API keys at rest (age, gpg, or macOS keychain)
   - Rotate credentials automatically
   - Secrets never stored in plaintext config files

6. **Kernel Hardening**
   - Enable ASLR (macOS default)
   - Disable unnecessary kernel modules
   - Validate System Integrity Protection (SIP) enabled

---

### Native Mode Security (New: native-macos-setup)

#### Baseline Security
Since native mode doesn't have VM isolation, we must compensate:

1. **Application Sandboxing**
   - Run Gateway with minimal privileges (non-root user)
   - Use macOS sandbox profiles if possible
   - Drop capabilities after binding to port

2. **Network Isolation**
   - macOS Application Firewall: Block all incoming except localhost
   - pf rules: Deny all traffic except loopback
   - Network extension for process-level filtering (advanced)

3. **File System Protection**
   - Workspace directory: `~/clawd/` with restrictive permissions (700)
   - Config directory: `~/.clawdbot/` locked down
   - Prevent Gateway from accessing user home directory outside workspace

4. **Monitoring**
   - fs_usage to detect unexpected file access
   - dtrace probes for system call monitoring
   - Log all Gateway subprocess creation

5. **Backup & Recovery**
   - Time Machine exclusion for ephemeral session data
   - Automated config backups to encrypted DMG
   - Disaster recovery runbook

6. **Secrets Protection**
   - macOS Keychain integration for API keys
   - Never store tokens in plaintext
   - Auto-lock keychain on screensaver

---

## Implementation Roadmap

### Phase 1: Enhance VM Mode (openclaw-vm-setup)
**Priority**: 🔴 High
**Timeline**: Current sprint

Tasks:
1. ✅ Complete Phase 0-8 base implementation (already planned)
2. **Enhance Phase 4**: Integrate `clawdbot onboard` automation
   - Pre-answer onboarding questions via config file
   - Install Gateway as launchd service
   - Validate health checks pass
3. **Enhance Phase 3**: Add advanced firewall rules
   - Egress filtering (allowlist model)
   - DNS filtering
   - Network segmentation (if Lume supports)
4. **Enhance Phase 5**: Add intrusion detection
   - SSH brute-force detection
   - Port scan alerts
   - Unexpected process monitoring
5. **Enhance Phase 4**: Add secrets management
   - Encrypt API keys with age/gpg
   - Keychain integration for token storage

### Phase 2: Create Native Mode (native-macos-setup)
**Priority**: 🟡 Medium
**Timeline**: Next sprint

Tasks:
1. Create `native-macos-setup/` directory structure
2. Write `setup.sh` master script
3. Implement security hardening:
   - Application Firewall configuration
   - pf rules for localhost-only binding
   - File permissions lockdown
   - Keychain integration
4. Implement monitoring:
   - Process monitoring script
   - File access logging
   - Health check daemon
5. Implement backup automation:
   - Config backup to encrypted DMG
   - Session data exclusion (ephemeral)
6. Write comprehensive README
7. Add to root-level documentation

### Phase 3: Channel Integration
**Priority**: 🟡 Medium
**Timeline**: v1.5 or v2

Tasks:
1. Add **Phase 9** to openclaw-vm-setup: Channel Setup
   - WhatsApp QR code workflow (interactive)
   - Telegram bot token configuration
   - Discord application setup
   - Slack workspace integration
   - iMessage/BlueBubbles (VM only)
2. Update configuration templates
3. Add channel-specific firewall rules
4. Document per-channel security considerations

### Phase 4: Tailscale Automation
**Priority**: 🟢 Low
**Timeline**: v2

Tasks:
1. Add **Phase 10** to openclaw-vm-setup: Remote Access
2. Automate Tailscale installation
3. Configure MagicDNS
4. Generate invite links for team members
5. Document multi-device access patterns

---

## Configuration File Enhancements

### Current: openclaw-vm-setup/config/settings.env
```bash
VM_NAME="openclaw-vm"
VM_MEMORY="4G"
VM_CPUS="2"
VM_DISK="20G"
GATEWAY_PORT="18789"
```

### Proposed: Add Gateway Configuration
```bash
# Existing VM settings...
VM_NAME="openclaw-vm"
VM_MEMORY="4G"
VM_CPUS="2"
VM_DISK="20G"

# Gateway settings
GATEWAY_PORT="18789"
GATEWAY_BIND="127.0.0.1"  # localhost-only
GATEWAY_MODE="production"

# AI Model settings (encrypted)
ANTHROPIC_API_KEY_ENCRYPTED="age1..."
OPENAI_API_KEY_ENCRYPTED="age1..."

# Channel settings
ENABLE_WHATSAPP="false"
ENABLE_TELEGRAM="false"
ENABLE_DISCORD="false"
ENABLE_SLACK="false"
ENABLE_IMESSAGE="false"

# Security settings
ENABLE_EXEC_APPROVALS="true"
ENABLE_MONITORING="true"
ENABLE_BACKUPS="true"
BACKUP_RETENTION_DAYS="30"

# Remote access
ENABLE_TAILSCALE="false"
TAILSCALE_AUTH_KEY=""  # Optional pre-auth key
```

### New: native-macos-setup/config/settings.env
```bash
# Gateway settings
GATEWAY_PORT="18789"
GATEWAY_BIND="127.0.0.1"  # localhost-only, no LAN
GATEWAY_MODE="production"

# AI Model settings
USE_KEYCHAIN="true"  # Store API keys in macOS Keychain
ANTHROPIC_API_KEY=""  # Leave blank, will prompt for keychain
OPENAI_API_KEY=""     # Leave blank, will prompt for keychain

# Security settings
ENABLE_APP_FIREWALL="true"
ENABLE_PF_RULES="true"
ENABLE_EXEC_APPROVALS="true"
ENABLE_MONITORING="true"
ENABLE_BACKUPS="true"
BACKUP_LOCATION="~/Documents/Clawdbot-Backups"
BACKUP_ENCRYPTION="true"

# Workspace
WORKSPACE_DIR="~/clawd"
CONFIG_DIR="~/.clawdbot"

# Remote access
ENABLE_TAILSCALE="false"
```

---

## Documentation Updates Needed

### 1. Update DOCUMENTATION/clawdbot-customer-setup-guide.md
Add security hardening sections:
- **Option A Enhancement**: Add "Security Hardening for macOS Native" section
- **Option F Enhancement**: Add "VM Security Hardening" section
- Cross-reference to `openclaw-vm-setup/` and `native-macos-setup/`

### 2. Update DOCUMENTATION/clawdbot-deployment-guide.md
Add security sections:
- "Security Best Practices" section
- "Hardening Checklist" for each platform
- "Threat Model" document
- "Incident Response Playbook"

### 3. Create New Security Documentation
- `DOCUMENTATION/security-hardening-guide.md`
  - VM isolation security
  - Native macOS security
  - Secrets management
  - Monitoring and alerting
  - Backup and recovery
  - Incident response

### 4. Update Root-Level README.md
Add navigation to:
- `openclaw-vm-setup/` (VM deployment)
- `native-macos-setup/` (Native deployment)
- Security hardening guides
- Quick start for each method

---

## Testing Requirements

### VM Mode Testing (openclaw-vm-setup)
- [ ] Fresh macOS Sequoia installation on M4 Mac Mini
- [ ] All phases complete without errors
- [ ] Gateway starts and responds to health checks
- [ ] Firewall rules prevent external access
- [ ] SSH connection works with Ed25519 key
- [ ] Monitoring detects simulated attacks
- [ ] Backup and restore work correctly
- [ ] exec-approvals block unauthorized commands
- [ ] Secrets are encrypted at rest

### Native Mode Testing (native-macos-setup)
- [ ] Fresh macOS Sequoia installation
- [ ] Application Firewall blocks external access
- [ ] pf rules restrict to localhost
- [ ] Keychain stores API keys securely
- [ ] Monitoring detects file access anomalies
- [ ] Backup creates encrypted DMG
- [ ] exec-approvals deny-by-default works
- [ ] Gateway cannot access files outside workspace

### Security Testing (Both Modes)
- [ ] Penetration testing from external network
- [ ] Privilege escalation attempts fail
- [ ] Data exfiltration attempts detected
- [ ] Resource exhaustion attacks handled
- [ ] Secrets never leaked in logs
- [ ] Audit trail is tamper-proof

---

## Success Criteria

### VM Mode (openclaw-vm-setup)
✅ Milestone 2 complete when:
- All Phase 0-8 implemented and tested
- Gateway installs and runs automatically
- Security hardening applied by default
- Monitoring and backups operational
- Documentation accurate and complete

### Native Mode (native-macos-setup)
✅ New milestone complete when:
- One-command setup works end-to-end
- Security hardening matches VM mode (where applicable)
- Keychain integration working
- Monitoring and backups operational
- Documentation covers all use cases

### Documentation
✅ Complete when:
- Customer setup guide includes security hardening
- Deployment guide has threat model section
- New security-hardening-guide.md created
- All guides tested by non-technical user

---

## Next Actions

### Immediate (This Sprint)
1. ✅ Review and approve this integration analysis
2. 🔴 Complete openclaw-vm-setup Phase 0-8 base implementation
3. 🔴 Enhance Phase 4 with Clawdbot onboard integration
4. 🔴 Add secrets encryption to Phase 4
5. 🟡 Document security hardening in customer guide

### Short-term (Next Sprint)
1. 🟡 Create `native-macos-setup/` directory
2. 🟡 Implement native mode security hardening
3. 🟡 Write native mode documentation
4. 🟡 Test both modes on clean installations

### Long-term (v2)
1. 🟢 Add channel integration (Phase 9)
2. 🟢 Add Tailscale automation (Phase 10)
3. 🟢 Create comprehensive security audit
4. 🟢 Video tutorials for both modes

---

## Questions for Review

1. **Priority**: Should we finish VM mode completely before starting native mode, or work on both in parallel?
   - Recommendation: Finish VM mode first (Milestone 2), then native mode (new Milestone 3)

2. **Secrets Management**: Use age/gpg encryption or macOS Keychain?
   - Recommendation: Keychain for native mode, age for VM mode (cross-platform)

3. **Channel Integration**: Include in v1 or defer to v2?
   - Recommendation: Defer to v1.5 or v2 (adds complexity, delays MVP)

4. **Testing**: Require security audit before v1 release?
   - Recommendation: Yes, basic penetration testing at minimum

5. **Documentation**: Separate security guide or integrate into existing docs?
   - Recommendation: Both - dedicated guide + inline security sections

---

*This analysis should be reviewed with the team before implementation begins.*
