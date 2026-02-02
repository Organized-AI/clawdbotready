#!/usr/bin/env bash
#===============================================================================
# OpenClaw Native - Emergency Stop (Kill Switch)
#===============================================================================
# Immediately stop all Gateway processes and disable auto-restart
# Use this if the Gateway is compromised or behaving maliciously
#
# Usage: ./emergency-stop.sh
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
LAUNCHAGENT_PLIST="${LAUNCHAGENT_PLIST:-/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}==================================================================${NC}"
echo -e "${RED}  EMERGENCY STOP - OpenClaw Gateway${NC}"
echo -e "${RED}==================================================================${NC}"
echo ""

echo -e "${YELLOW}WARNING: This will immediately stop the Gateway and prevent auto-restart${NC}"
echo ""

read -p "Are you sure you want to proceed? [y/N]: " response

if [[ ! "$response" =~ ^[Yy] ]]; then
    echo "Emergency stop cancelled"
    exit 0
fi

echo ""
echo "Initiating emergency shutdown..."

# Step 1: Unload LaunchAgent (prevents auto-restart)
echo "1. Disabling LaunchAgent..."
local user_id=$(id -u "$OPENCLAW_USER")

if sudo launchctl bootout "gui/${user_id}/ai.openclaw.gateway" 2>/dev/null; then
    echo "   ✓ LaunchAgent disabled"
else
    echo "   ⚠ LaunchAgent may not have been loaded"
fi

# Step 2: Kill all Gateway processes
echo "2. Terminating Gateway processes..."

if pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
    local pids=$(pgrep -u "$OPENCLAW_USER" openclaw-gateway)

    for pid in $pids; do
        echo "   Killing PID $pid..."
        sudo kill -TERM "$pid" 2>/dev/null || true
    done

    # Wait for graceful shutdown
    sleep 2

    # Force kill if still running
    if pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
        echo "   Force killing remaining processes..."
        sudo pkill -KILL -u "$OPENCLAW_USER" openclaw-gateway 2>/dev/null || true
    fi

    echo "   ✓ All Gateway processes terminated"
else
    echo "   ⚠ No Gateway processes found"
fi

# Step 3: Lock user account (optional but recommended)
echo "3. Locking user account..."
read -p "Lock openclaw user account to prevent login? [Y/n]: " lock_response

if [[ "$lock_response" =~ ^[Nn] ]]; then
    echo "   Skipping account lock"
else
    sudo dscl . -create "/Users/$OPENCLAW_USER" AuthenticationAuthority ";DisabledUser;"
    echo "   ✓ User account locked"
fi

echo ""
echo -e "${RED}EMERGENCY STOP COMPLETE${NC}"
echo ""
echo "The Gateway has been stopped and will not auto-restart."
echo ""
echo "Next steps:"
echo "  - Review logs: ${GATEWAY_LOG_DIR:-/Users/openclaw/.openclaw/logs}/"
echo "  - Investigate security incident"
echo "  - To restart: ./scripts/restart.sh"
echo "  - To unlock account: sudo dscl . -delete /Users/$OPENCLAW_USER AuthenticationAuthority"
echo ""
