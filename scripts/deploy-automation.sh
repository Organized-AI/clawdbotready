#!/usr/bin/env bash
set -euo pipefail

# Deploy a CLI tool to the Mac Mini and update TOOLS.md
# Usage: ./scripts/deploy-automation.sh <local-script> [tool-name]
#
# Example:
#   ./scripts/deploy-automation.sh scripts/blade-daily-report.sh blade-daily-report

MAC_MINI_IP="${OPENCLAW_HOST:-100.66.145.48}"
MAC_MINI_USER="${OPENCLAW_USER:-openclaw}"
SSH_OPTS="-o IdentitiesOnly=yes -o ConnectTimeout=10"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1"; }

# --- Argument parsing ---
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <local-script> [tool-name]"
    echo ""
    echo "Deploys a script to ~/bin/ on the Mac Mini and makes it executable."
    echo ""
    echo "Arguments:"
    echo "  local-script  Path to the script to deploy"
    echo "  tool-name     Name for the remote tool (default: script filename without .sh)"
    echo ""
    echo "Example:"
    echo "  $0 scripts/blade-daily-report.sh blade-daily-report"
    exit 1
fi

LOCAL_SCRIPT="$1"
TOOL_NAME="${2:-$(basename "$LOCAL_SCRIPT" .sh)}"

if [[ ! -f "$LOCAL_SCRIPT" ]]; then
    log_error "Script not found: $LOCAL_SCRIPT"
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Deploy Tool: ${TOOL_NAME}${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "  Source:  $LOCAL_SCRIPT"
echo -e "  Target:  ${MAC_MINI_USER}@${MAC_MINI_IP}:~/bin/${TOOL_NAME}"
echo ""

# Step 1: Check connectivity
log_info "Step 1: Checking connectivity..."
if ! ssh $SSH_OPTS "${MAC_MINI_USER}@${MAC_MINI_IP}" "echo ok" &>/dev/null; then
    log_error "Cannot connect to ${MAC_MINI_USER}@${MAC_MINI_IP}"
    echo "  - Is Tailscale running?"
    echo "  - Is the Mac Mini powered on?"
    exit 1
fi
log_success "Connected to Mac Mini"

# Step 2: Ensure ~/bin exists
log_info "Step 2: Ensuring ~/bin/ exists..."
ssh $SSH_OPTS "${MAC_MINI_USER}@${MAC_MINI_IP}" "mkdir -p ~/bin"
log_success "~/bin/ ready"

# Step 3: Backup existing tool if present
log_info "Step 3: Deploying ${TOOL_NAME}..."
ssh $SSH_OPTS "${MAC_MINI_USER}@${MAC_MINI_IP}" \
    "[ -f ~/bin/${TOOL_NAME} ] && cp ~/bin/${TOOL_NAME} ~/bin/${TOOL_NAME}.bak.$(date +%Y%m%d_%H%M%S) || true"

# Step 4: Copy and make executable
scp $SSH_OPTS "$LOCAL_SCRIPT" "${MAC_MINI_USER}@${MAC_MINI_IP}:~/bin/${TOOL_NAME}"
ssh $SSH_OPTS "${MAC_MINI_USER}@${MAC_MINI_IP}" "chmod +x ~/bin/${TOOL_NAME}"
log_success "Deployed ~/bin/${TOOL_NAME}"

# Step 5: Smoke test
log_info "Step 4: Smoke test..."
if ssh $SSH_OPTS "${MAC_MINI_USER}@${MAC_MINI_IP}" "~/bin/${TOOL_NAME} --help" &>/dev/null; then
    log_success "Smoke test passed (--help)"
else
    log_warn "Smoke test: --help not supported (this may be fine)"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Deployment Complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "  Tool: ~/bin/${TOOL_NAME}"
echo -e "  Host: ${MAC_MINI_USER}@${MAC_MINI_IP}"
echo ""
echo -e "  Test: ${BLUE}ssh ${MAC_MINI_USER}@${MAC_MINI_IP} '${TOOL_NAME}'${NC}"
echo ""
