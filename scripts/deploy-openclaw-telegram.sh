#!/usr/bin/env bash
#
# OpenClaw Automated Deployment Script - Telegram Edition
# Version: 1.0.0
# Created: 2026-02-02
# Purpose: Native macOS deployment with Telegram channel (no iMessage)
#

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GATEWAY_PORT=18789
GATEWAY_MODE="local"

# Telegram Bot Token (will be added later)
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"

# Helper Functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo ""; echo "=================================="; echo "$1"; echo "=================================="; echo ""; }
check_command() { command -v "$1" &> /dev/null; }

# Welcome
clear
print_header "OpenClaw Automated Installer - Telegram Edition"
cat << EOF
This script will:
✓ Configure your shell environment
✓ Install dependencies (Homebrew, Node.js, pnpm)
✓ Install OpenClaw Gateway
✓ Set up Telegram channel (token to be added later)
✓ Configure security and authentication

Estimated time: 10-15 minutes

${YELLOW}Note: Telegram bot token will be configured after installation${NC}
EOF
read -p "Ready to begin? (y/n) " -r
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 0

# Prerequisites
print_header "Checking Prerequisites"
log_info "Checking macOS version..."
log_success "macOS $(sw_vers -productVersion) detected"

log_info "Checking architecture..."
[[ "$(uname -m)" != "arm64" ]] && log_error "Apple Silicon required" && exit 1
log_success "Apple Silicon detected"

log_info "Checking disk space..."
AVAILABLE_GB=$(df -g / | tail -1 | awk '{print $4}')
[[ $AVAILABLE_GB -lt 5 ]] && log_error "Need 5GB, have ${AVAILABLE_GB}GB" && exit 1
log_success "${AVAILABLE_GB}GB available"

# Shell Environment
print_header "Configuring Shell Environment"
cat > ~/.zprofile << 'EOF'
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF
grep -q 'source ~/.zprofile' ~/.zshrc 2>/dev/null || echo 'source ~/.zprofile' >> ~/.zshrc
source ~/.zprofile 2>/dev/null || true
log_success "Shell environment configured"

# Install Homebrew
print_header "Installing Homebrew"
if check_command brew; then
    log_success "Homebrew already installed"
else
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log_success "Homebrew installed"
fi

# Install Node.js
print_header "Installing Node.js"
if check_command node; then
    log_success "Node.js already installed ($(node --version))"
else
    brew install node
    log_success "Node.js $(node --version) installed"
fi

# Install pnpm
print_header "Installing pnpm"
if check_command pnpm; then
    log_success "pnpm already installed (v$(pnpm --version))"
else
    brew install pnpm
    pnpm setup
    source ~/.zshrc 2>/dev/null || true
    log_success "pnpm v$(pnpm --version) installed"
fi

# Install OpenClaw
print_header "Installing OpenClaw Gateway"
if check_command openclaw; then
    log_warning "OpenClaw already installed"
else
    pnpm add -g openclaw@latest
    export PATH="$HOME/Library/pnpm:$PATH"
    log_success "OpenClaw $(openclaw --version) installed"
fi

# Configure Gateway
print_header "Configuring OpenClaw Gateway"
openclaw config set gateway.mode "$GATEWAY_MODE"
TOKEN=$(openssl rand -hex 32)
openclaw config set gateway.auth.token "$TOKEN"
mkdir -p ~/.openclaw
echo "$TOKEN" > ~/.openclaw/.gateway-token
chmod 600 ~/.openclaw/.gateway-token
log_success "Gateway configured (token saved)"

# Run Onboarding
print_header "Running OpenClaw Onboarding"
log_info "Follow the on-screen prompts..."
openclaw onboard --install-daemon

# Install Gateway Service
print_header "Installing Gateway Service"
openclaw gateway install --force --port "$GATEWAY_PORT"
openclaw gateway start
sleep 3
log_success "Gateway started on port $GATEWAY_PORT"

# Enable Telegram Plugin
print_header "Enabling Telegram Plugin"
openclaw plugins enable telegram || log_warning "Telegram plugin enable failed (will retry after token added)"
openclaw gateway restart
sleep 3
log_success "Gateway restarted"

# Setup Telegram Channel (if token provided)
print_header "Telegram Channel Setup"
if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
    log_info "Adding Telegram channel..."
    openclaw channels add --channel telegram \
        --token "$TELEGRAM_BOT_TOKEN" \
        --name "OpenClaw Telegram Bot"
    openclaw gateway restart
    log_success "Telegram channel configured"
else
    log_warning "No Telegram bot token provided"
    cat << EOF

${YELLOW}To add Telegram bot later, run:${NC}
    openclaw channels add --channel telegram \\
        --token YOUR_BOT_TOKEN \\
        --name "OpenClaw Telegram Bot"
    openclaw gateway restart

EOF
fi

# Create Dashboard
print_header "Creating Dashboard Access Page"
TOKEN=$(cat ~/.openclaw/.gateway-token)
cat > ~/openclaw-dashboard.html << DASHBOARD_EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenClaw Gateway - Dashboard</title>
    <style>
        body { font-family: -apple-system, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background: #1a1a1a; color: #e0e0e0; }
        .container { background: #2a2a2a; border-radius: 8px; padding: 30px; }
        h1 { color: #4fc3f7; }
        .token { background: #1e1e1e; padding: 15px; border-radius: 4px; font-family: monospace; color: #4fc3f7; margin: 20px 0; word-break: break-all; }
        .button { background: #4fc3f7; color: #1a1a1a; padding: 12px 24px; border: none; border-radius: 4px; text-decoration: none; display: inline-block; margin: 10px 0; font-weight: bold; }
        .success { color: #4caf50; }
        .warning { color: #ff9800; }
        code { background: #1e1e1e; padding: 2px 6px; border-radius: 3px; color: #4fc3f7; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🦞 OpenClaw Gateway Dashboard</h1>
        <h2 class="success">✅ Installation Complete!</h2>

        <h3>Your Gateway Token</h3>
        <div class="token">$TOKEN</div>

        <h3>Access Dashboard</h3>
        <a href="http://localhost:$GATEWAY_PORT/" class="button" target="_blank">Open Dashboard</a>

        <h3 class="warning">⚠️ Telegram Bot Setup Required</h3>
        <p>To complete Telegram integration:</p>
        <ol>
            <li>Get your bot token from @BotFather on Telegram</li>
            <li>Run this command in Terminal:</li>
        </ol>
        <div class="token">
openclaw channels add --channel telegram \\<br>
&nbsp;&nbsp;--token YOUR_BOT_TOKEN \\<br>
&nbsp;&nbsp;--name "OpenClaw Telegram Bot"<br>
openclaw gateway restart
        </div>

        <h3>Check Status</h3>
        <pre><code>openclaw gateway status
openclaw channels status
tail -f ~/.openclaw/logs/gateway.log</code></pre>
    </div>
</body>
</html>
DASHBOARD_EOF
log_success "Dashboard created at ~/openclaw-dashboard.html"
open ~/openclaw-dashboard.html 2>/dev/null || true

# Save token to easy-access file
cat > ~/openclaw-setup-info.txt << INFO_EOF
OpenClaw Gateway - Setup Information
=====================================
Installed: $(date)
Hostname: $(hostname)

Gateway Information:
- Port: $GATEWAY_PORT
- Token: $TOKEN
- Dashboard: http://localhost:$GATEWAY_PORT/

Configuration Files:
- Token: ~/.openclaw/.gateway-token
- Config: ~/.openclaw/openclaw.json
- Logs: ~/.openclaw/logs/gateway.log

Telegram Setup (Pending):
-------------------------
1. Create bot with @BotFather on Telegram
2. Copy the bot token
3. Run:
   openclaw channels add --channel telegram --token YOUR_BOT_TOKEN --name "OpenClaw Bot"
   openclaw gateway restart

Useful Commands:
----------------
# Check status
openclaw gateway status
openclaw channels status

# View logs
tail -f ~/.openclaw/logs/gateway.log

# Restart gateway
openclaw gateway restart

# Add Telegram channel
openclaw channels add --channel telegram --token TOKEN --name "Bot Name"
INFO_EOF
log_success "Setup info saved to ~/openclaw-setup-info.txt"

# Summary
print_header "Installation Complete!"
cat << EOF
${GREEN}✅ OpenClaw Gateway Successfully Installed!${NC}

${BLUE}Gateway Information:${NC}
- Port: $GATEWAY_PORT
- Token: $TOKEN
- Dashboard: http://localhost:$GATEWAY_PORT/
- Setup Info: ~/openclaw-setup-info.txt

${BLUE}Current Status:${NC}
EOF
openclaw gateway status || log_warning "Could not get gateway status"

cat << EOF

${YELLOW}Next Steps:${NC}
1. Get Telegram bot token from @BotFather
2. Run: openclaw channels add --channel telegram --token YOUR_TOKEN --name "Bot"
3. Run: openclaw gateway restart
4. Test by messaging your bot on Telegram

${BLUE}Quick Commands:${NC}
- View logs: tail -f ~/.openclaw/logs/gateway.log
- Check status: openclaw gateway status
- List channels: openclaw channels list

${GREEN}Installation successful!${NC} 🤖

All configuration saved to ~/openclaw-setup-info.txt
EOF
