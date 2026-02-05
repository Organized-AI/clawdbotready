#!/usr/bin/env bash
#===============================================================================
# OpenClaw Health Monitor - Telegram Provider Crash Detection & Auto-Recovery
#===============================================================================
# Monitors OpenClaw Gateway for Telegram provider crashes and automatically
# restarts the gateway when issues are detected.
#
# Usage:
#   ./openclaw-health-monitor.sh              # Run once
#   ./openclaw-health-monitor.sh --daemon     # Run continuously
#   ./openclaw-health-monitor.sh --install    # Install as LaunchAgent
#
# Checks performed:
# 1. Gateway process running
# 2. Telegram provider active (not crashed/timed out)
# 3. Recent errors in logs
# 4. Gateway responding to health checks
# 5. Sleep settings (prevents Mac from going to sleep)
#
#===============================================================================

set -euo pipefail

# Configuration
OPENCLAW_USER="${OPENCLAW_USER:-openclaw}"
OPENCLAW_HOME="/Users/${OPENCLAW_USER}"
GATEWAY_LOG="${OPENCLAW_HOME}/.openclaw/logs/gateway.log"
GATEWAY_ERR_LOG="${OPENCLAW_HOME}/.openclaw/logs/gateway.err.log"
MONITOR_LOG="/tmp/openclaw-monitor.log"
CHECK_INTERVAL=300  # 5 minutes
TELEGRAM_TIMEOUT_THRESHOLD=480  # Alert if no Telegram activity for 8 minutes

# Gateway restart command
GATEWAY_RESTART_CMD="/opt/homebrew/bin/node ${OPENCLAW_HOME}/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js gateway --port 18789"

DAEMON_MODE=false
INSTALL_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --daemon) DAEMON_MODE=true ;;
        --install) INSTALL_MODE=true ;;
    esac
done

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} [${level}] ${message}" | tee -a "$MONITOR_LOG"
}

check_gateway_process() {
    if pgrep -u "$OPENCLAW_USER" -f "openclaw-gateway" >/dev/null 2>&1; then
        return 0
    else
        log "ERROR" "Gateway process not running"
        return 1
    fi
}

check_telegram_provider() {
    if [[ ! -f "$GATEWAY_LOG" ]]; then
        log "WARN" "Gateway log not found: $GATEWAY_LOG"
        return 1
    fi

    # Check for recent Telegram activity
    local last_telegram_log=$(grep -E "\[telegram\].*starting provider" "$GATEWAY_LOG" | tail -1)

    if [[ -z "$last_telegram_log" ]]; then
        log "WARN" "No Telegram provider logs found"
        return 1
    fi

    # Extract timestamp from log (format: 2026-02-03T20:42:53.422Z)
    local log_timestamp=$(echo "$last_telegram_log" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}')

    if [[ -n "$log_timestamp" ]]; then
        local log_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$log_timestamp" "+%s" 2>/dev/null || echo "0")
        local current_epoch=$(date +%s)
        local time_diff=$((current_epoch - log_epoch))

        if [[ $time_diff -gt $TELEGRAM_TIMEOUT_THRESHOLD ]]; then
            log "ERROR" "Telegram provider inactive for ${time_diff}s (threshold: ${TELEGRAM_TIMEOUT_THRESHOLD}s)"
            return 1
        else
            log "INFO" "Telegram provider active (last activity: ${time_diff}s ago)"
            return 0
        fi
    fi

    return 1
}

check_for_crashes() {
    if [[ ! -f "$GATEWAY_ERR_LOG" ]]; then
        return 0
    fi

    # Check for Telegram-specific errors in last 10 minutes
    local recent_errors=$(find "$GATEWAY_ERR_LOG" -mmin -10 -exec grep -E "telegram.*exited|getUpdates.*timed out|telegram.*error" {} \; 2>/dev/null | wc -l | tr -d ' ')

    if [[ $recent_errors -gt 0 ]]; then
        log "ERROR" "Found ${recent_errors} Telegram errors in last 10 minutes"

        # Show last error
        local last_error=$(grep -E "telegram.*exited|getUpdates.*timed out" "$GATEWAY_ERR_LOG" | tail -1)
        log "ERROR" "Last error: ${last_error}"

        return 1
    fi

    return 0
}

check_sleep_settings() {
    local sleep_setting=$(pmset -g | grep -E "^\s+sleep" | awk '{print $2}')

    if [[ "$sleep_setting" != "0" ]]; then
        log "WARN" "Mac sleep is enabled (sleep=${sleep_setting}). This can cause connectivity issues!"
        log "WARN" "Run: sudo pmset -a sleep 0 disksleep 0 displaysleep 10 womp 0 powernap 0"
        return 1
    fi

    return 0
}

restart_gateway() {
    log "INFO" "Attempting to restart gateway..."

    # Kill existing process
    if pgrep -u "$OPENCLAW_USER" -f "openclaw-gateway" >/dev/null 2>&1; then
        log "INFO" "Stopping existing gateway process..."
        pkill -TERM -u "$OPENCLAW_USER" -f "openclaw-gateway" || true
        sleep 3

        # Force kill if still running
        if pgrep -u "$OPENCLAW_USER" -f "openclaw-gateway" >/dev/null 2>&1; then
            log "WARN" "Gateway did not stop gracefully, forcing..."
            pkill -KILL -u "$OPENCLAW_USER" -f "openclaw-gateway" || true
            sleep 2
        fi
    fi

    # Start gateway
    log "INFO" "Starting gateway..."
    if [[ "$(whoami)" == "$OPENCLAW_USER" ]]; then
        # Running as openclaw user, start directly
        eval "$GATEWAY_RESTART_CMD" > /dev/null 2>&1 &
    else
        # Running as different user, need to switch
        su - "$OPENCLAW_USER" -c "$GATEWAY_RESTART_CMD > /dev/null 2>&1 &"
    fi

    # Wait for startup
    sleep 5

    # Verify it started
    if check_gateway_process; then
        log "INFO" "✓ Gateway restarted successfully"

        # Check logs for successful start
        sleep 3
        local recent_start=$(tail -20 "$GATEWAY_LOG" | grep "listening on ws")
        if [[ -n "$recent_start" ]]; then
            log "INFO" "✓ Gateway is listening on port 18789"
            return 0
        fi
    else
        log "ERROR" "✗ Gateway restart failed"
        return 1
    fi
}

run_health_check() {
    log "INFO" "=== Starting health check ==="

    local needs_restart=false
    local failed_checks=0

    # 1. Check if process is running
    if ! check_gateway_process; then
        needs_restart=true
        failed_checks=$((failed_checks + 1))
    fi

    # 2. Check Telegram provider
    if ! check_telegram_provider; then
        needs_restart=true
        failed_checks=$((failed_checks + 1))
    fi

    # 3. Check for crash logs
    if ! check_for_crashes; then
        needs_restart=true
        failed_checks=$((failed_checks + 1))
    fi

    # 4. Check sleep settings (warning only)
    check_sleep_settings || true

    # Restart if needed
    if [[ "$needs_restart" == "true" ]]; then
        log "WARN" "Health check failed (${failed_checks} issue(s) detected)"
        restart_gateway
    else
        log "INFO" "✓ All health checks passed"
    fi

    log "INFO" "=== Health check complete ==="
}

install_launch_agent() {
    local plist_path="$HOME/Library/LaunchAgents/com.openclaw.healthmonitor.plist"
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.healthmonitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>${script_path}</string>
        <string>--daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-monitor.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-monitor.stderr.log</string>
</dict>
</plist>
EOF

    log "INFO" "LaunchAgent installed: $plist_path"
    log "INFO" "To load: launchctl load $plist_path"
    log "INFO" "To unload: launchctl unload $plist_path"

    # Ask to load it
    read -p "Load the LaunchAgent now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        launchctl load "$plist_path"
        log "INFO" "✓ Health monitor is now running in background"
    fi
}

# Main execution
if [[ "$INSTALL_MODE" == "true" ]]; then
    echo "Installing OpenClaw Health Monitor as LaunchAgent..."
    install_launch_agent
    exit 0
fi

if [[ "$DAEMON_MODE" == "true" ]]; then
    log "INFO" "Health monitor started in daemon mode (interval: ${CHECK_INTERVAL}s)"

    while true; do
        run_health_check
        sleep "$CHECK_INTERVAL"
    done
else
    echo "OpenClaw Health Monitor"
    echo "======================="
    echo ""
    run_health_check
    echo ""
    echo "Monitor log: $MONITOR_LOG"
    echo ""
    echo "To run continuously: ./openclaw-health-monitor.sh --daemon"
    echo "To install as service: ./openclaw-health-monitor.sh --install"
    echo ""
fi
