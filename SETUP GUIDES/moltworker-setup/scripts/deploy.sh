#!/usr/bin/env bash
#===============================================================================
# Moltworker Deploy/Redeploy
#===============================================================================
# Deploys (or redeploys) the moltworker to Cloudflare Workers
#===============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"
LOG_FILE="${SCRIPT_DIR}/logs/deploy-$(date +%Y%m%d_%H%M%S).log"

mkdir -p "${SCRIPT_DIR}/logs"

if [[ -f "$CONFIG_FILE" ]]; then
    set -a
    source "$CONFIG_FILE" 2>/dev/null || true
    set +a
fi

MOLTWORKER_DIR="${MOLTWORKER_DIR:-${SCRIPT_DIR}/../../../moltworker}"
mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd 2>/dev/null || echo "")

if [[ -z "$mw_dir" ]] || [[ ! -f "$mw_dir/package.json" ]]; then
    echo -e "${RED}Moltworker not found. Run setup.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Deploying moltworker...${NC}"
cd "$mw_dir"
npm run deploy 2>&1 | tee "$LOG_FILE"

# Extract and save worker URL
worker_url=$(grep -oE 'https://[a-zA-Z0-9.-]+\.workers\.dev' "$LOG_FILE" | tail -1 || echo "")
if [[ -n "$worker_url" ]]; then
    echo "$worker_url" > "${SCRIPT_DIR}/.worker_url"
    echo ""
    echo -e "${GREEN}Deployed to: ${worker_url}${NC}"
fi

echo -e "${GREEN}Deploy complete.${NC}"
echo "Log: ${LOG_FILE}"
