#!/usr/bin/env bash
#===============================================================================
# Moltworker Restart
#===============================================================================
# Restarts the OpenClaw gateway process inside the sandbox container
# Uses the admin API endpoint
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

echo -e "${BLUE}Restarting OpenClaw gateway...${NC}"
echo ""
echo "To restart the gateway process:"
echo "1. Open the Admin UI: ${worker_url}/_admin/"
echo "2. Click 'Restart Gateway'"
echo ""
echo "To force a full container restart (cold start):"
echo "1. Redeploy: ./scripts/deploy.sh"
echo "   This will restart the sandbox container from scratch"
echo "   R2 data will be restored automatically on startup"
echo ""
echo -e "${YELLOW}Note: Cold starts take 1-2 minutes.${NC}"
