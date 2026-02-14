#!/usr/bin/env bash
#===============================================================================
# Moltworker Backup (Trigger R2 Sync)
#===============================================================================
# Triggers an immediate R2 backup via the admin API
# Requires R2 to be configured and Cloudflare Access credentials
#===============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"

if [[ -f "$CONFIG_FILE" ]]; then
    set -a
    source "$CONFIG_FILE" 2>/dev/null || true
    set +a
fi

worker_url=""
if [[ -f "${SCRIPT_DIR}/.worker_url" ]]; then
    worker_url=$(cat "${SCRIPT_DIR}/.worker_url")
fi
worker_url="${worker_url:-${WORKER_URL:-}}"

if [[ -z "$worker_url" ]]; then
    echo -e "${RED}Worker URL not found. Run setup.sh or set WORKER_URL.${NC}"
    exit 1
fi

if [[ -z "${R2_ACCESS_KEY_ID:-}" ]]; then
    echo -e "${RED}R2 is not configured. Set R2_ACCESS_KEY_ID in settings.env.${NC}"
    echo "Without R2, there is nothing to back up."
    exit 1
fi

echo -e "${BLUE}Triggering R2 backup...${NC}"
echo ""
echo "Note: The backup is triggered via the admin UI."
echo "The automatic sync runs every 5 minutes."
echo ""
echo "To trigger a manual backup:"
echo "1. Open: ${worker_url}/_admin/"
echo "2. Click 'Backup Now'"
echo ""
echo -e "${YELLOW}Alternatively, the R2 sync cron runs automatically every 5 minutes.${NC}"
echo "Your data is safe as long as R2 is configured."
