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
# Remote Client Access (Tailscale)
# ─────────────────────────────────────────────────────────────

# Quick check if client's Mac Mini is online
client-ping hostname="100.66.145.48":
    @echo "Checking if {{hostname}} is reachable..."
    @tailscale ping {{hostname}} -c 3 2>/dev/null || ping -c 3 {{hostname}} 2>/dev/null || echo "❌ Device unreachable"

# SSH into client's Mac Mini via Tailscale
client-ssh hostname="100.66.145.48":
    @echo "Connecting to {{hostname}} via Tailscale..."
    ssh admin@{{hostname}}

# Quick health check on client's Mac Mini
client-health hostname="100.66.145.48":
    @echo "Running health check on {{hostname}}..."
    @ssh admin@{{hostname}} 'bash -s' << 'HEALTHEOF'
echo "════════════════════════════════════════════════════════════"
echo "OpenClaw Health Check - $(date)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 System Resources:"
echo "-----------------------------------------------------------"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo "Memory: $(vm_stat | grep 'Pages free' | awk '{print $3}' | sed 's/\.//')pages free"
echo "Disk Space:"
df -h / | tail -1 | awk '{print "  Root: " $4 " available (" $5 " used)"}'
echo ""
echo "🔌 OpenClaw Gateway Status:"
echo "-----------------------------------------------------------"
if pgrep -f "openclaw" > /dev/null; then
    echo "✅ OpenClaw process running (PID: $(pgrep -f openclaw))"
    echo "Memory usage: $(ps -o rss= -p $(pgrep -f openclaw) | awk '{print $1/1024 " MB"}')"
else
    echo "❌ OpenClaw process NOT running"
fi
echo ""
echo "🎯 Google Ads CLI Status:"
echo "-----------------------------------------------------------"
if command -v google-ads > /dev/null 2>&1; then
    echo "✅ Google Ads CLI installed: $(which google-ads)"
    echo "Version: $(google-ads --version 2>/dev/null || echo 'Unknown')"
    if [ -f "$HOME/.google-ads/config.yaml" ] || [ -f "$HOME/google-ads.yaml" ]; then
        echo "✅ Configuration file found"
        if google-ads accounts list > /dev/null 2>&1; then
            echo "✅ API connection successful"
            echo "Accounts: $(google-ads accounts list 2>/dev/null | wc -l) accessible"
        else
            echo "⚠️  API connection failed - check credentials"
        fi
    else
        echo "⚠️  Configuration file not found"
    fi
else
    echo "❌ Google Ads CLI not installed"
fi
echo ""
echo "🌐 Network Status:"
echo "-----------------------------------------------------------"
echo "Tailscale: $(tailscale status --self 2>/dev/null | head -1 || echo 'Not available')"
echo ""
echo "📝 Recent Logs (last 10 lines):"
echo "-----------------------------------------------------------"
if [ -d "$HOME/.openclaw/logs" ]; then
    tail -10 "$HOME/.openclaw/logs"/*.log 2>/dev/null || echo "No logs found"
else
    echo "Log directory not found"
fi
echo ""
echo "════════════════════════════════════════════════════════════"
HEALTHEOF

# Full diagnostic on client's Mac Mini (more detailed)
client-diagnostic hostname="100.66.145.48":
    @echo "Running full diagnostic on {{hostname}}..."
    @ssh admin@{{hostname}} 'bash -s' << 'DIAGEOF'
echo "════════════════════════════════════════════════════════════"
echo "Full OpenClaw Diagnostic - $(date)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🖥️  System Information:"
echo "-----------------------------------------------------------"
sw_vers
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo ""
echo "📊 Resource Usage:"
echo "-----------------------------------------------------------"
top -l 1 | head -10
echo ""
echo "💾 Disk Usage:"
echo "-----------------------------------------------------------"
df -h
echo ""
echo "🔌 OpenClaw Processes:"
echo "-----------------------------------------------------------"
ps aux | grep -i openclaw | grep -v grep || echo "No OpenClaw processes found"
echo ""
echo "🌐 Network & Tailscale:"
echo "-----------------------------------------------------------"
tailscale status 2>/dev/null || echo "Tailscale not available"
echo ""
echo "🔥 Firewall Status:"
echo "-----------------------------------------------------------"
sudo pfctl -s info 2>/dev/null || echo "Cannot check firewall (needs sudo)"
echo ""
echo "📋 LaunchAgents (Autostart):"
echo "-----------------------------------------------------------"
ls -la ~/Library/LaunchAgents/*openclaw* 2>/dev/null || echo "No OpenClaw LaunchAgents found"
echo ""
echo "════════════════════════════════════════════════════════════"
DIAGEOF

# Quick check: Device online + Google Ads CLI status
client-quick-check hostname="100.66.145.48":
    @echo "═══════════════════════════════════════════════════════"
    @echo "Quick Check: {{hostname}}"
    @echo "═══════════════════════════════════════════════════════"
    @echo ""
    @echo "🌐 Device Reachability:"
    @tailscale ping {{hostname}} -c 2 2>/dev/null && echo "✅ Device is ONLINE" || echo "❌ Device is OFFLINE"
    @echo ""
    @echo "Checking OpenClaw & Google Ads CLI..."
    @ssh admin@{{hostname}} 'bash -s' << 'QUICKEOF'
echo ""
echo "🔌 OpenClaw Status:"
if pgrep -f "openclaw" > /dev/null; then
    echo "  ✅ Running (PID: $(pgrep -f openclaw))"
else
    echo "  ❌ NOT running"
fi
echo ""
echo "🎯 Google Ads CLI Status:"
if command -v google-ads > /dev/null 2>&1; then
    echo "  ✅ Installed: $(which google-ads)"
    if [ -f "$HOME/.google-ads/config.yaml" ] || [ -f "$HOME/google-ads.yaml" ]; then
        echo "  ✅ Config found"
        if timeout 5 google-ads accounts list > /dev/null 2>&1; then
            echo "  ✅ API Connected - $(google-ads accounts list 2>/dev/null | wc -l | xargs) accounts"
        else
            echo "  ⚠️  API connection FAILED"
        fi
    else
        echo "  ⚠️  Config NOT found"
    fi
else
    echo "  ❌ NOT installed"
fi
QUICKEOF
    @echo ""
    @echo "═══════════════════════════════════════════════════════"

# Restart OpenClaw on client's Mac Mini
client-restart hostname="100.66.145.48":
    @echo "⚠️  Restarting OpenClaw on {{hostname}}..."
    @ssh admin@{{hostname}} 'pkill -f openclaw && sleep 2 && cd ~/.openclaw && ./start.sh'
    @echo "✅ Restart command sent. Run 'just client-health {{hostname}}' to verify."

# Fix Google Ads CLI configuration on client's Mac Mini
client-fix-google-ads hostname="100.66.145.48":
    @echo "🔧 Diagnosing Google Ads CLI on {{hostname}}..."
    @ssh admin@{{hostname}} 'bash -s' << 'FIXEOF'
echo "════════════════════════════════════════════════════════════"
echo "Google Ads CLI Diagnostic & Fix"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣ Installation Check:"
if command -v google-ads > /dev/null 2>&1; then
    echo "✅ google-ads binary: $(which google-ads)"
    echo "Version: $(google-ads --version 2>&1)"
else
    echo "❌ google-ads not found in PATH"
    echo "Searching for installation..."
    find ~ -name "google-ads" -type f 2>/dev/null | head -5
fi
echo ""
echo "2️⃣ Configuration Files:"
for config in "$HOME/.google-ads/config.yaml" "$HOME/google-ads.yaml" "$HOME/.config/google-ads/config.yaml"; do
    if [ -f "$config" ]; then
        echo "✅ Found: $config"
        echo "   Size: $(ls -lh "$config" | awk '{print $5}')"
        echo "   Modified: $(stat -f "%Sm" "$config")"
    fi
done
if ! [ -f "$HOME/.google-ads/config.yaml" ] && ! [ -f "$HOME/google-ads.yaml" ]; then
    echo "⚠️  No config files found. Expected locations:"
    echo "   - $HOME/.google-ads/config.yaml"
    echo "   - $HOME/google-ads.yaml"
fi
echo ""
echo "3️⃣ Credentials & Authentication:"
if [ -f "$HOME/.google-ads/config.yaml" ]; then
    echo "Checking config structure..."
    if grep -q "developer_token" "$HOME/.google-ads/config.yaml" 2>/dev/null; then
        echo "✅ developer_token present"
    else
        echo "❌ developer_token missing"
    fi
    if grep -q "client_id" "$HOME/.google-ads/config.yaml" 2>/dev/null; then
        echo "✅ client_id present"
    else
        echo "❌ client_id missing"
    fi
    if grep -q "client_secret" "$HOME/.google-ads/config.yaml" 2>/dev/null; then
        echo "✅ client_secret present"
    else
        echo "❌ client_secret missing"
    fi
    if grep -q "refresh_token" "$HOME/.google-ads/config.yaml" 2>/dev/null; then
        echo "✅ refresh_token present"
    else
        echo "❌ refresh_token missing"
    fi
fi
echo ""
echo "4️⃣ API Connection Test:"
if timeout 10 google-ads accounts list 2>&1; then
    echo "✅ API test successful"
else
    echo "❌ API test failed. Error details above."
fi
echo ""
echo "5️⃣ Environment Variables:"
env | grep -i google || echo "No Google-related env vars set"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "💡 Next Steps:"
echo "   1. If CLI not installed: Run installation script"
echo "   2. If config missing: Copy config.yaml to ~/.google-ads/"
echo "   3. If credentials invalid: Regenerate refresh_token"
echo "   4. If API fails: Check network/firewall settings"
echo ""
FIXEOF

# ─────────────────────────────────────────────────────────────
# Gateway Log Analysis
# ─────────────────────────────────────────────────────────────

# Pull gateway logs + sessions from client Mac Mini
log-pull hostname="100.66.145.48":
    ./scripts/pull-gateway-logs.sh {{hostname}}

# Analyze pulled logs and generate usage report
log-analyze:
    npx tsx scripts/analyze-gateway-usage.ts --raw-dir ".analysis/raw/latest"

# Full pipeline: pull fresh logs + analyze + report
log-report hostname="100.66.145.48":
    ./scripts/pull-gateway-logs.sh {{hostname}} && npx tsx scripts/analyze-gateway-usage.ts --raw-dir ".analysis/raw/latest"

# View latest analysis report
log-view:
    @cat .analysis/reports/latest-report.md 2>/dev/null || echo "No report found. Run: just log-report"

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
