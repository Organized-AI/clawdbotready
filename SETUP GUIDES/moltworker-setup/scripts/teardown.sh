#!/usr/bin/env bash
#===============================================================================
# Moltworker Teardown
#===============================================================================
# Removes the Cloudflare Workers deployment
# WARNING: This deletes the worker and all associated data
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

MOLTWORKER_DIR="${MOLTWORKER_DIR:-${SCRIPT_DIR}/../../../moltworker}"
WRANGLER_PROJECT_NAME="${WRANGLER_PROJECT_NAME:-moltworker}"

mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd 2>/dev/null || echo "")

echo -e "${RED}=== MOLTWORKER TEARDOWN ===${NC}"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  1. Delete the Cloudflare Worker (${WRANGLER_PROJECT_NAME})"
echo "  2. Remove all secrets and configuration"
echo "  3. Stop the sandbox container"
echo ""
echo -e "${YELLOW}This will NOT:${NC}"
echo "  - Delete your R2 bucket (manual cleanup needed)"
echo "  - Delete your Cloudflare Access application"
echo "  - Remove the local moltworker clone"
echo ""

read -p "Are you sure you want to tear down? Type 'yes' to confirm: " response

if [[ "$response" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

if [[ -n "$mw_dir" ]] && [[ -f "$mw_dir/package.json" ]]; then
    echo -e "${BLUE}Deleting worker...${NC}"
    cd "$mw_dir"
    npx wrangler delete "$WRANGLER_PROJECT_NAME" --force 2>&1 || true
fi

# Clean up local state files
rm -f "${SCRIPT_DIR}/.worker_url"
rm -f "${SCRIPT_DIR}/.gateway_token"

echo ""
echo -e "${GREEN}Teardown complete.${NC}"
echo ""
echo "Manual cleanup needed:"
echo "  - Delete R2 bucket 'moltbot-data' from Cloudflare dashboard"
echo "  - Remove Cloudflare Access application if created"
echo "  - Remove local clone: rm -rf ${mw_dir}"
