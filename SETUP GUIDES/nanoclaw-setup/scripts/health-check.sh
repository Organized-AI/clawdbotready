#!/usr/bin/env bash
# NanoClaw Health Check
# Comprehensive health check for all NanoClaw components
set -euo pipefail

NANOCLAW_ROOT="${NANOCLAW_ROOT:-$HOME/nanoclaw}"
JSON_MODE="${1:-}"

CHECKS=()
OVERALL="healthy"

check() {
    local name="$1"
    local status="$2"
    local detail="$3"

    if [[ "$JSON_MODE" == "--json" ]]; then
        CHECKS+=("{\"name\":\"$name\",\"status\":\"$status\",\"detail\":\"$detail\"}")
    else
        case "$status" in
            ok)   echo "  ✅ $name: $detail" ;;
            warn) echo "  ⚠️  $name: $detail" ;;
            fail) echo "  ❌ $name: $detail" ;;
        esac
    fi

    if [[ "$status" == "fail" ]]; then
        OVERALL="unhealthy"
    elif [[ "$status" == "warn" && "$OVERALL" == "healthy" ]]; then
        OVERALL="degraded"
    fi
}

if [[ "$JSON_MODE" != "--json" ]]; then
    echo "╔══════════════════════════════════════════════╗"
    echo "║      NanoClaw Health Check                   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
fi

# --- Process ---
if pgrep -f "dist/index.js" &>/dev/null; then
    PID=$(pgrep -f "dist/index.js")
    MEM=$(ps -p "$PID" -o rss= 2>/dev/null | awk '{printf "%.0f", $1/1024}')
    check "process" "ok" "Running (PID: $PID, ${MEM}MB RAM)"
else
    check "process" "fail" "Not running"
fi

# --- Service ---
if launchctl print "gui/$(id -u)/com.nanoclaw" &>/dev/null; then
    check "service" "ok" "launchd service loaded"
else
    check "service" "fail" "launchd service not loaded"
fi

# --- Container Runtime ---
if command -v container &>/dev/null; then
    check "runtime" "ok" "Apple Container available"
elif command -v docker &>/dev/null; then
    check "runtime" "ok" "Docker available"
else
    check "runtime" "fail" "No container runtime"
fi

# --- Container Image ---
IMAGE_EXISTS=false
if command -v container &>/dev/null && container images 2>/dev/null | grep -q "nanoclaw-agent"; then
    IMAGE_EXISTS=true
elif command -v docker &>/dev/null && docker images 2>/dev/null | grep -q "nanoclaw-agent"; then
    IMAGE_EXISTS=true
fi
if $IMAGE_EXISTS; then
    check "image" "ok" "nanoclaw-agent image exists"
else
    check "image" "fail" "nanoclaw-agent image not found"
fi

# --- WhatsApp Auth ---
if [[ -d "$NANOCLAW_ROOT/store/auth" ]] && [[ "$(ls -A "$NANOCLAW_ROOT/store/auth" 2>/dev/null)" ]]; then
    check "whatsapp" "ok" "Auth session present"
else
    check "whatsapp" "fail" "No auth session"
fi

# --- Database ---
DB_PATH="$NANOCLAW_ROOT/data/nanoclaw.db"
if [[ -f "$DB_PATH" ]]; then
    if command -v sqlite3 &>/dev/null; then
        INTEGRITY=$(sqlite3 "$DB_PATH" "PRAGMA integrity_check;" 2>/dev/null || echo "error")
        if [[ "$INTEGRITY" == "ok" ]]; then
            check "database" "ok" "SQLite healthy"
        else
            check "database" "warn" "Integrity: $INTEGRITY"
        fi
    else
        check "database" "ok" "Database file exists"
    fi
else
    check "database" "warn" "Database not created yet"
fi

# --- Disk Space ---
AVAILABLE_GB=$(df -g / | tail -1 | awk '{print $4}')
if [[ "$AVAILABLE_GB" -ge 10 ]]; then
    check "disk" "ok" "${AVAILABLE_GB}GB available"
elif [[ "$AVAILABLE_GB" -ge 5 ]]; then
    check "disk" "warn" "${AVAILABLE_GB}GB available (low)"
else
    check "disk" "fail" "${AVAILABLE_GB}GB available (critical)"
fi

# --- Log File Size ---
LOG_FILE="$NANOCLAW_ROOT/logs/nanoclaw.log"
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE_MB=$(du -m "$LOG_FILE" | cut -f1)
    if [[ "$LOG_SIZE_MB" -gt 500 ]]; then
        check "logs" "warn" "Log file ${LOG_SIZE_MB}MB (consider rotation)"
    else
        check "logs" "ok" "Log file ${LOG_SIZE_MB}MB"
    fi
else
    check "logs" "ok" "No log file yet"
fi

# --- Error Log ---
ERR_FILE="$NANOCLAW_ROOT/logs/nanoclaw.error.log"
if [[ -f "$ERR_FILE" ]] && [[ -s "$ERR_FILE" ]]; then
    RECENT_ERRORS=$(tail -20 "$ERR_FILE" | grep -ci "error\|fatal\|panic" || true)
    if [[ "$RECENT_ERRORS" -gt 5 ]]; then
        check "errors" "warn" "$RECENT_ERRORS errors in last 20 log lines"
    else
        check "errors" "ok" "Error log exists, $RECENT_ERRORS recent errors"
    fi
else
    check "errors" "ok" "No errors"
fi

# --- Network ---
if curl -s --connect-timeout 3 https://api.anthropic.com >/dev/null 2>&1; then
    check "network" "ok" "Anthropic API reachable"
else
    check "network" "warn" "Cannot reach Anthropic API"
fi

# --- Output ---
if [[ "$JSON_MODE" == "--json" ]]; then
    CHECKS_JSON=$(printf '%s,' "${CHECKS[@]}")
    CHECKS_JSON="[${CHECKS_JSON%,}]"
    echo "{\"status\":\"$OVERALL\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"checks\":$CHECKS_JSON}"
else
    echo ""
    echo "════════════════════════════════════════════════"
    case "$OVERALL" in
        healthy)   echo "  Overall: ✅ Healthy" ;;
        degraded)  echo "  Overall: ⚠️  Degraded (see warnings)" ;;
        unhealthy) echo "  Overall: ❌ Unhealthy (see failures)" ;;
    esac
    echo "════════════════════════════════════════════════"
fi
