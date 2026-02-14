#!/usr/bin/env bash
set -euo pipefail

# scheduled-report-cron — Daily performance report sent via Telegram
# Designed to run as a crontab entry on the Mac Mini
#
# Usage: scheduled-report-cron
# Crontab: 0 8 * * 1-5 ~/bin/scheduled-report-cron >> ~/logs/scheduled-reports.log 2>&1

# Source PATH (needed for non-interactive shells via SSH/cron)
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile" 2>/dev/null

LOG_DIR="$HOME/logs"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "scheduled-report-cron — Send daily Blade performance report via Telegram"
    echo ""
    echo "Usage: scheduled-report-cron"
    echo ""
    echo "Runs blade-daily-report and sends the output as a Telegram message"
    echo "through the OpenClaw gateway API."
    echo ""
    echo "Install as crontab:"
    echo "  0 8 * * 1-5 ~/bin/scheduled-report-cron >> ~/logs/scheduled-reports.log 2>&1"
    exit 0
fi

mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting scheduled report..."

# Check if gateway is running
if ! curl -s "http://localhost:${GATEWAY_PORT}/api/health" &>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Gateway not responding on port $GATEWAY_PORT"
    exit 1
fi

# Generate the report
REPORT=$(blade-daily-report today 2>&1) || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: blade-daily-report failed"
    echo "$REPORT"
    exit 1
}

# Send via gateway message API
# The gateway's /api/send endpoint sends to the default Telegram channel
SEND_RESULT=$(curl -s -X POST "http://localhost:${GATEWAY_PORT}/api/send" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg text "$REPORT" '{"text": $text}')" 2>&1) || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to send message via gateway"
    echo "$SEND_RESULT"
    exit 1
}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Report sent successfully"
echo "$REPORT" | head -5
echo "..."
