#!/usr/bin/env bash
set -euo pipefail

# Google Ads API Setup Script for Mac Mini
# Run this script ON THE MAC MINI (100.66.145.48)
# This will configure the Google Ads CLI credentials

echo "╔════════════════════════════════════════════════════════╗"
echo "║   Google Ads API Credentials Setup for Mac Mini       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Create directories
echo "Step 1: Creating directories..."
mkdir -p ~/.google-ads-cli ~/.google-ads
chmod 700 ~/.google-ads-cli ~/.google-ads
echo "✅ Directories created"

# Backup existing configs
if [ -f ~/.google-ads-cli/config.json ]; then
    echo ""
    echo "⚠️  Existing config found - backing up..."
    cp ~/.google-ads-cli/config.json ~/.google-ads-cli/config.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created"
fi

# Create JSON config for CLI
echo ""
echo "Step 2: Creating CLI configuration..."
cat > ~/.google-ads-cli/config.json << EOF
{
  "developer_token": "${GOOGLE_ADS_DEVELOPER_TOKEN:?Set GOOGLE_ADS_DEVELOPER_TOKEN}",
  "client_id": "${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID}",
  "client_secret": "${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET}",
  "refresh_token": "${GOOGLE_ADS_REFRESH_TOKEN:?Set GOOGLE_ADS_REFRESH_TOKEN}",
  "login_customer_id": "${GOOGLE_ADS_LOGIN_CUSTOMER_ID:-4761832056}"
}
EOF
chmod 600 ~/.google-ads-cli/config.json
echo "✅ CLI config created: ~/.google-ads-cli/config.json"

# Create YAML config for standard Google Ads library
echo ""
echo "Step 3: Creating YAML configuration..."
cat > ~/.google-ads/google-ads.yaml << EOF
# Google Ads API Configuration

developer_token: ${GOOGLE_ADS_DEVELOPER_TOKEN:?Set GOOGLE_ADS_DEVELOPER_TOKEN}
client_id: ${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID}
client_secret: ${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET}
refresh_token: ${GOOGLE_ADS_REFRESH_TOKEN:?Set GOOGLE_ADS_REFRESH_TOKEN}
login_customer_id: ${GOOGLE_ADS_LOGIN_CUSTOMER_ID:-4761832056}
EOF
chmod 600 ~/.google-ads/google-ads.yaml
echo "✅ YAML config created: ~/.google-ads/google-ads.yaml"

# Test the CLI
echo ""
echo "Step 4: Testing Google Ads CLI..."
echo ""

if command -v google-ads-cli &> /dev/null; then
    echo "Testing connection to Google Ads API..."
    echo ""

    if google-ads-cli campaigns --limit 1 2>&1; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║              🎉 SUCCESS! 🎉                            ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "✅ Google Ads API credentials are working!"
        echo "✅ CLI is properly configured"
        echo ""
        echo "You can now use commands like:"
        echo "  • google-ads-cli campaigns"
        echo "  • google-ads-cli cpa"
        echo "  • google-ads-cli report"
        echo ""
    else
        echo ""
        echo "⚠️  CLI test had errors (see above)"
        echo ""
        echo "Common issues:"
        echo "  1. Developer token not approved yet (check Google Ads API Center)"
        echo "  2. Google Ads API not enabled in Google Cloud Console"
        echo "  3. Refresh token expired (regenerate OAuth)"
        echo ""
        echo "The credentials are installed, but may need troubleshooting."
        echo ""
    fi
else
    echo "⚠️  google-ads-cli not found in PATH"
    echo ""
    echo "The credentials are installed at:"
    echo "  • ~/.google-ads-cli/config.json"
    echo "  • ~/.google-ads/google-ads.yaml"
    echo ""
    echo "But the CLI tool needs to be installed or added to PATH."
    echo ""
fi

echo "╔════════════════════════════════════════════════════════╗"
echo "║                Setup Complete                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Credentials installed:"
echo "  ✅ ~/.google-ads-cli/config.json (for CLI)"
echo "  ✅ ~/.google-ads/google-ads.yaml (for standard library)"
echo ""
