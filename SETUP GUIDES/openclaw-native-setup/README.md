# OpenClaw Native macOS Setup

Automated deployment toolkit for running OpenClaw Gateway directly on macOS (without virtualization) using user account isolation and deny-by-default security.

## Quick Start

```bash
# 1. Review configuration
cat config/settings.env

# 2. Run automated setup (requires sudo)
./setup.sh all

# 3. Check status
./scripts/status.sh

# 4. View logs
tail -f /Users/openclaw/.openclaw/logs/gateway.log
```

**Setup time**: 10-15 minutes (excluding Gateway binary installation)

---

## Overview

This toolkit automates the secure deployment of OpenClaw Gateway on macOS using:
- **User Account Isolation**: Dedicated `openclaw` user with minimal privileges
- **Deny-by-Default Security**: exec-approvals.json prevents unauthorized command execution
- **Protected Configuration**: Root-owned files prevent tampering
- **Auto-Start**: LaunchAgent ensures Gateway runs on boot
- **Monitoring**: Real-time health checks and alerting

---

## Prerequisites

### Hardware
- **Mac**: Apple Silicon (M1/M2/M3/M4)
- **Disk**: Minimum 10GB available space
- **Network**: Internet connection for downloads

### Software
- **macOS**: Sequoia (14.0+) or later
- **Homebrew**: Package manager ([install](https://brew.sh))
- **Node.js**: Recommended (install with: `brew install node`)
- **Sudo Access**: Admin account privileges

### Verify Prerequisites
```bash
# Check macOS version
sw_vers -productVersion

# Verify Apple Silicon
uname -m  # Should show: arm64

# Check Homebrew
which brew

# Check available disk space
df -h /
```

---

## Installation

### Option 1: Automated Setup (Recommended)

```bash
# Run all phases automatically
./setup.sh all
```

This will:
1. ✅ Validate prerequisites
2. ✅ Create `openclaw` user account
3. ✅ Configure exec-approvals.json
4. ✅ Set up LaunchAgent
5. ⚠️  Document Gateway installation (manual step)
6. ✅ Configure monitoring

### Option 2: Step-by-Step Setup

Run phases individually:

```bash
./setup.sh 0  # Prerequisites validation
./setup.sh 1  # User account creation
./setup.sh 2  # exec-approvals configuration
./setup.sh 3  # LaunchAgent setup
./setup.sh 4  # Gateway installation (manual)
./setup.sh 5  # Monitoring setup
./setup.sh 6  # Helper scripts
```

---

## Gateway Installation (Phase 4)

**Status**: Manual installation required (Gateway not yet publicly available)

### Steps:

1. **Obtain Gateway Binary**
   - Download from official release (when available)
   - Or build from source

2. **Install Binary**
   ```bash
   # Copy to installation directory
   sudo cp openclaw-gateway /Users/openclaw/.openclaw/gateway/

   # Set ownership
   sudo chown openclaw:staff /Users/openclaw/.openclaw/gateway/openclaw-gateway

   # Set permissions (execute-only for owner)
   sudo chmod 500 /Users/openclaw/.openclaw/gateway/openclaw-gateway
   ```

3. **Load LaunchAgent**
   ```bash
   # Start Gateway automatically
   sudo launchctl bootstrap gui/$(id -u openclaw) \
       /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist
   ```

4. **Verify Running**
   ```bash
   ./scripts/status.sh
   ```

---

## Helper Scripts

### Status Check
```bash
./scripts/status.sh
```
Comprehensive health check showing:
- User account status
- Directory structure
- Security configuration
- Gateway process status
- Resource usage
- Recent logs

### Connect to openclaw User
```bash
./scripts/connect.sh
```
Login to the `openclaw` user account for debugging or manual inspection.

### Restart Gateway
```bash
./scripts/restart.sh         # Graceful restart
./scripts/restart.sh --force  # Force kill if needed
```

### Emergency Stop (Kill Switch)
```bash
./scripts/emergency-stop.sh
```
Immediately stop Gateway and prevent auto-restart. Use if Gateway is compromised.

### Real-Time Monitoring
```bash
./scripts/monitor.sh           # One-time check
./scripts/monitor.sh --daemon  # Continuous monitoring
```

Monitors:
- Process health
- Resource usage (CPU, memory)
- Log file sizes
- Security file integrity
- Error rates

---

## Manual TCC Permissions

macOS security requires manual permission grants via System Settings:

### Required Permissions

1. **Open System Settings**
   ```
   System Settings > Privacy & Security > Privacy
   ```

2. **Grant Permissions**
   - **Automation**: Allow Gateway to control other apps (if needed)
   - **Accessibility**: Enable if Gateway needs UI control
   - **Full Disk Access**: Enable if Gateway needs broad file access

3. **Verify Permissions**
   ```bash
   # Check TCC database (requires sudo)
   sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
       "SELECT service, client FROM access WHERE client LIKE '%openclaw%'"
   ```

**Note**: These permissions cannot be automated and must be granted via the UI.

---

## Configuration

### settings.env

Customize deployment before running setup:

```bash
# Edit configuration
nano config/settings.env
```

**Key Settings**:
- `OPENCLAW_USER`: Username (default: `openclaw`)
- `OPENCLAW_UID`: User ID (default: `502`)
- `GATEWAY_INSTALL_DIR`: Binary location
- `MONITOR_INTERVAL`: Monitoring frequency (seconds)
- `LOG_MAX_SIZE_MB`: Log rotation threshold
- `CPU_ALERT_THRESHOLD`: CPU usage alert (%)
- `MEMORY_ALERT_THRESHOLD`: Memory usage alert (MB)

### exec-approvals.json

Deny-by-default command allowlist:

```json
{
  "approvals": {
    "allowed_commands": [
      "/usr/bin/curl",
      "/usr/bin/git",
      "...additional allowed commands..."
    ]
  }
}
```

**Security**: This file is protected (root-owned, read-only) to prevent tampering by the Gateway.

---

## Comparison: Native vs VM Deployment

| Feature | Native (This Tool) | VM (`openclaw-vm-setup`) |
|---------|-------------------|--------------------------|
| **Isolation** | User account | Full VM boundary |
| **Performance** | Native speed | Slight overhead |
| **Setup Time** | 10-15 min | 30-45 min |
| **Snapshots** | Config backups only | Full VM snapshots |
| **Recovery** | Recreate user | Rollback VM |
| **Best For** | Development, testing | Production, multi-tenant |
| **iMessage** | ✅ Yes | ✅ Yes |
| **Security** | Strong | Maximum |

**Choose Native If**:
- Running on M1 Mac mini for development
- Need fastest performance
- Single-user deployment
- Easier troubleshooting preferred

**Choose VM If**:
- Production environment
- Maximum isolation required
- Multi-tenant deployment
- Need snapshot/rollback capability

---

## Troubleshooting

### User Account Issues

**Problem**: User creation fails
```bash
# Check if user already exists
id openclaw

# Check UID availability
dscl . -list /Users UniqueID | grep 502

# Solution: Delete existing user or choose different UID
sudo dscl . -delete /Users/openclaw
# OR: Edit config/settings.env and change OPENCLAW_UID
```

### LaunchAgent Issues

**Problem**: LaunchAgent won't load
```bash
# Validate plist syntax
plutil -lint /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist

# Check ownership and permissions
ls -l /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist
# Should be: root:wheel, 444

# View launchctl errors
sudo launchctl print gui/$(id -u openclaw)/ai.openclaw.gateway
```

**Problem**: Gateway doesn't start
```bash
# Check binary exists
ls -l /Users/openclaw/.openclaw/gateway/openclaw-gateway

# Verify permissions (should be 500, openclaw:staff)
stat -f '%Lp %Su:%Sg' /Users/openclaw/.openclaw/gateway/openclaw-gateway

# View error logs
tail -f /Users/openclaw/.openclaw/logs/gateway.error.log
```

### Security Issues

**Problem**: exec-approvals.json not enforced
```bash
# Verify file exists
ls -l /Users/openclaw/.openclaw/exec-approvals.json

# Check ownership (should be root:wheel)
stat -f '%Su:%Sg' /Users/openclaw/.openclaw/exec-approvals.json

# Verify permissions (should be 444)
stat -f '%Lp' /Users/openclaw/.openclaw/exec-approvals.json

# Reinstall if needed
sudo cp config/exec-approvals.json /Users/openclaw/.openclaw/
sudo chown root:wheel /Users/openclaw/.openclaw/exec-approvals.json
sudo chmod 444 /Users/openclaw/.openclaw/exec-approvals.json
```

### Monitoring Issues

**Problem**: Monitoring not working
```bash
# Run monitor manually
./scripts/monitor.sh

# Check monitor log
tail -f /Users/openclaw/.openclaw/logs/monitor.log

# Verify configuration
cat /Users/openclaw/.openclaw/monitor.conf
```

---

## Logs

### Location
- **Setup logs**: `logs/setup-YYYYMMDD_HHMMSS.log`
- **Gateway stdout**: `/Users/openclaw/.openclaw/logs/gateway.log`
- **Gateway stderr**: `/Users/openclaw/.openclaw/logs/gateway.error.log`
- **Monitoring**: `/Users/openclaw/.openclaw/logs/monitor.log`

### Viewing Logs
```bash
# Gateway output
tail -f /Users/openclaw/.openclaw/logs/gateway.log

# Errors only
tail -f /Users/openclaw/.openclaw/logs/gateway.error.log

# Monitoring events
tail -f /Users/openclaw/.openclaw/logs/monitor.log

# Setup execution
tail logs/setup-*.log
```

### Log Rotation
- **Automatic**: When log exceeds `LOG_MAX_SIZE_MB` (default: 100MB)
- **Retention**: `LOG_RETENTION_DAYS` (default: 30 days)
- **Manual**: Run `./scripts/monitor.sh` to trigger rotation checks

---

## Backup & Recovery

### Password Backup
```bash
# Password stored securely in:
backups/.openclaw-password-YYYYMMDD_HHMMSS.txt

# View password (admin only)
cat backups/.openclaw-password-*.txt
```

### Configuration Backup
```bash
# Backup user account before changes
tar -czf backups/openclaw-backup-$(date +%Y%m%d).tar.gz \
    -C /Users openclaw

# Restore from backup
sudo tar -xzf backups/openclaw-backup-YYYYMMDD.tar.gz \
    -C /Users
```

### Disaster Recovery
```bash
# 1. Emergency stop
./scripts/emergency-stop.sh

# 2. Backup data
tar -czf gateway-data-backup.tar.gz \
    /Users/openclaw/.openclaw/data/

# 3. Remove compromised account
sudo dscl . -delete /Users/openclaw
sudo rm -rf /Users/openclaw

# 4. Re-run setup
./setup.sh all

# 5. Restore data
tar -xzf gateway-data-backup.tar.gz -C /
```

---

## Uninstallation

```bash
# 1. Stop Gateway
./scripts/emergency-stop.sh

# 2. Remove user account
sudo dscl . -delete /Users/openclaw

# 3. Remove home directory
sudo rm -rf /Users/openclaw

# 4. Clean up backups (optional)
rm -rf backups/

# 5. Clean up logs (optional)
rm -rf logs/
```

---

## Documentation

- **Implementation Plan**: [PLANNING/IMPLEMENTATION-MASTER-PLAN.md](PLANNING/IMPLEMENTATION-MASTER-PLAN.md)
- **Phase Prompts**: [PLANNING/implementation-phases/](PLANNING/implementation-phases/)
- **Security Guide**: [../openclaw-native-macos-lockdown-guide.md](../openclaw-native-macos-lockdown-guide.md)
- **Root README**: [../README.md](../README.md)

---

## Need Help? Use the Setup Agent

If you prefer guided assistance, the **Clawdbot Setup Agent** can walk you through this entire process via phone or chat — no terminal experience required.

The agent connects to your Mac via temporary SSH credentials (auto-expiring in 2 hours) and runs all setup phases autonomously. It detects errors, applies fixes, and keeps you updated with friendly progress messages.

See [`../clawdbot-setup-agent/`](../clawdbot-setup-agent/) for details, or tell your Clawdbot: *"I want to set up a native macOS deployment"*.

---

## Support

- **Issues**: https://github.com/Organized-AI/claudebotready/issues
- **Documentation**: See `PLANNING/` directory
- **Community**: Organized AI ecosystem

---

## Security Notice

This toolkit implements defense-in-depth security but relies on the integrity of the host macOS system. For maximum isolation, consider using the VM-based deployment ([`openclaw-vm-setup/`](../openclaw-vm-setup/)).

**Security Features**:
- ✅ User account isolation
- ✅ Deny-by-default command execution
- ✅ Protected configuration files
- ✅ Real-time monitoring
- ✅ Emergency stop capability

**Limitations**:
- ⚠️ Shares host kernel (no VM boundary)
- ⚠️ TCC permissions require manual grant
- ⚠️ No snapshot/rollback (use backups)

---

## License

Part of the [Organized AI](https://github.com/Organized-AI) ecosystem.

**Version**: 1.0.0
**Last Updated**: 2026-01-30
**Platform**: macOS Sequoia+ on Apple Silicon
