# Clawdbot Ready - Project Commands
# Run with: just <recipe>

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe - show available commands
default:
    @just --list

# ─────────────────────────────────────────────────────────────
# VM Setup Commands
# ─────────────────────────────────────────────────────────────

# Connect to OpenClaw VM via SSH
vm-connect:
    ./openclaw-vm-setup/scripts/connect.sh

# Check VM status
vm-status:
    ./openclaw-vm-setup/scripts/status.sh

# Create SSH tunnel to Gateway
vm-tunnel:
    ./openclaw-vm-setup/scripts/tunnel.sh

# Restart the VM
vm-restart:
    ./openclaw-vm-setup/scripts/restart-vm.sh

# Emergency stop the VM
vm-stop:
    ./openclaw-vm-setup/scripts/emergency-stop.sh

# ─────────────────────────────────────────────────────────────
# Deployment Scripts
# ─────────────────────────────────────────────────────────────

# Run auto-deploy script
deploy:
    ./scripts/auto-deploy-openclaw.sh

# Deploy with Telegram support
deploy-telegram:
    ./scripts/deploy-openclaw-telegram.sh

# Install OpenClaw
install:
    ./scripts/install-openclaw.sh

# Run health monitor
health:
    ./scripts/openclaw-health-monitor.sh

# Setup autostart
autostart:
    ./scripts/setup-openclaw-autostart.sh

# ─────────────────────────────────────────────────────────────
# Session Management (CLI Tools)
# ─────────────────────────────────────────────────────────────

# List recent sessions
sessions:
    ./CLI/session-tools.sh list

# Search session content
session-search term:
    ./CLI/session-tools.sh search "{{term}}"

# Sync sessions to iCloud
session-sync:
    ./CLI/session-tools.sh sync

# ─────────────────────────────────────────────────────────────
# Development
# ─────────────────────────────────────────────────────────────

# Install dependencies
install-deps:
    pnpm install

# Run shellcheck on all scripts
lint:
    find scripts openclaw-vm-setup/scripts openclaw-native-setup -name "*.sh" -exec shellcheck {} \; 2>/dev/null || echo "Install shellcheck: brew install shellcheck"

# Show project structure
tree:
    tree -L 2 -I 'node_modules|.git|.archive' --dirsfirst

# ─────────────────────────────────────────────────────────────
# Documentation
# ─────────────────────────────────────────────────────────────

# List all documentation files
docs:
    @echo "Documentation files:"
    @ls -1 DOCUMENTATION/

# Open docs folder in Finder
docs-open:
    open DOCUMENTATION/
