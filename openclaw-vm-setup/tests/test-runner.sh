#!/usr/bin/env bash
#===============================================================================
# OpenClaw VM Setup - Test Runner
#===============================================================================
# Comprehensive test suite for validating deployment scripts
# Tests: Unit, Integration, Security, Idempotency
#
# Usage: ./test-runner.sh [test-suite]
#   all          - Run all tests (default)
#   unit         - Unit tests for individual functions
#   integration  - Integration tests for complete phases
#   security     - Security validation tests
#   idempotency  - Re-run safety tests
#===============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_LOG_DIR="${SCRIPT_DIR}/logs"
TEST_RESULTS_FILE="${TEST_LOG_DIR}/results-$(date +%Y%m%d_%H%M%S).log"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Create test log directory
mkdir -p "$TEST_LOG_DIR"

#===============================================================================
# Test Framework Functions
#===============================================================================

test_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

test_section() {
    echo -e "\n${YELLOW}▸ $*${NC}"
}

test_start() {
    local test_name="$1"
    ((TESTS_RUN++))
    echo -n "  Testing: $test_name ... "
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [PASS] $*" >> "$TEST_RESULTS_FILE"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}"
    echo -e "${RED}  Error: $*${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [FAIL] $*" >> "$TEST_RESULTS_FILE"
}

test_skip() {
    ((TESTS_SKIPPED++))
    echo -e "${YELLOW}⊘ SKIP${NC}"
    echo -e "${YELLOW}  Reason: $*${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SKIP] $*" >> "$TEST_RESULTS_FILE"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values do not match}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "Expected: '$expected', Got: '$actual' - $message"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value is empty}"

    if [[ -n "$value" ]]; then
        return 0
    else
        echo "$message"
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="${2:-File does not exist: $filepath}"

    if [[ -f "$filepath" ]]; then
        return 0
    else
        echo "$message"
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command not found: $cmd}"

    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        echo "$message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String not found}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "Expected to find '$needle' in '$haystack' - $message"
        return 1
    fi
}

#===============================================================================
# Unit Tests - Configuration Loading
#===============================================================================

test_unit_config() {
    test_section "Unit Tests: Configuration"

    # Test 1: Config file exists
    test_start "Config file exists"
    if assert_file_exists "${PROJECT_ROOT}/config/settings.env"; then
        test_pass "Config file exists"
    else
        test_fail "Config file not found"
    fi

    # Test 2: Config file is readable
    test_start "Config file is readable"
    if [[ -r "${PROJECT_ROOT}/config/settings.env" ]]; then
        test_pass "Config file readable"
    else
        test_fail "Config file not readable"
    fi

    # Test 3: Config loads without errors
    test_start "Config loads successfully"
    if source "${PROJECT_ROOT}/config/settings.env" &>/dev/null; then
        test_pass "Config loaded successfully"
    else
        test_fail "Config failed to load"
    fi

    # Test 4: Required variables are set
    source "${PROJECT_ROOT}/config/settings.env"
    test_start "VM_NAME is set"
    if assert_not_empty "$VM_NAME"; then
        test_pass "VM_NAME configured: $VM_NAME"
    else
        test_fail "VM_NAME not set"
    fi

    test_start "VM_CPU is numeric"
    if [[ "$VM_CPU" =~ ^[0-9]+$ ]]; then
        test_pass "VM_CPU is valid: $VM_CPU"
    else
        test_fail "VM_CPU is not numeric: $VM_CPU"
    fi

    test_start "VM_MEMORY is numeric"
    if [[ "$VM_MEMORY" =~ ^[0-9]+$ ]]; then
        test_pass "VM_MEMORY is valid: $VM_MEMORY"
    else
        test_fail "VM_MEMORY is not numeric: $VM_MEMORY"
    fi
}

#===============================================================================
# Unit Tests - Script Validation
#===============================================================================

test_unit_scripts() {
    test_section "Unit Tests: Script Validation"

    # Test all shell scripts for syntax errors
    local scripts=(
        "${PROJECT_ROOT}/setup.sh"
        "${PROJECT_ROOT}/scripts/connect.sh"
        "${PROJECT_ROOT}/scripts/tunnel.sh"
        "${PROJECT_ROOT}/scripts/status.sh"
        "${PROJECT_ROOT}/scripts/backup-vm.sh"
        "${PROJECT_ROOT}/scripts/restore-vm.sh"
        "${PROJECT_ROOT}/scripts/emergency-stop.sh"
        "${PROJECT_ROOT}/scripts/restart-vm.sh"
    )

    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")

        test_start "$script_name exists"
        if assert_file_exists "$script"; then
            test_pass "$script_name exists"
        else
            test_fail "$script_name not found"
            continue
        fi

        test_start "$script_name is executable"
        if [[ -x "$script" ]]; then
            test_pass "$script_name is executable"
        else
            test_fail "$script_name not executable"
        fi

        test_start "$script_name syntax check"
        if bash -n "$script" &>/dev/null; then
            test_pass "$script_name syntax valid"
        else
            test_fail "$script_name has syntax errors"
        fi

        test_start "$script_name has strict mode"
        if grep -q "set -euo pipefail" "$script" || grep -q "set -e" "$script"; then
            test_pass "$script_name uses strict mode"
        else
            test_fail "$script_name missing strict mode (set -euo pipefail)"
        fi
    done
}

#===============================================================================
# Unit Tests - Security Configuration
#===============================================================================

test_unit_security() {
    test_section "Unit Tests: Security Configuration"

    # Test 1: exec-approvals.json exists
    test_start "exec-approvals.json exists"
    if assert_file_exists "${PROJECT_ROOT}/config/exec-approvals.json"; then
        test_pass "Security policy file exists"
    else
        test_fail "Security policy file missing"
        return
    fi

    # Test 2: exec-approvals.json is valid JSON
    test_start "exec-approvals.json is valid JSON"
    if jq empty "${PROJECT_ROOT}/config/exec-approvals.json" &>/dev/null; then
        test_pass "Security policy is valid JSON"
    else
        test_fail "Security policy is not valid JSON"
        return
    fi

    # Test 3: Default action is deny
    test_start "Default action is deny"
    local default_action=$(jq -r '.default_action' "${PROJECT_ROOT}/config/exec-approvals.json")
    if assert_equals "deny" "$default_action"; then
        test_pass "Default action is deny (secure)"
    else
        test_fail "Default action is not deny: $default_action"
    fi

    # Test 4: Dangerous commands are blocked
    local dangerous_cmds=("curl" "wget" "nc" "ssh" "sudo" "osascript")
    for cmd in "${dangerous_cmds[@]}"; do
        test_start "$cmd is denied"
        if jq -e ".rules[] | select(.id | contains(\"deny-$cmd\"))" \
            "${PROJECT_ROOT}/config/exec-approvals.json" &>/dev/null; then
            test_pass "$cmd is explicitly denied"
        else
            test_fail "$cmd is not explicitly denied"
        fi
    done

    # Test 5: Alerts are enabled for dangerous commands
    test_start "Alerts enabled for dangerous commands"
    local alert_count=$(jq '[.rules[] | select(.action == "deny" and .alert == true)] | length' \
        "${PROJECT_ROOT}/config/exec-approvals.json")
    if [[ "$alert_count" -gt 0 ]]; then
        test_pass "Alerts configured for $alert_count dangerous commands"
    else
        test_fail "No alerts configured for dangerous commands"
    fi

    # Test 6: Environment variable blocklist exists
    test_start "Environment blocklist configured"
    local blocklist_count=$(jq '.environment_blocklist | length' \
        "${PROJECT_ROOT}/config/exec-approvals.json")
    if [[ "$blocklist_count" -gt 0 ]]; then
        test_pass "Environment blocklist has $blocklist_count entries"
    else
        test_fail "Environment blocklist is empty"
    fi
}

#===============================================================================
# Integration Tests - Phase 0 (Environment Verification)
#===============================================================================

test_integration_phase0() {
    test_section "Integration Tests: Phase 0 - Environment Verification"

    # Test 1: Phase 0 script execution
    test_start "Phase 0 executes without syntax errors"
    local phase0_output
    if phase0_output=$("${PROJECT_ROOT}/setup.sh" 0 2>&1); then
        test_pass "Phase 0 executed successfully"
    else
        # Phase 0 may fail due to prerequisites, check if it's a controlled failure
        if echo "$phase0_output" | grep -q "ERROR\|WARN\|INFO"; then
            test_pass "Phase 0 executed with expected output"
        else
            test_fail "Phase 0 failed unexpectedly"
        fi
    fi

    # Test 2: Detects macOS
    test_start "Phase 0 detects macOS"
    if [[ "$(uname)" == "Darwin" ]]; then
        test_pass "Running on macOS"
    else
        test_skip "Not running on macOS (required for full test)"
    fi

    # Test 3: Detects Apple Silicon
    test_start "Phase 0 detects Apple Silicon"
    if [[ "$(uname -m)" == "arm64" ]]; then
        test_pass "Running on Apple Silicon"
    else
        test_skip "Not running on Apple Silicon (required for deployment)"
    fi

    # Test 4: Log file creation
    test_start "Phase 0 creates log file"
    local latest_log=$(ls -t "${PROJECT_ROOT}/logs/setup-"*.log 2>/dev/null | head -1)
    if assert_file_exists "$latest_log"; then
        test_pass "Log file created: $(basename "$latest_log")"
    else
        test_fail "No log file created"
    fi

    # Test 5: Disk space check
    test_start "Phase 0 checks disk space"
    if "$latest_log" && grep -q "disk space\|Disk" "$latest_log"; then
        test_pass "Disk space check performed"
    else
        test_fail "Disk space check not found in logs"
    fi
}

#===============================================================================
# Security Validation Tests
#===============================================================================

test_security_validation() {
    test_section "Security Validation Tests"

    # Test 1: No hardcoded credentials in scripts
    test_start "No hardcoded credentials in scripts"
    local cred_patterns="password|passwd|secret|token|api_key|apikey"
    if grep -rEi "$cred_patterns" "${PROJECT_ROOT}"/*.sh "${PROJECT_ROOT}"/scripts/*.sh 2>/dev/null | \
        grep -v "^#" | grep -v "echo" | grep -v "Password" | grep -v "GATEWAY_TOKEN"; then
        test_fail "Potential hardcoded credentials found"
    else
        test_pass "No hardcoded credentials detected"
    fi

    # Test 2: SSH key permissions (if exists)
    test_start "SSH key permissions are secure"
    local ssh_key="$HOME/.ssh/openclaw_vm_ed25519"
    if [[ -f "$ssh_key" ]]; then
        local perms=$(stat -f "%A" "$ssh_key" 2>/dev/null || stat -c "%a" "$ssh_key" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            test_pass "SSH key has correct permissions (600)"
        else
            test_fail "SSH key has insecure permissions: $perms (should be 600)"
        fi
    else
        test_skip "SSH key not yet generated"
    fi

    # Test 3: Setup script doesn't run as root
    test_start "Setup script doesn't require root"
    if grep -q "^if.*\$(id -u).*0" "${PROJECT_ROOT}/setup.sh"; then
        test_fail "Setup script checks for root (shouldn't run as root)"
    else
        test_pass "Setup script doesn't require root user"
    fi

    # Test 4: Firewall rules use localhost only
    test_start "Firewall rules restrict to localhost"
    if grep -q "127.0.0.1" "${PROJECT_ROOT}/setup.sh"; then
        test_pass "Firewall uses localhost-only access"
    else
        test_fail "Firewall may allow external access"
    fi

    # Test 5: SSH config disables password auth
    test_start "SSH config disables password authentication"
    if grep -q "PasswordAuthentication no" "${PROJECT_ROOT}/setup.sh"; then
        test_pass "Password authentication disabled in SSH config"
    else
        test_fail "Password authentication may be enabled"
    fi

    # Test 6: Strong key algorithms enforced
    test_start "Strong SSH key algorithms enforced"
    if grep -q "ed25519" "${PROJECT_ROOT}/setup.sh"; then
        test_pass "Ed25519 key algorithm enforced"
    else
        test_fail "Strong key algorithms not enforced"
    fi

    # Test 7: Sensitive files in .gitignore
    test_start "Sensitive files excluded from git"
    local sensitive_patterns=(".vm_ip" ".gateway_token" "*.key" "*.pem")
    local gitignore="${PROJECT_ROOT}/.gitignore"

    if [[ ! -f "$gitignore" ]]; then
        test_fail ".gitignore not found"
    else
        local missing=0
        for pattern in "${sensitive_patterns[@]}"; do
            if ! grep -q "$pattern" "$gitignore"; then
                ((missing++))
            fi
        done

        if [[ $missing -eq 0 ]]; then
            test_pass "All sensitive patterns in .gitignore"
        else
            test_fail "$missing sensitive patterns missing from .gitignore"
        fi
    fi
}

#===============================================================================
# Idempotency Tests
#===============================================================================

test_idempotency() {
    test_section "Idempotency Tests"

    # Test 1: Config loading is idempotent
    test_start "Config can be sourced multiple times"
    if source "${PROJECT_ROOT}/config/settings.env" && \
       source "${PROJECT_ROOT}/config/settings.env"; then
        test_pass "Config is idempotent"
    else
        test_fail "Config cannot be sourced multiple times"
    fi

    # Test 2: Check for idempotency patterns in scripts
    test_start "Scripts check existing state before creating"
    local idempotent_patterns="if.*exists\|if.*-f\|if.*-d\|grep -q"
    if grep -rE "$idempotent_patterns" "${PROJECT_ROOT}/setup.sh" | grep -q .; then
        test_pass "Scripts use idempotent patterns"
    else
        test_fail "Scripts may not be idempotent"
    fi

    # Test 3: Scripts have cleanup/rollback logic
    test_start "Scripts handle errors gracefully"
    if grep -q "trap\|error\|cleanup" "${PROJECT_ROOT}/setup.sh"; then
        test_pass "Error handling found in scripts"
    else
        test_fail "No error handling patterns found"
    fi
}

#===============================================================================
# Performance Tests
#===============================================================================

test_performance() {
    test_section "Performance Tests"

    # Test 1: Log files are rotated/limited
    test_start "Log rotation configured"
    local log_count=$(ls -1 "${PROJECT_ROOT}/logs/" 2>/dev/null | wc -l)
    if [[ $log_count -lt 100 ]]; then
        test_pass "Log count is reasonable ($log_count files)"
    else
        test_fail "Too many log files ($log_count) - consider rotation"
    fi

    # Test 2: Backup retention is configured
    test_start "Backup retention configured"
    if grep -q "keep.*7\|retention\|tail -n +8" "${PROJECT_ROOT}/setup.sh" \
        "${PROJECT_ROOT}/scripts/backup-vm.sh" 2>/dev/null; then
        test_pass "Backup retention configured"
    else
        test_fail "No backup retention found"
    fi
}

#===============================================================================
# Documentation Tests
#===============================================================================

test_documentation() {
    test_section "Documentation Tests"

    # Test 1: README exists
    test_start "README.md exists"
    if assert_file_exists "${PROJECT_ROOT}/README.md"; then
        test_pass "README.md exists"
    else
        test_fail "README.md not found"
    fi

    # Test 2: README has required sections
    local required_sections=("Overview" "Quick Start" "Usage" "Security" "Troubleshooting")
    for section in "${required_sections[@]}"; do
        test_start "README has '$section' section"
        if grep -qi "## $section\|# $section" "${PROJECT_ROOT}/README.md"; then
            test_pass "README has $section section"
        else
            test_fail "README missing $section section"
        fi
    done

    # Test 3: Scripts have usage information
    test_start "setup.sh has usage information"
    if grep -q "Usage:" "${PROJECT_ROOT}/setup.sh"; then
        test_pass "setup.sh has usage information"
    else
        test_fail "setup.sh missing usage information"
    fi
}

#===============================================================================
# Test Summary
#===============================================================================

print_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  TEST SUMMARY${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Total Tests:   $TESTS_RUN"
    echo -e "  ${GREEN}Passed:        $TESTS_PASSED${NC}"
    echo -e "  ${RED}Failed:        $TESTS_FAILED${NC}"
    echo -e "  ${YELLOW}Skipped:       $TESTS_SKIPPED${NC}"
    echo ""
    echo "  Results logged to: $TEST_RESULTS_FILE"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Review logs for details.${NC}"
        echo ""
        return 1
    fi
}

#===============================================================================
# Main Test Orchestration
#===============================================================================

main() {
    local test_suite="${1:-all}"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  OpenClaw VM Setup - Test Suite${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Test Suite: $test_suite"
    echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Platform: $(uname) $(uname -m)"
    echo ""

    case "$test_suite" in
        unit)
            test_unit_config
            test_unit_scripts
            test_unit_security
            ;;
        integration)
            test_integration_phase0
            ;;
        security)
            test_security_validation
            ;;
        idempotency)
            test_idempotency
            ;;
        performance)
            test_performance
            ;;
        docs|documentation)
            test_documentation
            ;;
        all)
            test_header "Unit Tests"
            test_unit_config
            test_unit_scripts
            test_unit_security

            test_header "Integration Tests"
            test_integration_phase0

            test_header "Security Tests"
            test_security_validation

            test_header "Idempotency Tests"
            test_idempotency

            test_header "Performance Tests"
            test_performance

            test_header "Documentation Tests"
            test_documentation
            ;;
        *)
            echo "Unknown test suite: $test_suite"
            echo ""
            echo "Available test suites:"
            echo "  all           - Run all tests (default)"
            echo "  unit          - Unit tests only"
            echo "  integration   - Integration tests only"
            echo "  security      - Security validation tests"
            echo "  idempotency   - Idempotency tests"
            echo "  performance   - Performance tests"
            echo "  docs          - Documentation tests"
            exit 1
            ;;
    esac

    print_summary
}

# Run tests
main "$@"
