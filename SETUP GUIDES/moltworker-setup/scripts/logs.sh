#!/usr/bin/env bash
#===============================================================================
# Moltworker Live Logs
#===============================================================================
# Streams live logs from the Cloudflare Worker using wrangler tail
#===============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"

if [[ -f "$CONFIG_FILE" ]]; then
    set -a
    source "$CONFIG_FILE" 2>/dev/null || true
    set +a
fi

MOLTWORKER_DIR="${MOLTWORKER_DIR:-${SCRIPT_DIR}/../../../moltworker}"
WRANGLER_PROJECT_NAME="${WRANGLER_PROJECT_NAME:-moltworker}"

mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd 2>/dev/null || echo "")

if [[ -z "$mw_dir" ]] || [[ ! -f "$mw_dir/package.json" ]]; then
    echo -e "${RED}Moltworker not found. Run setup.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}Streaming live logs from ${WRANGLER_PROJECT_NAME}...${NC}"
echo "Press Ctrl+C to stop"
echo ""

cd "$mw_dir"
npx wrangler tail "$WRANGLER_PROJECT_NAME" "$@"
