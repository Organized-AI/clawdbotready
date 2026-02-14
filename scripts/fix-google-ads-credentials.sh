#!/usr/bin/env bash
set -euo pipefail

# Interactive script to fix Google Ads credentials
# Run this AFTER diagnose-google-ads.sh identifies the issue

echo "=== Google Ads Credentials Setup ==="
echo ""
echo "This script will help you set up Google Ads API credentials."
echo ""

# Create .google-ads directory if it doesn't exist
if [ ! -d "$HOME/.google-ads" ]; then
    echo "Creating $HOME/.google-ads directory..."
    mkdir -p "$HOME/.google-ads"
    chmod 700 "$HOME/.google-ads"
    echo "✅ Directory created"
fi

# Check if credentials file already exists
CREDS_FILE="$HOME/.google-ads/google-ads.yaml"
if [ -f "$CREDS_FILE" ]; then
    echo "⚠️  Credentials file already exists: $CREDS_FILE"
    read -p "Do you want to backup and recreate it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$CREDS_FILE" "$CREDS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ Backed up existing file"
    else
        echo "❌ Aborted. Please manually edit: $CREDS_FILE"
        exit 1
    fi
fi

echo ""
echo "=== Required Information ==="
echo ""
echo "You need the following from Google Cloud Console:"
echo "1. Developer Token (from Google Ads API)"
echo "2. OAuth Client ID"
echo "3. OAuth Client Secret"
echo "4. OAuth Refresh Token"
echo "5. Login Customer ID (Google Ads account ID)"
echo ""
echo "If you don't have these, visit:"
echo "  - Developer Token: https://ads.google.com/aw/apicenter"
echo "  - OAuth Credentials: https://console.cloud.google.com/apis/credentials"
echo ""

read -p "Do you have all required credentials? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please gather credentials first, then run this script again."
    exit 1
fi

# Collect credentials
echo ""
echo "=== Enter Credentials ==="
echo ""

read -p "Developer Token: " DEV_TOKEN
read -p "OAuth Client ID: " CLIENT_ID
read -p "OAuth Client Secret: " CLIENT_SECRET
read -p "OAuth Refresh Token: " REFRESH_TOKEN
read -p "Login Customer ID (without dashes): " CUSTOMER_ID

# Validate inputs
if [ -z "$DEV_TOKEN" ] || [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$REFRESH_TOKEN" ] || [ -z "$CUSTOMER_ID" ]; then
    echo "❌ Error: All fields are required"
    exit 1
fi

# Create credentials file
cat > "$CREDS_FILE" << EOF
# Google Ads API Configuration
# Generated: $(date)

developer_token: $DEV_TOKEN

client_id: $CLIENT_ID
client_secret: $CLIENT_SECRET
refresh_token: $REFRESH_TOKEN

login_customer_id: $CUSTOMER_ID

# Optional: Uncomment to enable logging
# logging:
#   version: 1
#   disable_existing_loggers: False
#   formatters:
#     default_fmt:
#       format: '[%(asctime)s - %(levelname)s] %(message).5000s'
#       datefmt: '%Y-%m-%d %H:%M:%S'
#   handlers:
#     default_handler:
#       class: logging.StreamHandler
#       formatter: default_fmt
#   loggers:
#     "":
#       handlers: [default_handler]
#       level: INFO
EOF

# Set proper permissions
chmod 600 "$CREDS_FILE"

echo ""
echo "✅ Credentials file created: $CREDS_FILE"
echo ""
echo "=== Testing Connection ==="

# Test if Python google-ads library is available
if command -v python3 &> /dev/null && python3 -c "import google.ads.googleads" 2>/dev/null; then
    echo "Running connection test..."

    # Create a simple test script
    cat > /tmp/test_google_ads.py << 'PYTHON_EOF'
from google.ads.googleads.client import GoogleAdsClient
import sys

try:
    client = GoogleAdsClient.load_from_storage()
    customer_service = client.get_service("CustomerService")
    customer_id = client.login_customer_id

    # Try to get customer info
    customer_resource_name = customer_service.customer_path(customer_id)
    print(f"✅ Successfully connected to customer: {customer_id}")
    print(f"✅ Credentials are valid!")
    sys.exit(0)
except Exception as e:
    print(f"❌ Connection test failed: {e}")
    sys.exit(1)
PYTHON_EOF

    if python3 /tmp/test_google_ads.py; then
        echo "✅ Google Ads API connection successful!"
    else
        echo "⚠️  Connection test failed. Please verify credentials."
        echo "Common issues:"
        echo "  - Developer Token not approved"
        echo "  - Refresh Token expired (regenerate OAuth)"
        echo "  - Wrong Customer ID"
    fi

    rm /tmp/test_google_ads.py
else
    echo "⚠️  Cannot test connection (google-ads-python not installed)"
    echo "Install with: pip3 install google-ads"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Restart your application/bot"
echo "2. Monitor logs for any API errors"
echo "3. If issues persist, verify credentials in Google Cloud Console"
echo ""
echo "Credentials location: $CREDS_FILE"
