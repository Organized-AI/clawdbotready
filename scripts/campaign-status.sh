#!/usr/bin/env bash
set -euo pipefail

# campaign-status — List active campaigns with status and budget
# Wraps google-ads-cli campaigns for quick lookups
#
# Usage: campaign-status [--customer-id <id>] [--filter <name>]
# Default: Blade account (1741833734)

# Source PATH (needed for non-interactive shells via SSH/cron)
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile" 2>/dev/null

CLI="google-ads-cli"
CUSTOMER_ID="1741833734"
FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --customer-id)
            CUSTOMER_ID="$2"
            shift 2
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --help|-h)
            echo "campaign-status — List active campaigns with status and budget"
            echo ""
            echo "Usage: campaign-status [--customer-id <id>] [--filter <name>]"
            echo ""
            echo "Options:"
            echo "  --customer-id <id>   Google Ads customer ID (default: 1741833734 / Blade)"
            echo "  --filter <name>      Filter campaigns by name"
            echo ""
            echo "Known accounts:"
            echo "  1741833734  Blade (default)"
            echo "  6111060860  Myosin - Foundation Law"
            echo "  1729599101  Myosin - MVA Funnel"
            echo "  6650090207  Myosin - Mass Tort Law"
            echo "  6890103064  Teleios Health"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage: campaign-status [--customer-id <id>] [--filter <name>]"
            exit 1
            ;;
    esac
done

if ! command -v "$CLI" &>/dev/null; then
    echo "Error: $CLI not found in PATH"
    exit 1
fi

CMD="$CLI campaigns --customer-id $CUSTOMER_ID"
if [[ -n "$FILTER" ]]; then
    CMD="$CMD --filter $FILTER"
fi

echo "📋 Campaign Status — Account $CUSTOMER_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

$CMD 2>&1 || {
    echo "⚠ Could not fetch campaigns for account $CUSTOMER_ID"
    exit 1
}

echo ""
echo "Generated: $(date '+%Y-%m-%d %H:%M %Z')"
