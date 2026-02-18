#!/usr/bin/env bash
set -euo pipefail

# Google Ads CLI Health Monitor
# Monitors the Google Ads CLI on Mac Mini and sends alerts when down
# Can be run locally or deployed to Mac Mini as a cron job

# Configuration
MAC_MINI_IP="${GOOGLE_ADS_MONITOR_IP:-100.66.145.48}"
MAC_MINI_USER="${GOOGLE_ADS_MONITOR_USER:-openclaw}"
ALERT_EMAIL="${GOOGLE_ADS_ALERT_EMAIL:-}"
LOG_FILE="${GOOGLE_ADS_LOG_FILE:-/tmp/google-ads-cli-monitor.log}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Send alert function
send_alert() {
    local message="$1"
    local severity="${2:-warning}" # error, warning, info

    log "ALERT [$severity]: $message"

    # Send Telegram notification if configured
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        local emoji=""
        case "$severity" in
            error) emoji="🚨" ;;
            warning) emoji="⚠️" ;;
            info) emoji="ℹ️" ;;
        esac

        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${emoji} *Google Ads CLI Monitor*%0A%0A${message}" \
            -d "parse_mode=Markdown" > /dev/null || true
    fi

    # Send email if configured
    if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
        echo "$message" | mail -s "[Google Ads CLI] $severity Alert" "$ALERT_EMAIL" || true
    fi

    # Desktop notification (if running locally on Mac)
    if command -v osascript &> /dev/null && [ -z "${SSH_CONNECTION:-}" ]; then
        osascript -e "display notification \"$message\" with title \"Google Ads CLI Alert\" sound name \"Frog\"" || true
    fi
}

# Check if running locally or on Mac Mini
if [ "${1:-}" = "--local" ]; then
    # Running on local machine - monitor via SSH
    MODE="local"
    log "Starting monitor (local mode - checking Mac Mini via Tailscale)"

    # Test connectivity
    if ! ping -c 2 "$MAC_MINI_IP" > /dev/null 2>&1; then
        send_alert "❌ Mac Mini unreachable at $MAC_MINI_IP\nTailscale may be down or Mac Mini is offline" "error"
        exit 1
    fi

    log "✅ Mac Mini reachable"

    # Check if google-ads-cli exists
    if ! ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "command -v google-ads-cli" > /dev/null 2>&1; then
        send_alert "❌ google-ads-cli not found on Mac Mini\nCLI may not be installed" "error"
        exit 1
    fi

    log "✅ google-ads-cli installed"

    # Test API connection
    log "Testing Google Ads API connection..."
    if ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "google-ads-cli list-campaigns --limit 1" > /dev/null 2>&1; then
        log "✅ Google Ads API connection successful"
        send_alert "✅ Google Ads CLI is healthy and responding" "info"
        exit 0
    else
        error_output=$(ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "google-ads-cli list-campaigns --limit 1 2>&1" || true)
        send_alert "❌ Google Ads API connection failed\n\nError: ${error_output:0:200}" "error"
        exit 1
    fi

else
    # Running on Mac Mini directly
    MODE="remote"
    log "Starting monitor (remote mode - running on Mac Mini)"

    # Check if CLI is installed
    if ! command -v google-ads-cli &> /dev/null; then
        send_alert "❌ google-ads-cli not found in PATH" "error"
        exit 1
    fi

    log "✅ google-ads-cli installed"

    # Test API connection
    log "Testing Google Ads API connection..."
    if output=$(google-ads-cli list-campaigns --limit 1 2>&1); then
        log "✅ Google Ads API connection successful"

        # Extract campaign count if available
        if echo "$output" | grep -q "campaign"; then
            log "✅ Campaign data retrieved successfully"
        fi

        exit 0
    else
        log "❌ Google Ads API connection failed"
        log "Error output: $output"

        # Check for specific error types
        if echo "$output" | grep -iq "unauthorized\|401"; then
            send_alert "❌ Google Ads API authentication failed\nRefresh token may have expired" "error"
        elif echo "$output" | grep -iq "quota\|rate limit"; then
            send_alert "⚠️ Google Ads API quota exceeded\nRate limit reached" "warning"
        elif echo "$output" | grep -iq "network\|connection"; then
            send_alert "⚠️ Network connectivity issue\nCannot reach Google Ads API" "warning"
        else
            send_alert "❌ Google Ads API connection failed\n\nError: ${output:0:200}" "error"
        fi

        exit 1
    fi
fi
