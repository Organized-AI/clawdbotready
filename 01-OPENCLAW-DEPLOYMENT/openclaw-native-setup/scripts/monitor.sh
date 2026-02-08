#!/usr/bin/env bash
#===============================================================================
# OpenClaw Native - Real-time Monitoring
#===============================================================================
# Monitor Gateway health, resource usage, and security status
# Can be run manually or scheduled via cron/LaunchDaemon
#
# Usage: ./monitor.sh [--daemon]
#   --daemon: Run continuously (for LaunchDaemon)
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
GATEWAY_LOG_DIR="${GATEWAY_LOG_DIR:-${OPENCLAW_HOME}/.openclaw/logs}"
EXEC_APPROVALS_PATH="${EXEC_APPROVALS_PATH:-${OPENCLAW_HOME}/.openclaw/exec-approvals.json}"
MONITOR_INTERVAL="${MONITOR_INTERVAL:-300}"
LOG_MAX_SIZE_MB="${LOG_MAX_SIZE_MB:-100}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
CPU_ALERT_THRESHOLD="${CPU_ALERT_THRESHOLD:-80}"
MEMORY_ALERT_THRESHOLD="${MEMORY_ALERT_THRESHOLD:-1024}"

DAEMON_MODE=false
if [[ "${1:-}" == "--daemon" ]]; then
    DAEMON_MODE=true
fi

# Monitoring log
MONITOR_LOG="${GATEWAY_LOG_DIR}/monitor.log"

log_monitor() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} [${level}] ${message}" >> "$MONITOR_LOG"
}

alert() {
    local level="$1"
    shift
    local message="$*"

    log_monitor "$level" "$message"

    # Also output to console if not in daemon mode
    if [[ "$DAEMON_MODE" == "false" ]]; then
        echo "[$level] $message"
    fi

    # TODO: Add webhook/email notifications here
}

check_process() {
    if ! pgrep -u "$OPENCLAW_USER" openclaw-gateway &>/dev/null; then
        alert "ERROR" "Gateway process not running"
        return 1
    fi
    return 0
}

check_resources() {
    local pid=$(pgrep -u "$OPENCLAW_USER" openclaw-gateway 2>/dev/null || echo "")

    if [[ -z "$pid" ]]; then
        return 1
    fi

    # CPU usage
    local cpu=$(ps -p "$pid" -o %cpu= | tr -d ' ' | cut -d. -f1)
    if [[ "$cpu" -gt "$CPU_ALERT_THRESHOLD" ]]; then
        alert "WARN" "High CPU usage: ${cpu}% (threshold: ${CPU_ALERT_THRESHOLD}%)"
    fi

    # Memory usage (RSS in KB)
    local mem_kb=$(ps -p "$pid" -o rss= | tr -d ' ')
    local mem_mb=$((mem_kb / 1024))

    if [[ "$mem_mb" -gt "$MEMORY_ALERT_THRESHOLD" ]]; then
        alert "WARN" "High memory usage: ${mem_mb}MB (threshold: ${MEMORY_ALERT_THRESHOLD}MB)"
    fi

    log_monitor "INFO" "Resources: CPU=${cpu}%, Memory=${mem_mb}MB"
}

check_logs() {
    # Check log file sizes
    for log_file in "${GATEWAY_LOG_DIR}"/*.log; do
        if [[ -f "$log_file" ]]; then
            local size_mb=$(stat -f '%z' "$log_file" | awk '{printf "%d", $1/(1024*1024)}')

            if [[ "$size_mb" -gt "$LOG_MAX_SIZE_MB" ]]; then
                alert "WARN" "Large log file: $(basename "$log_file") (${size_mb}MB)"

                # Rotate log
                mv "$log_file" "${log_file}.$(date +%Y%m%d_%H%M%S)"
                touch "$log_file"
                chown "${OPENCLAW_USER}:staff" "$log_file"
                alert "INFO" "Log rotated: $(basename "$log_file")"
            fi
        fi
    done

    # Clean old logs
    find "${GATEWAY_LOG_DIR}" -name "*.log.*" -mtime "+${LOG_RETENTION_DAYS}" -delete 2>/dev/null || true
}

check_security() {
    # Verify exec-approvals.json integrity
    if [[ ! -f "$EXEC_APPROVALS_PATH" ]]; then
        alert "ERROR" "exec-approvals.json missing!"
        return 1
    fi

    local owner=$(stat -f '%Su:%Sg' "$EXEC_APPROVALS_PATH")
    local perms=$(stat -f '%Lp' "$EXEC_APPROVALS_PATH")

    if [[ "$owner" != "root:wheel" ]] || [[ "$perms" != "444" ]]; then
        alert "ERROR" "exec-approvals.json security violation: owner=${owner}, perms=${perms}"
        return 1
    fi

    # Check for unauthorized modifications
    local current_hash=$(md5 -q "$EXEC_APPROVALS_PATH" 2>/dev/null || echo "")
    local stored_hash_file="${SCRIPT_DIR}/../.exec-approvals.md5"

    if [[ -f "$stored_hash_file" ]]; then
        local stored_hash=$(cat "$stored_hash_file")
        if [[ "$current_hash" != "$stored_hash" ]]; then
            alert "ERROR" "exec-approvals.json has been modified! Hash mismatch."
            return 1
        fi
    else
        # First run - store hash
        echo "$current_hash" > "$stored_hash_file"
    fi
}

check_errors() {
    local error_log="${GATEWAY_LOG_DIR}/gateway.error.log"

    if [[ -f "$error_log" ]]; then
        # Count recent errors (last 5 minutes)
        local recent_errors=$(find "$error_log" -mmin -5 -exec grep -c "ERROR\|FATAL" {} \; 2>/dev/null || echo "0")

        if [[ "$recent_errors" -gt 10 ]]; then
            alert "WARN" "High error rate: ${recent_errors} errors in last 5 minutes"

            # Show last few errors
            tail -n 5 "$error_log" | while read -r line; do
                log_monitor "ERROR_SAMPLE" "$line"
            done
        fi
    fi
}

run_checks() {
    log_monitor "INFO" "Starting monitoring checks..."

    local failed=0

    check_process || failed=$((failed + 1))
    check_resources || failed=$((failed + 1))
    check_logs || failed=$((failed + 1))
    check_security || failed=$((failed + 1))
    check_errors || failed=$((failed + 1))

    if [[ $failed -eq 0 ]]; then
        log_monitor "INFO" "All checks passed"
    else
        log_monitor "WARN" "${failed} check(s) failed"
    fi

    return $failed
}

# Main execution
if [[ "$DAEMON_MODE" == "true" ]]; then
    # Daemon mode: run continuously
    log_monitor "INFO" "Monitor started in daemon mode (interval: ${MONITOR_INTERVAL}s)"

    while true; do
        run_checks
        sleep "$MONITOR_INTERVAL"
    done
else
    # One-time check
    echo "OpenClaw Native - Health Monitor"
    echo "================================="
    echo ""

    run_checks
    exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ All checks passed"
    else
        echo "⚠ ${exit_code} check(s) failed - see ${MONITOR_LOG}"
    fi

    echo ""
    echo "View monitoring log: tail -f ${MONITOR_LOG}"
    echo "Run in daemon mode: ./monitor.sh --daemon"
    echo ""

    exit $exit_code
fi
