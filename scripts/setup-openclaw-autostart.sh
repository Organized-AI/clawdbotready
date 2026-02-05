#!/usr/bin/env bash
# setup-openclaw-autostart.sh - Configure OpenClaw to start automatically

set -euo pipefail

echo "=========================================="
echo "OpenClaw Auto-Start Setup"
echo "=========================================="
echo ""

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.openclaw.gateway.plist"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENT_DIR"

echo "Creating LaunchAgent configuration..."

# Create the plist file
cat > "$LAUNCH_AGENT_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/node</string>
        <string>/Users/openclaw/Library/pnpm/global/5/.pnpm/openclaw@2026.2.1_@napi-rs+canvas@0.1.89_@types+express@5.0.6_node-llama-cpp@3.15.1_signal-polyfill@0.2.2/node_modules/openclaw/dist/index.js</string>
        <string>gateway</string>
        <string>--port</string>
        <string>18789</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/openclaw/.openclaw/logs/gateway.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/openclaw/.openclaw/logs/gateway.stderr.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/openclaw</string>
</dict>
</plist>
EOF

echo "✓ LaunchAgent file created at:"
echo "  $LAUNCH_AGENT_FILE"
echo ""

# Stop any running gateway
echo "Stopping any existing OpenClaw gateway..."
pkill -f "openclaw.*gateway" 2>/dev/null || true
sleep 2

# Load the launch agent
echo "Loading LaunchAgent..."
launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
launchctl load "$LAUNCH_AGENT_FILE"

# Start it
echo "Starting OpenClaw Gateway..."
launchctl start com.openclaw.gateway

sleep 3

# Verify it's running
if ps aux | grep -v grep | grep "openclaw.*gateway" > /dev/null; then
    echo ""
    echo "✓ SUCCESS! OpenClaw Gateway is running."
    echo ""
    echo "OpenClaw will now start automatically when you:"
    echo "  - Log in to your account"
    echo "  - Restart the Mac Mini"
    echo ""
    echo "To verify the bot works:"
    echo "  1. Open Telegram"
    echo "  2. Search for @SAMyosin_bot"
    echo "  3. Send a message"
    echo ""
    echo "To view logs:"
    echo "  tail -f ~/.openclaw/logs/gateway.log"
    echo ""
else
    echo ""
    echo "⚠ WARNING: OpenClaw may not have started correctly."
    echo ""
    echo "Check logs:"
    echo "  tail -30 ~/.openclaw/logs/gateway.log"
    echo "  tail -30 ~/.openclaw/logs/gateway.err.log"
    echo ""
fi
