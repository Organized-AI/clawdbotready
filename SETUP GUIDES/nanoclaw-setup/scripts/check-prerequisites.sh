#!/usr/bin/env bash
# NanoClaw Prerequisites Check
# Validates all requirements before setup
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "╔══════════════════════════════════════════════╗"
echo "║      NanoClaw Prerequisites Check            ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# --- Platform ---
echo "Platform:"
if [[ "$(uname)" == "Darwin" ]]; then
    pass "macOS detected"
else
    fail "macOS required (found: $(uname))"
fi

if [[ "$(uname -m)" == "arm64" ]]; then
    pass "Apple Silicon (arm64)"
else
    fail "Apple Silicon required (found: $(uname -m))"
fi

MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [[ "$MAJOR" -ge 15 ]]; then
    pass "macOS $MACOS_VERSION (Sequoia or later)"
elif [[ "$MAJOR" -ge 14 ]]; then
    warn "macOS $MACOS_VERSION — Sequoia+ recommended for Apple Container"
else
    fail "macOS $MACOS_VERSION — requires 14.0+ (Sonoma minimum)"
fi

echo ""

# --- Disk Space ---
echo "Disk Space:"
AVAILABLE_GB=$(df -g / | tail -1 | awk '{print $4}')
if [[ "$AVAILABLE_GB" -ge 15 ]]; then
    pass "${AVAILABLE_GB}GB available (15GB required)"
elif [[ "$AVAILABLE_GB" -ge 10 ]]; then
    warn "${AVAILABLE_GB}GB available — 15GB recommended, may be tight"
else
    fail "${AVAILABLE_GB}GB available — need at least 15GB"
fi

echo ""

# --- Software ---
echo "Software:"

# Node.js
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [[ "$NODE_MAJOR" -ge 20 ]]; then
        pass "Node.js v${NODE_VER} (20+ required)"
    else
        fail "Node.js v${NODE_VER} — version 20+ required (brew install node)"
    fi
else
    fail "Node.js not found (brew install node)"
fi

# npm
if command -v npm &>/dev/null; then
    pass "npm $(npm --version)"
else
    fail "npm not found (comes with Node.js)"
fi

# Git
if command -v git &>/dev/null; then
    pass "Git $(git --version | awk '{print $3}')"
else
    fail "Git not found (xcode-select --install)"
fi

# Claude Code
if command -v claude &>/dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null || echo "installed")
    pass "Claude Code ($CLAUDE_VER)"
else
    fail "Claude Code not found (install from claude.ai/download)"
fi

# Apple Container
if command -v container &>/dev/null; then
    CONTAINER_VER=$(container --version 2>/dev/null || echo "installed")
    pass "Apple Container ($CONTAINER_VER)"
else
    # Check for Docker as fallback
    if command -v docker &>/dev/null; then
        warn "Apple Container not found, but Docker is available (use /convert-to-docker skill)"
    else
        fail "Apple Container not found (brew install container)"
    fi
fi

echo ""

# --- Network ---
echo "Network:"
if curl -s --connect-timeout 5 https://api.anthropic.com >/dev/null 2>&1; then
    pass "Anthropic API reachable"
else
    warn "Cannot reach api.anthropic.com — check internet connection"
fi

if curl -s --connect-timeout 5 https://web.whatsapp.com >/dev/null 2>&1; then
    pass "WhatsApp Web reachable"
else
    warn "Cannot reach web.whatsapp.com — required for WhatsApp connection"
fi

echo ""

# --- Summary ---
echo "════════════════════════════════════════════════"
echo "  Results: $PASS passed, $WARN warnings, $FAIL failed"
echo "════════════════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
    echo ""
    echo "  Fix the failures above before proceeding with setup."
    exit 1
elif [[ "$WARN" -gt 0 ]]; then
    echo ""
    echo "  Warnings present — setup may work but review the items above."
    exit 0
else
    echo ""
    echo "  All prerequisites met! Ready to install NanoClaw."
    exit 0
fi
