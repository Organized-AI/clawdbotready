#!/usr/bin/env bash
#===============================================================================
# Moltbook Integration Setup
#===============================================================================
# Connects OpenClaw agent to Moltbook for agent management and monitoring
# https://www.moltbook.com/
#
# Usage: ./moltbook-setup.sh
#===============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_IP=$(cat "${SCRIPT_DIR}/.vm_ip" 2>/dev/null || echo "")
VM_USER="${VM_USER:-openclaw}"
SSH_KEY="$HOME/.ssh/openclaw_vm_ed25519"
LOG_FILE="${SCRIPT_DIR}/logs/moltbook-setup-$(date +%Y%m%d_%H%M%S).log"

# Utility functions
log() {
    echo -e "$@" | tee -a "$LOG_FILE"
}

header() {
    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}  $*${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

info() {
    log "${BLUE}[INFO]${NC} $*"
}

success() {
    log "${GREEN}[SUCCESS]${NC} $*"
}

error() {
    log "${RED}[ERROR]${NC} $*"
}

warn() {
    log "${YELLOW}[WARN]${NC} $*"
}

# Check prerequisites
check_prerequisites() {
    header "Checking Prerequisites"

    # Check VM IP
    if [[ -z "$VM_IP" ]]; then
        error "VM IP not found. Is the VM running?"
        error "Run './setup.sh' first to create and configure the VM."
        exit 1
    fi
    info "VM IP: $VM_IP"

    # Check SSH key
    if [[ ! -f "$SSH_KEY" ]]; then
        error "SSH key not found: $SSH_KEY"
        error "Run './setup.sh 2' to configure SSH hardening."
        exit 1
    fi
    info "SSH key: $SSH_KEY"

    # Test SSH connectivity
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=5 "${VM_USER}@${VM_IP}" "echo 'SSH OK'" &>/dev/null; then
        error "Cannot connect to VM via SSH"
        error "Ensure the VM is running and SSH is configured."
        exit 1
    fi
    success "SSH connectivity verified"

    # Check if OpenClaw Gateway is installed
    if ! ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" "command -v openclaw &>/dev/null || [[ -f ~/.openclaw/config.yaml ]]" 2>/dev/null; then
        warn "OpenClaw Gateway may not be installed yet"
        warn "This script assumes OpenClaw is installed and running"
        echo ""
        read -p "Continue anyway? [y/N]: " response
        if [[ ! "$response" =~ ^[Yy] ]]; then
            info "Exiting. Install OpenClaw Gateway first, then run this script."
            exit 0
        fi
    fi

    success "Prerequisites check complete"
}

# Install Moltbook integration
install_moltbook() {
    header "Installing Moltbook Integration"

    info "Installing Moltbook on VM..."

    # Method 1: Try npx (if Node.js is available)
    ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" bash << 'REMOTE_INSTALL'
set -e

echo "[INFO] Checking installation methods..."

# Check if npx is available
if command -v npx &>/dev/null; then
    echo "[INFO] npx found - installing via molthub"

    # Install Moltbook via molthub
    npx molthub@latest install moltbook

    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Moltbook installed successfully via npx"
        exit 0
    else
        echo "[WARN] npx installation failed, trying curl method..."
    fi
fi

# Method 2: Fallback to curl
echo "[INFO] Installing via curl..."

if command -v curl &>/dev/null; then
    # Create moltbook directory
    mkdir -p ~/.moltbook

    # Download skill definition
    curl -s https://moltbook.com/skill.md -o ~/.moltbook/skill.md

    if [[ $? -eq 0 && -f ~/.moltbook/skill.md ]]; then
        echo "[SUCCESS] Moltbook skill downloaded successfully"

        # Make it available to OpenClaw (assuming skill loading mechanism)
        # You may need to adjust this based on how OpenClaw loads skills
        if [[ -d ~/.openclaw/skills ]]; then
            cp ~/.moltbook/skill.md ~/.openclaw/skills/moltbook.md
            echo "[INFO] Copied Moltbook skill to OpenClaw skills directory"
        fi

        exit 0
    else
        echo "[ERROR] Failed to download Moltbook skill"
        exit 1
    fi
else
    echo "[ERROR] Neither npx nor curl is available"
    echo "[ERROR] Please install Node.js or curl to proceed"
    exit 1
fi
REMOTE_INSTALL

    if [[ $? -eq 0 ]]; then
        success "Moltbook installation complete"
        return 0
    else
        error "Moltbook installation failed"
        return 1
    fi
}

# Get claim link
get_claim_link() {
    header "Retrieving Moltbook Claim Link"

    info "Generating claim link for agent verification..."

    # Get claim link from Moltbook
    # This assumes Moltbook provides a claim link after installation
    # Adjust based on actual Moltbook API/CLI behavior

    local claim_link
    claim_link=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" bash << 'REMOTE_CLAIM'
set -e

# Try to get claim link from Moltbook
if command -v moltbook &>/dev/null; then
    # If Moltbook has a CLI command to get claim link
    moltbook claim 2>/dev/null || echo "CLAIM_NOT_AVAILABLE"
elif [[ -f ~/.moltbook/claim_url ]]; then
    # If claim URL is stored in a file
    cat ~/.moltbook/claim_url
else
    # Check for claim link in recent npx output or logs
    if [[ -f ~/.moltbook/install.log ]]; then
        grep -oE 'https://moltbook\.com/claim/[a-zA-Z0-9_-]+' ~/.moltbook/install.log | head -1 || echo "CLAIM_NOT_AVAILABLE"
    else
        echo "CLAIM_NOT_AVAILABLE"
    fi
fi
REMOTE_CLAIM
)

    if [[ "$claim_link" == "CLAIM_NOT_AVAILABLE" ]] || [[ -z "$claim_link" ]]; then
        warn "Claim link not automatically available"
        warn "You may need to check Moltbook documentation for manual claim process"
        echo ""
        echo "Possible next steps:"
        echo "  1. SSH into VM: ./scripts/connect.sh"
        echo "  2. Check Moltbook logs/output for claim URL"
        echo "  3. Visit https://www.moltbook.com/ for manual setup instructions"
        return 1
    else
        success "Claim link retrieved successfully"
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  🔗 Moltbook Claim Link${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "  ${claim_link}"
        echo ""
        echo -e "${YELLOW}ACTION REQUIRED:${NC}"
        echo "  1. Open the claim link above in your browser"
        echo "  2. Verify agent ownership"
        echo "  3. Configure agent settings in Moltbook dashboard"
        echo ""
        echo -e "${BLUE}After verification:${NC}"
        echo "  • Your OpenClaw agent will appear in Moltbook"
        echo "  • You can monitor agent activity"
        echo "  • Manage agent permissions and integrations"
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # Save claim link to file for reference
        echo "$claim_link" > "${SCRIPT_DIR}/.moltbook_claim_link"
        info "Claim link saved to: ${SCRIPT_DIR}/.moltbook_claim_link"

        return 0
    fi
}

# Verify Moltbook integration
verify_integration() {
    header "Verifying Moltbook Integration"

    info "Checking Moltbook status in VM..."

    # Check if Moltbook files exist
    local has_moltbook
    has_moltbook=$(ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" bash << 'REMOTE_VERIFY'
if [[ -d ~/.moltbook ]] || command -v moltbook &>/dev/null; then
    echo "INSTALLED"
else
    echo "NOT_INSTALLED"
fi
REMOTE_VERIFY
)

    if [[ "$has_moltbook" == "INSTALLED" ]]; then
        success "Moltbook integration verified"

        # Check for running Moltbook processes
        info "Checking for Moltbook processes..."
        ssh -i "$SSH_KEY" "${VM_USER}@${VM_IP}" "ps aux | grep -i moltbook | grep -v grep" || true

        return 0
    else
        error "Moltbook integration not verified"
        return 1
    fi
}

# Main execution
main() {
    mkdir -p "${SCRIPT_DIR}/logs"

    header "Moltbook Integration Setup"
    echo ""
    echo "  This script will connect your OpenClaw agent to Moltbook"
    echo "  for centralized agent management and monitoring."
    echo ""
    echo "  Website: https://www.moltbook.com/"
    echo "  Log file: $LOG_FILE"
    echo ""

    # Step 1: Check prerequisites
    check_prerequisites

    # Step 2: Install Moltbook
    if ! install_moltbook; then
        error "Installation failed. Check log: $LOG_FILE"
        exit 1
    fi

    # Step 3: Get claim link
    get_claim_link

    # Step 4: Verify integration
    verify_integration

    # Final summary
    header "Setup Complete"
    echo ""
    echo -e "${GREEN}✅ Moltbook integration setup complete${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Open the claim link provided above"
    echo "  2. Complete agent verification"
    echo "  3. Access your agent dashboard at https://www.moltbook.com/"
    echo ""
    echo "Troubleshooting:"
    echo "  • View setup log: cat $LOG_FILE"
    echo "  • Check Moltbook status: ssh to VM and check ~/.moltbook/"
    echo "  • SSH into VM: ./scripts/connect.sh"
    echo ""
}

# Run main
main "$@"
