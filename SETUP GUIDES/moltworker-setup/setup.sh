#!/usr/bin/env bash
#===============================================================================
# OpenClaw Cloudflare Workers (Moltworker) - Master Orchestrator
#===============================================================================
# This script orchestrates the deployment of OpenClaw on Cloudflare Workers
# using the moltworker framework.
#
# Usage: ./setup.sh [command]
#   all: Run all phases sequentially (default)
#   0-5: Run individual phases
#   secrets: Configure all wrangler secrets from settings.env
#===============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.env"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d_%H%M%S).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    # Source only non-empty, non-comment lines as env vars
    set -a
    source "$CONFIG_FILE" 2>/dev/null || true
    set +a
fi

# Defaults
MOLTWORKER_DIR="${MOLTWORKER_DIR:-${SCRIPT_DIR}/../../../moltworker}"
WRANGLER_PROJECT_NAME="${WRANGLER_PROJECT_NAME:-moltworker}"

#===============================================================================
# Utility Functions
#===============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

info() { log "INFO" "$*"; }
warn() { log "${YELLOW}WARN${NC}" "$*"; }
error() { log "${RED}ERROR${NC}" "$*"; }
success() { log "${GREEN}SUCCESS${NC}" "$*"; }

header() {
    echo ""
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}=================================================================${NC}"
    echo ""
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="${prompt} [Y/n]: "
    else
        prompt="${prompt} [y/N]: "
    fi

    read -p "$prompt" response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy] ]]
}

set_secret() {
    local name="$1"
    local value="$2"

    if [[ -z "$value" ]]; then
        info "Skipping ${name} (empty value)"
        return 0
    fi

    info "Setting secret: ${name}"
    echo "$value" | npx wrangler secret put "$name" --name "$WRANGLER_PROJECT_NAME" 2>&1 | tee -a "$LOG_FILE"
}

#===============================================================================
# Phase 0: Prerequisites Verification
#===============================================================================

phase0_verify_prerequisites() {
    header "Phase 0: Prerequisites Verification"

    local errors=0

    # Check Node.js
    if command -v node &>/dev/null; then
        local node_version=$(node --version)
        info "Node.js: ${node_version}"
        local major=$(echo "$node_version" | sed 's/v//' | cut -d. -f1)
        if [[ "$major" -lt 18 ]]; then
            error "Node.js 18+ required (found ${node_version})"
            ((errors++))
        fi
    else
        error "Node.js not found. Install via: brew install node"
        ((errors++))
    fi

    # Check npm
    if command -v npm &>/dev/null; then
        info "npm: $(npm --version)"
    else
        error "npm not found"
        ((errors++))
    fi

    # Check wrangler
    if command -v wrangler &>/dev/null || npx wrangler --version &>/dev/null 2>&1; then
        info "Wrangler: $(npx wrangler --version 2>/dev/null || echo 'available via npx')"
    else
        warn "Wrangler not found globally - will use npx (installed with moltworker deps)"
    fi

    # Check git
    if command -v git &>/dev/null; then
        info "Git: $(git --version)"
    else
        error "Git not found. Install via: brew install git"
        ((errors++))
    fi

    # Check Cloudflare auth
    if npx wrangler whoami &>/dev/null 2>&1; then
        info "Cloudflare: Authenticated"
    else
        warn "Not logged into Cloudflare. Run: npx wrangler login"
        info "This will open a browser for OAuth authentication"
    fi

    # Check config file
    if [[ -f "$CONFIG_FILE" ]]; then
        info "Config: ${CONFIG_FILE} found"

        if [[ -z "${ANTHROPIC_API_KEY:-}" ]] && [[ -z "${CLOUDFLARE_AI_GATEWAY_API_KEY:-}" ]]; then
            warn "No AI provider key set in settings.env"
            warn "You need either ANTHROPIC_API_KEY or CLOUDFLARE_AI_GATEWAY_API_KEY"
        fi
    else
        error "Config file not found: ${CONFIG_FILE}"
        ((errors++))
    fi

    if [[ "$errors" -gt 0 ]]; then
        error "Prerequisites check failed with ${errors} error(s)"
        return 1
    fi

    success "All prerequisites verified"

    # Write completion marker
    cat > "${SCRIPT_DIR}/PLANNING/PHASE-0-COMPLETE.md" << EOF
# Phase 0 Complete

**Completed:** $(date)

## Results
- Node.js: $(node --version 2>/dev/null || echo 'N/A')
- npm: $(npm --version 2>/dev/null || echo 'N/A')
- Git: $(git --version 2>/dev/null || echo 'N/A')
- Config: Found and loaded
EOF
}

#===============================================================================
# Phase 1: Clone and Configure
#===============================================================================

phase1_clone_and_configure() {
    header "Phase 1: Clone Moltworker and Configure Secrets"

    # Resolve moltworker directory
    local mw_dir
    mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd || echo "${MOLTWORKER_DIR}")

    if [[ -d "$mw_dir" ]] && [[ -f "$mw_dir/package.json" ]]; then
        info "Moltworker already cloned at: ${mw_dir}"
    else
        info "Cloning moltworker..."
        git clone https://github.com/cloudflare/moltworker.git "$mw_dir"
        info "Cloned to: ${mw_dir}"
    fi

    # Install dependencies
    info "Installing dependencies..."
    cd "$mw_dir"
    npm install 2>&1 | tee -a "$LOG_FILE"

    # Generate gateway token if not set
    if [[ -z "${MOLTBOT_GATEWAY_TOKEN:-}" ]]; then
        MOLTBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)
        info "Generated gateway token: ${MOLTBOT_GATEWAY_TOKEN}"
        warn "SAVE THIS TOKEN - you need it to access the Control UI"
        echo ""
        echo -e "${GREEN}Gateway Token: ${MOLTBOT_GATEWAY_TOKEN}${NC}"
        echo ""

        # Save to a local file for reference
        echo "$MOLTBOT_GATEWAY_TOKEN" > "${SCRIPT_DIR}/.gateway_token"
        info "Token saved to: ${SCRIPT_DIR}/.gateway_token"
    fi

    # Wrangler login check
    if ! npx wrangler whoami &>/dev/null 2>&1; then
        info "Logging into Cloudflare..."
        npx wrangler login
    fi

    # Set required secrets
    info "Configuring wrangler secrets..."

    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        set_secret "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"
    fi

    set_secret "MOLTBOT_GATEWAY_TOKEN" "$MOLTBOT_GATEWAY_TOKEN"

    success "Phase 1 complete - moltworker cloned and core secrets set"

    cat > "${SCRIPT_DIR}/PLANNING/PHASE-1-COMPLETE.md" << EOF
# Phase 1 Complete

**Completed:** $(date)

## Results
- Moltworker cloned to: ${mw_dir}
- Dependencies installed
- Gateway token configured
- Anthropic API key: $([ -n "${ANTHROPIC_API_KEY:-}" ] && echo "Set" || echo "Not set")
EOF
}

#===============================================================================
# Phase 2: Cloudflare Access
#===============================================================================

phase2_cloudflare_access() {
    header "Phase 2: Configure Cloudflare Access"

    local mw_dir
    mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd || echo "${MOLTWORKER_DIR}")
    cd "$mw_dir"

    if [[ -n "${CF_ACCESS_TEAM_DOMAIN:-}" ]] && [[ -n "${CF_ACCESS_AUD:-}" ]]; then
        set_secret "CF_ACCESS_TEAM_DOMAIN" "$CF_ACCESS_TEAM_DOMAIN"
        set_secret "CF_ACCESS_AUD" "$CF_ACCESS_AUD"
        success "Cloudflare Access secrets configured"
    else
        warn "Cloudflare Access not configured (CF_ACCESS_TEAM_DOMAIN / CF_ACCESS_AUD empty)"
        echo ""
        echo -e "${YELLOW}To set up Cloudflare Access:${NC}"
        echo "1. Go to Workers & Pages dashboard"
        echo "2. Select your Worker → Settings → Domains & Routes"
        echo "3. Enable Cloudflare Access on the workers.dev row"
        echo "4. Go to Zero Trust → Access → Applications"
        echo "5. Find your app, copy the Application Audience (AUD) tag"
        echo "6. Run:"
        echo "   npx wrangler secret put CF_ACCESS_TEAM_DOMAIN"
        echo "   npx wrangler secret put CF_ACCESS_AUD"
        echo ""

        if confirm "Skip Cloudflare Access for now?"; then
            warn "Skipping - admin UI will not be protected!"
        else
            error "Cannot proceed without Cloudflare Access"
            return 1
        fi
    fi

    cat > "${SCRIPT_DIR}/PLANNING/PHASE-2-COMPLETE.md" << EOF
# Phase 2 Complete

**Completed:** $(date)

## Results
- CF Access Team Domain: $([ -n "${CF_ACCESS_TEAM_DOMAIN:-}" ] && echo "Set" || echo "Skipped")
- CF Access AUD: $([ -n "${CF_ACCESS_AUD:-}" ] && echo "Set" || echo "Skipped")
EOF
}

#===============================================================================
# Phase 3: Deploy
#===============================================================================

phase3_deploy() {
    header "Phase 3: Deploy to Cloudflare Workers"

    local mw_dir
    mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd || echo "${MOLTWORKER_DIR}")
    cd "$mw_dir"

    info "Deploying moltworker to Cloudflare..."
    npm run deploy 2>&1 | tee -a "$LOG_FILE"

    # Extract worker URL from deploy output
    local worker_url
    worker_url=$(grep -oE 'https://[a-zA-Z0-9.-]+\.workers\.dev' "$LOG_FILE" | tail -1 || echo "")

    if [[ -n "$worker_url" ]]; then
        success "Deployed to: ${worker_url}"
        echo "$worker_url" > "${SCRIPT_DIR}/.worker_url"

        echo ""
        echo -e "${GREEN}Access your Control UI:${NC}"
        echo "${worker_url}/?token=${MOLTBOT_GATEWAY_TOKEN:-<your-token>}"
        echo ""
        echo -e "${GREEN}Admin UI:${NC}"
        echo "${worker_url}/_admin/"
        echo ""
    else
        warn "Could not extract worker URL from deploy output"
        info "Check your Cloudflare dashboard for the deployed URL"
    fi

    cat > "${SCRIPT_DIR}/PLANNING/PHASE-3-COMPLETE.md" << EOF
# Phase 3 Complete

**Completed:** $(date)

## Results
- Worker deployed: ${worker_url:-"check dashboard"}
- Control UI: ${worker_url:-"..."}/?token=<token>
- Admin UI: ${worker_url:-"..."}/_admin/
EOF
}

#===============================================================================
# Phase 4: R2 Storage and Chat Channels
#===============================================================================

phase4_persistence_and_channels() {
    header "Phase 4: R2 Persistence and Chat Channels"

    local mw_dir
    mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd || echo "${MOLTWORKER_DIR}")
    cd "$mw_dir"

    local changes=0

    # R2 Storage
    if [[ -n "${R2_ACCESS_KEY_ID:-}" ]] && [[ -n "${R2_SECRET_ACCESS_KEY:-}" ]] && [[ -n "${CF_ACCOUNT_ID:-}" ]]; then
        info "Configuring R2 persistent storage..."
        set_secret "R2_ACCESS_KEY_ID" "$R2_ACCESS_KEY_ID"
        set_secret "R2_SECRET_ACCESS_KEY" "$R2_SECRET_ACCESS_KEY"
        set_secret "CF_ACCOUNT_ID" "$CF_ACCOUNT_ID"
        success "R2 storage configured"
        ((changes++))
    else
        warn "R2 storage not configured - data will be ephemeral!"
        warn "Set R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, CF_ACCOUNT_ID in settings.env"
    fi

    # Chat channels
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
        info "Configuring Telegram..."
        set_secret "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
        [[ -n "${TELEGRAM_DM_POLICY:-}" ]] && set_secret "TELEGRAM_DM_POLICY" "$TELEGRAM_DM_POLICY"
        success "Telegram configured"
        ((changes++))
    fi

    if [[ -n "${DISCORD_BOT_TOKEN:-}" ]]; then
        info "Configuring Discord..."
        set_secret "DISCORD_BOT_TOKEN" "$DISCORD_BOT_TOKEN"
        [[ -n "${DISCORD_DM_POLICY:-}" ]] && set_secret "DISCORD_DM_POLICY" "$DISCORD_DM_POLICY"
        success "Discord configured"
        ((changes++))
    fi

    if [[ -n "${SLACK_BOT_TOKEN:-}" ]] && [[ -n "${SLACK_APP_TOKEN:-}" ]]; then
        info "Configuring Slack..."
        set_secret "SLACK_BOT_TOKEN" "$SLACK_BOT_TOKEN"
        set_secret "SLACK_APP_TOKEN" "$SLACK_APP_TOKEN"
        success "Slack configured"
        ((changes++))
    fi

    # Browser automation
    if [[ -n "${CDP_SECRET:-}" ]]; then
        info "Configuring browser automation..."
        set_secret "CDP_SECRET" "$CDP_SECRET"
        [[ -n "${WORKER_URL:-}" ]] && set_secret "WORKER_URL" "$WORKER_URL"
        success "Browser automation configured"
        ((changes++))
    fi

    # AI Gateway
    if [[ -n "${CLOUDFLARE_AI_GATEWAY_API_KEY:-}" ]]; then
        info "Configuring AI Gateway..."
        set_secret "CLOUDFLARE_AI_GATEWAY_API_KEY" "$CLOUDFLARE_AI_GATEWAY_API_KEY"
        [[ -n "${CF_AI_GATEWAY_ACCOUNT_ID:-}" ]] && set_secret "CF_AI_GATEWAY_ACCOUNT_ID" "$CF_AI_GATEWAY_ACCOUNT_ID"
        [[ -n "${CF_AI_GATEWAY_GATEWAY_ID:-}" ]] && set_secret "CF_AI_GATEWAY_GATEWAY_ID" "$CF_AI_GATEWAY_GATEWAY_ID"
        [[ -n "${CF_AI_GATEWAY_MODEL:-}" ]] && set_secret "CF_AI_GATEWAY_MODEL" "$CF_AI_GATEWAY_MODEL"
        success "AI Gateway configured"
        ((changes++))
    fi

    # Cost optimization
    if [[ -n "${SANDBOX_SLEEP_AFTER:-}" ]]; then
        set_secret "SANDBOX_SLEEP_AFTER" "$SANDBOX_SLEEP_AFTER"
        info "Sandbox sleep timer set to: ${SANDBOX_SLEEP_AFTER}"
        ((changes++))
    fi

    # Redeploy if we added secrets
    if [[ "$changes" -gt 0 ]]; then
        info "Redeploying with new secrets..."
        npm run deploy 2>&1 | tee -a "$LOG_FILE"
        success "Redeployed with ${changes} new configuration(s)"
    else
        warn "No optional features configured"
    fi

    cat > "${SCRIPT_DIR}/PLANNING/PHASE-4-COMPLETE.md" << EOF
# Phase 4 Complete

**Completed:** $(date)

## Results
- R2 Storage: $([ -n "${R2_ACCESS_KEY_ID:-}" ] && echo "Configured" || echo "Skipped (ephemeral)")
- Telegram: $([ -n "${TELEGRAM_BOT_TOKEN:-}" ] && echo "Configured" || echo "Skipped")
- Discord: $([ -n "${DISCORD_BOT_TOKEN:-}" ] && echo "Configured" || echo "Skipped")
- Slack: $([ -n "${SLACK_BOT_TOKEN:-}" ] && echo "Configured" || echo "Skipped")
- Browser (CDP): $([ -n "${CDP_SECRET:-}" ] && echo "Configured" || echo "Skipped")
- AI Gateway: $([ -n "${CLOUDFLARE_AI_GATEWAY_API_KEY:-}" ] && echo "Configured" || echo "Direct Anthropic")
- Sleep timer: ${SANDBOX_SLEEP_AFTER:-"Disabled (always-on)"}
EOF
}

#===============================================================================
# Phase 5: Verify and Pair Devices
#===============================================================================

phase5_verify() {
    header "Phase 5: Verify Deployment and Pair Devices"

    local worker_url
    if [[ -f "${SCRIPT_DIR}/.worker_url" ]]; then
        worker_url=$(cat "${SCRIPT_DIR}/.worker_url")
    else
        worker_url="${WORKER_URL:-}"
    fi

    local gateway_token
    if [[ -f "${SCRIPT_DIR}/.gateway_token" ]]; then
        gateway_token=$(cat "${SCRIPT_DIR}/.gateway_token")
    else
        gateway_token="${MOLTBOT_GATEWAY_TOKEN:-}"
    fi

    if [[ -z "$worker_url" ]]; then
        warn "Worker URL not found. Check your Cloudflare dashboard."
        read -p "Enter your worker URL: " worker_url
    fi

    # Health check
    info "Checking worker health..."
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "${worker_url}/" 2>/dev/null || echo "000")

    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "302" ]] || [[ "$http_code" == "401" ]]; then
        success "Worker is responding (HTTP ${http_code})"
    else
        warn "Worker returned HTTP ${http_code} - may still be starting (cold start takes 1-2 min)"
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Control UI:  ${BLUE}${worker_url}/?token=${gateway_token}${NC}"
    echo -e "Admin UI:    ${BLUE}${worker_url}/_admin/${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Open the Control UI in your browser"
    echo "2. Go to the Admin UI (/_admin/) to approve device pairings"
    echo "3. Connect your Telegram/Discord/Slack bot"
    echo "4. Send a test message to your bot"
    echo ""

    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
        echo -e "Telegram: Send a message to your bot - it will appear in /_admin/ for pairing approval"
    fi

    cat > "${SCRIPT_DIR}/PLANNING/PHASE-5-COMPLETE.md" << EOF
# Phase 5 Complete

**Completed:** $(date)

## Results
- Worker URL: ${worker_url}
- Health check: HTTP ${http_code}
- Gateway token saved to: .gateway_token

## Access URLs
- Control UI: ${worker_url}/?token=<token>
- Admin UI: ${worker_url}/_admin/

## Deployment Summary
This OpenClaw instance is running on Cloudflare Workers with:
- Container sandbox isolation
- $([ -n "${R2_ACCESS_KEY_ID:-}" ] && echo "R2 persistent storage (5-min sync)" || echo "Ephemeral storage (no R2)")
- $([ -n "${CF_ACCESS_TEAM_DOMAIN:-}" ] && echo "Cloudflare Access protection" || echo "No admin auth (configure CF Access!)")
- Channels: $([ -n "${TELEGRAM_BOT_TOKEN:-}" ] && echo "Telegram " || echo "")$([ -n "${DISCORD_BOT_TOKEN:-}" ] && echo "Discord " || echo "")$([ -n "${SLACK_BOT_TOKEN:-}" ] && echo "Slack" || echo "")$([ -z "${TELEGRAM_BOT_TOKEN:-}${DISCORD_BOT_TOKEN:-}${SLACK_BOT_TOKEN:-}" ] && echo "None" || echo "")
EOF
}

#===============================================================================
# Secret Configuration Helper
#===============================================================================

configure_all_secrets() {
    header "Configuring All Secrets from settings.env"

    local mw_dir
    mw_dir=$(cd "${SCRIPT_DIR}" && cd "${MOLTWORKER_DIR}" 2>/dev/null && pwd || echo "${MOLTWORKER_DIR}")
    cd "$mw_dir"

    # Map of env var -> wrangler secret name
    local -a secrets=(
        "ANTHROPIC_API_KEY"
        "MOLTBOT_GATEWAY_TOKEN"
        "CF_ACCESS_TEAM_DOMAIN"
        "CF_ACCESS_AUD"
        "R2_ACCESS_KEY_ID"
        "R2_SECRET_ACCESS_KEY"
        "CF_ACCOUNT_ID"
        "TELEGRAM_BOT_TOKEN"
        "TELEGRAM_DM_POLICY"
        "DISCORD_BOT_TOKEN"
        "DISCORD_DM_POLICY"
        "SLACK_BOT_TOKEN"
        "SLACK_APP_TOKEN"
        "CDP_SECRET"
        "WORKER_URL"
        "CLOUDFLARE_AI_GATEWAY_API_KEY"
        "CF_AI_GATEWAY_ACCOUNT_ID"
        "CF_AI_GATEWAY_GATEWAY_ID"
        "CF_AI_GATEWAY_MODEL"
        "SANDBOX_SLEEP_AFTER"
    )

    local count=0
    for name in "${secrets[@]}"; do
        local value="${!name:-}"
        if [[ -n "$value" ]]; then
            set_secret "$name" "$value"
            ((count++))
        fi
    done

    success "Configured ${count} secret(s)"
}

#===============================================================================
# Main
#===============================================================================

main() {
    echo -e "${BLUE}OpenClaw Cloudflare Workers (Moltworker) Setup${NC}"
    echo -e "Log: ${LOG_FILE}"
    echo ""

    case "${1:-all}" in
        all)
            phase0_verify_prerequisites
            phase1_clone_and_configure
            phase2_cloudflare_access
            phase3_deploy
            phase4_persistence_and_channels
            phase5_verify
            ;;
        0) phase0_verify_prerequisites ;;
        1) phase1_clone_and_configure ;;
        2) phase2_cloudflare_access ;;
        3) phase3_deploy ;;
        4) phase4_persistence_and_channels ;;
        5) phase5_verify ;;
        secrets) configure_all_secrets ;;
        *)
            echo "Usage: $0 [all|0-5|secrets]"
            echo ""
            echo "Phases:"
            echo "  0       Verify prerequisites"
            echo "  1       Clone moltworker and configure core secrets"
            echo "  2       Set up Cloudflare Access"
            echo "  3       Deploy to Cloudflare Workers"
            echo "  4       Configure R2 storage and chat channels"
            echo "  5       Verify deployment and pair devices"
            echo ""
            echo "Helpers:"
            echo "  all     Run all phases (default)"
            echo "  secrets Push all secrets from settings.env to wrangler"
            exit 1
            ;;
    esac
}

main "$@"
