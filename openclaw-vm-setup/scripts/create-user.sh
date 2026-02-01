#!/bin/bash
#===============================================================================
# Create Host User - Standalone Script
#===============================================================================
# Creates a dedicated macOS user account for VM access via Screen Sharing
#
# Usage: ./create-user.sh [username] [fullname] [--admin]
#   Or configure in config/settings.env and run without arguments
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Load configuration if available
if [[ -f "${SCRIPT_DIR}/config/settings.env" ]]; then
    source "${SCRIPT_DIR}/config/settings.env"
fi

# Override with command line arguments
if [[ $# -ge 1 ]] && [[ "$1" != "--"* ]]; then
    HOST_USER_NAME="$1"
fi

if [[ $# -ge 2 ]] && [[ "$2" != "--"* ]]; then
    HOST_USER_FULLNAME="$2"
fi

# Check for --admin flag
HOST_USER_ADMIN="${HOST_USER_ADMIN:-false}"
for arg in "$@"; do
    if [[ "$arg" == "--admin" ]]; then
        HOST_USER_ADMIN="true"
    fi
done

# Apply unified naming if INSTANCE_NAME is set and no explicit username given
INSTANCE_NAME="${INSTANCE_NAME:-}"
if [[ -n "$INSTANCE_NAME" ]] && [[ -z "${HOST_USER_NAME:-}" ]]; then
    HOST_USER_NAME="$INSTANCE_NAME"
    HOST_USER_FULLNAME="${HOST_USER_FULLNAME:-$(echo "$INSTANCE_NAME" | sed 's/\b\(.\)/\u\1/g' | tr '-' ' ') Operator}"
fi

# Defaults
HOST_USER_NAME="${HOST_USER_NAME:-}"
HOST_USER_FULLNAME="${HOST_USER_FULLNAME:-}"
HOST_USER_PASSWORD="${HOST_USER_PASSWORD:-}"
HOST_USER_SHELL="${HOST_USER_SHELL:-/bin/zsh}"

show_help() {
    echo "Create Host User - OpenClaw VM Setup"
    echo ""
    echo "Usage: $0 [username] [fullname] [--admin]"
    echo ""
    echo "Options:"
    echo "  username     Username for the new account (lowercase, no spaces)"
    echo "  fullname     Display name for the user"
    echo "  --admin      Grant admin privileges"
    echo ""
    echo "Examples:"
    echo "  $0 vmoperator \"VM Operator\""
    echo "  $0 vmoperator \"VM Operator\" --admin"
    echo ""
    echo "Or configure in config/settings.env:"
    echo "  HOST_USER_NAME=\"vmoperator\""
    echo "  HOST_USER_FULLNAME=\"VM Operator\""
    echo "  HOST_USER_PASSWORD=\"secure-password\""
    echo ""
}

check_user_exists() {
    dscl . -read /Users/"$1" &>/dev/null
}

# Check for help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

# Check we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script must be run on macOS"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Create Host User for VM Access${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Interactive configuration if needed
if [[ -z "$HOST_USER_NAME" ]]; then
    read -p "Username (lowercase, no spaces): " HOST_USER_NAME
fi

# Validate username
if [[ ! "$HOST_USER_NAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    error "Invalid username. Use lowercase letters, numbers, underscore, hyphen."
    exit 1
fi

if check_user_exists "$HOST_USER_NAME"; then
    warn "User '$HOST_USER_NAME' already exists"
    echo ""
    dscl . -read /Users/"$HOST_USER_NAME" RealName UniqueID 2>/dev/null || true
    echo ""
    exit 0
fi

if [[ -z "$HOST_USER_FULLNAME" ]]; then
    read -p "Full Name [$HOST_USER_NAME]: " HOST_USER_FULLNAME
    HOST_USER_FULLNAME="${HOST_USER_FULLNAME:-$HOST_USER_NAME}"
fi

if [[ -z "$HOST_USER_PASSWORD" ]]; then
    while true; do
        read -sp "Password: " HOST_USER_PASSWORD
        echo ""

        if [[ ${#HOST_USER_PASSWORD} -lt 8 ]]; then
            error "Password must be at least 8 characters"
            continue
        fi

        read -sp "Confirm Password: " confirm
        echo ""

        if [[ "$HOST_USER_PASSWORD" == "$confirm" ]]; then
            break
        fi
        error "Passwords do not match"
    done
fi

# Show summary
echo ""
echo "User Configuration:"
echo "  Username: $HOST_USER_NAME"
echo "  Full Name: $HOST_USER_FULLNAME"
echo "  Admin: $HOST_USER_ADMIN"
echo "  Shell: $HOST_USER_SHELL"
echo ""

read -p "Create this user? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    info "Cancelled"
    exit 0
fi

# Create user
info "Creating user '$HOST_USER_NAME'..."

admin_flag=""
if [[ "$HOST_USER_ADMIN" == "true" ]]; then
    admin_flag="-admin"
fi

if sudo sysadminctl -addUser "$HOST_USER_NAME" \
    -fullName "$HOST_USER_FULLNAME" \
    -password "$HOST_USER_PASSWORD" \
    -shell "$HOST_USER_SHELL" \
    $admin_flag 2>&1; then

    success "User '$HOST_USER_NAME' created successfully!"
else
    error "Failed to create user"
    exit 1
fi

# Enable Screen Sharing access
info "Configuring Screen Sharing access..."

# Try to add to screen sharing access group
if dscl . -read /Groups/com.apple.access_screensharing &>/dev/null; then
    sudo dscl . -append /Groups/com.apple.access_screensharing GroupMembership "$HOST_USER_NAME" 2>/dev/null || true
fi

echo ""
success "Host user '$HOST_USER_NAME' is ready!"
echo ""
echo "Next Steps:"
echo "  1. Log out of current session (Cmd+Shift+Q)"
echo "  2. Log in as '$HOST_USER_NAME'"
echo "  3. Run VM setup: cd $SCRIPT_DIR && ./setup.sh start"
echo "  4. Access VM via Screen Sharing once created"
echo ""
