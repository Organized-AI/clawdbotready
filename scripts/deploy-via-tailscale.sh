#!/usr/bin/env bash
set -euo pipefail

# Deploy Google Ads credentials via Tailscale (no SSH required)
# Uses Tailscale's file transfer feature

MAC_MINI_HOSTNAME="client-sclayton-macmini"  # Adjust if different

echo "=== Deploying Google Ads Credentials via Tailscale ==="
echo ""

# Create credentials files
echo "Creating credentials files..."
mkdir -p /tmp/google-ads-deploy

cat > /tmp/google-ads-deploy/config.json << EOF
{
  "developer_token": "${GOOGLE_ADS_DEVELOPER_TOKEN:?Set GOOGLE_ADS_DEVELOPER_TOKEN}",
  "client_id": "${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID}",
  "client_secret": "${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET}",
  "refresh_token": "${GOOGLE_ADS_REFRESH_TOKEN:?Set GOOGLE_ADS_REFRESH_TOKEN}",
  "login_customer_id": "${GOOGLE_ADS_LOGIN_CUSTOMER_ID:-4761832056}"
}
EOF

cat > /tmp/google-ads-deploy/google-ads.yaml << EOF
developer_token: ${GOOGLE_ADS_DEVELOPER_TOKEN:?Set GOOGLE_ADS_DEVELOPER_TOKEN}
client_id: ${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID}
client_secret: ${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET}
refresh_token: ${GOOGLE_ADS_REFRESH_TOKEN:?Set GOOGLE_ADS_REFRESH_TOKEN}
login_customer_id: ${GOOGLE_ADS_LOGIN_CUSTOMER_ID:-4761832056}
EOF

cat > /tmp/google-ads-deploy/INSTALL_INSTRUCTIONS.txt << 'EOF'
Google Ads API Credentials - Installation Instructions
=======================================================

On the Mac Mini, run these commands:

1. Create directories:
   mkdir -p ~/.google-ads-cli ~/.google-ads
   chmod 700 ~/.google-ads-cli ~/.google-ads

2. Move the credentials:
   mv ~/Downloads/config.json ~/.google-ads-cli/config.json
   mv ~/Downloads/google-ads.yaml ~/.google-ads/google-ads.yaml

3. Set permissions:
   chmod 600 ~/.google-ads-cli/config.json
   chmod 600 ~/.google-ads/google-ads.yaml

4. Test the CLI:
   google-ads-cli list-campaigns --limit 1

If the test works, the credentials are properly installed!
EOF

echo "✅ Created credentials files in /tmp/google-ads-deploy/"
echo ""

# Send files via Tailscale
echo "Sending files to Mac Mini via Tailscale..."
echo ""

if command -v tailscale &> /dev/null; then
    tailscale file cp /tmp/google-ads-deploy/config.json "$MAC_MINI_HOSTNAME:"
    tailscale file cp /tmp/google-ads-deploy/google-ads.yaml "$MAC_MINI_HOSTNAME:"
    tailscale file cp /tmp/google-ads-deploy/INSTALL_INSTRUCTIONS.txt "$MAC_MINI_HOSTNAME:"

    echo ""
    echo "✅ Files sent to Mac Mini!"
    echo ""
    echo "Next steps:"
    echo "1. On the Mac Mini, open ~/Downloads/ (or wherever Tailscale files are received)"
    echo "2. Follow the instructions in INSTALL_INSTRUCTIONS.txt"
    echo ""
else
    echo "❌ Tailscale CLI not found"
    echo ""
    echo "Alternative: Manually copy these files to the Mac Mini:"
    echo ""
    echo "Files created in: /tmp/google-ads-deploy/"
    echo "  - config.json (for CLI)"
    echo "  - google-ads.yaml (for standard library)"
    echo "  - INSTALL_INSTRUCTIONS.txt (setup guide)"
    echo ""
fi

# Clean up
# rm -rf /tmp/google-ads-deploy
echo "Files kept in /tmp/google-ads-deploy/ for manual transfer if needed"
