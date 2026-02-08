#!/usr/bin/env bash
#
# OpenClaw Gateway - Comprehensive Health Check System
#
# This script provides multi-level health monitoring and automatic recovery
# for production OpenClaw Gateway deployments.
#
# Features:
# - File descriptor monitoring and auto-recovery
# - Telegram connection health checks
# - Gateway process monitoring
# - Automatic restart with safety checks
# - Detailed logging and alerting
#
# Usage:
#   ./openclaw-comprehensive-health-check.sh        # Run once
#   ./openclaw-comprehensive-health-check.sh --install  # Install as LaunchAgent
#   ./openclaw-comprehensive-health-check.sh --uninstall # Remove LaunchAgent
#

set -euo pipefail

# Configuration
SCRIPT_NAME="openclaw-comprehensive-health-check"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
ALERT_FILE="/tmp/${SCRIPT_NAME}-alerts.log"
GATEWAY_LOG="$HOME/.openclaw/logs/gateway.log"
GATEWAY_ERR_LOG="$HOME/.openclaw/logs/gateway.err.log"
LAUNCHAGENT_LABEL="ai.openclaw.gateway"

# Thresholds
FD_WARNING_THRESHOLD=10000
FD_CRITICAL_THRESHOLD=30000
TELEGRAM_TIMEOUT_MINUTES=15
MAX_RESTART_ATTEMPTS=3
RESTART_COOLDOWN_SECONDS=300  # 5 minutes between restarts

# State files
RESTART_COUNT_FILE="/tmp/${SCRIPT_NAME}-restart-count"
LAST_RESTART_FILE="/tmp/${SCRIPT_NAME}-last-restart"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $*" | tee -a "$LOG_FILE" "$ALERT_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $*${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $*${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $*${NC}" | tee -a "$LOG_FILE"
}

# Health check functions

check_gateway_running() {
    log "🔍 Checking if gateway is running..."

    if pgrep -q openclaw-gateway; then
        PID=$(pgrep openclaw-gateway)
        UPTIME=$(ps -p "$PID" -o etime= | tr -d ' ')
        log_success "Gateway is running (PID: $PID, Uptime: $UPTIME)"
        return 0
    else
        log_error "Gateway is NOT running"
        return 1
    fi
}

check_file_descriptors() {
    log "🔍 Checking file descriptor usage..."

    PID=$(pgrep openclaw-gateway)
    if [ -z "$PID" ]; then
        log_error "Gateway not running, cannot check file descriptors"
        return 1
    fi

    FD_COUNT=$(lsof -p "$PID" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$FD_COUNT" -lt "$FD_WARNING_THRESHOLD" ]; then
        log_success "File descriptors: $FD_COUNT (healthy)"
        return 0
    elif [ "$FD_COUNT" -lt "$FD_CRITICAL_THRESHOLD" ]; then
        log_warning "File descriptors: $FD_COUNT (warning threshold: $FD_WARNING_THRESHOLD)"
        return 1
    else
        log_error "File descriptors: $FD_COUNT (CRITICAL threshold: $FD_CRITICAL_THRESHOLD)"
        log_alert "File descriptor leak detected: $FD_COUNT open files"
        return 2
    fi
}

check_emfile_errors() {
    log "🔍 Checking for EMFILE errors..."

    # Check for EMFILE errors in the last 5 minutes
    RECENT_EMFILE=$(tail -500 "$GATEWAY_ERR_LOG" 2>/dev/null | grep -c 'EMFILE' || true)

    if [ "$RECENT_EMFILE" -eq 0 ]; then
        log_success "No recent EMFILE errors"
        return 0
    else
        log_error "Found $RECENT_EMFILE EMFILE errors in recent logs"
        log_alert "EMFILE errors detected: $RECENT_EMFILE occurrences"
        return 1
    fi
}

check_telegram_connection() {
    log "🔍 Checking Telegram connection..."

    # Check when Telegram last started
    LAST_TELEGRAM=$(grep "telegram.*starting provider" "$GATEWAY_LOG" 2>/dev/null | tail -1 | cut -d' ' -f1 || echo "")

    if [ -z "$LAST_TELEGRAM" ]; then
        log_warning "No Telegram connection found in logs"
        return 1
    fi

    # Calculate time since last connection (approximate)
    CURRENT_TIME=$(date +%s)
    TELEGRAM_TIME=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${LAST_TELEGRAM:0:19}" +%s 2>/dev/null || echo "0")
    TIME_DIFF=$((CURRENT_TIME - TELEGRAM_TIME))
    MINUTES_DIFF=$((TIME_DIFF / 60))

    if [ "$MINUTES_DIFF" -lt "$TELEGRAM_TIMEOUT_MINUTES" ]; then
        log_success "Telegram connected $MINUTES_DIFF minutes ago"
        return 0
    else
        log_warning "Telegram last connected $MINUTES_DIFF minutes ago (threshold: $TELEGRAM_TIMEOUT_MINUTES minutes)"
        return 1
    fi
}

check_telegram_timeout() {
    log "🔍 Checking for Telegram timeout errors..."

    # Check for timeout in recent logs
    TIMEOUT_COUNT=$(tail -100 "$GATEWAY_ERR_LOG" 2>/dev/null | grep -c "timed out after 500 seconds" || true)

    if [ "$TIMEOUT_COUNT" -gt 0 ]; then
        log_error "Found $TIMEOUT_COUNT Telegram timeout errors"
        log_alert "Telegram provider timeout detected"
        return 1
    else
        log_success "No Telegram timeouts"
        return 0
    fi
}

check_recent_crashes() {
    log "🔍 Checking for recent crashes..."

    # Check for crash-related messages
    CRASH_COUNT=$(tail -100 "$GATEWAY_ERR_LOG" 2>/dev/null | grep -Ec "crashed|fatal|segfault" || true)

    if [ "$CRASH_COUNT" -gt 0 ]; then
        log_error "Found $CRASH_COUNT crash indicators in recent logs"
        return 1
    else
        log_success "No crash indicators found"
        return 0
    fi
}

check_telegram_api() {
    log "🔍 Testing Telegram API connectivity..."

    API_RESPONSE=$(curl -s -m 10 'https://api.telegram.org/bot8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4/getMe' 2>/dev/null || echo '{"ok":false}')

    if echo "$API_RESPONSE" | grep -q '"ok":true'; then
        log_success "Telegram API is reachable"
        return 0
    else
        log_error "Telegram API is unreachable or returned error"
        return 1
    fi
}

# Recovery functions

can_restart_gateway() {
    # Check if we're within restart limits

    # Get restart count
    if [ -f "$RESTART_COUNT_FILE" ]; then
        RESTART_COUNT=$(cat "$RESTART_COUNT_FILE")
    else
        RESTART_COUNT=0
    fi

    # Get last restart time
    if [ -f "$LAST_RESTART_FILE" ]; then
        LAST_RESTART=$(cat "$LAST_RESTART_FILE")
        CURRENT_TIME=$(date +%s)
        TIME_SINCE_RESTART=$((CURRENT_TIME - LAST_RESTART))

        # Reset count if cooldown has passed
        if [ "$TIME_SINCE_RESTART" -gt "$RESTART_COOLDOWN_SECONDS" ]; then
            RESTART_COUNT=0
            echo "0" > "$RESTART_COUNT_FILE"
        fi
    fi

    if [ "$RESTART_COUNT" -ge "$MAX_RESTART_ATTEMPTS" ]; then
        log_error "Maximum restart attempts ($MAX_RESTART_ATTEMPTS) reached. Manual intervention required."
        log_alert "Gateway restart limit reached. Stopping automatic restarts."
        return 1
    fi

    return 0
}

restart_gateway() {
    log "🔄 Initiating gateway restart..."

    if ! can_restart_gateway; then
        return 1
    fi

    # Increment restart count
    if [ -f "$RESTART_COUNT_FILE" ]; then
        RESTART_COUNT=$(cat "$RESTART_COUNT_FILE")
    else
        RESTART_COUNT=0
    fi
    RESTART_COUNT=$((RESTART_COUNT + 1))
    echo "$RESTART_COUNT" > "$RESTART_COUNT_FILE"
    echo "$(date +%s)" > "$LAST_RESTART_FILE"

    log "Restart attempt $RESTART_COUNT of $MAX_RESTART_ATTEMPTS"

    # Stop gateway
    log "Stopping gateway..."
    launchctl stop "$LAUNCHAGENT_LABEL" 2>/dev/null || true
    sleep 3

    # Kill if still running
    if pgrep -q openclaw-gateway; then
        log_warning "Gateway still running, force killing..."
        pkill -9 openclaw-gateway || true
        sleep 2
    fi

    # Start gateway
    log "Starting gateway..."
    launchctl start "$LAUNCHAGENT_LABEL"

    # Wait for startup
    sleep 10

    # Verify it started
    if pgrep -q openclaw-gateway; then
        PID=$(pgrep openclaw-gateway)
        log_success "Gateway restarted successfully (PID: $PID)"

        # Check file descriptors after restart
        FD_COUNT=$(lsof -p "$PID" 2>/dev/null | wc -l | tr -d ' ')
        log "File descriptors after restart: $FD_COUNT"

        return 0
    else
        log_error "Gateway failed to start after restart"
        log_alert "Gateway restart failed - manual intervention required"
        return 1
    fi
}

# Main health check logic

run_health_check() {
    log "================================================"
    log "Starting OpenClaw Gateway Health Check"
    log "================================================"

    ISSUES_FOUND=0
    CRITICAL_ISSUES=0

    # Check 1: Is gateway running?
    if ! check_gateway_running; then
        log_error "Gateway not running - attempting restart"
        if restart_gateway; then
            log_success "Gateway restart successful"
        else
            log_error "Failed to restart gateway"
            return 1
        fi
    fi

    # Check 2: File descriptors
    check_file_descriptors
    FD_STATUS=$?
    if [ "$FD_STATUS" -eq 2 ]; then
        # Critical file descriptor issue
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
        log_error "CRITICAL: File descriptor leak detected - restarting gateway"
        restart_gateway
    elif [ "$FD_STATUS" -eq 1 ]; then
        # Warning level
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi

    # Check 3: EMFILE errors
    if ! check_emfile_errors; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
        log_error "EMFILE errors detected - restarting gateway"
        restart_gateway
    fi

    # Check 4: Telegram connection
    if ! check_telegram_connection; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi

    # Check 5: Telegram timeouts
    if ! check_telegram_timeout; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        log_warning "Telegram timeout detected - restarting gateway"
        restart_gateway
    fi

    # Check 6: Recent crashes
    if ! check_recent_crashes; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi

    # Check 7: Telegram API
    if ! check_telegram_api; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        log_warning "Telegram API connectivity issue"
    fi

    # Summary
    log "================================================"
    if [ "$CRITICAL_ISSUES" -gt 0 ]; then
        log_error "Health Check FAILED: $CRITICAL_ISSUES critical issues, $ISSUES_FOUND total issues"
        return 1
    elif [ "$ISSUES_FOUND" -gt 0 ]; then
        log_warning "Health Check WARNING: $ISSUES_FOUND issues found (no critical)"
        return 0
    else
        log_success "Health Check PASSED: All systems operational"

        # Reset restart count on successful health check
        echo "0" > "$RESTART_COUNT_FILE"

        return 0
    fi
}

# Installation functions

install_health_monitor() {
    log "Installing OpenClaw Health Monitor as LaunchAgent..."

    PLIST_PATH="$HOME/Library/LaunchAgents/com.openclaw.health-monitor.plist"
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.health-monitor</string>

    <key>Comment</key>
    <string>OpenClaw Gateway Comprehensive Health Monitor</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_PATH</string>
    </array>

    <key>StartInterval</key>
    <integer>300</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$LOG_FILE</string>

    <key>StandardErrorPath</key>
    <string>$LOG_FILE</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
</dict>
</plist>
EOF

    # Load the LaunchAgent
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    launchctl load "$PLIST_PATH"

    log_success "Health Monitor installed successfully"
    log "Running every 5 minutes"
    log "Logs: $LOG_FILE"
    log "Alerts: $ALERT_FILE"
    log ""
    log "To view logs: tail -f $LOG_FILE"
    log "To check status: launchctl list | grep health-monitor"
}

uninstall_health_monitor() {
    log "Uninstalling OpenClaw Health Monitor..."

    PLIST_PATH="$HOME/Library/LaunchAgents/com.openclaw.health-monitor.plist"

    if [ -f "$PLIST_PATH" ]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        rm "$PLIST_PATH"
        log_success "Health Monitor uninstalled"
    else
        log_warning "Health Monitor not found"
    fi
}

# Usage information

show_usage() {
    cat << EOF
OpenClaw Gateway - Comprehensive Health Check System

Usage:
    $0                  Run health check once
    $0 --install        Install as LaunchAgent (runs every 5 minutes)
    $0 --uninstall      Remove LaunchAgent
    $0 --help           Show this help

Health Checks Performed:
    ✓ Gateway process running
    ✓ File descriptor usage (warning: $FD_WARNING_THRESHOLD, critical: $FD_CRITICAL_THRESHOLD)
    ✓ EMFILE errors in logs
    ✓ Telegram connection status
    ✓ Telegram timeout errors
    ✓ Recent crash indicators
    ✓ Telegram API connectivity

Automatic Recovery:
    - Restarts gateway when critical issues detected
    - Maximum $MAX_RESTART_ATTEMPTS restarts per $RESTART_COOLDOWN_SECONDS seconds
    - Detailed logging to $LOG_FILE
    - Critical alerts to $ALERT_FILE

Examples:
    # Run once
    ./$0

    # Install automated monitoring
    ./$0 --install

    # View real-time logs
    tail -f $LOG_FILE

    # Check alerts
    cat $ALERT_FILE
EOF
}

# Main entry point

main() {
    case "${1:-}" in
        --install)
            install_health_monitor
            ;;
        --uninstall)
            uninstall_health_monitor
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            run_health_check
            ;;
    esac
}

main "$@"
