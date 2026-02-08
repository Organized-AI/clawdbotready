# OpenClaw VM Setup - Test Suite

Comprehensive testing infrastructure for production-grade deployment validation.

---

## 📋 Test Suite Overview

This directory contains three levels of testing:

1. **Unit Tests** - Individual component validation
2. **Integration Tests** - End-to-end workflow validation
3. **Security Validation** - Production security auditing

All tests are designed to be **idempotent**, **non-destructive**, and **CI/CD friendly**.

---

## 🧪 Available Test Suites

### 1. test-runner.sh - Comprehensive Test Suite

Main test orchestrator with multiple test categories.

**Usage**:
```bash
./test-runner.sh [test-suite]
```

**Test Suites**:
- `all` - Run all tests (default)
- `unit` - Unit tests only
- `integration` - Integration tests only
- `security` - Security validation tests
- `idempotency` - Re-run safety tests
- `performance` - Performance and efficiency tests
- `docs` - Documentation completeness tests

**Example**:
```bash
# Run all tests
./test-runner.sh all

# Run only unit tests
./test-runner.sh unit

# Run security tests
./test-runner.sh security
```

**What It Tests**:
- ✅ Configuration file validity
- ✅ Script syntax and executability
- ✅ Security policy (exec-approvals.json)
- ✅ Phase 0 environment checks
- ✅ No hardcoded credentials
- ✅ SSH key permissions
- ✅ Firewall configuration
- ✅ Idempotency (safe to re-run)
- ✅ Documentation completeness

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TEST SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total Tests:   45
  Passed:        43
  Failed:        0
  Skipped:       2

  Results logged to: tests/logs/results-YYYYMMDD_HHMMSS.log

✓ All tests passed!
```

---

### 2. security-validator.sh - Production Security Audit

Deep security validation for production deployments. **Run this before going live**.

**Usage**:
```bash
./security-validator.sh [--vm-ip=IP] [--vm-user=USER] [--ssh-key=PATH]
```

**Example**:
```bash
# Auto-detect VM IP from .vm_ip file
./security-validator.sh

# Specify VM manually
./security-validator.sh --vm-ip=192.168.64.5 --vm-user=openclaw
```

**What It Tests**:

**Network Security**:
- ✅ VM not exposed to internet
- ✅ Gateway port (8080) not externally accessible
- ✅ No unexpected open ports

**SSH Hardening**:
- ✅ Password authentication disabled
- ✅ Root login disabled
- ✅ Ed25519 keys enforced
- ✅ Auth attempts limited (≤5)
- ✅ Idle timeout configured

**Firewall**:
- ✅ pf firewall enabled
- ✅ OpenClaw anchor loaded
- ✅ Localhost-only rules enforced
- ✅ Block rules present

**VM Hardening**:
- ✅ FileVault disk encryption enabled
- ✅ User is not admin
- ✅ Automatic updates enabled
- ✅ Gatekeeper active
- ✅ macOS Application Firewall enabled

**Gateway Security**:
- ✅ Gateway binds to 127.0.0.1 only
- ✅ TLS certificates present
- ✅ Authentication enabled
- ✅ Strong auth token (≥64 chars)
- ✅ Rate limiting configured

**exec-approvals**:
- ✅ Deployed to VM
- ✅ Default action is "deny"
- ✅ Dangerous commands blocked (curl, wget, ssh, sudo)
- ✅ Privilege escalation blocked
- ✅ Logging enabled
- ✅ Environment variable protection

**Secrets Management**:
- ✅ SSH key permissions (600)
- ✅ Gateway token permissions (600)
- ✅ No secrets in git
- ✅ .gitignore configured correctly

**Monitoring**:
- ✅ Security monitor script deployed
- ✅ Cron job configured
- ✅ Log files exist
- ✅ Alert log configured

**Backup & Recovery**:
- ✅ Backup script exists
- ✅ Restore script exists
- ✅ Backup directory present
- ✅ Recent backups found (if applicable)
- ✅ Retention policy configured

**Compliance**:
- ✅ Documentation complete
- ✅ Audit logging enabled
- ✅ Emergency procedures documented
- ✅ Configuration version controlled

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SECURITY VALIDATION REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Scan Date:     2026-01-30 14:30:45
  Target VM:     openclaw@192.168.64.5
  Report File:   tests/logs/security-report-YYYYMMDD_HHMMSS.txt

  Checks Passed: 68

  Issues Found:
    Critical:  0
    High:      0
    Medium:    2
    Low:       1

⚠ MEDIUM/LOW ISSUES FOUND - REVIEW RECOMMENDED
```

**Exit Codes**:
- `0` - All checks passed OR only medium/low issues
- `1` - High severity issues found
- `2` - **CRITICAL issues found - DO NOT DEPLOY**

---

### 3. integration-tests.sh - End-to-End Workflow Tests

Tests complete setup workflows from Phase 0 through Phase 6.

**Usage**:
```bash
./integration-tests.sh [--skip-vm-creation]
```

**Example**:
```bash
# Run all integration tests
./integration-tests.sh

# Skip VM creation tests (if VM already exists)
./integration-tests.sh --skip-vm-creation
```

**What It Tests**:

**Phase 0 Integration**:
- ✅ Script executes without errors
- ✅ Log file created
- ✅ Environment checks performed

**Phase 1 Integration**:
- ✅ Lume installation
- ✅ VM creation
- ✅ VM IP retrieval

**Phase 2 Integration**:
- ✅ SSH key generation
- ✅ Key permissions (600)
- ✅ Public key deployment
- ✅ SSH connectivity

**Phase 3 Integration**:
- ✅ pf availability
- ✅ Firewall anchor creation
- ✅ Anchor loaded in pf.conf
- ✅ Localhost restrictions enforced

**Phase 4 Integration**:
- ✅ Gateway token generation
- ✅ Token strength (≥64 chars)
- ✅ Token permissions (600)
- ✅ Gateway config deployed
- ✅ exec-approvals deployed
- ✅ TLS certificates generated

**Phase 5 Integration**:
- ✅ Monitoring scripts deployed
- ✅ Cron job configured
- ✅ Log files initialized
- ✅ Monitoring active

**Phase 6 Integration**:
- ✅ Backup script created
- ✅ Restore script created
- ✅ Backup directory exists
- ✅ Retention policy configured

**End-to-End Workflow**:
- ✅ All required components present
- ✅ Configuration files valid
- ✅ Helper scripts executable
- ✅ Documentation accessible

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Integration Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total Tests:   38
  Passed:        36
  Failed:        0

  Test Log:      tests/logs/integration-YYYYMMDD_HHMMSS.log

✓ All integration tests passed!
```

---

## 🚀 Recommended Testing Workflow

### Development/Testing

```bash
# 1. Run unit tests first (fastest)
./test-runner.sh unit

# 2. Run integration tests
./integration-tests.sh --skip-vm-creation

# 3. Run full test suite
./test-runner.sh all
```

### Pre-Production

```bash
# 1. Complete setup through all phases
cd ..
./setup.sh all

# 2. Run comprehensive integration tests
cd tests
./integration-tests.sh

# 3. Run security validation (CRITICAL)
./security-validator.sh

# 4. Verify NO critical or high issues
```

**Required**: Security validator must show **0 CRITICAL** and **0 HIGH** issues before production deployment.

### Production Monitoring

```bash
# Run security audit monthly
./security-validator.sh > security-audit-$(date +%Y%m).txt

# Compare results month-over-month
diff security-audit-202601.txt security-audit-202602.txt
```

---

## 📊 Test Logs

All tests write detailed logs to `logs/` directory:

```
tests/logs/
├── results-YYYYMMDD_HHMMSS.log       # test-runner.sh output
├── security-report-YYYYMMDD_HHMMSS.txt  # security-validator.sh output
└── integration-YYYYMMDD_HHMMSS.log   # integration-tests.sh output
```

**Log Retention**: Keep logs for 90 days (minimum) for audit purposes.

---

## 🔍 Understanding Test Results

### PASS ✓

Test completed successfully. No action needed.

### FAIL ✗

Test failed. **Must be fixed before production deployment**.

Review log file for details:
```bash
tail -50 logs/results-YYYYMMDD_HHMMSS.log
```

### SKIP ⊘

Test skipped due to missing prerequisites (e.g., VM not running, optional tool not installed).

**Action**: Review if skip is acceptable for your deployment.

---

## 🛠️ Troubleshooting Test Failures

### Common Issues

**1. "VM IP not found"**

```bash
# Check if .vm_ip file exists
cat ../.vm_ip

# Manually create if needed
lume get openclaw-secure | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1 > ../.vm_ip
```

**2. "SSH connection failed"**

```bash
# Check VM is running
lume list | grep openclaw-secure

# Test SSH manually
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw@$(cat ../.vm_ip)

# Check SSH key permissions
ls -la ~/.ssh/openclaw_vm_ed25519
# Should be: -rw------- (600)
```

**3. "exec-approvals.json invalid JSON"**

```bash
# Validate JSON syntax
jq empty ../config/exec-approvals.json

# Fix with:
vi ../config/exec-approvals.json
```

**4. "Firewall not enabled"**

```bash
# Enable pf firewall
sudo pfctl -e

# Load OpenClaw rules
sudo pfctl -f /etc/pf.conf
```

**5. "Security validator shows CRITICAL issues"**

**Do NOT deploy to production**. Fix all critical issues first.

```bash
# Review security report
cat logs/security-report-YYYYMMDD_HHMMSS.txt | grep CRITICAL

# Common critical issues and fixes:
# - Password auth enabled: Re-run Phase 2
# - Default action not deny: Fix exec-approvals.json
# - Firewall not blocking: Re-run Phase 3
# - Gateway exposed on 0.0.0.0: Fix Gateway config
```

---

## 🔐 Security Testing Best Practices

### Before Production

- [ ] Run `security-validator.sh` and verify 0 CRITICAL, 0 HIGH issues
- [ ] Run penetration tests from external network
- [ ] Test SSH brute-force protection
- [ ] Verify direct Gateway access fails
- [ ] Test exec-approvals blocking (try `curl`, `sudo`, etc.)
- [ ] Test emergency stop procedure
- [ ] Test backup restoration

### Ongoing

- [ ] Run `security-validator.sh` monthly
- [ ] Track security score over time
- [ ] Document and investigate new issues
- [ ] Retest after configuration changes
- [ ] Audit logs regularly

---

## 📝 CI/CD Integration

### GitHub Actions Example

```yaml
name: OpenClaw VM Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Unit Tests
        run: |
          cd openclaw-vm-setup/tests
          ./test-runner.sh unit

      - name: Run Security Validation
        run: |
          cd openclaw-vm-setup/tests
          ./test-runner.sh security

      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: openclaw-vm-setup/tests/logs/
```

### GitLab CI Example

```yaml
test:
  stage: test
  script:
    - cd openclaw-vm-setup/tests
    - ./test-runner.sh all
  artifacts:
    paths:
      - openclaw-vm-setup/tests/logs/
    when: always
```

---

## 📚 Additional Resources

### Documentation

- [Main README](../README.md) - Setup instructions
- [Hardening Guide](../HARDENING-GUIDE.md) - Security best practices
- [Production Checklist](../PRODUCTION-CHECKLIST.md) - Pre-deployment checklist

### Security References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- SSH Hardening: https://stribika.github.io/2015/01/04/secure-secure-shell.html
- macOS Security Guide: https://support.apple.com/guide/security/welcome/web

### Tools

- `jq` - JSON validation (install: `brew install jq`)
- `nmap` - Network scanning (install: `brew install nmap`)
- `shellcheck` - Shell script linting (install: `brew install shellcheck`)

---

## 🤝 Contributing

When adding new tests:

1. Follow existing test patterns
2. Use descriptive test names
3. Add proper error messages
4. Update this README
5. Test on clean system before committing

---

**Last Updated**: 2026-01-30
**Version**: 1.0
**Maintainer**: Clawdbot Ready Team
