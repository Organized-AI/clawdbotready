#!/usr/bin/env bash
set -euo pipefail

# fix-memory-search — Diagnose and fix OpenAI API key for memory_search
# Checks the gateway config for OPENAI_API_KEY and tests the embeddings endpoint
#
# Usage: fix-memory-search

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "fix-memory-search — Diagnose OpenAI API key for memory_search"
    echo ""
    echo "Usage: fix-memory-search"
    echo ""
    echo "Checks:"
    echo "  1. OPENAI_API_KEY exists in gateway config"
    echo "  2. Key is valid (tests embeddings endpoint)"
    echo "  3. Reports status and fix instructions if broken"
    exit 0
fi

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
echo "🔍 Memory Search Diagnostics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Check if config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "✗ Config file not found: $CONFIG_FILE"
    exit 1
fi
echo "✓ Config file: $CONFIG_FILE"

# Step 2: Extract OpenAI API key from config
# The key might be in the config JSON or in environment
API_KEY=""

# Try config JSON — check multiple known paths where OpenClaw stores the key
if command -v jq &>/dev/null; then
    API_KEY=$(jq -r '
        .openai.apiKey //
        .openaiApiKey //
        .integrations.openai.apiKey //
        .skills.entries["openai-image-gen"].apiKey //
        .skills.entries["openai-whisper-api"].apiKey //
        empty
    ' "$CONFIG_FILE" 2>/dev/null || true)
fi

# Fall back to environment
if [[ -z "$API_KEY" ]]; then
    API_KEY="${OPENAI_API_KEY:-}"
fi

if [[ -z "$API_KEY" ]]; then
    echo "✗ OPENAI_API_KEY not found"
    echo ""
    echo "  The key is not set in $CONFIG_FILE or environment."
    echo ""
    echo "  To fix:"
    echo "  1. Get an API key from https://platform.openai.com/api-keys"
    echo "  2. Add to config: jq '.openai.apiKey = \"sk-...\"' $CONFIG_FILE > /tmp/oc.json && mv /tmp/oc.json $CONFIG_FILE"
    echo "  3. Or set env: export OPENAI_API_KEY=sk-..."
    echo "  4. Restart gateway: kill -USR1 \$(pgrep -f openclaw)"
    exit 1
fi

# Mask key for display
KEY_PREVIEW="${API_KEY:0:8}...${API_KEY: -4}"
echo "✓ API key found: $KEY_PREVIEW"

# Step 3: Test the embeddings endpoint
echo ""
echo "Testing embeddings endpoint..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST https://api.openai.com/v1/embeddings \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"input": "test", "model": "text-embedding-3-small"}' \
    2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✓ Embeddings endpoint working (HTTP 200)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Memory search should be functional"
elif [[ "$HTTP_CODE" == "401" ]]; then
    echo "✗ API key is INVALID or EXPIRED (HTTP 401)"
    echo ""
    echo "  Error: $(echo "$BODY" | jq -r '.error.message // "unauthorized"' 2>/dev/null || echo "unauthorized")"
    echo ""
    echo "  To fix:"
    echo "  1. Generate a new key at https://platform.openai.com/api-keys"
    echo "  2. Update config with the new key"
    echo "  3. Restart gateway"
elif [[ "$HTTP_CODE" == "429" ]]; then
    echo "⚠ Rate limited (HTTP 429) — key is valid but quota exceeded"
    echo "  Check your OpenAI billing at https://platform.openai.com/settings/organization/billing"
elif [[ "$HTTP_CODE" == "000" ]]; then
    echo "✗ Could not reach OpenAI API (network error)"
    echo "  Check internet connectivity"
else
    echo "✗ Unexpected response (HTTP $HTTP_CODE)"
    echo "  Body: $(echo "$BODY" | head -c 200)"
fi

echo ""
echo "Generated: $(date '+%Y-%m-%d %H:%M %Z')"
