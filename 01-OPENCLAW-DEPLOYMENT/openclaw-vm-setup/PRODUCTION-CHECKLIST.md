# Production Deployment Checklist

**Version**: 1.0
**Last Updated**: 2026-01-30
**For**: OpenClaw VM Setup (macOS Edition)

---

## 📋 Overview

This checklist ensures your OpenClaw VM deployment is production-ready with proper security hardening, testing, and operational procedures in place.

**Deployment Type**: macOS VM (Lume hypervisor) on Apple Silicon

---

## ✅ Pre-Deployment Phase

### System Requirements

- [ ] **Hardware**: Apple Silicon Mac (M1/M2/M3/M4)
- [ ] **OS**: macOS Sequoia (15.0+) or later
- [ ] **Disk Space**: 70GB+ available
- [ ] **Memory**: 16GB+ RAM (8GB allocated to VM + 8GB for host)
- [ ] **Network**: Stable internet connection for setup

### Documentation Review

- [ ] Read [README.md](README.md) completely
- [ ] Review [HARDENING-GUIDE.md](HARDENING-GUIDE.md) security measures
- [ ] Understand emergency procedures ([scripts/emergency-stop.sh](scripts/emergency-stop.sh))
- [ ] Review exec-approvals policy ([config/exec-approvals.json](config/exec-approvals.json))

### Configuration Preparation

- [ ] Review and customize [config/settings.env](config/settings.env)
  - [ ] Set appropriate `VM_CPU` (2-4 cores recommended)
  - [ ] Set appropriate `VM_MEMORY` (4096-8192 MB recommended)
  - [ ] Set `VM_DISK` (60G+ recommended)
  - [ ] Customize `VM_NAME` if needed
  - [ ] Verify `VM_USER` setting

- [ ] Review [config/exec-approvals.json](config/exec-approvals.json)
  - [ ] Understand deny-by-default policy
  - [ ] Verify dangerous commands are blocked
  - [ ] Customize allowlist if needed for your use case
  - [ ] Ensure logging is enabled

### Secrets & Credentials

- [ ] **Plan SSH key management**
  - [ ] Decide on key storage location (default: `~/.ssh/openclaw_vm_ed25519`)
  - [ ] Plan key backup strategy
  - [ ] Document key recovery procedures

- [ ] **Plan Gateway token management**
  - [ ] Document token storage location
  - [ ] Plan token rotation schedule (90 days recommended)
  - [ ] Secure token backup procedure

- [ ] **Plan VM user password**
  - [ ] Generate strong password (24+ characters)
  - [ ] Store in password manager
  - [ ] Document password rotation policy

### Backup Strategy

- [ ] **Define backup schedule**
  - [ ] Daily automated backups (recommended)
  - [ ] Retention policy (7 days default, customize if needed)
  - [ ] Off-site backup location (external drive recommended)

- [ ] **Plan backup storage**
  - [ ] Local disk: [backups/](backups/) directory
  - [ ] External drive mount point
  - [ ] Cloud storage (optional, requires secure upload)

### Network Planning

- [ ] **Firewall configuration**
  - [ ] Verify pf firewall can be enabled (requires sudo)
  - [ ] Plan localhost-only access model
  - [ ] Document SSH tunnel procedures for Gateway access

- [ ] **Access control**
  - [ ] List authorized users/systems
  - [ ] Plan SSH bastion host (if applicable)
  - [ ] Document network topology

---

## 🔧 Deployment Phase

### Phase 0: Environment Verification

```bash
cd openclaw-vm-setup
./setup.sh 0
```

- [ ] Phase 0 completed successfully
- [ ] macOS version confirmed (15.0+)
- [ ] Apple Silicon confirmed (arm64)
- [ ] Disk space verified (70GB+)
- [ ] Network connectivity confirmed
- [ ] Log file created in [logs/](logs/)

**If Phase 0 fails**: Resolve issues before proceeding. Check [logs/](logs/) for details.

### Phase 1: Lume & VM Installation

```bash
./setup.sh 1
```

- [ ] Lume installer reviewed and approved
- [ ] Lume installed successfully
- [ ] `lume --version` returns version number
- [ ] VM creation started
- [ ] **Manual: Complete macOS Setup Assistant in VM**
  - [ ] Created local account (username: `openclaw`)
  - [ ] Used strong password (24+ chars, saved in password manager)
  - [ ] **Enabled FileVault disk encryption**
  - [ ] Skipped iCloud sign-in (or used burner Apple ID)
  - [ ] Disabled all "share data with Apple" options
  - [ ] Enabled Remote Login (System Settings → Sharing)
- [ ] VM finished booting
- [ ] VM IP address obtained and saved to [.vm_ip](.vm_ip)
- [ ] Can ping VM IP from host

**Verification**:
```bash
lume list | grep openclaw-secure
ping $(cat .vm_ip)
```

### Phase 2: SSH Hardening

```bash
./setup.sh 2
```

- [ ] Ed25519 SSH key generated (`~/.ssh/openclaw_vm_ed25519`)
- [ ] SSH key permissions set to 600
- [ ] Public key copied to VM
- [ ] Key-based authentication verified
- [ ] Password authentication disabled on VM
- [ ] Root login disabled
- [ ] Strong key algorithms enforced (ed25519 only)
- [ ] MaxAuthTries limited (≤5)
- [ ] Session timeout configured (ClientAliveInterval)
- [ ] Can connect to VM with key-only auth

**Verification**:
```bash
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw@$(cat .vm_ip) "echo 'SSH OK'"
# Should succeed

ssh -o PasswordAuthentication=yes openclaw@$(cat .vm_ip)
# Should fail (password auth disabled)
```

### Phase 3: Host Firewall

```bash
./setup.sh 3
```

- [ ] pf anchor file created (`/etc/pf.anchors/openclaw-vm`)
- [ ] Anchor added to `/etc/pf.conf`
- [ ] Firewall rules allow localhost → VM SSH (port 22)
- [ ] Firewall rules allow localhost → VM Gateway (port 8080)
- [ ] Firewall blocks all other access to VM
- [ ] pf firewall enabled
- [ ] Rules loaded and active

**Verification**:
```bash
sudo pfctl -si | grep "Status: Enabled"
sudo pfctl -sr | grep openclaw
cat /etc/pf.anchors/openclaw-vm | grep "127.0.0.1"
```

### Phase 4: Gateway Configuration

```bash
./setup.sh 4
```

- [ ] Gateway auth token generated (256-bit)
- [ ] Token saved to [.gateway_token](.gateway_token) with 600 permissions
- [ ] Token backed up to secure location
- [ ] TLS certificates generated in VM (`~/.openclaw/certs/`)
- [ ] Gateway config created (`~/.openclaw/config.yaml`)
  - [ ] Binds to 127.0.0.1:8080 (not 0.0.0.0)
  - [ ] TLS enabled
  - [ ] Authentication enabled
  - [ ] Rate limiting configured
- [ ] exec-approvals.json copied to VM
- [ ] Verified exec-approvals default action is "deny"
- [ ] Verified dangerous commands are blocked
- [ ] Gateway directory permissions secured

**Verification**:
```bash
# In VM:
cat ~/.openclaw/config.yaml | grep "bind: \"127.0.0.1:8080\""
jq -r '.default_action' ~/.openclaw/exec-approvals.json
# Should output: deny
```

### Phase 5: Monitoring Setup

```bash
./setup.sh 5
```

- [ ] Security monitoring script deployed to VM (`~/monitoring/security-monitor.sh`)
- [ ] Monitoring script executable
- [ ] Cron job configured (every 5 minutes)
- [ ] Alert log initialized (`~/monitoring/alerts.log`)
- [ ] Status log initialized (`~/monitoring/status.log`)
- [ ] Host-side monitor script created ([scripts/host-monitor.sh](scripts/host-monitor.sh))
- [ ] Monitoring checks for:
  - [ ] SSH failures
  - [ ] Suspicious processes
  - [ ] Disk usage
  - [ ] Gateway health

**Verification**:
```bash
# In VM:
crontab -l | grep security-monitor
ls -la ~/monitoring/
```

### Phase 6: Backup Configuration

```bash
./setup.sh 6
```

- [ ] Backup directory created ([backups/](backups/))
- [ ] Backup script created ([scripts/backup-vm.sh](scripts/backup-vm.sh))
- [ ] Restore script created ([scripts/restore-vm.sh](scripts/restore-vm.sh))
- [ ] Backup retention configured (7 days default)
- [ ] First backup completed successfully
- [ ] Backup includes:
  - [ ] VM configuration files
  - [ ] exec-approvals.json
  - [ ] SSH config
  - [ ] VM snapshot
- [ ] Backup verified (can list contents)
- [ ] Restore procedure tested (on test VM, not production)

**Verification**:
```bash
./scripts/backup-vm.sh
ls -lh backups/
lume snapshot list openclaw-secure
```

### Optional: Moltbook Integration

```bash
./scripts/moltbook-setup.sh
```

- [ ] Moltbook setup script completed successfully
- [ ] Installation method used (npx or curl)
- [ ] Claim link generated and displayed
- [ ] Claim link saved to [.moltbook_claim_link](.moltbook_claim_link)
- [ ] **Manual: Opened claim link in browser**
- [ ] **Manual: Completed agent verification in Moltbook**
- [ ] **Manual: Configured agent settings in dashboard**
- [ ] Agent appears in Moltbook dashboard
- [ ] Agent status shows "Online"
- [ ] Integration verified (check Moltbook logs in VM)

**Verification**:
```bash
# In VM:
ls -la ~/.moltbook/
cat ~/.moltbook/claim_url  # If available
```

**Moltbook Dashboard**: https://www.moltbook.com/

**Skip if**: Not using Moltbook for agent management.

---

## 🧪 Testing Phase

### Unit Tests

```bash
cd tests
./test-runner.sh unit
```

- [ ] All configuration tests pass
- [ ] All script validation tests pass
- [ ] All security configuration tests pass
- [ ] exec-approvals.json is valid JSON
- [ ] No syntax errors in shell scripts

### Integration Tests

```bash
./test-runner.sh integration
```

- [ ] Phase 0 environment checks pass
- [ ] VM creation workflow verified
- [ ] SSH hardening verified
- [ ] Firewall rules verified
- [ ] Gateway config verified
- [ ] Monitoring setup verified
- [ ] Backup/restore verified

### Security Validation

```bash
./security-validator.sh --vm-ip=$(cat ../.vm_ip)
```

- [ ] **No CRITICAL issues found**
- [ ] **No HIGH issues found**
- [ ] Medium/Low issues reviewed and accepted (if any)
- [ ] Network exposure tests pass
- [ ] SSH hardening tests pass
- [ ] Firewall tests pass
- [ ] VM hardening tests pass
- [ ] Gateway security tests pass
- [ ] exec-approvals tests pass
- [ ] Secrets management tests pass
- [ ] Monitoring tests pass
- [ ] Backup tests pass
- [ ] Compliance tests pass

**Critical**: Do NOT proceed if CRITICAL or HIGH severity issues are found.

### Full Test Suite

```bash
./test-runner.sh all
```

- [ ] Total tests run: ___
- [ ] Tests passed: ___
- [ ] Tests failed: 0
- [ ] Test report saved to [tests/logs/](tests/logs/)

---

## 🛡️ Security Hardening Verification

### Defense Layers Check

- [ ] **Layer 1: VM Isolation**
  - [ ] VM runs in isolated process
  - [ ] FileVault enabled (disk encryption)
  - [ ] Separate user account (`openclaw`, non-admin)

- [ ] **Layer 2: Network Isolation**
  - [ ] Gateway binds to localhost only (127.0.0.1:8080)
  - [ ] pf firewall blocks direct VM access
  - [ ] SSH tunnel required for Gateway access

- [ ] **Layer 3: Access Control**
  - [ ] SSH key-only authentication (no passwords)
  - [ ] Ed25519 keys enforced
  - [ ] MaxAuthTries limited
  - [ ] Session timeouts configured

- [ ] **Layer 4: Application Security**
  - [ ] exec-approvals deny-by-default
  - [ ] Dangerous commands blocked (curl, wget, ssh, sudo)
  - [ ] Gateway authentication enabled (token-based)
  - [ ] TLS encryption enabled
  - [ ] Rate limiting configured

- [ ] **Layer 5: Monitoring**
  - [ ] Security monitoring active
  - [ ] Logs aggregated
  - [ ] Alerts configured
  - [ ] Cron jobs running

### Penetration Testing (Optional but Recommended)

- [ ] Network scan from external host (should find no open ports)
- [ ] SSH brute-force test (should be blocked after 3 attempts)
- [ ] Password authentication test (should fail)
- [ ] Weak key algorithm test (should be rejected)
- [ ] Direct Gateway access test (should fail, only tunnel works)
- [ ] exec-approvals bypass test (curl should be blocked)

**Tools**:
```bash
# From external host:
nmap -p- $(cat .vm_ip)  # Should show no open ports or only 22

# Test password auth (should fail):
ssh -o PreferredAuthentications=password openclaw@$(cat .vm_ip)
```

---

## 📊 Operational Readiness

### Documentation Complete

- [ ] README.md present and accurate
- [ ] HARDENING-GUIDE.md reviewed
- [ ] PRODUCTION-CHECKLIST.md (this file) completed
- [ ] Emergency procedures documented
- [ ] Recovery procedures documented
- [ ] Incident response plan in place

### Runbook Creation

- [ ] **Daily operations runbook**
  - [ ] How to check VM status
  - [ ] How to view logs
  - [ ] How to check for alerts

- [ ] **Maintenance runbook**
  - [ ] How to rotate Gateway token
  - [ ] How to update macOS in VM
  - [ ] How to update OpenClaw Gateway
  - [ ] How to test backups

- [ ] **Emergency runbook**
  - [ ] How to stop VM immediately
  - [ ] How to investigate security incident
  - [ ] How to restore from backup
  - [ ] Who to contact for escalation

### Team Training

- [ ] Operations team trained on:
  - [ ] Daily monitoring procedures
  - [ ] Log review
  - [ ] Backup verification
  - [ ] Emergency procedures

- [ ] Security team trained on:
  - [ ] exec-approvals policy
  - [ ] Incident response
  - [ ] Security audit procedures
  - [ ] Penetration testing

### Monitoring & Alerting

- [ ] Log aggregation configured
- [ ] Alert delivery configured (email/Slack/webhook)
- [ ] Monitoring dashboard (optional)
- [ ] On-call rotation defined
- [ ] Escalation procedures documented

### Compliance & Audit

- [ ] Security policy documented
- [ ] Audit logging enabled
- [ ] Log retention policy defined (90 days recommended)
- [ ] Access control list documented
- [ ] Backup retention policy defined
- [ ] Disaster recovery plan documented
- [ ] Compliance requirements met (GDPR, SOC2, etc.)

---

## 🚀 Go-Live Checklist

### Final Pre-Flight Checks

- [ ] All deployment phases completed successfully
- [ ] All tests pass (unit, integration, security)
- [ ] No CRITICAL or HIGH security issues
- [ ] Backup verified and tested
- [ ] Monitoring active and alerting
- [ ] Documentation complete
- [ ] Team trained
- [ ] Emergency procedures tested

### Launch Readiness Sign-Off

- [ ] **Technical Lead**: _______________ Date: ___________
- [ ] **Security Review**: _______________ Date: ___________
- [ ] **Operations**: _______________ Date: ___________

### Go-Live Steps

1. [ ] Final backup before production traffic
2. [ ] Enable production workload
3. [ ] Monitor logs for 1 hour
4. [ ] Verify no security alerts
5. [ ] Verify Gateway responding correctly
6. [ ] Document go-live time and state

**Production Start Time**: ___________

---

## 📅 Post-Deployment Maintenance

### Daily Tasks

- [ ] Check VM status: `./scripts/status.sh`
- [ ] Review monitoring alerts: `ssh openclaw@$(cat .vm_ip) "tail -20 ~/monitoring/alerts.log"`
- [ ] Verify backups completed: `ls -lt backups/ | head -5`
- [ ] Check disk space on host and VM

### Weekly Tasks

- [ ] Review exec-approvals denials:
  ```bash
  ssh openclaw@$(cat .vm_ip) "grep DENY ~/.openclaw/logs/exec-approvals.log | tail -50"
  ```
- [ ] Review SSH failure logs:
  ```bash
  ssh openclaw@$(cat .vm_ip) "grep 'Failed' /var/log/system.log | tail -20"
  ```
- [ ] Verify firewall rules active: `sudo pfctl -sr | grep openclaw`
- [ ] Check macOS updates available in VM

### Monthly Tasks

- [ ] **Rotate Gateway token**:
  ```bash
  openssl rand -hex 32 > .gateway_token
  chmod 600 .gateway_token
  # Update in VM: ~/.openclaw/config.yaml
  # Restart Gateway
  ```
- [ ] Test backup restoration (on test VM)
- [ ] Review and update exec-approvals allowlist
- [ ] Check for OpenClaw Gateway updates
- [ ] Review security logs for anomalies
- [ ] Update macOS in VM (security patches)

### Quarterly Tasks

- [ ] Full security audit
- [ ] Run penetration tests
- [ ] Review incident response plan
- [ ] Update documentation
- [ ] Security training refresher
- [ ] Review and update this checklist

---

## 🚨 Emergency Procedures

### If VM is Compromised

1. **Isolate immediately**:
   ```bash
   ./scripts/emergency-stop.sh
   ```

2. **Snapshot current state** (for forensics):
   ```bash
   lume snapshot openclaw-secure --name "incident-$(date +%Y%m%d_%H%M%S)"
   ```

3. **Collect logs**:
   ```bash
   # Before VM is stopped, if possible:
   ssh openclaw@$(cat .vm_ip) "tar czf ~/logs-dump.tar.gz ~/.openclaw/logs ~/monitoring"
   scp openclaw@$(cat .vm_ip):~/logs-dump.tar.gz ./incident-logs-$(date +%Y%m%d).tar.gz
   ```

4. **Investigate**:
   - Review `~/.openclaw/logs/exec-approvals.log` for malicious commands
   - Review `~/monitoring/alerts.log` for security events
   - Review SSH logs for unauthorized access
   - Determine attack vector

5. **Restore from known-good backup**:
   ```bash
   ./scripts/restore-vm.sh
   # Select snapshot from before compromise
   ```

6. **Rotate all credentials**:
   - [ ] Generate new SSH key
   - [ ] Generate new Gateway token
   - [ ] Change VM user password
   - [ ] Update all access credentials

7. **Document incident**:
   - Date/time of discovery
   - Attack vector
   - Impact assessment
   - Remediation steps taken
   - Lessons learned

8. **Notify stakeholders** per incident response plan

### If Backup Fails

1. **Verify disk space**: `df -h`
2. **Check backup script logs**: `cat logs/backup-*.log`
3. **Manually run backup**: `./scripts/backup-vm.sh`
4. **If Lume snapshot fails**: Check Lume logs
5. **If config backup fails**: Manually tar configs
6. **Create incident ticket** and investigate root cause

### If Gateway Stops Responding

1. **Check VM health**: `./scripts/status.sh`
2. **Check Gateway process in VM**:
   ```bash
   ssh openclaw@$(cat .vm_ip) "ps aux | grep OpenClaw"
   ```
3. **Check Gateway logs**:
   ```bash
   ssh openclaw@$(cat .vm_ip) "tail -50 ~/.openclaw/logs/gateway.log"
   ```
4. **Restart Gateway** (if safe to do so)
5. **If restart fails**: Restore from backup

---

## 📝 Deployment Metadata

### Deployment Information

- **Deployment Date**: ___________
- **Deployed By**: ___________
- **VM Name**: openclaw-secure
- **VM IP**: (stored in `.vm_ip`)
- **macOS Version**: ___________
- **Lume Version**: ___________
- **OpenClaw Gateway Version**: ___________

### Configuration Snapshot

- **VM CPU**: ___ cores
- **VM Memory**: ___ MB
- **VM Disk**: ___ GB
- **Backup Retention**: ___ days
- **Monitoring Interval**: 5 minutes (default)

### Access Credentials Locations

- **SSH Private Key**: `~/.ssh/openclaw_vm_ed25519`
- **Gateway Token**: `.gateway_token`
- **VM IP**: `.vm_ip`
- **VM User Password**: (in password manager)

**IMPORTANT**: Keep this metadata up to date as configuration changes.

---

## ✅ Sign-Off

**Deployment Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete

**Checklist Completion**: ___% ( ___ / ___ items)

**Final Approval**:

- [ ] All checklist items completed
- [ ] All tests passing
- [ ] Security validated
- [ ] Team trained
- [ ] Documentation complete
- [ ] Ready for production

**Approved By**: _______________ **Date**: ___________

---

**Version History**:
- v1.0 (2026-01-30): Initial production checklist created

**Next Review Date**: ___________
