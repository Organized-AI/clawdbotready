#!/usr/bin/env bash
#===============================================================================
# OpenClaw Native - System Status Check
#===============================================================================
# Comprehensive health check for OpenClaw native deployment
#
# Usage: ./status.sh
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
GATEWAY_INSTALL_DIR="${GATEWAY_INSTALL_DIR:-${OPENCLAW_HOME}/.openclaw/gateway}"
GATEWAY_LOG_DIR="${GATEWAY_LOG_DIR:-${OPENCLAW_HOME}/.openclaw/logs}"
EXEC_APPROVALS_PATH="${EXEC_APPROVALS_PATH:-${OPENCLAW_HOME}/.openclaw/exec-approvals.json}"
LAUNCHAGENT_PLIST="${LAUNCHAGENT_PLIST:-${OPENCLAW_HOME}/Library/LaunchAgents/ai.openclaw.gateway.plist}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STATUS_OK="${GREEN}✓${NC}"
STATUS_WARN="${YELLOW}⚠${NC}"
STATUS_ERROR="${RED}✗${NC}"

header() {
    echo ""
    echo -e "${BLUE}==================================================================${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}==================================================================${NC}"
    echo ""
}

check_status() {
    local status=$1
    local message=$2

    if [[ "$status" == "ok" ]]; then
        echo -e "${STATUS_OK} ${message}"
    elif [[ "$status" == "warn" ]]; then
        echo -e "${STATUS_WARN} ${message}"
    else
        echo -e "${STATUS_ERROR} ${message}"
    fi
}

header "OpenClaw Native macOS - System Status"

# User Account Check
echo -e "${BLUE}User Account:${NC}"
if id "$OPENCLAW_USER" &>/dev/null; then
    check_status "ok" "User '${OPENCLAW_USER}' exists"
    echo "  UID: $(id -u "$OPENCLAW_USER")"
    echo "  GID: $(id -g "$OPENCLAW_USER")"
    echo "  Home: $(eval echo ~"$OPENCLAW_USER")"
else
    check_status "error" "User '${OPENCLAW_USER}' not found"
fi
echo ""

# Directory Structure
echo -e "${BLUE}Directory Structure:${NC}"
for dir in "$OPENCLAW_HOME" "${OPENCLAW_HOME}/.openclaw" "$GATEWAY_INSTALL_DIR" "$GATEWAY_LOG_DIR"; do
    if [[ -d "$dir" ]]; then
        local perms=$(stat -f '%Lp' "$dir" 2>/dev/null || echo "???")
        local owner=$(stat -f '%Su:%Sg' "$dir" 2>/dev/null || echo "???")
        check_status "ok" "$dir (${perms}, ${owner})"
    else
        check_status "error" "$dir - NOT FOUND"
    fi
done
echo ""

# Security Files
echo -e "${BLUE}Security Configuration:${NC}"
if [[ -f "$EXEC_APPROVALS_PATH" ]]; then
    local perms=$(stat -f '%Lp' "$EXEC_APPROVALS_PATH")
    local owner=$(stat -f '%Su:%Sg' "$EXEC_APPROVALS_PATH")

    if [[ "$owner" == "root:wheel" ]] && [[ "$perms" == "444" ]]; then
        check_status "ok" "exec-approvals.json (${perms}, ${owner})"
    else
        check_status "warn" "exec-approvals.json - insecure permissions (${perms}, ${owner})"
    fi
else
    check_status "error" "exec-approvals.json - NOT FOUND"
fi

if [[ -f "$LAUNCHAGENT_PLIST" ]]; then
    local perms=$(stat -f '%Lp' "$LAUNCHAGENT_PLIST")
    local owner=$(stat -f '%Su:%Sg' "$LAUNCHAGENT_PLIST")

    if [[ "$owner" == "root:wheel" ]] && [[ "$perms" == "444" ]]; then
        check_status "ok" "LaunchAgent plist (${perms}, ${owner})"
    else
        check_status "warn" "LaunchAgent plist - insecure permissions (${perms}, ${owner})"
    fi

    # Check if LaunchAgent is loaded
    local user_id=$(id -u "$OPENCLAW_USER")
    if sudo launchctl print "gui/${user_id}/ai.openclaw.gateway" &>/dev/null; then
        check_status "ok" "LaunchAgent loaded"
    else
        check_status "warn" "LaunchAgent not loaded"
    fi
else
    check_status "error" "LaunchAgent plist - NOT FOUND"
fi
echo ""

# Gateway Process
echo -e "${BLUE}Gateway Status:${NC}"
if pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
    local pid=$(pgrep -u "$OPENCLAW_USER" openclaw-gateway)
    check_status "ok" "Gateway running (PID: $pid)"

    # Get process details
    if command -v ps &>/dev/null; then
        local cpu=$(ps -p "$pid" -o %cpu= | tr -d ' ')
        local mem=$(ps -p "$pid" -o %mem= | tr -d ' ')
        local rss=$(ps -p "$pid" -o rss= | awk '{printf "%.1f MB", $1/1024}')

        echo "  CPU: ${cpu}%"
        echo "  Memory: ${mem}% (RSS: ${rss})"

        # Uptime
        local start_time=$(ps -p "$pid" -o lstart=)
        echo "  Started: ${start_time}"
    fi
else
    check_status "error" "Gateway not running"
fi
echo ""

# Gateway Binary
echo -e "${BLUE}Gateway Binary:${NC}"
if [[ -f "${GATEWAY_INSTALL_DIR}/openclaw-gateway" ]]; then
    local perms=$(stat -f '%Lp' "${GATEWAY_INSTALL_DIR}/openclaw-gateway")
    local owner=$(stat -f '%Su:%Sg' "${GATEWAY_INSTALL_DIR}/openclaw-gateway")
    local size=$(stat -f '%z' "${GATEWAY_INSTALL_DIR}/openclaw-gateway" | awk '{printf "%.1f MB", $1/(1024*1024)}')

    check_status "ok" "Binary found (${size}, ${perms}, ${owner})"

    if [[ -x "${GATEWAY_INSTALL_DIR}/openclaw-gateway" ]]; then
        check_status "ok" "Binary is executable"
    else
        check_status "error" "Binary not executable"
    fi
else
    check_status "error" "Gateway binary not found"
    echo "  Expected: ${GATEWAY_INSTALL_DIR}/openclaw-gateway"
fi
echo ""

# Log Files
echo -e "${BLUE}Recent Logs:${NC}"
if [[ -f "${GATEWAY_LOG_DIR}/gateway.log" ]]; then
    local log_size=$(stat -f '%z' "${GATEWAY_LOG_DIR}/gateway.log" | awk '{printf "%.1f MB", $1/(1024*1024)}')
    check_status "ok" "gateway.log (${log_size})"

    echo ""
    echo "Last 5 lines:"
    tail -n 5 "${GATEWAY_LOG_DIR}/gateway.log" 2>/dev/null | sed 's/^/  /'
else
    check_status "warn" "gateway.log not found"
fi

if [[ -f "${GATEWAY_LOG_DIR}/gateway.error.log" ]]; then
    local error_size=$(stat -f '%z' "${GATEWAY_LOG_DIR}/gateway.error.log" 2>/dev/null | awk '{printf "%.1f MB", $1/(1024*1024)}')
    local error_lines=$(wc -l < "${GATEWAY_LOG_DIR}/gateway.error.log" 2>/dev/null | tr -d ' ')

    if [[ "$error_lines" -gt 0 ]]; then
        check_status "warn" "gateway.error.log (${error_size}, ${error_lines} lines)"
    else
        check_status "ok" "gateway.error.log (${error_size}, no errors)"
    fi
else
    check_status "ok" "gateway.error.log not found (no errors yet)"
fi
echo ""

# System Resources
echo -e "${BLUE}System Resources:${NC}"
local load_avg=$(uptime | awk -F'load averages:' '{print $2}' | xargs)
check_status "ok" "Load average: ${load_avg}"

local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
local disk_avail=$(df -h / | awk 'NR==2 {print $4}')
check_status "ok" "Disk usage: ${disk_usage} (${disk_avail} available)"

echo ""

header "Status Check Complete"
