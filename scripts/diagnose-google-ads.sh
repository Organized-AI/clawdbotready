#!/usr/bin/env bash
set -euo pipefail

# Diagnostic script for Google Ads API credentials issue
# Run this on the client's Mac Mini after SSH connection

echo "=== Google Ads Credentials Diagnostic ==="
echo ""

# 1. Check for credentials file in common locations
echo "1. Checking for credentials files..."
LOCATIONS=(
    "$HOME/.google-ads/google-ads.yaml"
    "$HOME/.google-ads.yaml"
    "$HOME/google-ads.yaml"
    "/etc/google-ads.yaml"
)

FOUND=false
for loc in "${LOCATIONS[@]}"; do
    if [ -f "$loc" ]; then
        echo "  ✅ Found: $loc"
        FOUND=true
    else
        echo "  ❌ Not found: $loc"
    fi
done

echo ""

# 2. Check if google-ads directory exists
echo "2. Checking .google-ads directory..."
if [ -d "$HOME/.google-ads" ]; then
    echo "  ✅ Directory exists: $HOME/.google-ads"
    ls -la "$HOME/.google-ads/"
else
    echo "  ❌ Directory does not exist: $HOME/.google-ads"
fi

echo ""

# 3. Check for Python environment and packages
echo "3. Checking Python environment..."
if command -v python3 &> /dev/null; then
    echo "  ✅ Python3 found: $(python3 --version)"

    # Check if google-ads is installed
    if python3 -c "import google.ads.googleads" 2>/dev/null; then
        echo "  ✅ google-ads-python package installed"
    else
        echo "  ❌ google-ads-python package NOT installed"
    fi
else
    echo "  ❌ Python3 not found"
fi

echo ""

# 4. Check environment variables
echo "4. Checking environment variables..."
ENV_VARS=(
    "GOOGLE_ADS_CONFIGURATION_FILE_PATH"
    "GOOGLE_ADS_CLIENT_ID"
    "GOOGLE_ADS_CLIENT_SECRET"
    "GOOGLE_ADS_DEVELOPER_TOKEN"
    "GOOGLE_ADS_REFRESH_TOKEN"
)

for var in "${ENV_VARS[@]}"; do
    if [ -n "${!var:-}" ]; then
        echo "  ✅ $var is set"
    else
        echo "  ❌ $var is NOT set"
    fi
done

echo ""

# 5. Check if there's a project directory with configs
echo "5. Checking for project-specific configs..."
if [ -f "$(pwd)/google-ads.yaml" ]; then
    echo "  ✅ Found google-ads.yaml in current directory"
elif [ -f "$(pwd)/config/google-ads.yaml" ]; then
    echo "  ✅ Found google-ads.yaml in config directory"
else
    echo "  ❌ No google-ads.yaml in current or config directory"
fi

echo ""
echo "=== Summary ==="
if [ "$FOUND" = true ]; then
    echo "✅ Credentials file exists - may need validation"
    echo "Next step: Check file contents and API credentials"
else
    echo "❌ No credentials file found"
    echo "Next step: Create credentials file or set up OAuth"
fi

echo ""
echo "=== Recommended Actions ==="
echo "1. If no credentials exist: Run Google Ads API setup wizard"
echo "2. If credentials exist but invalid: Regenerate OAuth refresh token"
echo "3. Check Google Cloud Console for valid OAuth client"
echo "4. Verify Developer Token is approved"
