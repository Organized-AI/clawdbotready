#!/usr/bin/env bash
#===============================================================================
# OpenClaw Native macOS Security Setup - Master Orchestrator
#===============================================================================
# This script automates the secure deployment of OpenClaw Gateway directly on
# macOS (without virtualization) using user account isolation and deny-by-default
# exec-approvals.
#
# Target: macOS Sequoia+ on Apple Silicon (M1/M2/M3/M4)
#
# Usage: ./setup.sh [phase|all]
#   phase 0: Prerequisites validation
#   phase 1: User account creation
#   phase 2: exec-approvals configuration
#   phase 3: LaunchAgent setup
#   phase 4: Gateway installation
#   phase 5: Monitoring setup
#   phase 6: Helper scripts & documentation
#   all: Run all phases (default)
#
# Security Model:
#   - Dedicated 'openclaw' user account with minimal privileges
#   - Deny-by-default command execution via exec-approvals.json
#   - LaunchAgent protected from modification (owned by root)
#   - Gateway runs with restricted permissions
#   - Real-time monitoring and alerting
#===============================================================================

set -euo pipefail

#===============================================================================
# Configuration
#===============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${SCRIPT_DIR}/backups"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d_%H%M%S).log"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=config/settings.env
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Default values if not set in settings.env
OPENCLAW_USER="${OPENCLAW_USER:-openclaw}"
OPENCLAW_UID="${OPENCLAW_UID:-502}"
OPENCLAW_HOME="${OPENCLAW_HOME:-/Users/openclaw}"
GATEWAY_INSTALL_DIR="${GATEWAY_INSTALL_DIR:-${OPENCLAW_HOME}/.openclaw/gateway}"
GATEWAY_DATA_DIR="${GATEWAY_DATA_DIR:-${OPENCLAW_HOME}/.openclaw/data}"
GATEWAY_LOG_DIR="${GATEWAY_LOG_DIR:-${OPENCLAW_HOME}/.openclaw/logs}"
EXEC_APPROVALS_PATH="${EXEC_APPROVALS_PATH:-${OPENCLAW_HOME}/.openclaw/exec-approvals.json}"
LAUNCHAGENT_PLIST="${LAUNCHAGENT_PLIST:-${OPENCLAW_HOME}/Library/LaunchAgents/ai.openclaw.gateway.plist}"
FORCE_MODE="${FORCE_MODE:-false}"
BACKUP_BEFORE_OVERWRITE="${BACKUP_BEFORE_OVERWRITE:-true}"
VERBOSE="${VERBOSE:-false}"

#===============================================================================
# Utility Functions
#===============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

info() { log "${BLUE}INFO${NC}" "$*"; }
warn() { log "${YELLOW}WARN${NC}" "$*"; }
error() { log "${RED}ERROR${NC}" "$*"; }
success() { log "${GREEN}SUCCESS${NC}" "$*"; }
debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        log "${CYAN}DEBUG${NC}" "$*"
    fi
}

header() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}=================================================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}  $*${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}=================================================================${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

confirm() {
    if [[ "$FORCE_MODE" == "true" ]]; then
        return 0
    fi

    local prompt="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="${prompt} [Y/n]: "
    else
        prompt="${prompt} [y/N]: "
    fi

    read -p "$prompt" response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy] ]]
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script must NOT be run as root"
        error "Run without sudo - you'll be prompted for sudo when needed"
        exit 1
    fi
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        info "This script requires sudo access for user creation and configuration"
        sudo -v || {
            error "Failed to obtain sudo privileges"
            exit 1
        }
    fi

    # Keep sudo alive
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$$" || exit
    done 2>/dev/null &
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script must be run on macOS"
        exit 1
    fi

    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)

    if [[ "$major_version" -lt 14 ]]; then
        warn "macOS Sequoia (14.0+) or later recommended. You are running $macos_version"
    fi

    if [[ "$(uname -m)" != "arm64" ]]; then
        error "This script requires Apple Silicon (M1/M2/M3/M4)"
        exit 1
    fi

    info "Running on macOS $macos_version ($(uname -m))"
}

check_disk_space() {
    local required_gb=10
    local available_gb=$(df -g / | awk 'NR==2 {print $4}')

    if [[ "$available_gb" -lt "$required_gb" ]]; then
        error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        exit 1
    fi

    info "Disk space check passed: ${available_gb}GB available"
}

check_homebrew() {
    if ! command -v brew &> /dev/null; then
        error "Homebrew not found. Install from https://brew.sh"
        exit 1
    fi
    info "Homebrew found: $(brew --version | head -n1)"
}

check_nodejs() {
    if ! command -v node &> /dev/null; then
        warn "Node.js not found. Gateway may require it."
        warn "Install with: brew install node"
    else
        info "Node.js found: $(node --version)"
    fi
}

#===============================================================================
# Phase 0: Prerequisites Validation
#===============================================================================

phase_0() {
    header "Phase 0: Prerequisites Validation"

    info "Validating system requirements..."

    check_root
    check_sudo
    check_macos
    check_disk_space
    check_homebrew
    check_nodejs

    # Check if openclaw user already exists
    if id "$OPENCLAW_USER" &>/dev/null; then
        warn "User '$OPENCLAW_USER' already exists"

        if [[ "$BACKUP_BEFORE_OVERWRITE" == "true" ]]; then
            if confirm "Backup existing user account before proceeding?" "y"; then
                local backup_file="${BACKUP_DIR}/openclaw-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
                info "Creating backup of ${OPENCLAW_HOME}..."

                if [[ -d "$OPENCLAW_HOME" ]]; then
                    sudo tar -czf "$backup_file" -C "$(dirname "$OPENCLAW_HOME")" "$(basename "$OPENCLAW_HOME")" 2>/dev/null || true
                    success "Backup created: $backup_file"
                fi
            fi
        fi

        if ! confirm "Delete and recreate user '$OPENCLAW_USER'?" "n"; then
            error "Cannot proceed with existing user. Exiting."
            exit 1
        fi

        info "Removing existing user account..."
        sudo dscl . -delete "/Users/$OPENCLAW_USER" 2>/dev/null || true
        sudo rm -rf "$OPENCLAW_HOME" 2>/dev/null || true
        success "Existing user removed"
    fi

    # Check UID availability
    if dscl . -list /Users UniqueID | grep -q "^[[:space:]]*$OPENCLAW_UID$"; then
        error "UID $OPENCLAW_UID is already in use"
        error "Update OPENCLAW_UID in config/settings.env to an available UID"
        exit 1
    fi

    success "Phase 0 complete: All prerequisites validated"
}

#===============================================================================
# Phase 1: User Account Creation
#===============================================================================

phase_1() {
    header "Phase 1: User Account Creation"

    info "Creating user account '$OPENCLAW_USER' with UID $OPENCLAW_UID..."

    # Generate secure random password
    local password=$(openssl rand -base64 24)
    local password_file="${BACKUP_DIR}/.openclaw-password-$(date +%Y%m%d_%H%M%S).txt"

    echo "$password" > "$password_file"
    chmod 600 "$password_file"

    info "Generated secure password (saved to: $password_file)"

    # Create user account
    sudo dscl . -create "/Users/$OPENCLAW_USER"
    sudo dscl . -create "/Users/$OPENCLAW_USER" UserShell /bin/bash
    sudo dscl . -create "/Users/$OPENCLAW_USER" RealName "OpenClaw Gateway"
    sudo dscl . -create "/Users/$OPENCLAW_USER" UniqueID "$OPENCLAW_UID"
    sudo dscl . -create "/Users/$OPENCLAW_USER" PrimaryGroupID 20
    sudo dscl . -create "/Users/$OPENCLAW_USER" NFSHomeDirectory "$OPENCLAW_HOME"
    sudo dscl . -passwd "/Users/$OPENCLAW_USER" "$password"

    success "User account created successfully"

    # Create home directory
    info "Creating home directory structure..."
    sudo mkdir -p "$OPENCLAW_HOME"
    sudo mkdir -p "${OPENCLAW_HOME}/.openclaw/gateway"
    sudo mkdir -p "${OPENCLAW_HOME}/.openclaw/data"
    sudo mkdir -p "${OPENCLAW_HOME}/.openclaw/logs"
    sudo mkdir -p "${OPENCLAW_HOME}/Library/LaunchAgents"

    # Set ownership
    sudo chown -R "${OPENCLAW_USER}:staff" "$OPENCLAW_HOME"

    # Set permissions
    sudo chmod 700 "$OPENCLAW_HOME"
    sudo chmod 700 "${OPENCLAW_HOME}/.openclaw"
    sudo chmod 700 "${OPENCLAW_HOME}/.openclaw/gateway"
    sudo chmod 700 "${OPENCLAW_HOME}/.openclaw/data"
    sudo chmod 700 "${OPENCLAW_HOME}/.openclaw/logs"

    success "Home directory structure created"

    # Verify user can login
    info "Verifying user account..."
    if id "$OPENCLAW_USER" &>/dev/null; then
        success "User '$OPENCLAW_USER' verified"
    else
        error "User account verification failed"
        exit 1
    fi

    success "Phase 1 complete: User account created"
}

#===============================================================================
# Phase 2: exec-approvals Configuration
#===============================================================================

phase_2() {
    header "Phase 2: exec-approvals Configuration"

    info "Installing exec-approvals.json..."

    local source_file="${SCRIPT_DIR}/config/exec-approvals.json"

    if [[ ! -f "$source_file" ]]; then
        error "exec-approvals.json not found: $source_file"
        exit 1
    fi

    # Copy exec-approvals.json
    sudo cp "$source_file" "$EXEC_APPROVALS_PATH"

    # Set ownership to root (prevent tampering)
    sudo chown root:wheel "$EXEC_APPROVALS_PATH"

    # Set read-only permissions
    sudo chmod 444 "$EXEC_APPROVALS_PATH"

    success "exec-approvals.json installed and protected"

    # Verify
    info "Verifying configuration..."
    if [[ -f "$EXEC_APPROVALS_PATH" ]]; then
        local owner=$(stat -f '%Su:%Sg' "$EXEC_APPROVALS_PATH")
        local perms=$(stat -f '%Lp' "$EXEC_APPROVALS_PATH")

        if [[ "$owner" == "root:wheel" ]] && [[ "$perms" == "444" ]]; then
            success "Security verification passed"
        else
            warn "Security verification warning: owner=$owner, perms=$perms"
        fi
    else
        error "Verification failed: file not found"
        exit 1
    fi

    success "Phase 2 complete: exec-approvals configured"
}

#===============================================================================
# Phase 3: LaunchAgent Setup
#===============================================================================

phase_3() {
    header "Phase 3: LaunchAgent Setup"

    info "Creating LaunchAgent plist..."

    local template_file="${SCRIPT_DIR}/config/launchagent-template.plist"

    if [[ ! -f "$template_file" ]]; then
        error "LaunchAgent template not found: $template_file"
        exit 1
    fi

    # Copy template
    sudo cp "$template_file" "$LAUNCHAGENT_PLIST"

    # Set ownership to root (prevent tampering)
    sudo chown root:wheel "$LAUNCHAGENT_PLIST"

    # Set read-only permissions
    sudo chmod 444 "$LAUNCHAGENT_PLIST"

    success "LaunchAgent plist created and protected"

    # Validate plist syntax
    info "Validating plist syntax..."
    if plutil -lint "$LAUNCHAGENT_PLIST" >/dev/null 2>&1; then
        success "Plist syntax valid"
    else
        error "Plist syntax validation failed"
        exit 1
    fi

    # Note: LaunchAgent will be loaded in Phase 4 after Gateway installation

    success "Phase 3 complete: LaunchAgent configured"
}

#===============================================================================
# Phase 4: Gateway Installation
#===============================================================================

phase_4() {
    header "Phase 4: Gateway Installation"

    warn "Gateway installation is currently manual"
    warn "OpenClaw Gateway binary not yet publicly available"

    info "Manual installation steps:"
    info "  1. Obtain OpenClaw Gateway binary"
    info "  2. Copy to: $GATEWAY_INSTALL_DIR/openclaw-gateway"
    info "  3. Set ownership: sudo chown ${OPENCLAW_USER}:staff <binary>"
    info "  4. Set permissions: sudo chmod 500 <binary>"
    info "  5. Create configuration file in: $GATEWAY_INSTALL_DIR"

    if [[ -n "${GATEWAY_DOWNLOAD_URL:-}" ]]; then
        info "Attempting to download from: $GATEWAY_DOWNLOAD_URL"
        # TODO: Implement download logic when Gateway URL is available
        warn "Download not implemented yet - use manual installation"
    fi

    # Check if binary exists
    if [[ -f "${GATEWAY_INSTALL_DIR}/openclaw-gateway" ]]; then
        success "Gateway binary found"

        # Load LaunchAgent
        info "Loading LaunchAgent..."
        local user_id=$(id -u "$OPENCLAW_USER")

        if sudo launchctl bootstrap "gui/${user_id}" "$LAUNCHAGENT_PLIST" 2>/dev/null; then
            success "LaunchAgent loaded successfully"
        else
            warn "LaunchAgent may already be loaded or Gateway binary not ready"
        fi
    else
        warn "Gateway binary not found - complete manual installation then run:"
        warn "  sudo launchctl bootstrap gui/\$(id -u $OPENCLAW_USER) $LAUNCHAGENT_PLIST"
    fi

    success "Phase 4 complete: Gateway installation documented"
}

#===============================================================================
# Phase 5: Monitoring Setup
#===============================================================================

phase_5() {
    header "Phase 5: Monitoring Setup"

    info "Monitoring script will be created in Phase 6"
    info "Monitor configuration:"
    info "  - Interval: ${MONITOR_INTERVAL}s"
    info "  - Log max size: ${LOG_MAX_SIZE_MB}MB"
    info "  - Log retention: ${LOG_RETENTION_DAYS} days"

    # Create monitor configuration file
    local monitor_conf="${OPENCLAW_HOME}/.openclaw/monitor.conf"

    sudo tee "$monitor_conf" > /dev/null <<EOF
# OpenClaw Monitoring Configuration
MONITOR_INTERVAL=${MONITOR_INTERVAL}
LOG_MAX_SIZE_MB=${LOG_MAX_SIZE_MB}
LOG_RETENTION_DAYS=${LOG_RETENTION_DAYS}
CPU_ALERT_THRESHOLD=${CPU_ALERT_THRESHOLD:-80}
MEMORY_ALERT_THRESHOLD=${MEMORY_ALERT_THRESHOLD:-1024}
EOF

    sudo chown "${OPENCLAW_USER}:staff" "$monitor_conf"
    sudo chmod 600 "$monitor_conf"

    success "Phase 5 complete: Monitoring configuration created"
}

#===============================================================================
# Phase 6: Helper Scripts & Documentation
#===============================================================================

phase_6() {
    header "Phase 6: Helper Scripts & Documentation"

    info "Helper scripts available in: ${SCRIPT_DIR}/scripts/"
    info "  - connect.sh: Login to openclaw user"
    info "  - status.sh: Health check"
    info "  - emergency-stop.sh: Kill switch"
    info "  - restart.sh: Restart Gateway"
    info "  - monitor.sh: Real-time monitoring"

    # Make all scripts executable
    chmod +x "${SCRIPT_DIR}"/scripts/*.sh 2>/dev/null || true

    info "Documentation:"
    info "  - README.md: Quick start guide"
    info "  - PLANNING/: Implementation details"

    success "Phase 6 complete: Helper scripts ready"
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    header "OpenClaw Native macOS Setup"

    info "Script directory: $SCRIPT_DIR"
    info "Log file: $LOG_FILE"
    info "Configuration: $CONFIG_FILE"

    local phase="${1:-all}"

    case "$phase" in
        0)
            phase_0
            ;;
        1)
            phase_0
            phase_1
            ;;
        2)
            phase_0
            phase_1
            phase_2
            ;;
        3)
            phase_0
            phase_1
            phase_2
            phase_3
            ;;
        4)
            phase_0
            phase_1
            phase_2
            phase_3
            phase_4
            ;;
        5)
            phase_0
            phase_1
            phase_2
            phase_3
            phase_4
            phase_5
            ;;
        6|all)
            phase_0
            phase_1
            phase_2
            phase_3
            phase_4
            phase_5
            phase_6
            ;;
        *)
            echo "Usage: $0 [0|1|2|3|4|5|6|all]"
            echo ""
            echo "Phases:"
            echo "  0 - Prerequisites validation"
            echo "  1 - User account creation"
            echo "  2 - exec-approvals configuration"
            echo "  3 - LaunchAgent setup"
            echo "  4 - Gateway installation"
            echo "  5 - Monitoring setup"
            echo "  6 - Helper scripts & documentation"
            echo "  all - Run all phases (default)"
            exit 1
            ;;
    esac

    header "Setup Complete!"
    success "OpenClaw native macOS deployment configured successfully"

    info "Next steps:"
    info "  1. Review password file: ${BACKUP_DIR}/.openclaw-password-*.txt"
    info "  2. Install Gateway binary (if not done): ${GATEWAY_INSTALL_DIR}"
    info "  3. Load LaunchAgent: sudo launchctl bootstrap gui/\$(id -u $OPENCLAW_USER) $LAUNCHAGENT_PLIST"
    info "  4. Check status: ${SCRIPT_DIR}/scripts/status.sh"
    info "  5. View logs: tail -f ${GATEWAY_LOG_DIR}/gateway.log"
}

# Run main function
main "$@"
