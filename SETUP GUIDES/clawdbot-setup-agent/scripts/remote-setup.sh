#!/usr/bin/env bash
#
# Remote Setup Executor for Clawdbot Setup Assistant
# Executes setup phases on user's Mac via SSH
#
# Usage:
#   ./remote-setup.sh run [TOKEN] [PATH] [PHASE]    Run specific phase
#   ./remote-setup.sh status [TOKEN]                 Get setup status
#   ./remote-setup.sh test-connection [TOKEN]        Test SSH connection
#   ./remote-setup.sh rollback [TOKEN] [PHASE]       Rollback to phase
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_MANAGER="${SCRIPT_DIR}/ssh-manager.sh"
LOG_DIR="${HOME}/.openclaw/logs/remote-setups"
STATE_DIR="${HOME}/.openclaw/setup-assistant/state"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$LOG_DIR" "$STATE_DIR"

log() {
    local token="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_DIR}/${token}.log"
}

error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

info() {
    echo -e "${BLUE}ℹ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $*${NC}"
}

# Get SSH key for token
get_ssh_key() {
    local token="$1"
    "$SSH_MANAGER" get-key "$token"
}

# Validate token before use
validate_token() {
    local token="$1"
    local status
    status=$("$SSH_MANAGER" validate "$token")

    if [[ "$status" != "valid" ]]; then
        error "Token invalid or expired: $status"
    fi
}

# Test SSH connection
test_connection() {
    local token="$1"
    validate_token "$token"

    local key_path
    key_path=$(get_ssh_key "$token")

    local user_ip
    user_ip=$(get_user_ip "$token")

    info "Testing SSH connection to $user_ip..."

    if ssh -i "$key_path" \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no \
        "$user_ip" 'echo "SSH_CONNECTION_OK"' 2>/dev/null | grep -q "SSH_CONNECTION_OK"; then
        success "SSH connection successful"
        return 0
    else
        error "SSH connection failed"
        return 1
    fi
}

# Get user's Mac IP from state
get_user_ip() {
    local token="$1"
    local state_file="${STATE_DIR}/${token}.json"

    if [[ ! -f "$state_file" ]]; then
        error "No state file found for token: $token"
    fi

    jq -r '.user_mac_ip' "$state_file"
}

# Save setup state
save_state() {
    local token="$1"
    local phase="$2"
    local path="$3"
    local status="$4"

    local state_file="${STATE_DIR}/${token}.json"

    cat > "$state_file" <<EOF
{
  "token": "${token}",
  "current_phase": ${phase},
  "deployment_path": "${path}",
  "status": "${status}",
  "last_updated": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "phases_completed": $(jq -n --argjson p "$phase" '[range($p)]')
}
EOF
}

# Run system checks
run_system_checks() {
    local token="$1"
    local key_path
    key_path=$(get_ssh_key "$token")

    local user_ip
    user_ip=$(get_user_ip "$token")

    info "Running system checks..."

    local macos_version arch disk_free internet

    # macOS version
    macos_version=$(ssh -i "$key_path" "$user_ip" 'sw_vers -productVersion' 2>/dev/null || echo "unknown")
    log "$token" "macOS version: $macos_version"

    # Architecture
    arch=$(ssh -i "$key_path" "$user_ip" 'uname -m' 2>/dev/null || echo "unknown")
    log "$token" "Architecture: $arch"

    # Disk space
    disk_free=$(ssh -i "$key_path" "$user_ip" "df -g / | awk 'NR==2 {print \$4}'" 2>/dev/null || echo "0")
    log "$token" "Disk free: ${disk_free}GB"

    # Internet
    if ssh -i "$key_path" "$user_ip" 'ping -c 1 -t 5 google.com &>/dev/null'; then
        internet="ok"
    else
        internet="fail"
    fi
    log "$token" "Internet: $internet"

    # Output results as JSON
    cat <<EOF
{
  "macos_version": "${macos_version}",
  "architecture": "${arch}",
  "disk_free_gb": ${disk_free},
  "internet": "${internet}",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF
}

# Run setup phase
run_phase() {
    local token="$1"
    local path="$2"  # "vm" or "native"
    local phase="$3"

    validate_token "$token"

    local key_path
    key_path=$(get_ssh_key "$token")

    local user_ip
    user_ip=$(get_user_ip "$token")

    log "$token" "Starting Phase $phase ($path setup)"

    # Determine setup script path
    local setup_dir
    if [[ "$path" == "vm" ]]; then
        setup_dir="~/clawdbot-ready/SETUP\ GUIDES/openclaw-vm-setup"
    else
        setup_dir="~/clawdbot-ready/SETUP\ GUIDES/openclaw-native-setup"
    fi

    # Run phase via SSH
    local phase_output
    local exit_code=0

    phase_output=$(ssh -i "$key_path" \
        -o ConnectTimeout=300 \
        -o ServerAliveInterval=30 \
        "$user_ip" \
        "cd $setup_dir && ./setup.sh $phase 2>&1" || exit_code=$?)

    # Log output
    echo "$phase_output" >> "${LOG_DIR}/${token}.log"

    if [[ $exit_code -eq 0 ]]; then
        log "$token" "Phase $phase completed successfully"
        save_state "$token" "$phase" "$path" "completed"

        # Create snapshot for rollback
        create_snapshot "$token" "$phase"

        echo "$phase_output"
        return 0
    else
        log "$token" "Phase $phase failed with exit code: $exit_code"
        save_state "$token" "$phase" "$path" "failed"

        echo "$phase_output"
        return "$exit_code"
    fi
}

# Create snapshot for rollback
create_snapshot() {
    local token="$1"
    local phase="$2"

    local snapshot_dir="${HOME}/.openclaw/setup-assistant/snapshots/${token}"
    mkdir -p "$snapshot_dir"

    local snapshot_file="${snapshot_dir}/phase-${phase}.json"

    cat > "$snapshot_file" <<EOF
{
  "phase": ${phase},
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "state_file": "${STATE_DIR}/${token}.json",
  "log_file": "${LOG_DIR}/${token}.log"
}
EOF

    log "$token" "Snapshot created: phase-${phase}"
}

# Rollback to phase
rollback_to_phase() {
    local token="$1"
    local target_phase="$2"

    validate_token "$token"

    local key_path
    key_path=$(get_ssh_key "$token")

    local user_ip
    user_ip=$(get_user_ip "$token")

    log "$token" "Rolling back to Phase $target_phase"

    # Get deployment path from state
    local state_file="${STATE_DIR}/${token}.json"
    local path
    path=$(jq -r '.deployment_path' "$state_file")

    local setup_dir
    if [[ "$path" == "vm" ]]; then
        setup_dir="~/clawdbot-ready/SETUP\ GUIDES/openclaw-vm-setup"
    else
        setup_dir="~/clawdbot-ready/SETUP\ GUIDES/openclaw-native-setup"
    fi

    # Run rollback script
    ssh -i "$key_path" "$user_ip" \
        "cd $setup_dir && ./scripts/rollback.sh --to-phase $target_phase"

    # Update state
    save_state "$token" "$target_phase" "$path" "rolled_back"

    success "Rolled back to Phase $target_phase"
}

# Get setup status
get_status() {
    local token="$1"
    local state_file="${STATE_DIR}/${token}.json"

    if [[ ! -f "$state_file" ]]; then
        error "No setup found for token: $token"
    fi

    jq '.' "$state_file"
}

# Detect error in phase output
detect_error() {
    local output="$1"

    # Known error patterns
    if echo "$output" | grep -qi "command not found"; then
        echo "command_not_found"
    elif echo "$output" | grep -qi "permission denied"; then
        echo "permission_denied"
    elif echo "$output" | grep -qi "no space left"; then
        echo "disk_space"
    elif echo "$output" | grep -qi "connection refused\|timeout"; then
        echo "network"
    elif echo "$output" | grep -qi "failed to install lume"; then
        echo "lume_install_fail"
    else
        echo "unknown"
    fi
}

# Apply fix for known error
apply_fix() {
    local token="$1"
    local error_type="$2"
    local phase="$3"

    local key_path
    key_path=$(get_ssh_key "$token")

    local user_ip
    user_ip=$(get_user_ip "$token")

    log "$token" "Applying fix for: $error_type"

    case "$error_type" in
        command_not_found)
            # Apply PATH fix (from v2.2.0 lessons)
            log "$token" "Applying PATH configuration fix"
            ssh -i "$key_path" "$user_ip" 'cat > ~/.zprofile << '\''EOF'\''
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF'
            ssh -i "$key_path" "$user_ip" 'echo "source ~/.zprofile" >> ~/.zshrc'
            ssh -i "$key_path" "$user_ip" 'source ~/.zprofile'
            success "PATH fix applied"
            return 0
            ;;

        lume_install_fail)
            # Try Homebrew install
            log "$token" "Trying Lume install via Homebrew"
            ssh -i "$key_path" "$user_ip" 'brew install lume'
            success "Lume installed via Homebrew"
            return 0
            ;;

        *)
            warning "No automatic fix available for: $error_type"
            return 1
            ;;
    esac
}

# Run phase with auto-retry
run_phase_with_retry() {
    local token="$1"
    local path="$2"
    local phase="$3"
    local max_attempts=3

    for attempt in $(seq 1 $max_attempts); do
        info "Attempt $attempt/$max_attempts for Phase $phase"

        local output
        if output=$(run_phase "$token" "$path" "$phase"); then
            success "Phase $phase completed"
            echo "$output"
            return 0
        else
            warning "Phase $phase failed (attempt $attempt)"

            # Detect error type
            local error_type
            error_type=$(detect_error "$output")
            log "$token" "Error type detected: $error_type"

            # Try to apply fix
            if apply_fix "$token" "$error_type" "$phase"; then
                info "Fix applied, retrying..."
                continue
            else
                if [[ $attempt -eq $max_attempts ]]; then
                    error "Phase $phase failed after $max_attempts attempts"
                    return 1
                fi
            fi
        fi
    done

    return 1
}

# Main command dispatcher
case "${1:-}" in
    test-connection)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 test-connection [TOKEN]"
        fi
        test_connection "$2"
        ;;

    system-checks)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 system-checks [TOKEN]"
        fi
        run_system_checks "$2"
        ;;

    run)
        if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]] || [[ -z "${4:-}" ]]; then
            error "Usage: $0 run [TOKEN] [PATH] [PHASE]"
        fi
        run_phase "$2" "$3" "$4"
        ;;

    run-with-retry)
        if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]] || [[ -z "${4:-}" ]]; then
            error "Usage: $0 run-with-retry [TOKEN] [PATH] [PHASE]"
        fi
        run_phase_with_retry "$2" "$3" "$4"
        ;;

    rollback)
        if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
            error "Usage: $0 rollback [TOKEN] [PHASE]"
        fi
        rollback_to_phase "$2" "$3"
        ;;

    status)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 status [TOKEN]"
        fi
        get_status "$2"
        ;;

    *)
        cat <<EOF
Remote Setup Executor for Clawdbot Setup Assistant

Usage:
  $0 test-connection [TOKEN]                Test SSH connection
  $0 system-checks [TOKEN]                  Run system checks
  $0 run [TOKEN] [PATH] [PHASE]             Run specific phase
  $0 run-with-retry [TOKEN] [PATH] [PHASE]  Run phase with auto-retry
  $0 rollback [TOKEN] [PHASE]               Rollback to phase
  $0 status [TOKEN]                         Get setup status

PATH: "vm" or "native"
PHASE: 0-7 for VM, 0-6 for native

Examples:
  # Test connection
  $0 test-connection abc123def456

  # Run system checks
  $0 system-checks abc123def456

  # Run Phase 1 (VM setup)
  $0 run abc123def456 vm 1

  # Run Phase 4 with auto-retry
  $0 run-with-retry abc123def456 vm 4

  # Check status
  $0 status abc123def456

EOF
        exit 1
        ;;
esac
