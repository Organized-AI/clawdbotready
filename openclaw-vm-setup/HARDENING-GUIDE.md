# VM Hardening Best Practices for Production

This guide documents the security hardening measures implemented in openclaw-vm-setup and additional best practices for production deployments.

## Table of Contents

- [Defense in Depth Architecture](#defense-in-depth-architecture)
- [VM-Level Hardening](#vm-level-hardening)
- [Network Security](#network-security)
- [Access Control](#access-control)
- [Application Security](#application-security)
- [Monitoring & Incident Response](#monitoring--incident-response)
- [Compliance & Auditing](#compliance--auditing)
- [Production Checklist](#production-checklist)

---

## Defense in Depth Architecture

Our security model implements multiple overlapping layers of protection:

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 7: Monitoring & Alerting                              │
│  - Real-time security monitoring                            │
│  - Intrusion detection                                      │
│  - Log aggregation and analysis                             │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 6: Application Security                               │
│  - exec-approvals (deny-by-default)                         │
│  - Gateway authentication (token-based)                     │
│  - TLS encryption                                           │
│  - Rate limiting                                            │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 5: Access Control                                     │
│  - SSH key-only authentication                              │
│  - Ed25519 cryptography                                     │
│  - Limited auth attempts                                    │
│  - Session timeouts                                         │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: Network Isolation                                  │
│  - Localhost-only bindings                                  │
│  - SSH tunnel for Gateway access                            │
│  - pf firewall rules                                        │
│  - No direct internet exposure                              │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: VM Isolation                                       │
│  - Complete process isolation                               │
│  - Separate user accounts                                   │
│  - FileVault disk encryption                                │
│  - Resource limits                                          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Host OS Security                                   │
│  - macOS security features (SIP, Gatekeeper)                │
│  - Firmware password                                        │
│  - Automatic security updates                               │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Physical Security                                  │
│  - Secure data center / locked office                       │
│  - Access logs                                              │
│  - Tamper detection                                         │
└─────────────────────────────────────────────────────────────┘
```

**Key Principle**: If one layer is compromised, multiple other layers continue to protect the system.

---

## VM-Level Hardening

### 1. Disk Encryption (FileVault)

**Status**: ✅ Implemented in Phase 1

Enable full-disk encryption on the VM during macOS Setup Assistant:

```bash
# Verification (run inside VM):
fdesetup status
# Expected: "FileVault is On."
```

**Why**: Protects data at rest if VM disk image is stolen or accessed offline.

### 2. User Account Isolation

**Status**: ✅ Implemented in Phase 1

- Create a dedicated `openclaw` user (not admin)
- Use strong password (24+ chars, random)
- No password sharing between host and VM

```bash
# Check user is not admin:
groups openclaw
# Should NOT include "admin" group
```

**Why**: Limits blast radius if account is compromised; prevents privilege escalation.

### 3. Disable Unnecessary Services

**Status**: 🟡 Recommended (manual)

Disable services not needed for Gateway operation:

```bash
# Inside VM - disable unused services:
sudo launchctl disable system/com.apple.screensharing
sudo launchctl disable system/com.apple.AirPlayXPCHelper
sudo launchctl disable system/com.apple.RemoteDesktop

# Keep only essential services:
# - SSH (com.openssh.sshd)
# - Network (com.apple.networkd)
```

**Why**: Reduces attack surface; fewer services = fewer vulnerabilities.

### 4. Resource Limits

**Status**: ✅ Implemented in config/settings.env

Limit VM resources to prevent resource exhaustion attacks:

```bash
# In config/settings.env:
VM_CPU="4"              # Don't allocate more than needed
VM_MEMORY="8192"        # 8GB is sufficient for most workloads
VM_DISK="60G"           # Prevents disk exhaustion on host
```

**Additional Hardening**:

```bash
# Inside VM - set ulimits for openclaw user:
sudo tee -a /etc/launchd.conf <<EOF
limit maxfiles 4096 8192
limit maxproc 512 1024
EOF
```

**Why**: Prevents denial-of-service via resource exhaustion.

### 5. macOS Security Settings

**Status**: 🟡 Recommended (manual during setup)

During VM setup, configure:

1. **Gatekeeper**: Block unsigned applications
2. **Firewall**: Enable macOS Application Firewall
3. **Privacy**: Disable analytics, Siri, location services
4. **Updates**: Enable automatic security updates
5. **Screen Lock**: 5-minute idle timeout

```bash
# Verification commands (inside VM):
spctl --status                    # Gatekeeper status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
defaults read com.apple.SoftwareUpdate AutomaticCheckEnabled
```

**Why**: Leverages built-in macOS security features.

---

## Network Security

### 1. Firewall Rules (pf)

**Status**: ✅ Implemented in Phase 3

Host firewall restricts all direct access to VM:

```bash
# /etc/pf.anchors/openclaw-vm:
vm_ip = "192.168.64.X"

# Allow SSH from localhost only
pass in quick proto tcp from 127.0.0.1 to $vm_ip port 22

# Allow Gateway access via tunnel only
pass in quick proto tcp from 127.0.0.1 to $vm_ip port 8080

# Block all other access
block in quick from any to $vm_ip
```

**Verification**:

```bash
sudo pfctl -sr | grep openclaw
sudo pfctl -sn              # Show active NAT rules
```

**Why**: Prevents direct network access to VM from external sources.

### 2. Gateway Network Binding

**Status**: ✅ Implemented in Phase 4

Gateway binds to localhost only:

```yaml
# ~/.openclaw/config.yaml (inside VM):
gateway:
  bind: "127.0.0.1:8080"    # NOT 0.0.0.0:8080
```

**Verification**:

```bash
# Inside VM:
netstat -an | grep 8080
# Should show: tcp4  0  0  127.0.0.1.8080  *.*  LISTEN
```

**Why**: Prevents direct access even if firewall rules fail.

### 3. SSH Tunnel for Gateway Access

**Status**: ✅ Implemented in scripts/tunnel.sh

Access Gateway only via encrypted SSH tunnel:

```bash
# Create tunnel:
ssh -i ~/.ssh/openclaw_vm_ed25519 \
    -L 8080:127.0.0.1:8080 \
    -N openclaw@<VM_IP>

# Access via https://localhost:8080
```

**Benefits**:
- End-to-end encryption
- No direct network exposure
- Audit trail in SSH logs
- Compatible with bastion host patterns

### 4. TLS Encryption

**Status**: ✅ Implemented in Phase 4

Gateway uses TLS even for localhost connections:

```bash
# Inside VM - certificate generation:
openssl req -x509 -newkey rsa:4096 \
  -keyout ~/.openclaw/certs/server.key \
  -out ~/.openclaw/certs/server.crt \
  -days 365 -nodes \
  -subj "/CN=openclaw-vm"
```

**Production Enhancement** (optional):

```bash
# Use Let's Encrypt for valid certificate:
# (Only if exposing Gateway externally - NOT recommended)
certbot certonly --standalone -d gateway.example.com
```

**Why**: Prevents eavesdropping even on localhost; defense in depth.

### 5. Rate Limiting

**Status**: ✅ Implemented in Phase 4

Gateway rate limits prevent abuse:

```yaml
gateway:
  rate_limit:
    requests_per_minute: 60
    burst: 10
```

**Monitoring**:

```bash
# Check rate limit violations:
grep "rate limit" ~/.openclaw/logs/gateway.log
```

**Why**: Prevents brute-force attacks and resource exhaustion.

---

## Access Control

### 1. SSH Key-Only Authentication

**Status**: ✅ Implemented in Phase 2

No password authentication allowed:

```bash
# /etc/ssh/sshd_config:
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
```

**Key Security**:

```bash
# Host key permissions:
chmod 600 ~/.ssh/openclaw_vm_ed25519
chmod 644 ~/.ssh/openclaw_vm_ed25519.pub

# Verification:
ls -la ~/.ssh/openclaw_vm_ed25519
# Should show: -rw-------
```

**Why**: Passwords can be brute-forced; keys cannot.

### 2. Strong Cryptography (Ed25519)

**Status**: ✅ Implemented in Phase 2

Use Ed25519 keys exclusively:

```bash
# Key generation:
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/openclaw_vm_ed25519

# SSH config enforces algorithm:
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
```

**Why**: Ed25519 is faster and more secure than RSA; resistant to timing attacks.

### 3. Limited Authentication Attempts

**Status**: ✅ Implemented in Phase 2

Limit failed SSH attempts:

```bash
# /etc/ssh/sshd_config:
MaxAuthTries 3
MaxSessions 2
```

**Monitoring**:

```bash
# Check failed attempts:
grep "Failed" /var/log/system.log | grep sshd
```

**Why**: Slows brute-force attacks; triggers alerts.

### 4. Session Timeouts

**Status**: ✅ Implemented in Phase 2

Automatic session termination for idle connections:

```bash
# /etc/ssh/sshd_config:
ClientAliveInterval 300       # 5 minutes
ClientAliveCountMax 2         # 2 missed checks = disconnect
```

**Why**: Prevents hijacking of abandoned sessions.

### 5. User Restriction

**Status**: ✅ Implemented in Phase 2

Only `openclaw` user can SSH:

```bash
# /etc/ssh/sshd_config:
AllowUsers openclaw
PermitRootLogin no
```

**Why**: Limits attack surface to a single non-admin account.

---

## Application Security

### 1. exec-approvals (Command Allowlisting)

**Status**: ✅ Implemented in config/exec-approvals.json

Deny-by-default command execution with explicit allowlist:

```json
{
  "default_action": "deny",
  "log_all_attempts": true,
  "rules": [
    {
      "id": "allow-echo",
      "binary": "/bin/echo",
      "action": "allow",
      "argument_rules": {
        "forbidden_patterns": [">>", ">", "|", ";", "`"]
      }
    }
  ]
}
```

**Blocked Commands**:
- Network: `curl`, `wget`, `nc`, `ssh`, `scp`
- System: `sudo`, `su`, `osascript`, `launchctl`
- Persistence: `crontab`, `at`
- Security: `chmod`, `chown`, `security`, `defaults`

**Monitoring**:

```bash
# Check denied attempts:
tail -f ~/.openclaw/logs/exec-approvals.log
```

**Why**: Prevents unauthorized command execution by AI agents.

### 2. Gateway Authentication

**Status**: ✅ Implemented in Phase 4

Token-based authentication required:

```yaml
gateway:
  auth:
    enabled: true
    token: "<256-bit random token>"
```

**Token Security**:

```bash
# Generate strong token:
openssl rand -hex 32

# Store securely (host):
chmod 600 .gateway_token
```

**Rotation Schedule**: Every 90 days (recommended)

**Why**: Prevents unauthorized Gateway access.

### 3. Workspace Isolation

**Status**: 🟡 Recommended (additional hardening)

Restrict file access to workspace directory:

```bash
# Inside VM - create workspace:
mkdir -p ~/.openclaw/workspace
chmod 700 ~/.openclaw/workspace

# exec-approvals rules enforce workspace prefix:
"required_prefix": ["/Users/openclaw/.openclaw/workspace"]
```

**Why**: Prevents access to sensitive files (`.ssh`, `.gnupg`, keychains).

### 4. Dependency Security

**Status**: 🟡 Recommended (ongoing)

Keep OpenClaw Gateway dependencies updated:

```bash
# Inside VM - check for updates:
npm audit
npm update

# Or use automated tools:
npm install -g npm-check-updates
ncu -u
```

**Why**: Patches known vulnerabilities in dependencies.

### 5. Environment Variable Security

**Status**: ✅ Implemented in exec-approvals.json

Block dangerous environment variables:

```json
{
  "environment_blocklist": [
    "PATH",
    "LD_LIBRARY_PATH",
    "DYLD_*",
    "NODE_OPTIONS",
    "BASH_ENV"
  ]
}
```

**Why**: Prevents privilege escalation via environment manipulation.

---

## Monitoring & Incident Response

### 1. Security Monitoring

**Status**: ✅ Implemented in Phase 5

Automated monitoring checks every 5 minutes:

```bash
# Inside VM - monitoring script:
~/monitoring/security-monitor.sh

# Checks:
# - SSH failure count
# - Suspicious processes (nc, netcat, curl | sh)
# - Disk usage
# - exec-approvals denials
```

**Logs**:

```bash
~/monitoring/alerts.log       # Security alerts
~/monitoring/status.log       # Routine checks
~/.openclaw/logs/gateway.log  # Gateway logs
~/.openclaw/logs/exec-approvals.log  # Command attempts
```

### 2. Host-Side Monitoring

**Status**: ✅ Implemented in scripts/host-monitor.sh

Host checks VM health:

```bash
# Run manually or via cron:
./scripts/host-monitor.sh

# Checks:
# - VM responds to ping
# - SSH accessible
# - Fetches VM alerts
```

### 3. Log Aggregation

**Status**: 🟡 Recommended (for production)

Centralize logs for analysis:

```bash
# Option 1: syslog forwarding
# Inside VM - forward to host syslog:
sudo tee -a /etc/asl.conf <<EOF
> host.example.com udp
EOF

# Option 2: File-based aggregation
# Host cron job:
*/10 * * * * ssh openclaw@<VM_IP> "cat ~/monitoring/alerts.log" >> /var/log/openclaw-alerts.log
```

**Why**: Centralized logs survive VM compromise; easier analysis.

### 4. Alert Delivery

**Status**: 🟡 Recommended (for production)

Configure alert notifications:

```bash
# Option 1: Email alerts (requires SMTP)
# Add to security-monitor.sh:
if [[ $ssh_failures -gt 10 ]]; then
    echo "High SSH failures on OpenClaw VM" | \
        mail -s "Security Alert" admin@example.com
fi

# Option 2: Slack/Discord webhook
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK \
    -d '{"text":"OpenClaw VM Security Alert"}'
```

**Why**: Real-time notifications enable faster incident response.

### 5. Incident Response Plan

**Status**: 📋 Documented below

**If VM is compromised**:

1. **Isolate**: Run `./scripts/emergency-stop.sh` immediately
2. **Snapshot**: VM is already stopped; snapshot is preserved
3. **Investigate**: Review logs in `logs/` and VM monitoring logs
4. **Restore**: Use `./scripts/restore-vm.sh` to restore from known-good snapshot
5. **Rotate**: Change all credentials (SSH keys, Gateway token)
6. **Audit**: Review exec-approvals.log to understand attack vector

**Emergency Contacts**:
- Primary: [Your contact info]
- Escalation: [Team lead / security team]

---

## Compliance & Auditing

### 1. Audit Logging

**Status**: ✅ Implemented

All security-relevant actions are logged:

```bash
# SSH logs (inside VM):
/var/log/system.log

# Gateway logs:
~/.openclaw/logs/gateway.log

# Command execution logs:
~/.openclaw/logs/exec-approvals.log

# Monitoring logs:
~/monitoring/alerts.log
~/monitoring/status.log

# Host logs:
openclaw-vm-setup/logs/setup-*.log
openclaw-vm-setup/logs/host-monitor.log
```

**Retention**: 90 days (minimum recommended)

### 2. Access Audit Trail

Track all VM access:

```bash
# SSH access history (inside VM):
last -20

# Who accessed what:
grep "Accepted publickey" /var/log/system.log

# Failed access attempts:
grep "Failed" /var/log/system.log
```

### 3. Configuration Change Tracking

**Status**: ✅ Implemented via git

All configuration files tracked in version control:

```bash
# Review configuration history:
git log --oneline config/

# Compare current vs original:
git diff HEAD~5 config/exec-approvals.json
```

**Why**: Provides audit trail for security policy changes.

### 4. Regular Security Audits

**Status**: 📋 Recommended schedule

**Weekly**:
- Review exec-approvals denials
- Check SSH failure logs
- Verify firewall rules still active

**Monthly**:
- Rotate Gateway token
- Review and update exec-approvals allowlist
- Test backup restoration
- Check for OpenClaw updates

**Quarterly**:
- Full security assessment (penetration test)
- Review incident response plan
- Update documentation
- Security training for operators

### 5. Compliance Documentation

Maintain records for compliance:

```bash
# Document security configurations:
openclaw-vm-setup/HARDENING-GUIDE.md  # This file
openclaw-vm-setup/config/             # Security policies
openclaw-vm-setup/logs/               # Audit logs

# Backup policies:
openclaw-vm-setup/scripts/backup-vm.sh
openclaw-vm-setup/backups/            # Backup history
```

---

## Production Checklist

### Pre-Deployment

- [ ] Review and customize `config/exec-approvals.json`
- [ ] Generate strong SSH key (`ssh-keygen -t ed25519 -a 100`)
- [ ] Configure firewall rules for your network
- [ ] Set strong VM user password (24+ characters)
- [ ] Enable FileVault during VM setup
- [ ] Disable unnecessary macOS services in VM
- [ ] Configure log aggregation
- [ ] Set up alert notifications (email/Slack)
- [ ] Document emergency contacts
- [ ] Test backup and restore procedures

### Post-Deployment

- [ ] Verify all phases completed successfully
- [ ] Test SSH access with key authentication
- [ ] Confirm Gateway accessible only via tunnel
- [ ] Verify firewall rules active (`sudo pfctl -sr`)
- [ ] Check monitoring scripts running (cron)
- [ ] Review initial logs for errors
- [ ] Create initial VM snapshot
- [ ] Document Gateway token location
- [ ] Test emergency stop procedure
- [ ] Conduct security scan (nmap, vulnerability scanner)

### Ongoing Operations

**Daily**:
- [ ] Check `./scripts/status.sh` output
- [ ] Review monitoring alerts

**Weekly**:
- [ ] Review exec-approvals denials
- [ ] Check SSH failure logs
- [ ] Verify backups completed successfully
- [ ] Review Gateway logs for anomalies

**Monthly**:
- [ ] Rotate Gateway authentication token
- [ ] Test VM restore from snapshot
- [ ] Update macOS in VM (security patches)
- [ ] Review and update exec-approvals allowlist
- [ ] Check for OpenClaw Gateway updates

**Quarterly**:
- [ ] Full security audit
- [ ] Penetration testing
- [ ] Review incident response plan
- [ ] Update documentation
- [ ] Security training refresher

### Decommissioning

When retiring the VM:

- [ ] Backup all logs and configurations
- [ ] Export any required data
- [ ] Delete Gateway authentication token
- [ ] Delete SSH keys
- [ ] Delete VM and all snapshots
- [ ] Remove firewall rules
- [ ] Remove monitoring cron jobs
- [ ] Document decommissioning date and reason

---

## Additional Resources

### Security References

- **SSH Hardening**: https://stribika.github.io/2015/01/04/secure-secure-shell.html
- **macOS Security**: https://support.apple.com/guide/security/welcome/web
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **CIS macOS Benchmark**: https://www.cisecurity.org/benchmark/apple_os

### Tools for Security Testing

```bash
# Network scanning:
nmap -sV -sC <VM_IP>

# SSH audit:
ssh-audit <VM_IP>

# macOS security audit (inside VM):
# Download from: https://github.com/kristovatlas/osx-config-check
python osx-config-check.py

# Dependency vulnerabilities:
npm audit
```

### Threat Modeling

Consider these attack scenarios:

1. **Compromised AI Agent**: exec-approvals blocks malicious commands
2. **Network Intrusion**: Firewall + localhost-only binding prevents access
3. **SSH Brute Force**: Key-only auth + attempt limits stop attack
4. **Data Exfiltration**: Network command blocking prevents data theft
5. **Privilege Escalation**: Non-admin user + sudo blocking limits damage
6. **Persistence**: crontab/launchctl blocking prevents backdoors

Each layer of defense addresses multiple scenarios.

---

## Support and Contributions

For questions, issues, or improvements to this hardening guide:

- **Issues**: https://github.com/your-org/clawdbot-ready/issues
- **Security Reports**: security@example.com (do not file public issues for vulnerabilities)
- **Documentation**: Update this guide when adding new security measures

---

**Last Updated**: 2026-01-30
**Version**: 1.0
**Maintainer**: Clawdbot Ready Security Team
