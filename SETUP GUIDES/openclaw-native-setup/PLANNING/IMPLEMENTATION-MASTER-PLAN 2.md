# OpenClaw Native macOS Setup - Implementation Master Plan

## Executive Summary

Automated deployment toolkit for running OpenClaw Gateway directly on macOS (without virtualization) using user account isolation and deny-by-default security model.

**Status**: Implementation complete
**Created**: 2026-01-30
**Version**: v1.0

## Architecture Overview

### Security Model: User Account Isolation

```
┌─────────────────────────────────────────────────────────────┐
│ Host macOS System (Admin User)                              │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ openclaw User Account (UID 502, Minimal Privileges)    │ │
│  │                                                         │ │
│  │  /Users/openclaw/.openclaw/                            │ │
│  │  ├── gateway/  (OpenClaw Gateway binary)               │ │
│  │  ├── data/     (Gateway storage)                       │ │
│  │  ├── logs/     (Runtime logs)                          │ │
│  │  └── exec-approvals.json (deny-by-default, root-owned) │ │
│  │                                                         │ │
│  │  LaunchAgent (ai.openclaw.gateway.plist)               │ │
│  │  - Auto-start on boot                                  │ │
│  │  - Keep alive (restart on crash)                       │ │
│  │  - Protected from modification (root-owned)            │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Helper Scripts (admin access required):                    │
│  - connect.sh: Login to openclaw user                       │
│  - status.sh: Health checks                                 │
│  - emergency-stop.sh: Kill switch                           │
│  - restart.sh: Recovery restart                             │
│  - monitor.sh: Real-time monitoring                         │
└─────────────────────────────────────────────────────────────┘
```

### Defense-in-Depth Layers

1. **User Account Isolation**: Gateway runs as dedicated `openclaw` user with minimal privileges
2. **exec-approvals.json**: Deny-by-default command execution (root-owned, read-only)
3. **LaunchAgent Protection**: Auto-start configuration protected from tampering (root-owned)
4. **File Permissions**: Restrictive permissions on Gateway binary and data directories
5. **Monitoring**: Real-time health checks and security auditing
6. **Emergency Stop**: Kill switch to immediately halt compromised Gateway

## Implementation Phases

### Phase 0: Prerequisites Validation
**Purpose**: Verify system requirements before deployment

**Checks**:
- macOS Sequoia+ on Apple Silicon
- Admin sudo access
- Homebrew installed
- Node.js available (if required by Gateway)
- Sufficient disk space (>10GB)
- No existing `openclaw` user or UID conflict

**Outputs**:
- Validated environment
- Log directory created
- Configuration loaded

---

### Phase 1: User Account Creation
**Purpose**: Create isolated user account for Gateway

**Actions**:
1. Generate secure 24-character password
2. Create `openclaw` user account via `dscl`:
   - UID: 502 (configurable)
   - Home: /Users/openclaw
   - Shell: /bin/bash
   - Group: staff (GID 20)
3. Create directory structure:
   ```
   /Users/openclaw/
   ├── .openclaw/
   │   ├── gateway/  (700, openclaw:staff)
   │   ├── data/     (700, openclaw:staff)
   │   └── logs/     (700, openclaw:staff)
   └── Library/LaunchAgents/
   ```
4. Set restrictive permissions (700 on all directories)

**Security**:
- Password stored in secured backup file (600 permissions)
- Backup existing user if present
- User account isolated from host system

**Verification**:
- User account exists (`id openclaw`)
- Password works for login
- Directory structure correct
- Permissions properly set

---

### Phase 2: exec-approvals Configuration
**Purpose**: Install deny-by-default command execution policy

**Actions**:
1. Copy `exec-approvals.json` to `/Users/openclaw/.openclaw/`
2. Set ownership: `root:wheel` (prevents tampering by Gateway)
3. Set permissions: `444` (read-only for all)

**Security Rationale**:
- Gateway can read but cannot modify allowlist
- Root ownership prevents privilege escalation
- Deny-by-default protects against zero-day exploits

**Verification**:
- File exists at correct path
- Owner is root:wheel
- Permissions are 444
- Gateway user can read file

---

### Phase 3: LaunchAgent Setup
**Purpose**: Configure automatic Gateway startup

**Actions**:
1. Create LaunchAgent plist from template:
   - Label: `ai.openclaw.gateway`
   - Program: `/Users/openclaw/.openclaw/gateway/openclaw-gateway`
   - RunAtLoad: true (start on boot)
   - KeepAlive: true (restart on crash)
   - Environment variables:
     - `EXEC_APPROVALS_PATH`
     - `OPENCLAW_CONFIG_DIR`
     - `OPENCLAW_DATA_DIR`
     - `OPENCLAW_LOG_DIR`
2. Install to `/Users/openclaw/Library/LaunchAgents/`
3. Set ownership: `root:wheel`
4. Set permissions: `444`
5. Validate plist syntax (`plutil -lint`)

**Security**:
- Protected from modification by Gateway user
- Resource limits enforced
- Exit timeout prevents zombie processes

**Note**: LaunchAgent loaded in Phase 4 after Gateway installation

---

### Phase 4: Gateway Installation
**Purpose**: Install OpenClaw Gateway binary

**Actions**:
1. Download Gateway binary (if URL provided)
2. Install to `/Users/openclaw/.openclaw/gateway/openclaw-gateway`
3. Set ownership: `openclaw:staff`
4. Set permissions: `500` (read/execute for owner only)
5. Create Gateway configuration file
6. Load LaunchAgent: `launchctl bootstrap gui/$(id -u openclaw) <plist>`

**Current Status**: Manual installation (Gateway not yet publicly available)

**Manual Steps**:
1. Obtain Gateway binary
2. Copy to installation directory
3. Set correct ownership and permissions
4. Load LaunchAgent to start Gateway

**Verification**:
- Binary exists and is executable
- Gateway process running under `openclaw` user
- LaunchAgent loaded successfully
- Process responds to health checks

---

### Phase 5: Monitoring Setup
**Purpose**: Configure health monitoring and alerting

**Actions**:
1. Create monitoring configuration file
2. Configure log rotation (max size: 100MB by default)
3. Set log retention (30 days by default)
4. Configure alert thresholds:
   - CPU: 80%
   - Memory: 1024MB

**Monitoring Checks**:
- Gateway process status
- Resource usage (CPU, memory)
- Log file sizes
- exec-approvals.json integrity (hash verification)
- Error rates in logs

**Alerts**: Currently log-based (webhook/email support planned for v2)

---

### Phase 6: Helper Scripts & Documentation
**Purpose**: Provide operational tools and documentation

**Helper Scripts**:
1. **connect.sh**: Switch to openclaw user for debugging
2. **status.sh**: Comprehensive health check
3. **emergency-stop.sh**: Kill switch for compromised Gateway
4. **restart.sh**: Graceful restart with force-kill fallback
5. **monitor.sh**: Real-time monitoring (manual or daemon mode)

**Documentation**:
- README.md: Quick start guide
- This file: Architecture and implementation details
- Phase prompts: Step-by-step execution guides

---

## File Inventory

### Configuration Files
| File | Purpose | Owner | Permissions |
|------|---------|-------|-------------|
| `config/settings.env` | User-customizable settings | admin | 644 |
| `config/exec-approvals.json` | Command allowlist template | admin | 644 |
| `config/launchagent-template.plist` | LaunchAgent template | admin | 644 |
| `/Users/openclaw/.openclaw/exec-approvals.json` | Runtime allowlist | root:wheel | 444 |
| `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist` | Runtime plist | root:wheel | 444 |

### Scripts
| Script | Purpose | Requires Sudo |
|--------|---------|---------------|
| `setup.sh` | Master orchestrator | Yes |
| `scripts/connect.sh` | Login to openclaw user | Yes |
| `scripts/status.sh` | Health check | Yes (for process info) |
| `scripts/emergency-stop.sh` | Kill switch | Yes |
| `scripts/restart.sh` | Restart Gateway | Yes |
| `scripts/monitor.sh` | Monitoring | No (read-only) |

### Logs
| Log File | Purpose | Rotation |
|----------|---------|----------|
| `logs/setup-*.log` | Setup execution logs | Manual |
| `/Users/openclaw/.openclaw/logs/gateway.log` | Gateway stdout | 100MB |
| `/Users/openclaw/.openclaw/logs/gateway.error.log` | Gateway stderr | 100MB |
| `/Users/openclaw/.openclaw/logs/monitor.log` | Monitoring logs | 100MB |

---

## Key Differences from VM Setup

| Aspect | VM Setup (openclaw-vm-setup) | Native Setup (openclaw-native-setup) |
|--------|------------------------------|--------------------------------------|
| **Isolation** | Full VM boundary | User account isolation |
| **Threat Model** | External network attacks | Compromised agent attacks |
| **Phase Count** | 8 phases | 6 phases |
| **Dependencies** | Lume hypervisor, SSH hardening | dscl, launchctl |
| **Snapshots** | Lume VM snapshots | Config backups only |
| **Recovery** | Rollback VM | Recreate user account |
| **Performance** | Virtualized (slight overhead) | Native (full hardware access) |
| **Setup Time** | 30-45 minutes | 10-15 minutes |
| **Best For** | Production, multi-tenant | Development, testing |

---

## Security Considerations

### Threat Model
**Primary Threat**: Compromised AI agent attempting to:
- Execute unauthorized commands
- Modify security configurations
- Access sensitive host files
- Escalate privileges
- Persist across restarts

### Mitigations
1. **exec-approvals.json**: Deny-by-default command execution
2. **Root-owned configs**: Prevents modification by Gateway user
3. **User account isolation**: Limited access to host system
4. **Monitoring**: Detects anomalous behavior
5. **Emergency stop**: Immediate shutdown capability

### Manual Steps (Cannot Be Automated)
macOS security requires user interaction for:
1. **TCC Permissions**: Security & Privacy > Privacy > Automation
2. **Accessibility**: If Gateway needs UI control
3. **Full Disk Access**: If Gateway needs broad file system access

**Solution**: Documentation in README.md with verification script

---

## Testing Strategy

### Automated Tests
- [x] Prerequisites validation
- [x] User account creation
- [x] Directory structure and permissions
- [x] exec-approvals installation
- [x] LaunchAgent syntax validation
- [ ] Gateway binary installation (pending Gateway availability)
- [ ] End-to-end setup on clean macOS

### Manual Validation
- [ ] Test on M1 Mac mini (user's target hardware)
- [ ] Verify Gateway startup and operation
- [ ] Test emergency stop and restart procedures
- [ ] Validate monitoring alerts
- [ ] Confirm exec-approvals denies unauthorized commands

### Success Criteria
- [ ] setup.sh completes without errors
- [ ] Gateway runs under `openclaw` user
- [ ] exec-approvals enforced (deny-by-default works)
- [ ] All helper scripts functional
- [ ] Monitoring detects issues
- [ ] Emergency stop kills Gateway immediately
- [ ] User can deploy in <20 minutes

---

## Future Enhancements (v2)

1. **Interactive Setup Wizard**: GUI-based configuration
2. **Automated Testing Framework**: Integration and security tests
3. **Cloud Monitoring Integration**: Webhook/email alerts
4. **Multi-user Support**: Multiple Gateway instances
5. **Migration Tool**: Convert between native and VM deployments
6. **Auto-update**: Automatic Gateway binary updates
7. **TCC Permission Automation**: Use MDM profiles for enterprise

---

## Troubleshooting

### Common Issues

**User account creation fails**
- Check UID availability: `dscl . -list /Users UniqueID`
- Verify sudo access: `sudo -v`

**LaunchAgent won't load**
- Validate plist syntax: `plutil -lint <plist>`
- Check ownership: `ls -l <plist>` (should be root:wheel)
- Check user ID: `id -u openclaw`

**Gateway doesn't start**
- Verify binary exists: `ls -l /Users/openclaw/.openclaw/gateway/`
- Check permissions: Should be 500, owned by openclaw:staff
- View error log: `tail -f /Users/openclaw/.openclaw/logs/gateway.error.log`

**exec-approvals not enforced**
- Verify file exists: `ls -l /Users/openclaw/.openclaw/exec-approvals.json`
- Check ownership: Should be root:wheel
- Check permissions: Should be 444
- Verify Gateway reads it: Check EXEC_APPROVALS_PATH environment variable

---

## Maintenance

### Regular Tasks
- **Daily**: Check status with `status.sh`
- **Weekly**: Review monitoring logs
- **Monthly**: Verify security configurations
- **Quarterly**: Test emergency stop procedure

### Backup Strategy
- Password file: `backups/.openclaw-password-*.txt`
- exec-approvals.json: Version controlled in git
- Gateway configuration: Manual backup recommended
- User home directory: Time Machine or manual tar.gz

---

## References

- Native macOS Lockdown Guide: `/openclaw-native-macos-lockdown-guide.md`
- VM Security Hardening Guide: `/openclaw-macos-vm-security-hardening-guide.md`
- Customer Setup Guide: `/clawdbot-customer-setup-guide.md`
- macOS `dscl` documentation: `man dscl`
- macOS `launchctl` documentation: `man launchctl`
- TCC Database: `/Library/Application Support/com.apple.TCC/`

---

**Document Version**: 1.0
**Last Updated**: 2026-01-30
**Maintained By**: Organized AI Team
