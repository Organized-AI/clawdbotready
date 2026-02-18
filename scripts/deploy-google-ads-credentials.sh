#!/usr/bin/env bash
set -euo pipefail

# Deploy Google Ads credentials to Mac Mini
# Target: openclaw@100.66.145.48 (via Tailscale)

MAC_MINI_IP="100.66.145.48"
MAC_MINI_USER="openclaw"

echo "=== Deploying Google Ads Credentials to Mac Mini ==="
echo ""
echo "Target: ${MAC_MINI_USER}@${MAC_MINI_IP}"
echo ""

# Check if Mac Mini is reachable
echo "Step 1: Testing connection..."
if ping -c 2 "$MAC_MINI_IP" > /dev/null 2>&1; then
    echo "✅ Mac Mini is reachable"
else
    echo "❌ Error: Cannot reach Mac Mini at $MAC_MINI_IP"
    echo "   - Is Tailscale running?"
    echo "   - Is the Mac Mini powered on?"
    exit 1
fi

# Create credentials JSON
echo ""
echo "Step 2: Creating credentials file..."
cat > /tmp/google-ads-config.json << EOF
{
  "developer_token": "${GOOGLE_ADS_DEVELOPER_TOKEN:?Set GOOGLE_ADS_DEVELOPER_TOKEN}",
  "client_id": "${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID}",
  "client_secret": "${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET}",
  "refresh_token": "${GOOGLE_ADS_REFRESH_TOKEN:?Set GOOGLE_ADS_REFRESH_TOKEN}",
  "login_customer_id": "${GOOGLE_ADS_LOGIN_CUSTOMER_ID:-4761832056}"
}
EOF

echo "✅ Created credentials file"

# Also create the YAML format for standard google-ads library
echo ""
echo "Step 3: Creating YAML credentials..."
cat > /tmp/google-ads.yaml << EOF
# Google Ads API Configuration

developer_token: ${GOOGLE_ADS_DEVELOPER_TOKEN:?Set GOOGLE_ADS_DEVELOPER_TOKEN}
client_id: ${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID}
client_secret: ${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET}
refresh_token: ${GOOGLE_ADS_REFRESH_TOKEN:?Set GOOGLE_ADS_REFRESH_TOKEN}
login_customer_id: ${GOOGLE_ADS_LOGIN_CUSTOMER_ID:-4761832056}
EOF

echo "✅ Created YAML credentials"

# Copy credentials to Mac Mini
echo ""
echo "Step 4: Copying credentials to Mac Mini..."
echo ""
echo "This will prompt for your SSH connection (or use your SSH key if configured)"
echo ""

# Create directories on Mac Mini
ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "mkdir -p ~/.google-ads-cli ~/.google-ads && chmod 700 ~/.google-ads-cli ~/.google-ads" || {
    echo "❌ Error: Could not create directories on Mac Mini"
    echo "   - Is SSH access configured?"
    echo "   - Do you have permission to connect?"
    exit 1
}

# Backup existing config if it exists
ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "[ -f ~/.google-ads-cli/config.json ] && cp ~/.google-ads-cli/config.json ~/.google-ads-cli/config.json.backup.$(date +%Y%m%d_%H%M%S) || true"

# Copy JSON config for CLI
scp /tmp/google-ads-config.json "${MAC_MINI_USER}@${MAC_MINI_IP}:~/.google-ads-cli/config.json"
ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "chmod 600 ~/.google-ads-cli/config.json"
echo "✅ Copied JSON config to ~/.google-ads-cli/config.json"

# Copy YAML config for standard library
scp /tmp/google-ads.yaml "${MAC_MINI_USER}@${MAC_MINI_IP}:~/.google-ads/google-ads.yaml"
ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "chmod 600 ~/.google-ads/google-ads.yaml"
echo "✅ Copied YAML config to ~/.google-ads/google-ads.yaml"

# Clean up local temp files
rm /tmp/google-ads-config.json /tmp/google-ads.yaml
echo "✅ Cleaned up temporary files"

echo ""
echo "Step 5: Testing CLI on Mac Mini..."
echo ""

# Test if google-ads-cli is available
if ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "command -v google-ads-cli" > /dev/null 2>&1; then
    echo "✅ google-ads-cli is installed"

    # Test version
    echo ""
    echo "CLI Version:"
    ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "google-ads-cli --version"

    echo ""
    echo "Testing API connection (listing campaigns)..."
    ssh "${MAC_MINI_USER}@${MAC_MINI_IP}" "google-ads-cli list-campaigns --limit 1" || {
        echo ""
        echo "⚠️  API call failed. This could be:"
        echo "   - Developer token not approved yet"
        echo "   - Customer ID incorrect"
        echo "   - Google Ads API access not enabled"
        echo ""
        echo "Check the error message above for details."
    }
else
    echo "⚠️  google-ads-cli not found in PATH"
    echo "   The CLI may need to be installed or linked"
fi

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Credentials deployed to:"
echo "  - ~/.google-ads-cli/config.json (for CLI)"
echo "  - ~/.google-ads/google-ads.yaml (for standard library)"
echo ""
echo "Next steps:"
echo "  1. Test the CLI: ssh ${MAC_MINI_USER}@${MAC_MINI_IP} 'google-ads-cli list-campaigns'"
echo "  2. Check OpenClaw Gateway integration"
echo "  3. Set up monitoring"
echo ""
