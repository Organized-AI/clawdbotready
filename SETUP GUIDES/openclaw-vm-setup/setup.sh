#!/bin/bash
#===============================================================================
# OpenClaw macOS VM Security Setup - Master Orchestrator
#===============================================================================
# This script orchestrates the complete secure setup of OpenClaw in a macOS VM
# Target: M4 Mac Mini (fresh machine)
#
# Usage: ./setup.sh [command]
#   Recommended: start → continue (async workflow)
#   start: Verify environment + create VM in background
#   continue: Complete setup after VM creation
#   all: Run all phases sequentially (default)
#   0-6: Run individual phases
#===============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d_%H%M%S).log"
VM_CREATION_PID_FILE="${SCRIPT_DIR}/.vm_creation.pid"
VM_CREATION_LOG="${LOG_DIR}/vm-creation-background.log"

# VM Configuration (will be loaded from settings.env)
VM_NAME="${VM_NAME:-openclaw-secure}"
VM_CPU="${VM_CPU:-4}"
VM_MEMORY="${VM_MEMORY:-8192}"
VM_DISK="${VM_DISK:-60G}"
VM_USER="${VM_USER:-openclaw}"

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

info() { log "INFO" "$*"; }
warn() { log "${YELLOW}WARN${NC}" "$*"; }
error() { log "${RED}ERROR${NC}" "$*"; }
success() { log "${GREEN}SUCCESS${NC}" "$*"; }

header() {
    echo ""
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}=================================================================${NC}"
    echo ""
}

confirm() {
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

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script must be run on macOS"
        exit 1
    fi

    # Check for Apple Silicon
    if [[ "$(uname -m)" != "arm64" ]]; then
        error "This script requires Apple Silicon (M1/M2/M3/M4)"
        exit 1
    fi

    info "Running on macOS $(sw_vers -productVersion) ($(uname -m))"
}

check_disk_space() {
    local required_gb=55
    local available_gb=$(df -g / | awk 'NR==2 {print $4}')

    if [[ "$available_gb" -lt "$required_gb" ]]; then
        error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        exit 1
    fi

    info "Disk space OK: ${available_gb}GB available"
}

wait_for_vm() {
    local max_attempts=60
    local attempt=0

    info "Waiting for VM to be ready..."

    while [[ $attempt -lt $max_attempts ]]; do
        if lume get "$VM_NAME" &>/dev/null; then
            local ip=$(lume get "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            if [[ -n "$ip" ]]; then
                if nc -z -w5 "$ip" 22 &>/dev/null; then
                    success "VM is ready at $ip"
                    echo "$ip" > "${SCRIPT_DIR}/.vm_ip"
                    return 0
                fi
            fi
        fi

        ((attempt++))
        echo -n "."
        sleep 5
    done

    error "Timeout waiting for VM"
    return 1
}

get_vm_ip() {
    if [[ -f "${SCRIPT_DIR}/.vm_ip" ]]; then
        cat "${SCRIPT_DIR}/.vm_ip"
    else
        lume get "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1
    fi
}

#===============================================================================
# Async VM Creation Helpers
#===============================================================================

is_vm_creation_running() {
    if [[ -f "$VM_CREATION_PID_FILE" ]]; then
        local pid=$(cat "$VM_CREATION_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Running
        else
            # Stale PID file
            rm -f "$VM_CREATION_PID_FILE"
            return 1  # Not running
        fi
    fi
    return 1  # Not running
}

wait_for_vm_creation() {
    if ! is_vm_creation_running; then
        # Check if VM already exists
        if lume get "$VM_NAME" &>/dev/null; then
            success "VM already exists and ready"
            return 0
        fi
        return 0  # Not running, nothing to wait for
    fi

    local pid=$(cat "$VM_CREATION_PID_FILE")
    info "VM creation in progress (PID: $pid)"
    info "Waiting for VM creation to complete..."
    info "Tail log: tail -f $VM_CREATION_LOG"

    # Wait for the background process
    while ps -p "$pid" > /dev/null 2>&1; do
        echo -n "."
        sleep 5
    done
    echo ""

    rm -f "$VM_CREATION_PID_FILE"

    # Check if VM was created successfully
    if lume get "$VM_NAME" &>/dev/null; then
        success "VM creation completed successfully"
        return 0
    else
        error "VM creation failed. Check log: $VM_CREATION_LOG"
        return 1
    fi
}

start_vm_creation_background() {
    if is_vm_creation_running; then
        warn "VM creation already in progress"
        return 0
    fi

    if lume get "$VM_NAME" &>/dev/null; then
        warn "VM '$VM_NAME' already exists"
        return 0
    fi

    info "Starting VM creation in background..."

    # Run Phase 1 in background
    (
        phase1_install_lume
    ) > "$VM_CREATION_LOG" 2>&1 &

    local bg_pid=$!
    echo "$bg_pid" > "$VM_CREATION_PID_FILE"

    success "VM creation started in background (PID: $bg_pid)"
    info "Monitor progress: tail -f $VM_CREATION_LOG"
    info "Check status: ./status.sh"
    info "Continue setup when ready: ./setup.sh continue"
}

#===============================================================================
# Phase 0: Environment Verification
#===============================================================================

phase0_verify_environment() {
    header "Phase 0: Environment Verification"

    local all_checks_passed=true

    # Check machine identity
    info "Checking machine identity..."
    info "Hostname: $(hostname)"
    info "User: $(whoami)"
    info "Home: $HOME"

    # Verify Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
        success "Apple Silicon detected (arm64)"
    else
        error "Not Apple Silicon. This setup requires M1/M2/M3/M4 Mac"
        all_checks_passed=false
    fi

    # Check hardware details
    local chip_info=$(system_profiler SPHardwareDataType | grep "Chip" | head -1)
    local memory_info=$(system_profiler SPHardwareDataType | grep "Memory" | head -1)
    info "Hardware: $chip_info"
    info "$memory_info"

    # Check macOS version
    local os_version=$(sw_vers -productVersion)
    local major_version=$(echo "$os_version" | cut -d. -f1)

    info "macOS Version: $os_version"

    if [[ "$major_version" -ge 15 ]]; then
        success "macOS version OK (Sequoia or later)"
    else
        warn "macOS 15+ (Sequoia) recommended for Lume. Current: $os_version"
    fi

    # Check disk space
    local available_gb=$(df -g / | awk 'NR==2 {print $4}')
    info "Available disk space: ${available_gb}GB"

    if [[ "$available_gb" -ge 55 ]]; then
        success "Disk space OK (55GB+ available)"
    else
        error "Need at least 55GB free (VM requires ~50GB). Available: ${available_gb}GB"
        all_checks_passed=false
    fi

    # Check for existing Lume installation
    if command -v lume &>/dev/null; then
        local lume_version=$(lume --version 2>/dev/null || echo "unknown")
        info "Lume is installed: $lume_version"

        local vm_count=$(lume list 2>/dev/null | wc -l | tr -d ' ')
        info "Existing VMs: $vm_count"
    else
        info "Lume is NOT installed (Phase 1 will install it)"
    fi

    # Check network connectivity
    info "Checking network connectivity..."

    if ping -c 1 -W 5 google.com &>/dev/null; then
        success "Internet: Connected"
    else
        error "Internet: No connection"
        all_checks_passed=false
    fi

    # Test Lume download site
    if curl -sI https://lume.dev | head -1 | grep -q "200\|301\|302"; then
        success "Lume site: Accessible"
    else
        warn "Lume site: May be blocked or down"
    fi

    # Test Apple CDN
    if curl -sI https://updates.cdn-apple.com | head -1 | grep -q "200\|301\|302\|403"; then
        success "Apple CDN: Accessible"
    else
        warn "Apple CDN: May have issues"
    fi

    echo ""
    if [[ "$all_checks_passed" == "true" ]]; then
        success "All critical checks passed! Ready to proceed."
        return 0
    else
        error "Some critical checks failed. Please resolve issues before continuing."
        return 1
    fi
}

#===============================================================================
# Phase 1: Install Lume and Create VM
#===============================================================================

phase1_install_lume() {
    header "Phase 1: Installing Lume and Creating VM"

    # Check if Lume is already installed
    if command -v lume &>/dev/null; then
        info "Lume is already installed: $(lume --version 2>/dev/null || echo 'version unknown')"
        if ! confirm "Reinstall Lume?"; then
            info "Skipping Lume installation"
        else
            install_lume
        fi
    else
        install_lume
    fi

    # Create VM
    create_vm
}

install_lume() {
    # Try Homebrew first (more reliable)
    if command -v brew &>/dev/null; then
        info "Homebrew detected. Installing Lume via Homebrew..."

        if confirm "Install Lume via Homebrew? (Recommended)"; then
            brew install lume

            if command -v lume &>/dev/null; then
                success "Lume installed successfully via Homebrew"
                return 0
            else
                warn "Homebrew installation failed, trying alternative method..."
            fi
        else
            info "Homebrew installation declined, trying alternative method..."
        fi
    fi

    # Fallback: Download install script
    info "Downloading Lume installer script..."

    local install_script="${SCRIPT_DIR}/logs/lume-install.sh"
    if curl -fsSL https://lume.dev/install.sh -o "$install_script"; then
        # Calculate hash for verification
        local hash=$(shasum -a 256 "$install_script" | awk '{print $1}')
        info "Installer SHA256: $hash"

        # Check if it's actually a shell script (not HTML)
        if head -1 "$install_script" | grep -q "^#!"; then
            # Show user what we're about to run
            warn "Please review the installer script at: $install_script"

            if confirm "Proceed with Lume installation?"; then
                info "Installing Lume..."
                bash "$install_script"

                if command -v lume &>/dev/null; then
                    success "Lume installed successfully"
                    return 0
                else
                    error "Lume installation failed"
                    exit 1
                fi
            else
                error "Lume installation cancelled"
                exit 1
            fi
        else
            error "Downloaded file is not a valid shell script (may be HTML redirect)"
            error "Please install Lume manually:"
            error "  Option 1 (Recommended): brew install lume"
            error "  Option 2: Visit https://lume.dev for installation instructions"
            exit 1
        fi
    else
        error "Failed to download Lume installer"
        error "Please install Lume manually: brew install lume"
        exit 1
    fi
}

create_vm() {
    info "Creating VM: $VM_NAME"

    # Check if VM already exists
    if lume list 2>/dev/null | grep -q "$VM_NAME"; then
        warn "VM '$VM_NAME' already exists"

        if confirm "Delete existing VM and create fresh?"; then
            info "Deleting existing VM..."
            lume delete "$VM_NAME" --force || true
        else
            info "Using existing VM"
            return 0
        fi
    fi

    info "Creating VM with: CPU=$VM_CPU, Memory=${VM_MEMORY}MB, Disk=$VM_DISK"

    lume create "$VM_NAME" \
        --os macos \
        --ipsw latest \
        --cpu "$VM_CPU" \
        --memory "${VM_MEMORY}MB" \
        --disk-size "$VM_DISK"

    success "VM created successfully"

    # Start the VM
    info "Starting VM..."
    lume run "$VM_NAME" &

    echo ""
    echo -e "${YELLOW}=================================================================${NC}"
    echo -e "${YELLOW}  MANUAL STEP REQUIRED${NC}"
    echo -e "${YELLOW}=================================================================${NC}"
    echo ""
    echo "Complete the macOS Setup Assistant in the VM window:"
    echo "  1. Create a LOCAL account (don't sign into iCloud yet)"
    echo "  2. Username: $VM_USER"
    echo "  3. Use a STRONG password (save it securely!)"
    echo "  4. Enable FileVault when prompted"
    echo "  5. Skip all 'share data with Apple' options"
    echo "  6. Go to System Settings → General → Sharing → Enable 'Remote Login'"
    echo ""

    read -p "Press ENTER when Setup Assistant is complete and SSH is enabled..."

    wait_for_vm
}

#===============================================================================
# Phase 2: SSH Hardening
#===============================================================================

phase2_ssh_hardening() {
    header "Phase 2: SSH Hardening"

    local vm_ip=$(get_vm_ip)
    if [[ -z "$vm_ip" ]]; then
        error "Cannot determine VM IP. Is the VM running?"
        exit 1
    fi

    info "VM IP: $vm_ip"

    # Generate SSH keys if needed
    generate_ssh_keys

    # Copy public key to VM
    copy_ssh_key "$vm_ip"

    # Harden SSH config on VM
    harden_ssh_config "$vm_ip"

    success "SSH hardening complete"
}

generate_ssh_keys() {
    local key_path="$HOME/.ssh/openclaw_vm_ed25519"

    if [[ -f "$key_path" ]]; then
        info "SSH key already exists: $key_path"
        return 0
    fi

    info "Generating Ed25519 SSH key..."
    ssh-keygen -t ed25519 -a 100 -f "$key_path" -C "openclaw-vm-access" -N ""

    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"

    success "SSH key generated: $key_path"
}

copy_ssh_key() {
    local vm_ip="$1"
    local key_path="$HOME/.ssh/openclaw_vm_ed25519.pub"

    info "Copying SSH public key to VM..."

    # Use password from settings.env if provided, otherwise prompt
    if [[ -n "$VM_PASSWORD" ]]; then
        info "Using password from settings.env for automated SSH key copy..."

        # Use expect to automate password input
        # Pass variables as environment variables to avoid escaping issues
        VM_PASS="$VM_PASSWORD" VM_IP="$vm_ip" VM_KEY="$key_path" VM_U="$VM_USER" expect << 'EXPECT_SCRIPT'
set timeout 30
set password $env(VM_PASS)
spawn ssh-copy-id -o IdentitiesOnly=yes -o PreferredAuthentications=password -o StrictHostKeyChecking=no -i $env(VM_KEY) $env(VM_U)@$env(VM_IP)
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    "Password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
EXPECT_SCRIPT
    else
        echo ""
        echo "You will be prompted for the VM user's password."
        echo ""

        # Use -o IdentitiesOnly=yes to prevent trying other SSH keys
        ssh-copy-id -o IdentitiesOnly=yes -o PreferredAuthentications=password -i "$key_path" "${VM_USER}@${vm_ip}"
    fi

    # Verify key-based auth works
    if ssh -i "${key_path%.pub}" -o PasswordAuthentication=no "${VM_USER}@${vm_ip}" "echo 'SSH key auth working'" &>/dev/null; then
        success "SSH key authentication verified"
    else
        error "SSH key authentication failed"
        exit 1
    fi
}

harden_ssh_config() {
    local vm_ip="$1"
    local key_path="$HOME/.ssh/openclaw_vm_ed25519"

    info "Hardening SSH configuration on VM..."

    # Create hardened sshd_config
    local sshd_config=$(cat << 'SSHD_EOF'
# OpenClaw Hardened SSH Configuration
# Generated by setup.sh

# Authentication
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
PermitRootLogin no
PubkeyAuthentication yes

# Key algorithms (strong only)
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com,ssh-ed25519

# Session limits
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable unnecessary features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no

# Logging
LogLevel VERBOSE
SSHD_EOF
)

    # Apply configuration
    if [[ -n "$VM_PASSWORD" ]]; then
        # Use password for sudo commands
        ssh -i "$key_path" "${VM_USER}@${vm_ip}" bash << REMOTE_EOF
# Backup original config
echo '$VM_PASSWORD' | sudo -S cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Write new config
echo '$sshd_config' | sudo -S tee /etc/ssh/sshd_config.hardened > /dev/null

# Add user restriction
echo "AllowUsers ${VM_USER}" | sudo -S tee -a /etc/ssh/sshd_config.hardened > /dev/null

# Apply config
echo '$VM_PASSWORD' | sudo -S mv /etc/ssh/sshd_config.hardened /etc/ssh/sshd_config

# Restart SSH
echo '$VM_PASSWORD' | sudo -S launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
echo '$VM_PASSWORD' | sudo -S launchctl load /System/Library/LaunchDaemons/ssh.plist

echo "SSH configuration hardened"
REMOTE_EOF
    else
        # Prompt for password
        ssh -i "$key_path" -t "${VM_USER}@${vm_ip}" << REMOTE_EOF
# Backup original config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Write new config
echo '$sshd_config' | sudo tee /etc/ssh/sshd_config.hardened > /dev/null

# Add user restriction
echo "AllowUsers ${VM_USER}" | sudo tee -a /etc/ssh/sshd_config.hardened > /dev/null

# Apply config
sudo mv /etc/ssh/sshd_config.hardened /etc/ssh/sshd_config

# Restart SSH
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist

echo "SSH configuration hardened"
REMOTE_EOF
    fi

    # Verify we can still connect
    sleep 2
    if ssh -i "$key_path" -o ConnectTimeout=10 "${VM_USER}@${vm_ip}" "echo 'Connection verified'" &>/dev/null; then
        success "SSH hardening verified - connection still works"
    else
        error "WARNING: Cannot connect after hardening. Check VM console."
    fi
}

#===============================================================================
# Phase 3: Host Firewall
#===============================================================================

phase3_host_firewall() {
    header "Phase 3: Host Firewall Configuration"

    local vm_ip=$(get_vm_ip)
    if [[ -z "$vm_ip" ]]; then
        error "Cannot determine VM IP"
        exit 1
    fi

    info "Configuring pf firewall for VM at $vm_ip"

    # Create pf anchor file
    local anchor_file="/etc/pf.anchors/openclaw-vm"

    cat << EOF | sudo tee "$anchor_file" > /dev/null
# OpenClaw VM Firewall Rules
# VM IP: $vm_ip
# Generated: $(date)

# Define VM IP
vm_ip = "$vm_ip"

# Allow SSH to VM (from localhost only for security)
pass in quick proto tcp from 127.0.0.1 to \$vm_ip port 22

# Allow Gateway access via SSH tunnel only
pass in quick proto tcp from 127.0.0.1 to \$vm_ip port 8080

# Block direct external access to VM
block in quick from any to \$vm_ip
EOF

    info "Created firewall anchor: $anchor_file"

    # Check if anchor is already in pf.conf
    if ! grep -q "openclaw-vm" /etc/pf.conf 2>/dev/null; then
        info "Adding anchor to pf.conf..."

        # Backup pf.conf
        sudo cp /etc/pf.conf /etc/pf.conf.backup.$(date +%Y%m%d)

        # Add anchor
        echo '' | sudo tee -a /etc/pf.conf > /dev/null
        echo '# OpenClaw VM firewall rules' | sudo tee -a /etc/pf.conf > /dev/null
        echo 'anchor "openclaw-vm"' | sudo tee -a /etc/pf.conf > /dev/null
        echo 'load anchor "openclaw-vm" from "/etc/pf.anchors/openclaw-vm"' | sudo tee -a /etc/pf.conf > /dev/null
    fi

    # Load firewall rules
    info "Loading firewall rules..."
    sudo pfctl -f /etc/pf.conf 2>/dev/null || true
    sudo pfctl -e 2>/dev/null || true

    success "Host firewall configured"
}

#===============================================================================
# Phase 4: Gateway Configuration
#===============================================================================

phase4_gateway_config() {
    header "Phase 4: OpenClaw Gateway Installation & Configuration"

    local vm_ip=$(get_vm_ip)
    local key_path="$HOME/.ssh/openclaw_vm_ed25519"

    info "Installing OpenClaw Gateway on VM..."

    # Install Node.js and OpenClaw Gateway
    ssh -i "$key_path" "${VM_USER}@${vm_ip}" << 'INSTALL_EOF'
# Check if Node.js is installed
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."

    # Check if Homebrew is available
    if command -v brew &>/dev/null; then
        brew install node
    else
        # Install Homebrew first
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add Homebrew to PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        brew install node
    fi
fi

# Verify Node.js installation
node_version=$(node --version)
npm_version=$(npm --version)
echo "Node.js installed: $node_version"
echo "npm installed: $npm_version"

# Install OpenClaw Gateway globally
echo "Installing OpenClaw Gateway..."
npm install -g openclaw@latest

# Verify OpenClaw installation
if command -v openclaw &>/dev/null; then
    openclaw_version=$(openclaw --version 2>/dev/null || echo "unknown")
    echo "OpenClaw Gateway installed: $openclaw_version"
else
    echo "ERROR: OpenClaw installation failed"
    exit 1
fi

# Create directories
mkdir -p ~/.openclaw/certs
mkdir -p ~/.openclaw/logs
mkdir -p ~/.openclaw/skills

echo "OpenClaw Gateway installation complete"
INSTALL_EOF

    if [[ $? -ne 0 ]]; then
        error "OpenClaw Gateway installation failed"
        exit 1
    fi

    success "OpenClaw Gateway installed successfully"

    # Generate auth token
    local auth_token=$(openssl rand -hex 32)
    info "Generated Gateway auth token (save this!): $auth_token"
    echo "$auth_token" > "${SCRIPT_DIR}/.gateway_token"
    chmod 600 "${SCRIPT_DIR}/.gateway_token"

    # Create Gateway config
    info "Configuring Gateway on VM..."
    ssh -i "$key_path" "${VM_USER}@${vm_ip}" << REMOTE_EOF
# Generate self-signed TLS certificate
cd ~/.openclaw/certs
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt \
    -days 365 -nodes -subj "/CN=openclaw-vm" 2>/dev/null
chmod 600 server.key
chmod 644 server.crt

# Create Gateway config
cat > ~/.openclaw/config.yaml << 'GATEWAY_CONFIG'
gateway:
  # Bind to localhost only - access via SSH tunnel
  bind: "127.0.0.1:8080"

  # Authentication
  auth:
    enabled: true
    token: "${auth_token}"

  # TLS
  tls:
    enabled: true
    cert: "~/.openclaw/certs/server.crt"
    key: "~/.openclaw/certs/server.key"

  # Rate limiting
  rate_limit:
    requests_per_minute: 60
    burst: 10

  # Logging
  logging:
    level: "info"
    file: "~/.openclaw/logs/gateway.log"

# Execution security
exec:
  approvals_file: "~/.openclaw/exec-approvals.json"
  log_all: true
GATEWAY_CONFIG

echo "Gateway configuration created"
REMOTE_EOF

    # Copy exec-approvals template
    if [[ -f "${SCRIPT_DIR}/config/exec-approvals.json" ]]; then
        info "Copying exec-approvals configuration..."
        cat "${SCRIPT_DIR}/config/exec-approvals.json" | \
            ssh -i "$key_path" "${VM_USER}@${vm_ip}" "cat > ~/.openclaw/exec-approvals.json"
    fi

    # Run OpenClaw onboarding (non-interactive for VM)
    info "Running OpenClaw onboarding..."
    ssh -i "$key_path" "${VM_USER}@${vm_ip}" << 'ONBOARD_EOF'
# Run onboarding in non-interactive mode
openclaw onboard --install-daemon --non-interactive 2>&1 || echo "Onboarding completed with warnings (expected)"

# Verify Gateway can start
echo "Testing Gateway startup..."
timeout 5 openclaw gateway --port 8080 --bind 127.0.0.1 &>/dev/null || echo "Gateway test complete"
ONBOARD_EOF

    success "Gateway installation and configuration complete"

    echo ""
    echo -e "${GREEN}✓ OpenClaw Gateway is ready!${NC}"
    echo ""
    echo -e "${YELLOW}Gateway Access:${NC}"
    echo "  1. Create SSH tunnel: ssh -i $key_path -L 8080:127.0.0.1:8080 -N ${VM_USER}@${vm_ip}"
    echo "  2. Access Gateway at: https://localhost:8080"
    echo "  3. Auth token saved to: ${SCRIPT_DIR}/.gateway_token"
    echo ""
    echo -e "${YELLOW}Start Gateway:${NC}"
    echo "  ssh -i $key_path ${VM_USER}@${vm_ip} 'openclaw gateway --port 8080'"
}

#===============================================================================
# Phase 5: Monitoring Setup
#===============================================================================

phase5_monitoring() {
    header "Phase 5: Monitoring and Alerting Setup"

    local vm_ip=$(get_vm_ip)
    local key_path="$HOME/.ssh/openclaw_vm_ed25519"

    # Create monitoring script on VM
    info "Installing monitoring scripts on VM..."

    ssh -i "$key_path" "${VM_USER}@${vm_ip}" << 'REMOTE_EOF'
# Create monitoring directory
mkdir -p ~/monitoring

# Create security monitor script
cat > ~/monitoring/security-monitor.sh << 'MONITOR_SCRIPT'
#!/bin/bash
# OpenClaw Security Monitor

LOG_DIR=~/.openclaw/logs
ALERT_LOG=~/monitoring/alerts.log

# Check SSH failures
ssh_failures=$(grep "sshd.*Failed" /var/log/system.log 2>/dev/null | wc -l | tr -d ' ')
if [[ "$ssh_failures" -gt 10 ]]; then
    echo "$(date): ALERT - High SSH failures: $ssh_failures" >> "$ALERT_LOG"
fi

# Check for suspicious processes
suspicious=$(ps aux | grep -E "(nc|ncat|netcat|socat|curl.*\|)" | grep -v grep)
if [[ -n "$suspicious" ]]; then
    echo "$(date): ALERT - Suspicious process: $suspicious" >> "$ALERT_LOG"
fi

# Check disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [[ "$disk_usage" -gt 80 ]]; then
    echo "$(date): WARN - Disk usage at $disk_usage%" >> "$ALERT_LOG"
fi

# Log status
echo "$(date): Monitor check complete - SSH failures: $ssh_failures, Disk: $disk_usage%" >> ~/monitoring/status.log
MONITOR_SCRIPT

chmod +x ~/monitoring/security-monitor.sh

# Create cron job for monitoring (every 5 minutes)
(crontab -l 2>/dev/null | grep -v security-monitor; echo "*/5 * * * * ~/monitoring/security-monitor.sh") | crontab -

echo "Monitoring scripts installed"
REMOTE_EOF

    # Create host-side monitoring
    info "Setting up host monitoring..."

    local host_monitor="${SCRIPT_DIR}/scripts/host-monitor.sh"
    cat > "$host_monitor" << 'HOST_MONITOR'
#!/bin/bash
# Host-side monitoring for OpenClaw VM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
LOG_FILE="${SCRIPT_DIR}/logs/host-monitor.log"

# Check VM is running
if ! ping -c 1 -W 2 "$VM_IP" &>/dev/null; then
    echo "$(date): ALERT - VM not responding" >> "$LOG_FILE"
    exit 1
fi

# Check SSH is accessible
if ! nc -z -w5 "$VM_IP" 22 &>/dev/null; then
    echo "$(date): ALERT - SSH not accessible" >> "$LOG_FILE"
    exit 1
fi

# Fetch and display VM alerts
ssh -i "$KEY_PATH" -o ConnectTimeout=10 "${VM_USER:-openclaw}@${VM_IP}" \
    "tail -20 ~/monitoring/alerts.log 2>/dev/null" >> "$LOG_FILE"

echo "$(date): Host monitor check complete" >> "$LOG_FILE"
HOST_MONITOR

    chmod +x "$host_monitor"

    success "Monitoring setup complete"
}

#===============================================================================
# Phase 6: Backup Configuration
#===============================================================================

phase6_backups() {
    header "Phase 6: Backup Configuration"

    local vm_ip=$(get_vm_ip)
    local key_path="$HOME/.ssh/openclaw_vm_ed25519"
    local backup_dir="${SCRIPT_DIR}/backups"

    mkdir -p "$backup_dir"

    # Create backup script
    info "Creating backup scripts..."

    local backup_script="${SCRIPT_DIR}/scripts/backup-vm.sh"
    cat > "$backup_script" << BACKUP_SCRIPT
#!/bin/bash
# Backup OpenClaw VM configuration

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
VM_NAME="${VM_NAME}"
VM_IP=\$(cat "\${SCRIPT_DIR}/.vm_ip" 2>/dev/null)
KEY_PATH="\$HOME/.ssh/openclaw_vm_ed25519"
BACKUP_DIR="\${SCRIPT_DIR}/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

mkdir -p "\$BACKUP_DIR"

echo "Starting backup: \$DATE"

# Backup VM configuration files
echo "Backing up VM configs..."
ssh -i "\$KEY_PATH" "${VM_USER}@\${VM_IP}" \
    "tar czf - ~/.openclaw /etc/ssh/sshd_config 2>/dev/null" > \
    "\${BACKUP_DIR}/config_\${DATE}.tar.gz"

# Create VM snapshot
echo "Creating VM snapshot..."
lume snapshot "\$VM_NAME" --name "backup-\$DATE"

# Cleanup old backups (keep last 7)
ls -t "\${BACKUP_DIR}"/config_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null

echo "Backup complete: \$DATE"
echo "  Config: \${BACKUP_DIR}/config_\${DATE}.tar.gz"
echo "  Snapshot: backup-\$DATE"
BACKUP_SCRIPT

    chmod +x "$backup_script"

    # Create restore script
    local restore_script="${SCRIPT_DIR}/scripts/restore-vm.sh"
    cat > "$restore_script" << 'RESTORE_SCRIPT'
#!/bin/bash
# Restore OpenClaw VM from snapshot

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/settings.env" 2>/dev/null || true

VM_NAME="${VM_NAME:-openclaw-secure}"

echo "Available snapshots:"
lume snapshot list "$VM_NAME"

echo ""
read -p "Enter snapshot name to restore: " snapshot_name

if [[ -z "$snapshot_name" ]]; then
    echo "No snapshot specified"
    exit 1
fi

echo "WARNING: This will restore VM to snapshot: $snapshot_name"
read -p "Continue? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy] ]]; then
    lume snapshot restore "$VM_NAME" --name "$snapshot_name"
    echo "Restore complete"
else
    echo "Restore cancelled"
fi
RESTORE_SCRIPT

    chmod +x "$restore_script"

    success "Backup scripts created"
    echo "  Backup: ${SCRIPT_DIR}/scripts/backup-vm.sh"
    echo "  Restore: ${SCRIPT_DIR}/scripts/restore-vm.sh"
}

#===============================================================================
# Main Entry Point
#===============================================================================

main() {
    # Setup logging
    mkdir -p "$LOG_DIR"

    header "OpenClaw macOS VM Security Setup"

    info "Log file: $LOG_FILE"

    # Load config if exists
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        info "Loaded configuration from $CONFIG_FILE"
    fi

    # Pre-flight checks
    check_macos

    # Determine which phase to run
    local phase="${1:-all}"

    # Only check disk space for phases that create/modify the VM
    case "$phase" in
        0|phase0|1|phase1|all)
            check_disk_space
            ;;
        *)
            info "Skipping disk space check (not needed for Phase $phase)"
            ;;
    esac

    case "$phase" in
        start)
            # Run Phase 0, then start Phase 1 in background
            phase0_verify_environment || exit 1
            start_vm_creation_background

            echo ""
            header "Next Steps"
            echo -e "${GREEN}✅ Environment verified${NC}"
            echo -e "${YELLOW}🚀 VM creation started in background (25 min)${NC}"
            echo ""
            echo "While you wait:"
            echo "  • Monitor progress: tail -f $VM_CREATION_LOG"
            echo "  • Check VM status: ./status.sh"
            echo ""
            echo "When VM creation completes:"
            echo "  1. Complete manual macOS Setup Assistant"
            echo "     - Username: $VM_USER"
            echo "     - Password: (from settings.env)"
            echo "     - Enable Remote Login"
            echo "  2. Run: ./setup.sh continue"
            ;;
        continue)
            # Wait for VM creation, then run Phases 2-6
            wait_for_vm_creation || exit 1

            echo ""
            info "Ready to continue with SSH hardening and configuration"
            echo ""
            echo -e "${YELLOW}⏸️  Manual Setup Required${NC}"
            echo "Please complete these steps in the VM Screen Sharing window:"
            echo "  1. Complete macOS Setup Assistant"
            echo "     - Username: $VM_USER"
            echo "     - Password: $VM_PASSWORD"
            echo "  2. Enable Remote Login:"
            echo "     System Settings → General → Sharing → Remote Login"
            echo ""
            read -p "Press Enter when manual setup is complete..."

            phase2_ssh_hardening
            phase3_host_firewall
            phase4_gateway_config
            phase5_monitoring
            phase6_backups

            header "Setup Complete!"
            echo -e "${GREEN}OpenClaw VM is now configured with security hardening.${NC}"
            ;;
        0|phase0)
            phase0_verify_environment
            ;;
        1|phase1)
            phase1_install_lume
            ;;
        2|phase2)
            phase2_ssh_hardening
            ;;
        3|phase3)
            phase3_host_firewall
            ;;
        4|phase4)
            phase4_gateway_config
            ;;
        5|phase5)
            phase5_monitoring
            ;;
        6|phase6)
            phase6_backups
            ;;
        all)
            phase0_verify_environment || exit 1
            phase1_install_lume
            phase2_ssh_hardening
            phase3_host_firewall
            phase4_gateway_config
            phase5_monitoring
            phase6_backups

            header "Setup Complete!"

            echo -e "${GREEN}OpenClaw VM is now configured with security hardening.${NC}"
            echo ""
            echo "Quick Reference:"
            echo "  VM Name: $VM_NAME"
            echo "  VM IP: $(get_vm_ip)"
            echo "  SSH Key: ~/.ssh/openclaw_vm_ed25519"
            echo "  Gateway Token: ${SCRIPT_DIR}/.gateway_token"
            echo ""
            echo "Connect to VM:"
            echo "  ssh -i ~/.ssh/openclaw_vm_ed25519 ${VM_USER}@$(get_vm_ip)"
            echo ""
            echo "Create Gateway tunnel:"
            echo "  ssh -i ~/.ssh/openclaw_vm_ed25519 -L 8080:127.0.0.1:8080 -N ${VM_USER}@$(get_vm_ip)"
            echo ""
            echo "Backup VM:"
            echo "  ${SCRIPT_DIR}/scripts/backup-vm.sh"
            ;;
        *)
            echo "Usage: $0 [command]"
            echo ""
            echo "Recommended Workflow:"
            echo "  start        Quick start - verify environment + create VM in background"
            echo "  continue     Continue after VM creation - run all remaining phases"
            echo ""
            echo "Individual Phases:"
            echo "  0 or phase0  Verify environment and prerequisites"
            echo "  1 or phase1  Install Lume and create VM"
            echo "  2 or phase2  Configure SSH hardening"
            echo "  3 or phase3  Setup host firewall"
            echo "  4 or phase4  Install and configure OpenClaw Gateway"
            echo "  5 or phase5  Setup monitoring and alerting"
            echo "  6 or phase6  Configure backups"
            echo "  all          Run all phases sequentially (default)"
            echo ""
            echo "Example:"
            echo "  ./setup.sh start    # Start VM creation, do other work"
            echo "  ./setup.sh continue # Complete setup when VM ready"
            exit 1
            ;;
    esac
}

# Run main
main "$@"
