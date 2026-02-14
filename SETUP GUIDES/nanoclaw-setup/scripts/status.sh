#!/usr/bin/env bash
# NanoClaw Status Check
# Shows service status, process info, and recent log entries
set -euo pipefail

NANOCLAW_ROOT="${NANOCLAW_ROOT:-$HOME/nanoclaw}"

echo "╔══════════════════════════════════════════════╗"
echo "║      NanoClaw Status                         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# --- Service Status ---
echo "Service:"
if launchctl print "gui/$(id -u)/com.nanoclaw" &>/dev/null; then
    echo "  ✅ launchd service loaded"
    STATE=$(launchctl print "gui/$(id -u)/com.nanoclaw" 2>/dev/null | grep "state" | head -1 || echo "  state = unknown")
    echo "  $STATE"
else
    echo "  ❌ launchd service not loaded"
fi
echo ""

# --- Process ---
echo "Process:"
if pgrep -f "dist/index.js" &>/dev/null; then
    PID=$(pgrep -f "dist/index.js")
    echo "  ✅ Running (PID: $PID)"

    # CPU and memory
    PS_INFO=$(ps -p "$PID" -o %cpu,%mem,etime 2>/dev/null | tail -1)
    CPU=$(echo "$PS_INFO" | awk '{print $1}')
    MEM=$(echo "$PS_INFO" | awk '{print $2}')
    UPTIME=$(echo "$PS_INFO" | awk '{print $3}')
    echo "  CPU: ${CPU}%  |  Memory: ${MEM}%  |  Uptime: ${UPTIME}"
else
    echo "  ❌ Not running"
fi
echo ""

# --- Container Runtime ---
echo "Container Runtime:"
if command -v container &>/dev/null; then
    echo "  ✅ Apple Container available"
    RUNNING=$(container ps -q 2>/dev/null | wc -l | tr -d ' ')
    echo "  Active containers: $RUNNING"
elif command -v docker &>/dev/null; then
    echo "  ✅ Docker available"
    RUNNING=$(docker ps -q --filter "ancestor=nanoclaw-agent" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Active containers: $RUNNING"
else
    echo "  ❌ No container runtime found"
fi

# Container image
if command -v container &>/dev/null; then
    if container images 2>/dev/null | grep -q "nanoclaw-agent"; then
        echo "  ✅ nanoclaw-agent image exists"
    else
        echo "  ❌ nanoclaw-agent image not built"
    fi
elif command -v docker &>/dev/null; then
    if docker images 2>/dev/null | grep -q "nanoclaw-agent"; then
        echo "  ✅ nanoclaw-agent image exists"
    else
        echo "  ❌ nanoclaw-agent image not built"
    fi
fi
echo ""

# --- WhatsApp ---
echo "WhatsApp:"
if [[ -d "$NANOCLAW_ROOT/store/auth" ]] && [[ "$(ls -A "$NANOCLAW_ROOT/store/auth" 2>/dev/null)" ]]; then
    echo "  ✅ Auth session exists"
else
    echo "  ❌ Not authenticated (run: cd $NANOCLAW_ROOT && npm run auth)"
fi
echo ""

# --- Database ---
echo "Database:"
DB_PATH="$NANOCLAW_ROOT/data/nanoclaw.db"
if [[ -f "$DB_PATH" ]]; then
    DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
    echo "  ✅ Database exists ($DB_SIZE)"

    # Message count
    if command -v sqlite3 &>/dev/null; then
        MSG_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM messages;" 2>/dev/null || echo "?")
        GROUP_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM groups;" 2>/dev/null || echo "?")
        echo "  Messages: $MSG_COUNT  |  Groups: $GROUP_COUNT"
    fi
else
    echo "  ⚠️  Database not created yet (created on first run)"
fi
echo ""

# --- Groups ---
echo "Groups:"
if [[ -d "$NANOCLAW_ROOT/groups" ]]; then
    GROUP_DIRS=$(find "$NANOCLAW_ROOT/groups" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
    echo "  $GROUP_DIRS group folder(s)"
    if [[ -f "$NANOCLAW_ROOT/groups/CLAUDE.md" ]]; then
        echo "  ✅ Global CLAUDE.md exists"
    else
        echo "  ⚠️  No global CLAUDE.md yet"
    fi
else
    echo "  ⚠️  No groups directory yet"
fi
echo ""

# --- Logs ---
echo "Recent Logs (last 5 lines):"
LOG_FILE="$NANOCLAW_ROOT/logs/nanoclaw.log"
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(du -h "$LOG_FILE" | cut -f1)
    echo "  ($LOG_FILE — $LOG_SIZE)"
    echo "  ────────────────────────────────────────"
    tail -5 "$LOG_FILE" 2>/dev/null | sed 's/^/  /'
else
    echo "  No log file yet"
fi

ERR_FILE="$NANOCLAW_ROOT/logs/nanoclaw.error.log"
if [[ -f "$ERR_FILE" ]] && [[ -s "$ERR_FILE" ]]; then
    echo ""
    echo "Recent Errors (last 3 lines):"
    echo "  ($ERR_FILE)"
    echo "  ────────────────────────────────────────"
    tail -3 "$ERR_FILE" 2>/dev/null | sed 's/^/  /'
fi

echo ""
echo "════════════════════════════════════════════════"
