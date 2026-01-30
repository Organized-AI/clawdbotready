# OpenClaw macOS VM Security Setup

Automated setup scripts for deploying OpenClaw in a hardened macOS VM on Apple Silicon.

## Overview

This toolkit automates the secure deployment of OpenClaw in an isolated macOS VM using [Lume](https://lume.dev). The VM provides complete isolation from your host system, protecting against agent-based attacks.

**Target:** M4 Mac Mini (or any Apple Silicon Mac)
**Requirements:**
- macOS Sequoia or later
- Apple Silicon (M1/M2/M3/M4)
- ~70GB disk space
- ~30 minutes for full setup

## Quick Start

```bash
# 1. Clone or download this folder to your Mac

# 2. Make scripts executable
chmod +x setup.sh scripts/*.sh

# 3. Run full setup
./setup.sh all
```

## What It Does

The setup process runs through 6 phases:

| Phase | Description |
|-------|-------------|
| 1 | Install Lume hypervisor and create macOS VM |
| 2 | Harden SSH (key-only auth, strong algorithms) |
| 3 | Configure host firewall (pf rules) |
| 4 | Install and secure OpenClaw Gateway |
| 5 | Set up monitoring and alerting |
| 6 | Configure automated backups |

## Directory Structure

```
openclaw-vm-setup/
├── setup.sh                    # Master orchestration script
├── config/
│   ├── settings.env            # Customize VM settings here
│   └── exec-approvals.json     # Command allowlist (security)
├── scripts/
│   ├── connect.sh              # SSH into VM
│   ├── tunnel.sh               # Create Gateway tunnel
│   ├── status.sh               # Check VM status
│   ├── backup-vm.sh            # Backup VM and configs
│   ├── restore-vm.sh           # Restore from snapshot
│   ├── emergency-stop.sh       # EMERGENCY: Kill VM immediately
│   └── restart-vm.sh           # Restart after emergency stop
├── logs/                       # Setup and monitoring logs
├── backups/                    # Config backups stored here
└── README.md                   # This file
```

## Configuration

Edit `config/settings.env` before running setup:

```bash
VM_NAME="openclaw-secure"       # VM name
VM_CPU="4"                      # CPU cores for VM
VM_MEMORY="8192"                # RAM in MB
VM_DISK="60G"                   # Disk size
VM_USER="openclaw"              # VM user account
```

## Usage

### Initial Setup

```bash
# Run all phases
./setup.sh all

# Or run phases individually
./setup.sh 1    # Install Lume + create VM
./setup.sh 2    # SSH hardening
./setup.sh 3    # Host firewall
./setup.sh 4    # Gateway config
./setup.sh 5    # Monitoring
./setup.sh 6    # Backups
```

### Daily Operations

```bash
# Check VM status
./scripts/status.sh

# Connect to VM via SSH
./scripts/connect.sh

# Create tunnel to access Gateway
./scripts/tunnel.sh
# Then access: https://localhost:8080

# Backup VM
./scripts/backup-vm.sh
```

### Emergency Procedures

```bash
# If agent is compromised or misbehaving:
./scripts/emergency-stop.sh

# After investigation, to restart:
./scripts/restart-vm.sh

# Restore from backup:
./scripts/restore-vm.sh
```

## Security Features

### VM Isolation
- Complete process isolation from host
- Separate Apple ID (burner recommended)
- Isolated network stack
- Easy snapshot/restore for recovery

### SSH Hardening
- Ed25519 keys only (no passwords)
- Limited auth attempts (3 max)
- Session timeouts
- Restricted to single user

### Gateway Security
- Binds to localhost only
- Access via SSH tunnel only
- TLS encryption
- Token authentication
- Rate limiting

### Command Restrictions
- Deny-by-default exec-approvals
- Explicit allowlist for safe commands
- Blocked: curl, wget, ssh, osascript, security, etc.
- All command attempts logged

### Monitoring
- Automated security checks every 5 minutes
- SSH failure monitoring
- Suspicious process detection
- Disk space alerts

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    INTERNET                               │
└─────────────────────────┬────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│                M4 MAC MINI (HOST)                         │
│  ┌────────────────────────────────────────────────────┐  │
│  │  pf Firewall: Block direct VM access               │  │
│  │  Only allow: localhost → VM:22, localhost → VM:8080│  │
│  └────────────────────────────────────────────────────┘  │
│                          │                                │
│                          ▼                                │
│  ┌────────────────────────────────────────────────────┐  │
│  │           SANDBOXED macOS VM (Lume)                │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │  OpenClaw Gateway (localhost:8080)           │  │  │
│  │  │  - TLS + Token Auth                          │  │  │
│  │  │  - exec-approvals (deny by default)          │  │  │
│  │  │  - Monitoring daemon                         │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
                          │
                          │ SSH Tunnel
                          ▼
              ┌─────────────────────┐
              │  Your Application   │
              │  localhost:8080     │
              └─────────────────────┘
```

## Credentials & Secrets

After setup, important files are stored:

| File | Contents |
|------|----------|
| `~/.ssh/openclaw_vm_ed25519` | SSH private key |
| `.vm_ip` | VM IP address |
| `.gateway_token` | Gateway auth token |

**Keep these secure!** The SSH key provides full access to the VM.

## Backup Schedule

By default, backups run automatically:
- Config backup: Daily at 2 AM
- VM snapshots: Created with each backup
- Retention: 7 days

Modify in `config/settings.env`:
```bash
BACKUP_RETENTION_DAYS="7"
BACKUP_SCHEDULE="0 2 * * *"
```

## Troubleshooting

### VM won't start
```bash
# Check Lume status
lume list

# Try stopping and restarting
lume stop openclaw-secure
lume run openclaw-secure
```

### Can't SSH to VM
```bash
# Verify VM IP
lume get openclaw-secure

# Test connectivity
ping <VM_IP>
nc -z <VM_IP> 22

# Check SSH key permissions
ls -la ~/.ssh/openclaw_vm_ed25519
# Should be: -rw------- (600)
```

### Gateway not accessible
```bash
# Ensure tunnel is running
./scripts/tunnel.sh

# Check Gateway is running in VM
./scripts/connect.sh
ps aux | grep OpenClaw
tail -f ~/.openclaw/logs/gateway.log
```

### High resource usage
```bash
# Check VM resources
./scripts/status.sh

# Adjust in settings.env and recreate VM
VM_CPU="2"
VM_MEMORY="4096"
```

## Maintenance Checklist

### Daily
- [ ] Check `./scripts/status.sh`
- [ ] Review alerts in logs/

### Weekly
- [ ] Verify backups: `ls -la backups/`
- [ ] Review exec-approvals denials
- [ ] Check macOS updates in VM

### Monthly
- [ ] Rotate Gateway token
- [ ] Test restore from backup
- [ ] Review and update exec-approvals
- [ ] Check Lume for updates

## License

These scripts are provided as-is for securing OpenClaw deployments. Use at your own risk.

## Support

- OpenClaw Docs: https://docs.openclaw.ai
- Lume Docs: https://lume.dev/docs
