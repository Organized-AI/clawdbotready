#!/usr/bin/env bash
#===============================================================================
# OpenClaw VM Setup - Integration Tests
#===============================================================================
# End-to-end integration tests for all setup phases
# Tests complete workflows from Phase 0 through Phase 6
#
# Usage: ./integration-tests.sh [--skip-vm-creation]
#===============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_LOG="${SCRIPT_DIR}/logs/integration-$(date +%Y%m%d_%H%M%S).log"
SKIP_VM_CREATION=false

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#===============================================================================
# Utility Functions
#===============================================================================

log() {
    echo -e "$@" | tee -a "$TEST_LOG"
}

header() {
    log ""
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${CYAN}  $*${NC}"
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

test_phase() {
    local phase_name="$1"
    ((TESTS_RUN++))
    log ""
    log "${BLUE}▸ Testing: $phase_name${NC}"
}

test_pass() {
    ((TESTS_PASSED++))
    log "${GREEN}  ✓ PASS:${NC} $*"
}

test_fail() {
    ((TESTS_FAILED++))
    log "${RED}  ✗ FAIL:${NC} $*"
}

test_info() {
    log "${YELLOW}  ℹ INFO:${NC} $*"
}

cleanup() {
    log ""
    log "${YELLOW}Cleaning up test environment...${NC}"
    # Add cleanup logic here if needed
}

#===============================================================================
# Phase 0 Integration Tests
#===============================================================================

test_phase0_integration() {
    test_phase "Phase 0: Environment Verification (Integration)"

    # Test: Phase 0 exits successfully on valid system
    test_info "Running Phase 0 verification..."
    if "${PROJECT_ROOT}/setup.sh" 0 2>&1 | tee -a "$TEST_LOG"; then
        test_pass "Phase 0 completed without errors"
    else
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            test_info "Phase 0 failed (expected on systems with insufficient resources)"
        else
            test_fail "Phase 0 exited with unexpected code: $exit_code"
        fi
    fi

    # Test: Log file created
    local latest_log=$(ls -t "${PROJECT_ROOT}/logs/setup-"*.log 2>/dev/null | head -1)
    if [[ -n "$latest_log" && -f "$latest_log" ]]; then
        test_pass "Log file created: $(basename "$latest_log")"
    else
        test_fail "No log file created by Phase 0"
    fi

    # Test: Log contains required checks
    if grep -q "macOS\|disk space\|Apple Silicon" "$latest_log" 2>/dev/null; then
        test_pass "Log contains environment checks"
    else
        test_fail "Log missing required environment checks"
    fi
}

#===============================================================================
# Phase 1 Integration Tests
#===============================================================================

test_phase1_integration() {
    test_phase "Phase 1: Lume Installation & VM Creation (Integration)"

    if [[ "$SKIP_VM_CREATION" == "true" ]]; then
        test_info "Skipping VM creation (--skip-vm-creation flag)"
        return
    fi

    # Test: Lume installation check
    test_info "Checking Lume installation status..."
    if command -v lume &>/dev/null; then
        test_pass "Lume is installed: $(lume --version 2>/dev/null || echo 'version unknown')"
    else
        test_info "Lume not installed - Phase 1 would install it"
    fi

    # Test: VM existence check
    local vm_name=$(grep "^VM_NAME=" "${PROJECT_ROOT}/config/settings.env" 2>/dev/null | cut -d= -f2 | tr -d '"')
    if lume list 2>/dev/null | grep -q "$vm_name"; then
        test_pass "VM '$vm_name' exists"
    else
        test_info "VM does not exist - Phase 1 would create it"
    fi

    # Test: VM can be queried
    if lume get "$vm_name" &>/dev/null; then
        local vm_ip=$(lume get "$vm_name" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        if [[ -n "$vm_ip" ]]; then
            test_pass "VM IP retrieved: $vm_ip"
            echo "$vm_ip" > "${PROJECT_ROOT}/.vm_ip"
        else
            test_fail "Could not determine VM IP"
        fi
    else
        test_info "VM not running - cannot test connectivity"
    fi
}

#===============================================================================
# Phase 2 Integration Tests
#===============================================================================

test_phase2_integration() {
    test_phase "Phase 2: SSH Hardening (Integration)"

    # Test: SSH key exists
    local ssh_key="$HOME/.ssh/openclaw_vm_ed25519"
    if [[ -f "$ssh_key" ]]; then
        test_pass "SSH key exists: $ssh_key"

        # Test: Key permissions
        local perms=$(stat -f "%A" "$ssh_key" 2>/dev/null || stat -c "%a" "$ssh_key" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            test_pass "SSH key has correct permissions (600)"
        else
            test_fail "SSH key has incorrect permissions: $perms (should be 600)"
        fi

        # Test: Public key exists
        if [[ -f "${ssh_key}.pub" ]]; then
            test_pass "SSH public key exists"
        else
            test_fail "SSH public key missing"
        fi
    else
        test_info "SSH key not generated yet - Phase 2 would create it"
    fi

    # Test: SSH connectivity (if VM exists)
    if [[ -f "${PROJECT_ROOT}/.vm_ip" ]]; then
        local vm_ip=$(cat "${PROJECT_ROOT}/.vm_ip")
        local vm_user=$(grep "^VM_USER=" "${PROJECT_ROOT}/config/settings.env" 2>/dev/null | cut -d= -f2 | tr -d '"')

        test_info "Testing SSH connectivity to $vm_user@$vm_ip..."
        if ssh -i "$ssh_key" -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
            "${vm_user}@${vm_ip}" "echo 'SSH OK'" &>/dev/null; then
            test_pass "SSH connection successful"
        else
            test_info "SSH connection failed (VM may not be fully configured)"
        fi
    else
        test_info "VM IP not available - skipping SSH test"
    fi
}

#===============================================================================
# Phase 3 Integration Tests
#===============================================================================

test_phase3_integration() {
    test_phase "Phase 3: Host Firewall (Integration)"

    # Test: pf is available
    if command -v pfctl &>/dev/null; then
        test_pass "pf firewall utility available"
    else
        test_fail "pf firewall utility not found"
        return
    fi

    # Test: pf is enabled
    if sudo pfctl -si 2>/dev/null | grep -q "Status: Enabled"; then
        test_pass "pf firewall is enabled"
    else
        test_info "pf firewall is disabled (Phase 3 would enable it)"
    fi

    # Test: OpenClaw anchor exists
    if [[ -f "/etc/pf.anchors/openclaw-vm" ]]; then
        test_pass "Firewall anchor file exists"

        # Test: Anchor contains localhost restriction
        if grep -q "127.0.0.1" /etc/pf.anchors/openclaw-vm; then
            test_pass "Anchor uses localhost-only rules"
        else
            test_fail "Anchor missing localhost restrictions"
        fi
    else
        test_info "Firewall anchor not created yet - Phase 3 would create it"
    fi

    # Test: Anchor loaded in pf.conf
    if sudo pfctl -sr 2>/dev/null | grep -q "openclaw"; then
        test_pass "OpenClaw firewall rules are loaded"
    else
        test_info "OpenClaw rules not loaded yet"
    fi
}

#===============================================================================
# Phase 4 Integration Tests
#===============================================================================

test_phase4_integration() {
    test_phase "Phase 4: Gateway Configuration (Integration)"

    # Test: Gateway token generated
    if [[ -f "${PROJECT_ROOT}/.gateway_token" ]]; then
        test_pass "Gateway auth token exists"

        # Test: Token strength
        local token_length=$(wc -c < "${PROJECT_ROOT}/.gateway_token" | tr -d ' ')
        if [[ $token_length -ge 64 ]]; then
            test_pass "Gateway token is strong (${token_length} chars)"
        else
            test_fail "Gateway token is weak (${token_length} chars, should be ≥64)"
        fi

        # Test: Token permissions
        local token_perms=$(stat -f "%A" "${PROJECT_ROOT}/.gateway_token" 2>/dev/null || stat -c "%a" "${PROJECT_ROOT}/.gateway_token" 2>/dev/null)
        if [[ "$token_perms" == "600" ]]; then
            test_pass "Token file has secure permissions (600)"
        else
            test_fail "Token file has insecure permissions: $token_perms"
        fi
    else
        test_info "Gateway token not generated yet - Phase 4 would create it"
    fi

    # Test: Gateway config in VM (if accessible)
    if [[ -f "${PROJECT_ROOT}/.vm_ip" && -f "$HOME/.ssh/openclaw_vm_ed25519" ]]; then
        local vm_ip=$(cat "${PROJECT_ROOT}/.vm_ip")
        local vm_user=$(grep "^VM_USER=" "${PROJECT_ROOT}/config/settings.env" 2>/dev/null | cut -d= -f2 | tr -d '"')
        local ssh_key="$HOME/.ssh/openclaw_vm_ed25519"

        test_info "Checking Gateway configuration in VM..."
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "[[ -f ~/.openclaw/config.yaml ]]" 2>/dev/null; then
            test_pass "Gateway config file exists in VM"
        else
            test_info "Gateway config not deployed yet"
        fi

        # Test: exec-approvals deployed
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "[[ -f ~/.openclaw/exec-approvals.json ]]" 2>/dev/null; then
            test_pass "exec-approvals.json deployed to VM"
        else
            test_info "exec-approvals not deployed yet"
        fi

        # Test: TLS certificates
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "[[ -f ~/.openclaw/certs/server.crt && -f ~/.openclaw/certs/server.key ]]" 2>/dev/null; then
            test_pass "TLS certificates generated in VM"
        else
            test_info "TLS certificates not generated yet"
        fi
    else
        test_info "VM not accessible - skipping Gateway config tests"
    fi
}

#===============================================================================
# Phase 5 Integration Tests
#===============================================================================

test_phase5_integration() {
    test_phase "Phase 5: Monitoring Setup (Integration)"

    # Test: Host monitoring script
    if [[ -x "${PROJECT_ROOT}/scripts/host-monitor.sh" ]]; then
        test_pass "Host monitoring script exists and is executable"
    else
        test_info "Host monitoring script not created yet - Phase 5 would create it"
    fi

    # Test: VM monitoring (if accessible)
    if [[ -f "${PROJECT_ROOT}/.vm_ip" && -f "$HOME/.ssh/openclaw_vm_ed25519" ]]; then
        local vm_ip=$(cat "${PROJECT_ROOT}/.vm_ip")
        local vm_user=$(grep "^VM_USER=" "${PROJECT_ROOT}/config/settings.env" 2>/dev/null | cut -d= -f2 | tr -d '"')
        local ssh_key="$HOME/.ssh/openclaw_vm_ed25519"

        test_info "Checking VM monitoring setup..."

        # Test: Monitoring directory
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "[[ -d ~/monitoring ]]" 2>/dev/null; then
            test_pass "Monitoring directory exists in VM"
        else
            test_info "Monitoring directory not created yet"
        fi

        # Test: Security monitor script
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "[[ -x ~/monitoring/security-monitor.sh ]]" 2>/dev/null; then
            test_pass "Security monitor script deployed"
        else
            test_info "Security monitor script not deployed yet"
        fi

        # Test: Cron job configured
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "crontab -l 2>/dev/null | grep -q security-monitor" 2>/dev/null; then
            test_pass "Monitoring cron job configured"
        else
            test_info "Monitoring cron job not scheduled yet"
        fi

        # Test: Log files
        if ssh -i "$ssh_key" -o ConnectTimeout=5 "${vm_user}@${vm_ip}" \
            "[[ -f ~/monitoring/alerts.log || -f ~/monitoring/status.log ]]" 2>/dev/null; then
            test_pass "Monitoring log files exist"
        else
            test_info "Monitoring logs not created yet (normal for new deployment)"
        fi
    else
        test_info "VM not accessible - skipping VM monitoring tests"
    fi
}

#===============================================================================
# Phase 6 Integration Tests
#===============================================================================

test_phase6_integration() {
    test_phase "Phase 6: Backup Configuration (Integration)"

    # Test: Backup script exists
    if [[ -x "${PROJECT_ROOT}/scripts/backup-vm.sh" ]]; then
        test_pass "Backup script exists and is executable"

        # Test: Script contains required functionality
        if grep -q "lume snapshot\|tar czf" "${PROJECT_ROOT}/scripts/backup-vm.sh"; then
            test_pass "Backup script has VM snapshot and config backup logic"
        else
            test_fail "Backup script missing expected functionality"
        fi
    else
        test_info "Backup script not created yet - Phase 6 would create it"
    fi

    # Test: Restore script exists
    if [[ -x "${PROJECT_ROOT}/scripts/restore-vm.sh" ]]; then
        test_pass "Restore script exists and is executable"
    else
        test_info "Restore script not created yet - Phase 6 would create it"
    fi

    # Test: Backup directory
    if [[ -d "${PROJECT_ROOT}/backups" ]]; then
        test_pass "Backup directory exists"

        # Test: Check for existing backups
        local backup_count=$(ls -1 "${PROJECT_ROOT}/backups/"*.tar.gz 2>/dev/null | wc -l)
        if [[ $backup_count -gt 0 ]]; then
            test_pass "Found $backup_count existing backup(s)"
        else
            test_info "No backups yet (run backup script to create first backup)"
        fi
    else
        test_info "Backup directory not created yet"
    fi

    # Test: Backup retention logic
    if [[ -f "${PROJECT_ROOT}/scripts/backup-vm.sh" ]]; then
        if grep -q "tail -n +8\|ls -t.*| tail\|RETENTION" "${PROJECT_ROOT}/scripts/backup-vm.sh"; then
            test_pass "Backup retention policy implemented"
        else
            test_fail "No backup retention logic found"
        fi
    fi
}

#===============================================================================
# End-to-End Workflow Tests
#===============================================================================

test_e2e_workflow() {
    header "End-to-End Workflow Tests"

    # Test: Complete setup flow (config → scripts → VM)
    test_info "Verifying complete setup workflow..."

    local workflow_complete=true

    # Step 1: Configuration
    if [[ ! -f "${PROJECT_ROOT}/config/settings.env" ]]; then
        test_fail "Missing config/settings.env"
        workflow_complete=false
    fi

    if [[ ! -f "${PROJECT_ROOT}/config/exec-approvals.json" ]]; then
        test_fail "Missing config/exec-approvals.json"
        workflow_complete=false
    fi

    # Step 2: Main setup script
    if [[ ! -x "${PROJECT_ROOT}/setup.sh" ]]; then
        test_fail "Missing or non-executable setup.sh"
        workflow_complete=false
    fi

    # Step 3: Helper scripts
    local required_scripts=(
        "scripts/connect.sh"
        "scripts/tunnel.sh"
        "scripts/status.sh"
        "scripts/emergency-stop.sh"
        "scripts/restart-vm.sh"
    )

    for script in "${required_scripts[@]}"; do
        if [[ ! -x "${PROJECT_ROOT}/${script}" ]]; then
            test_fail "Missing or non-executable: $script"
            workflow_complete=false
        fi
    done

    if [[ "$workflow_complete" == "true" ]]; then
        test_pass "All required components present"
    else
        test_fail "Workflow incomplete - missing components"
    fi

    # Test: Documentation is accessible
    if [[ -f "${PROJECT_ROOT}/README.md" ]]; then
        test_pass "README.md exists"
    else
        test_fail "README.md missing"
    fi

    if [[ -f "${PROJECT_ROOT}/HARDENING-GUIDE.md" ]]; then
        test_pass "HARDENING-GUIDE.md exists"
    else
        test_info "HARDENING-GUIDE.md not present"
    fi
}

#===============================================================================
# Helper Script Tests
#===============================================================================

test_helper_scripts() {
    header "Helper Script Tests"

    # Test: connect.sh
    test_info "Testing connect.sh..."
    if [[ -x "${PROJECT_ROOT}/scripts/connect.sh" ]]; then
        if grep -q "ssh.*openclaw" "${PROJECT_ROOT}/scripts/connect.sh"; then
            test_pass "connect.sh has SSH connection logic"
        else
            test_fail "connect.sh missing SSH logic"
        fi
    fi

    # Test: tunnel.sh
    test_info "Testing tunnel.sh..."
    if [[ -x "${PROJECT_ROOT}/scripts/tunnel.sh" ]]; then
        if grep -q "8080:127.0.0.1:8080" "${PROJECT_ROOT}/scripts/tunnel.sh"; then
            test_pass "tunnel.sh creates Gateway tunnel"
        else
            test_fail "tunnel.sh missing tunnel logic"
        fi
    fi

    # Test: status.sh
    test_info "Testing status.sh..."
    if [[ -x "${PROJECT_ROOT}/scripts/status.sh" ]]; then
        if grep -q "lume.*get\|ping" "${PROJECT_ROOT}/scripts/status.sh"; then
            test_pass "status.sh checks VM health"
        else
            test_fail "status.sh missing health check logic"
        fi
    fi

    # Test: emergency-stop.sh
    test_info "Testing emergency-stop.sh..."
    if [[ -x "${PROJECT_ROOT}/scripts/emergency-stop.sh" ]]; then
        if grep -q "lume.*stop\|kill" "${PROJECT_ROOT}/scripts/emergency-stop.sh"; then
            test_pass "emergency-stop.sh has VM shutdown logic"
        else
            test_fail "emergency-stop.sh missing shutdown logic"
        fi
    fi
}

#===============================================================================
# Test Summary
#===============================================================================

print_summary() {
    header "Integration Test Summary"

    log ""
    log "  Total Tests:   $TESTS_RUN"
    log "  ${GREEN}Passed:        $TESTS_PASSED${NC}"
    log "  ${RED}Failed:        $TESTS_FAILED${NC}"
    log ""
    log "  Test Log:      $TEST_LOG"
    log ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log "${GREEN}✓ All integration tests passed!${NC}"
        log ""
        return 0
    else
        log "${RED}✗ Some integration tests failed.${NC}"
        log "${YELLOW}  Review the test log for details.${NC}"
        log ""
        return 1
    fi
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --skip-vm-creation)
                SKIP_VM_CREATION=true
                ;;
        esac
    done

    # Create log directory
    mkdir -p "$(dirname "$TEST_LOG")"

    header "OpenClaw VM Setup - Integration Tests"
    log ""
    log "  Test Suite:     Integration"
    log "  Date:           $(date '+%Y-%m-%d %H:%M:%S')"
    log "  Platform:       $(uname) $(uname -m)"
    log "  Skip VM Create: $SKIP_VM_CREATION"
    log ""

    # Run integration tests for all phases
    test_phase0_integration
    test_phase1_integration
    test_phase2_integration
    test_phase3_integration
    test_phase4_integration
    test_phase5_integration
    test_phase6_integration

    # Run workflow tests
    test_e2e_workflow
    test_helper_scripts

    # Print summary
    print_summary
    exit_code=$?

    exit $exit_code
}

# Set trap for cleanup
trap cleanup EXIT

# Run tests
main "$@"
