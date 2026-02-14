#!/usr/bin/env bash
#===============================================================================
# Moltworker Status Check
#===============================================================================
# Checks the health and configuration of your Cloudflare Workers deployment
#===============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    set -a
    source "$CONFIG_FILE" 2>/dev/null || true
    set +a
fi

MOLTWORKER_DIR="${MOLTWORKER_DIR:-${SCRIPT_DIR}/../../../moltworker}"

echo -e "${BLUE}=== Moltworker Deployment Status ===${NC}"
echo ""

# Worker URL
worker_url=""
if [[ -f "${SCRIPT_DIR}/.worker_url" ]]; then
    worker_url=$(cat "${SCRIPT_DIR}/.worker_url")
fi
worker_url="${worker_url:-${WORKER_URL:-}}"

if [[ -n "$worker_url" ]]; then
    echo -e "Worker URL: ${GREEN}${worker_url}${NC}"
else
    echo -e "Worker URL: ${RED}Not found${NC}"
    echo "  Run setup.sh first, or set WORKER_URL in settings.env"
fi

# Health check
if [[ -n "$worker_url" ]]; then
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${worker_url}/" 2>/dev/null || echo "000")
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "302" ]] || [[ "$http_code" == "401" ]]; then
        echo -e "Health:     ${GREEN}Responding (HTTP ${http_code})${NC}"
    elif [[ "$http_code" == "000" ]]; then
        echo -e "Health:     ${RED}Unreachable (timeout)${NC}"
    else
        echo -e "Health:     ${YELLOW}HTTP ${http_code}${NC}"
    fi
fi

# Gateway token
if [[ -f "${SCRIPT_DIR}/.gateway_token" ]]; then
    echo -e "Token:      ${GREEN}Saved (.gateway_token)${NC}"
else
    echo -e "Token:      ${YELLOW}Not saved locally${NC}"
fi

echo ""

# Moltworker directory
echo -e "${BLUE}=== Local Files ===${NC}"
mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd 2>/dev/null || echo "not found")
if [[ -d "$mw_dir" ]] && [[ -f "$mw_dir/package.json" ]]; then
    echo -e "Moltworker: ${GREEN}${mw_dir}${NC}"
else
    echo -e "Moltworker: ${RED}Not cloned${NC}"
fi

echo ""

# Configured features
echo -e "${BLUE}=== Configured Features ===${NC}"
echo -e "Anthropic API:  $([ -n "${ANTHROPIC_API_KEY:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "CF Access:      $([ -n "${CF_ACCESS_TEAM_DOMAIN:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "R2 Storage:     $([ -n "${R2_ACCESS_KEY_ID:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${RED}Not set (ephemeral!)${NC}")"
echo -e "Telegram:       $([ -n "${TELEGRAM_BOT_TOKEN:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "Discord:        $([ -n "${DISCORD_BOT_TOKEN:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "Slack:          $([ -n "${SLACK_BOT_TOKEN:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "Browser (CDP):  $([ -n "${CDP_SECRET:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "AI Gateway:     $([ -n "${CLOUDFLARE_AI_GATEWAY_API_KEY:-}" ] && echo -e "${GREEN}Set${NC}" || echo -e "${YELLOW}Not set${NC}")"
echo -e "Sleep timer:    ${SANDBOX_SLEEP_AFTER:-"Disabled (always-on)"}"

echo ""

# Quick commands
echo -e "${BLUE}=== Quick Commands ===${NC}"
echo "  Deploy:    ./scripts/deploy.sh"
echo "  Logs:      ./scripts/logs.sh"
echo "  Backup:    ./scripts/backup.sh"
echo "  Restart:   ./scripts/restart.sh"
echo "  Teardown:  ./scripts/teardown.sh"

if [[ -n "$worker_url" ]]; then
    echo ""
    echo -e "${BLUE}=== Access URLs ===${NC}"
    echo "  Control UI:  ${worker_url}/?token=<your-token>"
    echo "  Admin UI:    ${worker_url}/_admin/"
    if [[ -n "${CDP_SECRET:-}" ]]; then
        echo "  CDP:         ${worker_url}/cdp/json/version?secret=<cdp-secret>"
    fi
fi
