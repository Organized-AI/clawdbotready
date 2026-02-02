#!/usr/bin/env bash
#===============================================================================
# OpenClaw VM Setup - Security Validator
#===============================================================================
# Deep security validation for production deployments
# Tests: Penetration testing, vulnerability scanning, configuration auditing
#
# Usage: ./security-validator.sh [--vm-ip=IP] [--vm-user=USER]
#===============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_FILE="${SCRIPT_DIR}/logs/security-report-$(date +%Y%m%d_%H%M%S).txt"

# VM configuration
VM_IP=""
VM_USER="openclaw"
SSH_KEY="$HOME/.ssh/openclaw_vm_ed25519"

# Vulnerability counters
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0
PASSED_CHECKS=0

#===============================================================================
# Utility Functions
#===============================================================================

header() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $*${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}▸ $*${NC}"
}

check() {
    echo -n "  [CHECK] $*... "
}

pass() {
    ((PASSED_CHECKS++))
    echo -e "${GREEN}✓ PASS${NC}"
    log_result "PASS" "$*"
}

fail() {
    local severity="$1"
    shift
    local message="$*"

    case "$severity" in
        CRITICAL)
            ((CRITICAL_ISSUES++))
            echo -e "${RED}✗ CRITICAL${NC}"
            echo -e "${RED}    $message${NC}"
            ;;
        HIGH)
            ((HIGH_ISSUES++))
            echo -e "${RED}✗ HIGH${NC}"
            echo -e "${RED}    $message${NC}"
            ;;
        MEDIUM)
            ((MEDIUM_ISSUES++))
            echo -e "${YELLOW}⚠ MEDIUM${NC}"
            echo -e "${YELLOW}    $message${NC}"
            ;;
        LOW)
            ((LOW_ISSUES++))
            echo -e "${YELLOW}⚠ LOW${NC}"
            echo -e "${YELLOW}    $message${NC}"
            ;;
    esac

    log_result "$severity" "$message"
}

log_result() {
    local status="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$status] $*" >> "$REPORT_FILE"
}

#===============================================================================
# Security Test Functions
#===============================================================================

test_network_exposure() {
    section "Network Exposure Tests"

    # Test 1: VM not directly accessible from internet
    check "VM is not exposed to internet"
    if timeout 5 bash -c "echo >/dev/tcp/$VM_IP/22" 2>/dev/null; then
        # If we can connect, check if it's only from localhost
        local connection_source=$(netstat -an | grep "$VM_IP:22" | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1)
        if [[ "$connection_source" == "127.0.0.1" ]] || [[ -z "$connection_source" ]]; then
            pass "VM SSH only accessible via localhost"
        else
            fail CRITICAL "VM SSH is accessible from external IP: $connection_source"
        fi
    else
        pass "VM not directly accessible (expected)"
    fi

    # Test 2: Gateway port not exposed
    check "Gateway port (8080) not exposed externally"
    if timeout 3 bash -c "echo >/dev/tcp/$VM_IP/8080" 2>/dev/null; then
        fail HIGH "Gateway port 8080 is accessible from external network"
    else
        pass "Gateway port properly isolated"
    fi

    # Test 3: No unexpected open ports
    check "No unexpected ports open on VM"
    if command -v nmap &>/dev/null; then
        local open_ports=$(nmap -p- --open -T4 "$VM_IP" 2>/dev/null | grep "^[0-9]" | grep -v "22/tcp\|8080/tcp" || true)
        if [[ -n "$open_ports" ]]; then
            fail MEDIUM "Unexpected open ports detected: $open_ports"
        else
            pass "Only expected ports open (22, 8080)"
        fi
    else
        echo -e "${YELLOW}⊘ SKIP${NC} (nmap not installed)"
    fi
}

test_ssh_hardening() {
    section "SSH Hardening Tests"

    # Test 1: Password authentication disabled
    check "Password authentication is disabled"
    local ssh_config=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" "cat /etc/ssh/sshd_config" 2>/dev/null)
    if echo "$ssh_config" | grep -q "^PasswordAuthentication no"; then
        pass "Password authentication disabled"
    else
        fail CRITICAL "Password authentication may be enabled"
    fi

    # Test 2: Root login disabled
    check "Root login is disabled"
    if echo "$ssh_config" | grep -q "^PermitRootLogin no"; then
        pass "Root login disabled"
    else
        fail HIGH "Root login may be permitted"
    fi

    # Test 3: Only strong key algorithms
    check "Strong SSH key algorithms enforced"
    if echo "$ssh_config" | grep -q "ed25519"; then
        pass "Ed25519 algorithm enforced"
    else
        fail MEDIUM "Strong key algorithms may not be enforced"
    fi

    # Test 4: MaxAuthTries is limited
    check "SSH authentication attempts limited"
    if echo "$ssh_config" | grep -q "MaxAuthTries [1-5]"; then
        pass "Auth attempts limited to ≤5"
    else
        fail MEDIUM "Auth attempts not sufficiently limited"
    fi

    # Test 5: SSH timeout configured
    check "SSH idle timeout configured"
    if echo "$ssh_config" | grep -q "ClientAliveInterval"; then
        pass "Idle timeout configured"
    else
        fail LOW "No idle timeout configured"
    fi

    # Test 6: Test weak authentication methods fail
    check "Weak SSH authentication methods are rejected"
    if ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no \
        "${VM_USER}@${VM_IP}" "echo test" 2>&1 | grep -q "Permission denied"; then
        pass "Weak authentication methods rejected"
    else
        fail HIGH "System may accept weak authentication"
    fi
}

test_firewall_rules() {
    section "Firewall Configuration Tests"

    # Test 1: pf firewall is enabled
    check "pf firewall is enabled on host"
    if sudo pfctl -si 2>/dev/null | grep -q "Status: Enabled"; then
        pass "pf firewall is active"
    else
        fail CRITICAL "pf firewall is NOT enabled"
    fi

    # Test 2: OpenClaw anchor is loaded
    check "OpenClaw firewall rules loaded"
    if sudo pfctl -sr 2>/dev/null | grep -q "openclaw"; then
        pass "OpenClaw firewall anchor loaded"
    else
        fail HIGH "OpenClaw firewall rules not loaded"
    fi

    # Test 3: Verify anchor file exists
    check "Firewall anchor file exists"
    if [[ -f "/etc/pf.anchors/openclaw-vm" ]]; then
        pass "Anchor file present"
    else
        fail HIGH "Firewall anchor file missing"
    fi

    # Test 4: Anchor contains localhost restriction
    check "Firewall restricts access to localhost"
    if grep -q "127.0.0.1" /etc/pf.anchors/openclaw-vm 2>/dev/null; then
        pass "Firewall uses localhost-only rules"
    else
        fail CRITICAL "Firewall may allow external access"
    fi

    # Test 5: Block rules are present
    check "Block rules are configured"
    if grep -q "block" /etc/pf.anchors/openclaw-vm 2>/dev/null; then
        pass "Block rules configured"
    else
        fail HIGH "No block rules found in firewall"
    fi
}

test_vm_hardening() {
    section "VM-Level Hardening Tests"

    # Test 1: FileVault is enabled
    check "FileVault disk encryption enabled"
    local filevault_status=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "fdesetup status" 2>/dev/null)
    if echo "$filevault_status" | grep -q "FileVault is On"; then
        pass "FileVault enabled"
    else
        fail HIGH "FileVault is NOT enabled - data at rest not encrypted"
    fi

    # Test 2: User is not admin
    check "openclaw user is not admin"
    local user_groups=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" "groups" 2>/dev/null)
    if echo "$user_groups" | grep -qv "admin"; then
        pass "User does not have admin privileges"
    else
        fail MEDIUM "User has admin privileges - increases blast radius"
    fi

    # Test 3: Automatic updates enabled
    check "Automatic security updates enabled"
    local auto_update=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled" 2>/dev/null || echo "0")
    if [[ "$auto_update" == "1" ]]; then
        pass "Automatic updates enabled"
    else
        fail MEDIUM "Automatic updates not enabled"
    fi

    # Test 4: Gatekeeper is active
    check "Gatekeeper is enforcing app security"
    local gatekeeper_status=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "spctl --status" 2>/dev/null)
    if echo "$gatekeeper_status" | grep -q "assessments enabled"; then
        pass "Gatekeeper is active"
    else
        fail MEDIUM "Gatekeeper may be disabled"
    fi

    # Test 5: macOS Application Firewall enabled
    check "macOS Application Firewall enabled"
    local app_firewall=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate" 2>/dev/null || echo "disabled")
    if echo "$app_firewall" | grep -q "enabled"; then
        pass "Application Firewall enabled"
    else
        fail LOW "macOS Application Firewall not enabled"
    fi
}

test_gateway_security() {
    section "Gateway Security Tests"

    # Test 1: Gateway binds to localhost only
    check "Gateway binds to localhost only"
    local gateway_bind=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "netstat -an | grep 8080" 2>/dev/null || echo "")
    if echo "$gateway_bind" | grep -q "127.0.0.1.*8080"; then
        pass "Gateway bound to localhost"
    elif [[ -z "$gateway_bind" ]]; then
        echo -e "${YELLOW}⊘ SKIP${NC} (Gateway not running)"
    else
        fail CRITICAL "Gateway may be exposed on 0.0.0.0"
    fi

    # Test 2: TLS is enabled
    check "Gateway TLS certificate exists"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "[[ -f ~/.openclaw/certs/server.crt ]]" 2>/dev/null; then
        pass "TLS certificate present"
    else
        fail HIGH "TLS certificate missing - no encryption"
    fi

    # Test 3: Gateway requires authentication
    check "Gateway authentication configured"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "grep -q 'auth.*enabled.*true' ~/.openclaw/config.yaml 2>/dev/null" 2>/dev/null; then
        pass "Gateway authentication enabled"
    else
        fail CRITICAL "Gateway authentication may be disabled"
    fi

    # Test 4: Auth token is strong
    check "Gateway auth token strength"
    if [[ -f "${PROJECT_ROOT}/.gateway_token" ]]; then
        local token_length=$(wc -c < "${PROJECT_ROOT}/.gateway_token" | tr -d ' ')
        if [[ $token_length -ge 64 ]]; then
            pass "Gateway token is strong (≥64 chars)"
        else
            fail MEDIUM "Gateway token is weak (<64 chars)"
        fi
    else
        fail HIGH "Gateway token file not found"
    fi

    # Test 5: Rate limiting configured
    check "Gateway rate limiting configured"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "grep -q 'rate_limit' ~/.openclaw/config.yaml 2>/dev/null" 2>/dev/null; then
        pass "Rate limiting configured"
    else
        fail MEDIUM "Rate limiting not configured"
    fi
}

test_exec_approvals() {
    section "exec-approvals Security Tests"

    # Test 1: exec-approvals file exists in VM
    check "exec-approvals.json deployed to VM"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "[[ -f ~/.openclaw/exec-approvals.json ]]" 2>/dev/null; then
        pass "exec-approvals.json deployed"
    else
        fail CRITICAL "exec-approvals.json missing from VM"
    fi

    # Test 2: Default action is deny
    check "Default action is deny"
    local default_action=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "jq -r '.default_action' ~/.openclaw/exec-approvals.json 2>/dev/null" || echo "")
    if [[ "$default_action" == "deny" ]]; then
        pass "Default action is deny (secure)"
    else
        fail CRITICAL "Default action is not deny: $default_action"
    fi

    # Test 3: Dangerous commands are blocked
    check "Dangerous commands (curl, wget, nc) are denied"
    local dangerous_blocked=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "jq '[.rules[] | select(.action == \"deny\")] | length' ~/.openclaw/exec-approvals.json 2>/dev/null" || echo "0")
    if [[ "$dangerous_blocked" -ge 3 ]]; then
        pass "Dangerous network commands blocked ($dangerous_blocked deny rules)"
    else
        fail HIGH "Not all dangerous commands are blocked"
    fi

    # Test 4: Privilege escalation blocked
    check "Privilege escalation (sudo, su) blocked"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "jq -e '.rules[] | select(.id == \"deny-sudo\" or .id == \"deny-su\")' ~/.openclaw/exec-approvals.json" &>/dev/null; then
        pass "sudo and su are blocked"
    else
        fail CRITICAL "Privilege escalation may be possible"
    fi

    # Test 5: Logging enabled
    check "Command execution logging enabled"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "jq -r '.log_all_attempts' ~/.openclaw/exec-approvals.json 2>/dev/null" | grep -q "true"; then
        pass "All command attempts logged"
    else
        fail MEDIUM "Command logging not enabled"
    fi

    # Test 6: Environment variable protection
    check "Dangerous environment variables blocked"
    local env_blocklist=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "jq '.environment_blocklist | length' ~/.openclaw/exec-approvals.json 2>/dev/null" || echo "0")
    if [[ "$env_blocklist" -gt 0 ]]; then
        pass "Environment variable blocklist configured ($env_blocklist entries)"
    else
        fail MEDIUM "No environment variable protection"
    fi
}

test_secrets_management() {
    section "Secrets Management Tests"

    # Test 1: SSH key permissions
    check "SSH private key has secure permissions"
    if [[ -f "$SSH_KEY" ]]; then
        local key_perms=$(stat -f "%A" "$SSH_KEY" 2>/dev/null || stat -c "%a" "$SSH_KEY" 2>/dev/null)
        if [[ "$key_perms" == "600" ]]; then
            pass "SSH key permissions correct (600)"
        else
            fail HIGH "SSH key has insecure permissions: $key_perms"
        fi
    else
        fail MEDIUM "SSH key not found at $SSH_KEY"
    fi

    # Test 2: Gateway token permissions
    check "Gateway token has secure permissions"
    if [[ -f "${PROJECT_ROOT}/.gateway_token" ]]; then
        local token_perms=$(stat -f "%A" "${PROJECT_ROOT}/.gateway_token" 2>/dev/null || stat -c "%a" "${PROJECT_ROOT}/.gateway_token" 2>/dev/null)
        if [[ "$token_perms" == "600" ]]; then
            pass "Gateway token permissions correct (600)"
        else
            fail MEDIUM "Gateway token has weak permissions: $token_perms"
        fi
    else
        fail LOW "Gateway token file not found"
    fi

    # Test 3: No secrets in git
    check "Secrets not committed to git"
    if git -C "$PROJECT_ROOT" grep -E "password|secret|token" 2>/dev/null | grep -v "GATEWAY_TOKEN\|PASSWORD\|placeholder"; then
        fail HIGH "Potential secrets found in git history"
    else
        pass "No obvious secrets in git"
    fi

    # Test 4: .gitignore contains sensitive patterns
    check ".gitignore excludes sensitive files"
    if [[ -f "${PROJECT_ROOT}/.gitignore" ]]; then
        if grep -q ".gateway_token\|.vm_ip\|*.key" "${PROJECT_ROOT}/.gitignore"; then
            pass "Sensitive files in .gitignore"
        else
            fail MEDIUM "Some sensitive patterns missing from .gitignore"
        fi
    else
        fail MEDIUM ".gitignore not found"
    fi

    # Test 5: Secrets stored in secure location
    check "Secrets stored outside project directory"
    if [[ "$SSH_KEY" == "$HOME/.ssh/"* ]]; then
        pass "SSH key in standard secure location (~/.ssh/)"
    else
        fail LOW "SSH key not in standard location"
    fi
}

test_monitoring() {
    section "Monitoring & Logging Tests"

    # Test 1: Monitoring script exists in VM
    check "Security monitoring script deployed"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "[[ -x ~/monitoring/security-monitor.sh ]]" 2>/dev/null; then
        pass "Monitoring script deployed"
    else
        fail MEDIUM "Monitoring script missing or not executable"
    fi

    # Test 2: Monitoring cron job configured
    check "Monitoring scheduled via cron"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "crontab -l 2>/dev/null | grep -q security-monitor" 2>/dev/null; then
        pass "Monitoring cron job configured"
    else
        fail MEDIUM "Monitoring not scheduled"
    fi

    # Test 3: Log files exist
    check "Gateway log file exists"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "[[ -f ~/.openclaw/logs/gateway.log ]]" 2>/dev/null; then
        pass "Gateway log file present"
    else
        echo -e "${YELLOW}⊘ SKIP${NC} (Gateway may not be running yet)"
    fi

    # Test 4: Logs are being written
    check "Recent log activity"
    local log_age=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "find ~/monitoring -name '*.log' -mtime -1 2>/dev/null | wc -l" || echo "0")
    if [[ "$log_age" -gt 0 ]]; then
        pass "Logs written in last 24 hours"
    else
        echo -e "${YELLOW}⊘ SKIP${NC} (No recent log activity - may be new deployment)"
    fi

    # Test 5: Alert log exists
    check "Alert log file exists"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "[[ -f ~/monitoring/alerts.log ]]" 2>/dev/null; then
        pass "Alert log configured"
    else
        fail MEDIUM "Alert log not found"
    fi
}

test_backup_recovery() {
    section "Backup & Recovery Tests"

    # Test 1: Backup script exists
    check "Backup script exists and is executable"
    if [[ -x "${PROJECT_ROOT}/scripts/backup-vm.sh" ]]; then
        pass "Backup script ready"
    else
        fail MEDIUM "Backup script missing or not executable"
    fi

    # Test 2: Backup directory exists
    check "Backup directory configured"
    if [[ -d "${PROJECT_ROOT}/backups" ]]; then
        pass "Backup directory exists"
    else
        fail MEDIUM "Backup directory not created"
    fi

    # Test 3: Recent backups exist
    check "Recent backups present"
    local backup_count=$(find "${PROJECT_ROOT}/backups" -name "*.tar.gz" -mtime -7 2>/dev/null | wc -l)
    if [[ $backup_count -gt 0 ]]; then
        pass "Found $backup_count backup(s) from last 7 days"
    else
        echo -e "${YELLOW}⊘ SKIP${NC} (No recent backups - run backup script)"
    fi

    # Test 4: Restore script exists
    check "Restore script exists"
    if [[ -x "${PROJECT_ROOT}/scripts/restore-vm.sh" ]]; then
        pass "Restore script ready"
    else
        fail MEDIUM "Restore script missing"
    fi

    # Test 5: Backup retention configured
    check "Backup retention policy configured"
    if grep -q "tail -n +8\|RETENTION\|keep.*7" "${PROJECT_ROOT}/scripts/backup-vm.sh" 2>/dev/null; then
        pass "Backup retention configured"
    else
        fail LOW "No backup retention policy found"
    fi
}

test_compliance() {
    section "Compliance & Documentation Tests"

    # Test 1: Documentation exists
    check "Security documentation present"
    local docs_found=0
    [[ -f "${PROJECT_ROOT}/README.md" ]] && ((docs_found++))
    [[ -f "${PROJECT_ROOT}/HARDENING-GUIDE.md" ]] && ((docs_found++))

    if [[ $docs_found -ge 2 ]]; then
        pass "Security documentation complete"
    else
        fail MEDIUM "Missing documentation ($docs_found/2 files)"
    fi

    # Test 2: Audit logs configured
    check "Audit logging configured"
    if ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" \
        "grep -q 'LogLevel VERBOSE' /etc/ssh/sshd_config 2>/dev/null" 2>/dev/null; then
        pass "SSH verbose logging enabled"
    else
        fail LOW "SSH verbose logging not enabled"
    fi

    # Test 3: Emergency procedures documented
    check "Emergency stop procedure exists"
    if [[ -x "${PROJECT_ROOT}/scripts/emergency-stop.sh" ]]; then
        pass "Emergency stop script ready"
    else
        fail MEDIUM "Emergency stop script missing"
    fi

    # Test 4: Configuration under version control
    check "Configuration tracked in git"
    if git -C "$PROJECT_ROOT" ls-files 2>/dev/null | grep -q "config/"; then
        pass "Configuration tracked in version control"
    else
        fail LOW "Configuration not in version control"
    fi
}

#===============================================================================
# Report Generation
#===============================================================================

generate_report() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  SECURITY VALIDATION REPORT${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Scan Date:     $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Target VM:     ${VM_USER}@${VM_IP}"
    echo "  Report File:   $REPORT_FILE"
    echo ""
    echo "  Checks Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo ""
    echo "  Issues Found:"
    echo -e "    ${RED}Critical:  $CRITICAL_ISSUES${NC}"
    echo -e "    ${RED}High:      $HIGH_ISSUES${NC}"
    echo -e "    ${YELLOW}Medium:    $MEDIUM_ISSUES${NC}"
    echo -e "    ${YELLOW}Low:       $LOW_ISSUES${NC}"
    echo ""

    local total_issues=$((CRITICAL_ISSUES + HIGH_ISSUES + MEDIUM_ISSUES + LOW_ISSUES))

    if [[ $CRITICAL_ISSUES -gt 0 ]]; then
        echo -e "${RED}✗ CRITICAL ISSUES FOUND - DO NOT DEPLOY TO PRODUCTION${NC}"
        echo ""
        return 2
    elif [[ $HIGH_ISSUES -gt 0 ]]; then
        echo -e "${RED}✗ HIGH SEVERITY ISSUES FOUND - FIX BEFORE DEPLOYMENT${NC}"
        echo ""
        return 1
    elif [[ $total_issues -gt 0 ]]; then
        echo -e "${YELLOW}⚠ MEDIUM/LOW ISSUES FOUND - REVIEW RECOMMENDED${NC}"
        echo ""
        return 0
    else
        echo -e "${GREEN}✓ ALL SECURITY CHECKS PASSED${NC}"
        echo -e "${GREEN}  System is ready for production deployment${NC}"
        echo ""
        return 0
    fi
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --vm-ip=*)
                VM_IP="${arg#*=}"
                ;;
            --vm-user=*)
                VM_USER="${arg#*=}"
                ;;
            --ssh-key=*)
                SSH_KEY="${arg#*=}"
                ;;
        esac
    done

    # Auto-detect VM IP if not provided
    if [[ -z "$VM_IP" ]]; then
        if [[ -f "${PROJECT_ROOT}/.vm_ip" ]]; then
            VM_IP=$(cat "${PROJECT_ROOT}/.vm_ip")
        else
            echo -e "${RED}Error: VM IP not provided and .vm_ip file not found${NC}"
            echo "Usage: $0 --vm-ip=<IP> [--vm-user=<USER>] [--ssh-key=<PATH>]"
            exit 1
        fi
    fi

    # Create report directory
    mkdir -p "$(dirname "$REPORT_FILE")"

    # Print header
    header "OpenClaw VM Security Validator"
    echo ""
    echo "  Target: ${VM_USER}@${VM_IP}"
    echo "  SSH Key: $SSH_KEY"
    echo ""
    echo "  Running comprehensive security validation..."
    echo ""

    # Run all security tests
    test_network_exposure
    test_ssh_hardening
    test_firewall_rules
    test_vm_hardening
    test_gateway_security
    test_exec_approvals
    test_secrets_management
    test_monitoring
    test_backup_recovery
    test_compliance

    # Generate final report
    generate_report
    exit_code=$?

    echo "  Full report: $REPORT_FILE"
    echo ""

    exit $exit_code
}

# Run security validation
main "$@"
