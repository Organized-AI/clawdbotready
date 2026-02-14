#!/usr/bin/env bash
#===============================================================================
# OpenClaw Native - Restart Gateway
#===============================================================================
# Gracefully restart the OpenClaw Gateway process
#
# Usage: ./restart.sh [--force]
#   --force: Force kill if graceful shutdown fails
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
OPENCLAW_HOME="${OPENCLAW_HOME:-/Users/openclaw}"
LAUNCHAGENT_PLIST="${LAUNCHAGENT_PLIST:-${OPENCLAW_HOME}/Library/LaunchAgents/ai.openclaw.gateway.plist}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

FORCE_MODE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE_MODE=true
fi

echo -e "${CYAN}==================================================================${NC}"
echo -e "${CYAN}  Restarting OpenClaw Gateway${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo ""

# Check if user exists
if ! id "$OPENCLAW_USER" &>/dev/null; then
    echo "ERROR: User '$OPENCLAW_USER' does not exist"
    exit 1
fi

# Get user ID for launchctl
user_id=$(id -u "$OPENCLAW_USER")

# Step 1: Stop Gateway gracefully
echo "1. Stopping Gateway..."

if pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
    local pid=$(pgrep -u "$OPENCLAW_USER" openclaw-gateway)
    echo "   Found Gateway process (PID: $pid)"

    # Try graceful shutdown via SIGTERM
    echo "   Sending SIGTERM..."
    sudo kill -TERM "$pid" 2>/dev/null || true

    # Wait for graceful shutdown (up to 10 seconds)
    local waited=0
    while pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null && [[ $waited -lt 10 ]]; do
        sleep 1
        waited=$((waited + 1))
    done

    # Check if still running
    if pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
        if [[ "$FORCE_MODE" == "true" ]]; then
            echo "   Graceful shutdown failed, force killing..."
            sudo pkill -KILL -u "$OPENCLAW_USER" openclaw-gateway 2>/dev/null || true
        else
            echo -e "${YELLOW}   WARNING: Gateway did not stop gracefully${NC}"
            echo "   Run with --force to force kill"
            exit 1
        fi
    fi

    echo "   ✓ Gateway stopped"
else
    echo "   ⚠ Gateway was not running"
fi

# Step 2: Clear temporary files (optional)
echo "2. Clearing temporary files..."
if [[ -d "${OPENCLAW_HOME}/.openclaw/tmp" ]]; then
    sudo -u "$OPENCLAW_USER" rm -rf "${OPENCLAW_HOME}/.openclaw/tmp/"* 2>/dev/null || true
    echo "   ✓ Temporary files cleared"
else
    echo "   ⚠ No temporary directory found"
fi

# Step 3: Restart via LaunchAgent
echo "3. Starting Gateway..."

# Check if LaunchAgent is loaded
if sudo launchctl print "gui/${user_id}/ai.openclaw.gateway" &>/dev/null; then
    # LaunchAgent is loaded, it should auto-restart
    echo "   LaunchAgent will restart Gateway automatically..."
    sleep 2
else
    # LaunchAgent not loaded, load it now
    echo "   Loading LaunchAgent..."
    if sudo launchctl bootstrap "gui/${user_id}" "$LAUNCHAGENT_PLIST" 2>/dev/null; then
        echo "   ✓ LaunchAgent loaded"
    else
        echo "   ERROR: Failed to load LaunchAgent"
        exit 1
    fi
fi

# Step 4: Verify Gateway started
echo "4. Verifying Gateway status..."
sleep 3

if pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
    local new_pid=$(pgrep -u "$OPENCLAW_USER" openclaw-gateway)
    echo -e "${GREEN}   ✓ Gateway restarted successfully (PID: $new_pid)${NC}"
else
    echo -e "${YELLOW}   ⚠ Gateway process not found${NC}"
    echo "   Check logs: tail -f ${OPENCLAW_HOME}/.openclaw/logs/gateway.error.log"
    exit 1
fi

echo ""
echo -e "${GREEN}Restart complete!${NC}"
echo ""
echo "Check status with: ${SCRIPT_DIR}/status.sh"
echo "View logs: tail -f ${OPENCLAW_HOME}/.openclaw/logs/gateway.log"
echo ""
