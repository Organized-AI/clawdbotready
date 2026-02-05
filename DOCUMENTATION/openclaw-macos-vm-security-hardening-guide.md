# OpenClaw macOS VM Security Hardening Guide

**Target Machine:** M4 Mac Mini (jordaaan)
**Threat Model:** External attacks — network intrusion, unauthorized access, supply chain
**Philosophy:** Perimeter defense with defense-in-depth layers

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Pre-Installation Security Checklist](#pre-installation-security-checklist)
3. [Lume VM Installation with Hardening](#lume-vm-installation-with-hardening)
4. [Network Security Configuration](#network-security-configuration)
5. [SSH Hardening](#ssh-hardening)
6. [Gateway Security](#gateway-security)
7. [iMessage/BlueBubbles Security](#imessagebluebubbles-security)
8. [Monitoring & Alerting](#monitoring--alerting)
9. [Backup & Recovery](#backup--recovery)
10. [Incident Response Playbook](#incident-response-playbook)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ROUTER FIREWALL                               │
│              (Block all inbound by default)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   M4 MAC MINI (HOST)                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    macOS Host                              │  │
│  │  • Lume hypervisor                                         │  │
│  │  • Host firewall (pf)                                      │  │
│  │  • No OpenClaw components                                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              SANDBOXED macOS VM                            │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  OpenClaw Gateway + Node                             │  │  │
│  │  │  BlueBubbles (iMessage)                              │  │  │
│  │  │  Isolated Apple ID                                   │  │  │
│  │  │  VM-only credentials                                 │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Principle:** The VM is the blast radius. If compromised, delete and recreate. Host remains untouched.

---

## Pre-Installation Security Checklist

Before installing anything, complete these steps on your M4 Mac Mini:

### 1. Host System Hardening

```bash
# Enable FileVault (full disk encryption)
sudo fdesetup enable

# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on

# Disable remote management services you don't need
sudo systemsetup -setremotelogin off  # Re-enable only if needed for host
sudo systemsetup -setremoteappleevents off

# Enable automatic security updates
sudo softwareupdate --schedule on
```

### 2. Create Isolated Network Profile (Optional but Recommended)

If your router supports VLANs, create a dedicated VLAN for the VM:

```
VLAN 10: Trusted devices (your main network)
VLAN 20: OpenClaw VM (isolated, no access to VLAN 10)
```

### 3. Verify Lume Source Integrity

```bash
# Download Lume installer
curl -fsSL https://lume.dev/install.sh -o install.sh

# Review the script before running
less install.sh

# Check for any suspicious URLs or commands
grep -E "(curl|wget|eval|exec)" install.sh

# Only proceed if script looks legitimate
```

---

## Lume VM Installation with Hardening

### Step 1: Install Lume

```bash
# Install Lume (after reviewing install.sh)
bash install.sh
```

### Step 2: Create VM with Minimal Resources

```bash
# Create VM with explicit resource limits
lume create openclaw-secure \
  --os macos \
  --ipsw latest \
  --cpu 4 \
  --memory 8192 \
  --disk 60G
```

### Step 3: Initial VM Setup

```bash
# Start the VM
lume run openclaw-secure

# Complete Setup Assistant with these choices:
# - Create LOCAL account only (don't sign into iCloud during setup)
# - Use a STRONG password (20+ chars, generated)
# - Enable FileVault in the VM
# - Skip all "share data with Apple" options
```

### Step 4: Get VM IP and Configure SSH

```bash
# Get VM IP address
lume get openclaw-secure

# Example output: 192.168.64.5
```

---

## Network Security Configuration

### Host-Level Firewall (pf)

Create `/etc/pf.anchors/openclaw-vm`:

```
# OpenClaw VM firewall rules
# Only allow specific ports to/from VM

# Get VM IP dynamically or set statically
vm_ip = "192.168.64.5"

# Block all by default, allow specific
block in quick on bridge100 from any to $vm_ip
pass in quick on bridge100 proto tcp from any to $vm_ip port 22
pass in quick on bridge100 proto tcp from 127.0.0.1 to $vm_ip port 8080
```

Enable the anchor in `/etc/pf.conf`:

```
anchor "openclaw-vm"
load anchor "openclaw-vm" from "/etc/pf.anchors/openclaw-vm"
```

Reload firewall:

```bash
sudo pfctl -f /etc/pf.conf
sudo pfctl -e
```

### VM-Level Firewall

Inside the VM, enable the application firewall:

```bash
# Enable firewall in VM
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Only allow signed apps
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on

# Block all incoming except SSH and Gateway
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
```

---

## SSH Hardening

### Step 1: Generate Strong SSH Keys (On Your Main Machine)

```bash
# Generate Ed25519 key (stronger than RSA)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/openclaw_vm_ed25519 -C "openclaw-vm-access"

# Set restrictive permissions
chmod 600 ~/.ssh/openclaw_vm_ed25519
chmod 644 ~/.ssh/openclaw_vm_ed25519.pub
```

### Step 2: Configure SSH on the VM

SSH into the VM and configure:

```bash
ssh user@192.168.64.5

# Add your public key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 3: Harden SSH Daemon

Edit `/etc/ssh/sshd_config` in the VM:

```bash
# Disable password authentication (keys only)
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no

# Disable root login
PermitRootLogin no

# Use only Ed25519 keys
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com,ssh-ed25519

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 2

# Timeout idle sessions
ClientAliveInterval 300
ClientAliveCountMax 2

# Restrict to specific user
AllowUsers openclaw-user

# Disable unnecessary features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no

# Log verbosely
LogLevel VERBOSE
```

Restart SSH:

```bash
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
```

---

## Gateway Security

### Step 1: Install OpenClaw in VM

```bash
# SSH into VM
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw-user@192.168.64.5

# Install OpenClaw (verify download)
curl -fsSL https://openclaw.ai/install.sh -o install.sh
shasum -a 256 install.sh  # Verify against published hash
bash install.sh
```

### Step 2: Configure Gateway with Authentication

Create `~/.openclaw/config.yaml`:

```yaml
gateway:
  # Bind to localhost only - access via SSH tunnel
  bind: "127.0.0.1:8080"

  # Require authentication
  auth:
    enabled: true
    # Generate with: openssl rand -hex 32
    token: "YOUR_64_CHAR_HEX_TOKEN_HERE"

  # TLS (even for localhost)
  tls:
    enabled: true
    cert: "/home/openclaw-user/.openclaw/certs/server.crt"
    key: "/home/openclaw-user/.openclaw/certs/server.key"

  # Rate limiting
  rate_limit:
    requests_per_minute: 60
    burst: 10

  # Logging
  logging:
    level: "info"
    file: "/var/log/openclaw/gateway.log"
```

### Step 3: Generate TLS Certificates

```bash
mkdir -p ~/.openclaw/certs
cd ~/.openclaw/certs

# Generate self-signed cert (for internal use)
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt \
  -days 365 -nodes -subj "/CN=openclaw-vm"

chmod 600 server.key
chmod 644 server.crt
```

### Step 4: Access Gateway via SSH Tunnel Only

From your main machine:

```bash
# Create SSH tunnel to Gateway
ssh -i ~/.ssh/openclaw_vm_ed25519 \
  -L 8080:127.0.0.1:8080 \
  -N \
  openclaw-user@192.168.64.5

# Gateway is now available at https://localhost:8080
```

---

## iMessage/BlueBubbles Security

### Step 1: Create Burner Apple ID

**Do NOT use your primary Apple ID in the VM.**

1. Go to appleid.apple.com on your main machine
2. Create a new Apple ID with:
   - Dedicated email address (not your main email)
   - Unique password (not reused anywhere)
   - No payment method
   - Minimal personal info

### Step 2: Install BlueBubbles with Hardening

```bash
# In the VM
# Download BlueBubbles from official source
# Verify checksum before installing

# Configure BlueBubbles
# Settings → Server → Security:
#   - Enable password protection
#   - Generate strong API key
#   - Enable HTTPS only
#   - Disable unnecessary features
```

### Step 3: Webhook Security

Configure BlueBubbles webhooks to only communicate with the local Gateway:

```yaml
# BlueBubbles webhook config
webhook:
  url: "https://127.0.0.1:8080/bluebubbles/webhook"
  secret: "STRONG_WEBHOOK_SECRET"
  verify_ssl: true
```

---

## Monitoring & Alerting

### Step 1: Enable Comprehensive Logging

Create `/usr/local/bin/openclaw-monitor.sh`:

```bash
#!/bin/bash
# OpenClaw VM Security Monitor

LOG_DIR="/var/log/openclaw"
ALERT_EMAIL="your-email@example.com"

# Create log directory
mkdir -p "$LOG_DIR"

# Function to send alert
send_alert() {
  local subject="$1"
  local body="$2"
  echo "$body" | mail -s "[OpenClaw VM Alert] $subject" "$ALERT_EMAIL"
}

# Monitor SSH attempts
ssh_failures=$(grep "sshd.*Failed" /var/log/system.log | wc -l)
if [ "$ssh_failures" -gt 10 ]; then
  send_alert "High SSH Failures" "Detected $ssh_failures failed SSH attempts"
fi

# Monitor Gateway errors
if [ -f "$LOG_DIR/gateway.log" ]; then
  errors=$(grep -c "ERROR" "$LOG_DIR/gateway.log")
  if [ "$errors" -gt 50 ]; then
    send_alert "Gateway Errors" "Detected $errors errors in last period"
  fi
fi

# Monitor disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$disk_usage" -gt 80 ]; then
  send_alert "Disk Space Low" "Disk usage at $disk_usage%"
fi

# Monitor unexpected processes
unexpected=$(ps aux | grep -E "(nc|ncat|netcat|socat)" | grep -v grep)
if [ -n "$unexpected" ]; then
  send_alert "Suspicious Process" "Detected: $unexpected"
fi

# Log summary
echo "$(date): SSH failures: $ssh_failures, Gateway errors: $errors, Disk: $disk_usage%" >> "$LOG_DIR/monitor.log"
```

Schedule monitoring:

```bash
sudo crontab -e
# Add: */15 * * * * /usr/local/bin/openclaw-monitor.sh
```

---

## Backup & Recovery

### Step 1: Create VM Snapshots

```bash
# On host machine - create snapshot before major changes
lume snapshot openclaw-secure --name "pre-update-$(date +%Y%m%d)"

# List snapshots
lume snapshot list openclaw-secure

# Restore if needed
lume snapshot restore openclaw-secure --name "pre-update-20260130"
```

### Step 2: Automated Backup Script

Create `/usr/local/bin/backup-openclaw-vm.sh` on the host:

```bash
#!/bin/bash
# Backup OpenClaw VM configuration

BACKUP_DIR="/Users/jordaaan/Backups/openclaw-vm"
DATE=$(date +%Y%m%d_%H%M%S)
VM_IP="192.168.64.5"

mkdir -p "$BACKUP_DIR"

# Backup VM config files via SSH
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw-user@$VM_IP \
  "tar czf - ~/.openclaw /etc/ssh/sshd_config" > \
  "$BACKUP_DIR/config_$DATE.tar.gz"

# Create VM snapshot
lume snapshot openclaw-secure --name "backup-$DATE"

# Keep only last 7 backups
ls -t "$BACKUP_DIR"/config_*.tar.gz | tail -n +8 | xargs rm -f 2>/dev/null

echo "Backup completed: $DATE"
```

---

## Incident Response Playbook

### Suspected Compromise

**Step 1: Isolate**
```bash
# Immediately stop the VM
lume stop openclaw-secure

# Or if still running, cut network
# On host, block VM traffic
sudo pfctl -t blocklist -T add 192.168.64.5
```

**Step 2: Preserve Evidence**
```bash
# Create forensic snapshot
lume snapshot openclaw-secure --name "forensic-$(date +%Y%m%d_%H%M%S)"

# Export logs from host
cp /var/log/system.log ~/incident-$(date +%Y%m%d)/host-system.log
```

**Step 3: Analyze**
```bash
# Start VM in isolated mode (no network)
lume run openclaw-secure --no-network

# Review logs
grep -E "(Failed|error|unauthorized)" /var/log/*
last -10
history
```

**Step 4: Recover**
```bash
# Option A: Restore from known-good snapshot
lume snapshot restore openclaw-secure --name "pre-incident"

# Option B: Full rebuild (recommended for severe compromise)
lume delete openclaw-secure
lume create openclaw-secure --os macos --ipsw latest
# Re-run hardening steps
```

**Step 5: Rotate Credentials**
- Generate new SSH keys
- Generate new Gateway auth token
- Generate new BlueBubbles API key
- Rotate webhook secrets

---

## Security Maintenance Checklist

### Daily
- [ ] Review monitoring alerts
- [ ] Check Gateway logs for anomalies

### Weekly
- [ ] Review SSH auth logs
- [ ] Verify backup integrity
- [ ] Check for macOS updates in VM

### Monthly
- [ ] Rotate Gateway auth tokens
- [ ] Review and prune exec-approvals
- [ ] Test restore from backup
- [ ] Audit installed packages in VM

### Quarterly
- [ ] Full security review
- [ ] Update Lume to latest version
- [ ] Review and update firewall rules
- [ ] Penetration test (if applicable)

---

## Quick Reference Commands

```bash
# Start VM
lume run openclaw-secure

# Stop VM
lume stop openclaw-secure

# SSH into VM
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw-user@192.168.64.5

# Create SSH tunnel to Gateway
ssh -i ~/.ssh/openclaw_vm_ed25519 -L 8080:127.0.0.1:8080 -N openclaw-user@192.168.64.5

# Create snapshot
lume snapshot openclaw-secure --name "snapshot-name"

# Restore snapshot
lume snapshot restore openclaw-secure --name "snapshot-name"

# View VM logs (from host)
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw-user@192.168.64.5 "tail -f /var/log/openclaw/gateway.log"

# Check VM status
lume get openclaw-secure
```

---

**Document Version:** 1.0
**Last Updated:** January 30, 2026
**Next Review:** April 30, 2026
