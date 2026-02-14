#!/usr/bin/env bash
set -euo pipefail

# blade-daily-report — Blade campaign performance summary
# Wraps google-ads-cli to produce a Telegram-friendly report
#
# Usage: blade-daily-report [today|last7|last30|yesterday]
# Default: today

# Source PATH (needed for non-interactive shells via SSH/cron)
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile" 2>/dev/null

CUSTOMER_ID="1741833734"
CLI="google-ads-cli"

# Map friendly names to API date ranges
case "${1:-today}" in
    today)     DATE_RANGE="TODAY" ;;
    yesterday) DATE_RANGE="YESTERDAY" ;;
    last7)     DATE_RANGE="LAST_7_DAYS" ;;
    last30)    DATE_RANGE="LAST_30_DAYS" ;;
    --help|-h)
        echo "blade-daily-report — Blade campaign performance summary"
        echo ""
        echo "Usage: blade-daily-report [today|yesterday|last7|last30]"
        echo "Default: today"
        echo ""
        echo "Generates a formatted report with CPA, spend, conversions,"
        echo "clicks, and impressions for the Blade Google Ads account."
        exit 0
        ;;
    *)
        echo "Error: Unknown date range '$1'"
        echo "Usage: blade-daily-report [today|yesterday|last7|last30]"
        exit 1
        ;;
esac

# Check CLI is available
if ! command -v "$CLI" &>/dev/null; then
    echo "Error: $CLI not found in PATH"
    echo "Install it or add ~/bin to your PATH"
    exit 1
fi

echo "📊 Blade Campaign Report — ${DATE_RANGE//_/ }"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get CPA metrics
echo "## Performance Metrics"
echo ""
$CLI cpa --customer-id "$CUSTOMER_ID" --date "$DATE_RANGE" 2>&1 || {
    echo "⚠ Could not fetch CPA metrics"
}

echo ""
echo "## Active Campaigns"
echo ""
$CLI campaigns --customer-id "$CUSTOMER_ID" 2>&1 || {
    echo "⚠ Could not fetch campaign list"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generated: $(date '+%Y-%m-%d %H:%M %Z')"
