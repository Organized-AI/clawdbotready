#!/bin/bash
# OpenClaw Gateway Installation Script for Clawdbot Ready
# Run this from the Clawdbot Ready project root

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
OPENCLAW_DIR="${PROJECT_ROOT}/openclaw-gateway"
LOG_FILE="${PROJECT_ROOT}/logs/openclaw-install-$(date +%Y%m%d_%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Create logs directory
mkdir -p "${PROJECT_ROOT}/logs"

echo ""
echo "🦞 ============================================="
echo "   OPENCLAW GATEWAY INSTALLATION"
echo "   Clawdbot Ready Integration"
echo "============================================="
echo ""

# Check Node.js version
log "Checking Node.js version..."
NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
if [[ -z "$NODE_VERSION" ]]; then
    error "Node.js is not installed. Please install Node.js >= 22"
fi
if [[ "$NODE_VERSION" -lt 22 ]]; then
    error "Node.js version $NODE_VERSION is too old. OpenClaw requires Node.js >= 22"
fi
log "✅ Node.js v$(node -v) detected"

# Check for pnpm
if command -v pnpm &> /dev/null; then
    PKG_MANAGER="pnpm"
    log "✅ pnpm detected"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
    warn "pnpm not found, using npm (pnpm recommended for OpenClaw)"
else
    error "No package manager found. Please install npm or pnpm"
fi

# Installation method selection
echo ""
echo "Select installation method:"
echo "  1) Git Submodule (recommended for development)"
echo "  2) Git Clone (standalone copy)"
echo "  3) NPM Global Install (simplest)"
echo ""
read -p "Enter choice [1-3]: " INSTALL_METHOD

case $INSTALL_METHOD in
    1)
        log "Installing OpenClaw as git submodule..."
        
        if [[ -d "$OPENCLAW_DIR" ]]; then
            warn "openclaw-gateway directory already exists"
            read -p "Remove and reinstall? [y/N]: " REINSTALL
            if [[ "$REINSTALL" =~ ^[Yy]$ ]]; then
                rm -rf "$OPENCLAW_DIR"
                git submodule deinit -f openclaw-gateway 2>/dev/null || true
                git rm -f openclaw-gateway 2>/dev/null || true
            else
                error "Installation cancelled"
            fi
        fi
        
        git submodule add https://github.com/openclaw/openclaw.git openclaw-gateway
        git submodule update --init --recursive
        
        log "Building OpenClaw from source..."
        cd "$OPENCLAW_DIR"
        $PKG_MANAGER install
        $PKG_MANAGER run ui:build
        $PKG_MANAGER run build
        cd "$PROJECT_ROOT"
        
        log "✅ OpenClaw installed as submodule"
        ;;
        
    2)
        log "Cloning OpenClaw repository..."
        
        if [[ -d "$OPENCLAW_DIR" ]]; then
            warn "openclaw-gateway directory already exists"
            read -p "Remove and reclone? [y/N]: " RECLONE
            if [[ "$RECLONE" =~ ^[Yy]$ ]]; then
                rm -rf "$OPENCLAW_DIR"
            else
                error "Installation cancelled"
            fi
        fi
        
        git clone https://github.com/openclaw/openclaw.git openclaw-gateway
        
        log "Building OpenClaw from source..."
        cd "$OPENCLAW_DIR"
        $PKG_MANAGER install
        $PKG_MANAGER run ui:build
        $PKG_MANAGER run build
        cd "$PROJECT_ROOT"
        
        log "✅ OpenClaw cloned and built"
        ;;
        
    3)
        log "Installing OpenClaw globally via npm..."
        npm install -g openclaw@latest
        log "✅ OpenClaw installed globally"
        ;;
        
    *)
        error "Invalid selection"
        ;;
esac

# Ask about daemon installation
echo ""
read -p "Install OpenClaw as background daemon (launchd/systemd)? [Y/n]: " INSTALL_DAEMON

if [[ ! "$INSTALL_DAEMON" =~ ^[Nn]$ ]]; then
    log "Running OpenClaw onboarding with daemon installation..."
    
    if [[ "$INSTALL_METHOD" == "3" ]]; then
        openclaw onboard --install-daemon
    else
        cd "$OPENCLAW_DIR"
        $PKG_MANAGER run openclaw onboard --install-daemon
        cd "$PROJECT_ROOT"
    fi
    
    log "✅ OpenClaw daemon installed"
fi

# Create default configuration if not exists
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [[ ! -f "$OPENCLAW_CONFIG" ]]; then
    log "Creating default OpenClaw configuration..."
    mkdir -p "$HOME/.openclaw"
    cat > "$OPENCLAW_CONFIG" << 'EOF'
{
  "agent": {
    "model": "anthropic/claude-opus-4-5"
  },
  "gateway": {
    "port": 18789,
    "bind": "loopback"
  },
  "channels": {
    "whatsapp": {
      "enabled": false
    },
    "telegram": {
      "enabled": false
    },
    "discord": {
      "enabled": false
    }
  }
}
EOF
    log "✅ Default configuration created at $OPENCLAW_CONFIG"
else
    log "OpenClaw configuration already exists at $OPENCLAW_CONFIG"
fi

# Summary
echo ""
echo "🦞 ============================================="
echo "   INSTALLATION COMPLETE!"
echo "============================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Configure your AI provider:"
echo "     - Set ANTHROPIC_API_KEY or"
echo "     - Run 'openclaw auth' to use OAuth"
echo ""
echo "  2. Enable channels in ~/.openclaw/openclaw.json"
echo ""
echo "  3. Start the gateway:"
if [[ "$INSTALL_METHOD" == "3" ]]; then
    echo "     openclaw gateway --port 18789 --verbose"
else
    echo "     cd openclaw-gateway && pnpm openclaw gateway --port 18789 --verbose"
fi
echo ""
echo "  4. Run diagnostics:"
echo "     openclaw doctor"
echo ""
echo "Documentation: https://docs.openclaw.ai"
echo "Discord: https://discord.gg/clawd"
echo ""
log "Installation log saved to: $LOG_FILE"