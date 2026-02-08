#!/usr/bin/env bash
#===============================================================================
# OpenClaw Native - Connect to User Account
#===============================================================================
# Login to the openclaw user account for manual inspection or debugging
#
# Usage: ./connect.sh
#===============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/settings.env"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=../config/settings.env
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

OPENCLAW_USER="${OPENCLAW_USER:-openclaw}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==================================================================${NC}"
echo -e "${CYAN}  Connecting to OpenClaw User Account${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo ""

# Check if user exists
if ! id "$OPENCLAW_USER" &>/dev/null; then
    echo -e "${YELLOW}ERROR: User '$OPENCLAW_USER' does not exist${NC}"
    echo "Run setup.sh first to create the user account"
    exit 1
fi

echo -e "${GREEN}Switching to user: $OPENCLAW_USER${NC}"
echo ""
echo "You will be prompted for your sudo password"
echo "Type 'exit' to return to your normal user account"
echo ""

# Switch to openclaw user
exec sudo -u "$OPENCLAW_USER" -i
