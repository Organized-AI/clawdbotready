#!/usr/bin/env bash
set -euo pipefail

# Script to generate Google Ads API OAuth Refresh Token
# This uses the OAuth2 flow to get a refresh token for Google Ads API access

CLIENT_ID="${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID env var}"
CLIENT_SECRET="${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET env var}"
REDIRECT_URI="urn:ietf:wg:oauth:2.0:oob"  # For desktop/CLI apps
SCOPE="https://www.googleapis.com/auth/adwords"

echo "=== Google Ads API - OAuth Refresh Token Generator ==="
echo ""
echo "This script will help you generate a refresh token for Google Ads API."
echo ""

# Step 1: Generate authorization URL
echo "Step 1: Authorize the application"
echo "=========================================="
echo ""
echo "Open this URL in your browser:"
echo ""
AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPE}&response_type=code&access_type=offline&prompt=consent"
echo "$AUTH_URL"
echo ""
echo "This will:"
echo "1. Ask you to sign in to your Google account"
echo "2. Show permissions that the app needs"
echo "3. Give you an authorization code"
echo ""

read -p "Press Enter after you've completed the authorization in your browser..."

# Step 2: Get authorization code from user
echo ""
echo "Step 2: Enter the authorization code"
echo "=========================================="
echo ""
read -p "Paste the authorization code here: " AUTH_CODE

if [ -z "$AUTH_CODE" ]; then
    echo "❌ Error: No authorization code provided"
    exit 1
fi

# Step 3: Exchange code for tokens
echo ""
echo "Step 3: Exchanging code for tokens..."
echo "=========================================="

RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
    -d "code=${AUTH_CODE}" \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "redirect_uri=${REDIRECT_URI}" \
    -d "grant_type=authorization_code")

# Extract refresh token
REFRESH_TOKEN=$(echo "$RESPONSE" | grep -o '"refresh_token":"[^"]*' | sed 's/"refresh_token":"//')
ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')

if [ -z "$REFRESH_TOKEN" ]; then
    echo "❌ Error: Failed to get refresh token"
    echo "Response from Google:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

echo ""
echo "✅ Success! Tokens generated:"
echo "=========================================="
echo ""
echo "REFRESH_TOKEN=$REFRESH_TOKEN"
echo ""
echo "Access Token (expires in 1 hour): ${ACCESS_TOKEN:0:20}..."
echo ""

# Step 4: Update .claude/settings.env
echo "Step 4: Updating .claude/settings.env..."
SETTINGS_FILE="$(dirname "$0")/../.claude/settings.env"

if [ -f "$SETTINGS_FILE" ]; then
    # Backup first
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

    # Update REFRESH_TOKEN line
    if grep -q "^REFRESH_TOKEN=" "$SETTINGS_FILE"; then
        # Line exists, replace it
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^REFRESH_TOKEN=.*|REFRESH_TOKEN=${REFRESH_TOKEN}|" "$SETTINGS_FILE"
        else
            sed -i "s|^REFRESH_TOKEN=.*|REFRESH_TOKEN=${REFRESH_TOKEN}|" "$SETTINGS_FILE"
        fi
        echo "✅ Updated REFRESH_TOKEN in $SETTINGS_FILE"
    else
        # Line doesn't exist, add it
        echo "REFRESH_TOKEN=${REFRESH_TOKEN}" >> "$SETTINGS_FILE"
        echo "✅ Added REFRESH_TOKEN to $SETTINGS_FILE"
    fi
else
    echo "⚠️  Settings file not found: $SETTINGS_FILE"
    echo "Please manually add this to your settings:"
    echo "REFRESH_TOKEN=${REFRESH_TOKEN}"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your refresh token has been saved. You can now use the Google Ads API."
echo ""
echo "Next steps:"
echo "1. Restart your OpenClaw Gateway"
echo "2. Test the Google Ads API connection"
echo ""
