#!/usr/bin/env bash
# NanoClaw Service Installer
# Builds TypeScript, generates launchd plist, and starts the service
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$(dirname "$SCRIPT_DIR")"

# --- Detect NanoClaw root ---
NANOCLAW_ROOT="${NANOCLAW_ROOT:-}"
if [[ -z "$NANOCLAW_ROOT" ]]; then
    # Try common locations
    for candidate in \
        "$HOME/nanoclaw" \
        "$HOME/projects/nanoclaw" \
        "$HOME/repos/nanoclaw" \
        "$HOME/code/nanoclaw"; do
        if [[ -f "$candidate/package.json" ]] && grep -q '"nanoclaw"' "$candidate/package.json" 2>/dev/null; then
            NANOCLAW_ROOT="$candidate"
            break
        fi
    done
fi

if [[ -z "$NANOCLAW_ROOT" || ! -f "$NANOCLAW_ROOT/package.json" ]]; then
    echo "❌ Cannot find NanoClaw installation."
    echo "   Set NANOCLAW_ROOT environment variable or clone to ~/nanoclaw"
    echo ""
    echo "   git clone https://github.com/qwibitai/nanoclaw.git ~/nanoclaw"
    exit 1
fi

echo "╔══════════════════════════════════════════════╗"
echo "║      NanoClaw Service Installer              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Project: $NANOCLAW_ROOT"

# --- Load settings if available ---
if [[ -f "$NANOCLAW_ROOT/.env" ]]; then
    echo "  Config:  $NANOCLAW_ROOT/.env"
    set -a
    source "$NANOCLAW_ROOT/.env"
    set +a
fi

# --- Resolve paths ---
NODE_PATH="${NODE_PATH:-$(which node)}"
ASSISTANT_NAME="${ASSISTANT_NAME:-Andy}"
PROJECT_ROOT="$NANOCLAW_ROOT"
HOME_DIR="$HOME"

echo "  Node:    $NODE_PATH"
echo "  Trigger: @$ASSISTANT_NAME"
echo ""

# --- Step 1: Build TypeScript ---
echo "→ Building TypeScript..."
cd "$NANOCLAW_ROOT"
npm run build
echo "  ✅ Build complete"
echo ""

# --- Step 2: Create logs directory ---
mkdir -p "$NANOCLAW_ROOT/logs"

# --- Step 3: Generate launchd plist ---
PLIST_TEMPLATE="$SETUP_DIR/config/com.nanoclaw.plist.template"
PLIST_DEST="$HOME/Library/LaunchAgents/com.nanoclaw.plist"

if [[ ! -f "$PLIST_TEMPLATE" ]]; then
    echo "❌ Plist template not found at: $PLIST_TEMPLATE"
    exit 1
fi

echo "→ Generating launchd plist..."
mkdir -p "$HOME/Library/LaunchAgents"

sed \
    -e "s|{{NODE_PATH}}|$NODE_PATH|g" \
    -e "s|{{PROJECT_ROOT}}|$PROJECT_ROOT|g" \
    -e "s|{{HOME}}|$HOME_DIR|g" \
    -e "s|{{ASSISTANT_NAME}}|$ASSISTANT_NAME|g" \
    "$PLIST_TEMPLATE" > "$PLIST_DEST"

echo "  ✅ Plist written to: $PLIST_DEST"

# --- Step 4: Validate plist ---
echo "→ Validating plist..."
plutil -lint "$PLIST_DEST"
echo ""

# --- Step 5: Unload existing service (if running) ---
if launchctl print "gui/$(id -u)/com.nanoclaw" &>/dev/null; then
    echo "→ Stopping existing service..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    sleep 2
    echo "  ✅ Previous service stopped"
fi

# --- Step 6: Load and start service ---
echo "→ Starting NanoClaw service..."
launchctl load "$PLIST_DEST"
sleep 3

# --- Step 7: Verify ---
if pgrep -f "dist/index.js" &>/dev/null; then
    PID=$(pgrep -f "dist/index.js")
    echo "  ✅ NanoClaw is running (PID: $PID)"
else
    echo "  ⚠️  Service loaded but process not detected yet."
    echo "     Check logs: tail -f $NANOCLAW_ROOT/logs/nanoclaw.error.log"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  NanoClaw service installed successfully!"
echo ""
echo "  Manage with:"
echo "    $SCRIPT_DIR/status.sh       — Check status"
echo "    $SCRIPT_DIR/stop.sh         — Stop service"
echo "    $SCRIPT_DIR/start.sh        — Start service"
echo "    $SCRIPT_DIR/restart.sh      — Restart service"
echo "    $SCRIPT_DIR/logs.sh         — View logs"
echo "════════════════════════════════════════════════"
