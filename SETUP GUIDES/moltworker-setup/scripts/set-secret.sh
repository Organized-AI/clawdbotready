#!/usr/bin/env bash
#===============================================================================
# Moltworker Set Secret Helper
#===============================================================================
# Quick helper to set a single wrangler secret
# Usage: ./scripts/set-secret.sh SECRET_NAME "secret_value"
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

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 SECRET_NAME [SECRET_VALUE]"
    echo ""
    echo "If SECRET_VALUE is omitted, you'll be prompted to enter it securely."
    echo ""
    echo "Examples:"
    echo "  $0 TELEGRAM_BOT_TOKEN \"123456:ABC-DEF\""
    echo "  $0 ANTHROPIC_API_KEY"
    exit 1
fi

SECRET_NAME="$1"
SECRET_VALUE="${2:-}"

mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd 2>/dev/null || echo "")

if [[ -z "$mw_dir" ]] || [[ ! -f "$mw_dir/package.json" ]]; then
    echo -e "${RED}Moltworker not found. Run setup.sh first.${NC}"
    exit 1
fi

cd "$mw_dir"

if [[ -n "$SECRET_VALUE" ]]; then
    echo "$SECRET_VALUE" | npx wrangler secret put "$SECRET_NAME" --name "$WRANGLER_PROJECT_NAME"
else
    echo -e "${BLUE}Enter value for ${SECRET_NAME}:${NC}"
    npx wrangler secret put "$SECRET_NAME" --name "$WRANGLER_PROJECT_NAME"
fi

echo -e "${GREEN}Secret ${SECRET_NAME} set. Redeploy for changes to take effect:${NC}"
echo "  ./scripts/deploy.sh"
