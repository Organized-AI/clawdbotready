#!/usr/bin/env bash
# Pull OpenClaw Gateway logs from remote Mac Mini
# Usage: ./scripts/pull-gateway-logs.sh [hostname]

set -euo pipefail

# Configuration
REMOTE_HOST="${1:-100.66.145.48}"
REMOTE_USER="openclaw"
SSH_OPTS="-o IdentitiesOnly=yes -o ConnectTimeout=10 -o BatchMode=yes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/.analysis/raw"
DATE_STAMP=$(date +%Y-%m-%d)

# Remote paths
REMOTE_SESSIONS="~/.openclaw/agents/main/sessions"
REMOTE_GATEWAY_LOG="~/.openclaw/logs/gateway.log"
REMOTE_GATEWAY_ERR="~/.openclaw/logs/gateway.err.log"
REMOTE_COMMANDS_LOG="~/.openclaw/logs/commands.log"
REMOTE_DAILY_LOGS="/tmp/openclaw"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[pull]${NC} $1"; }
log_success() { echo -e "${GREEN}[pull]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[pull]${NC} $1"; }
log_error() { echo -e "${RED}[pull]${NC} $1"; }

check_connectivity() {
    log_info "Checking connectivity to $REMOTE_USER@$REMOTE_HOST..."
    if ! ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "echo ok" &>/dev/null; then
        log_error "Cannot connect to $REMOTE_USER@$REMOTE_HOST"
        log_error "Check: tailscale ping $REMOTE_HOST"
        exit 1
    fi
    log_success "Connected"
}

pull_sessions() {
    local dest="$OUTPUT_DIR/$DATE_STAMP/sessions"
    mkdir -p "$dest"

    log_info "Pulling session JSONL files..."

    # Get list of session files with sizes
    local file_list
    file_list=$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
        "ls -l $REMOTE_SESSIONS/*.jsonl $REMOTE_SESSIONS/sessions.json 2>/dev/null || true")

    if [[ -z "$file_list" ]]; then
        log_warn "No session files found"
        return
    fi

    # Use rsync for incremental sync (only changed files)
    rsync -az --progress \
        -e "ssh $SSH_OPTS" \
        "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SESSIONS/" \
        "$dest/" 2>/dev/null || {
        # Fallback to scp if rsync not available
        log_warn "rsync failed, falling back to scp..."
        scp $SSH_OPTS -r "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SESSIONS/"*.jsonl "$dest/" 2>/dev/null || true
        scp $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SESSIONS/sessions.json" "$dest/" 2>/dev/null || true
    }

    local count
    count=$(find "$dest" -name "*.jsonl" | wc -l | tr -d ' ')
    log_success "Pulled $count session files"
}

pull_gateway_logs() {
    local dest="$OUTPUT_DIR/$DATE_STAMP/logs"
    mkdir -p "$dest"

    log_info "Pulling gateway logs..."

    # Pull main gateway logs
    for remote_path in "$REMOTE_GATEWAY_LOG" "$REMOTE_GATEWAY_ERR" "$REMOTE_COMMANDS_LOG"; do
        local filename
        filename=$(basename "$remote_path")
        scp $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST:$remote_path" "$dest/$filename" 2>/dev/null && \
            log_success "  $filename ($(du -h "$dest/$filename" | cut -f1))" || \
            log_warn "  $filename not found"
    done
}

pull_daily_logs() {
    local dest="$OUTPUT_DIR/$DATE_STAMP/daily"
    mkdir -p "$dest"

    log_info "Pulling daily structured logs..."

    # Pull all daily logs from /tmp/openclaw/
    scp $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DAILY_LOGS/"*.log "$dest/" 2>/dev/null && \
        log_success "  $(find "$dest" -name "*.log" | wc -l | tr -d ' ') daily log files" || \
        log_warn "  No daily logs found in $REMOTE_DAILY_LOGS"
}

create_latest_symlink() {
    local latest="$OUTPUT_DIR/latest"
    rm -f "$latest"
    ln -sf "$DATE_STAMP" "$latest"
    log_success "Symlinked .analysis/raw/latest -> $DATE_STAMP"
}

summarize() {
    local dest="$OUTPUT_DIR/$DATE_STAMP"
    local total_size
    total_size=$(du -sh "$dest" 2>/dev/null | cut -f1)

    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Log Pull Complete${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "  Host:     $REMOTE_USER@$REMOTE_HOST"
    echo -e "  Date:     $DATE_STAMP"
    echo -e "  Output:   .analysis/raw/$DATE_STAMP/"
    echo -e "  Size:     $total_size"
    echo ""
    echo -e "  Next: ${BLUE}just log-analyze${NC}"
    echo ""
}

main() {
    echo ""
    log_info "Gateway Log Pull - $DATE_STAMP"
    echo ""

    check_connectivity
    pull_sessions
    pull_gateway_logs
    pull_daily_logs
    create_latest_symlink
    summarize
}

main
