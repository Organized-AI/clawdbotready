#!/usr/bin/env bash
# NanoClaw Container Rebuild
# Clean rebuild of the agent container image (purges build cache)
set -euo pipefail

NANOCLAW_ROOT="${NANOCLAW_ROOT:-$HOME/nanoclaw}"

if [[ ! -f "$NANOCLAW_ROOT/container/build.sh" ]]; then
    echo "❌ Cannot find NanoClaw at: $NANOCLAW_ROOT"
    echo "   Set NANOCLAW_ROOT or clone to ~/nanoclaw"
    exit 1
fi

echo "╔══════════════════════════════════════════════╗"
echo "║      NanoClaw Container Rebuild              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

CLEAN="${1:-}"

if command -v container &>/dev/null; then
    # Apple Container
    if [[ "$CLEAN" == "--clean" ]]; then
        echo "→ Purging Apple Container build cache..."
        container builder stop 2>/dev/null || true
        container builder rm 2>/dev/null || true
        container builder start 2>/dev/null || true
        echo "  ✅ Build cache purged"
        echo ""
    fi

    echo "→ Building container image..."
    cd "$NANOCLAW_ROOT"
    ./container/build.sh

    echo ""
    echo "→ Verifying image..."
    if container images 2>/dev/null | grep -q "nanoclaw-agent"; then
        echo "  ✅ nanoclaw-agent image rebuilt successfully"
    else
        echo "  ❌ Image not found after build"
        exit 1
    fi

elif command -v docker &>/dev/null; then
    # Docker
    if [[ "$CLEAN" == "--clean" ]]; then
        echo "→ Removing old image..."
        docker rmi nanoclaw-agent:latest 2>/dev/null || true
        echo "  ✅ Old image removed"
        echo ""
    fi

    echo "→ Building container image with Docker..."
    cd "$NANOCLAW_ROOT/container"
    docker build -t nanoclaw-agent:latest .

    echo ""
    echo "  ✅ nanoclaw-agent image rebuilt successfully"
else
    echo "❌ No container runtime found (need Apple Container or Docker)"
    exit 1
fi

echo ""
echo "→ Testing container..."
echo '{"prompt":"What is 2+2?","groupFolder":"test","chatJid":"test@g.us","isMain":false}' | \
    timeout 120 container run -i --rm nanoclaw-agent:latest 2>/dev/null && \
    echo "  ✅ Container test passed" || \
    echo "  ⚠️  Container test failed — check logs"

echo ""
echo "════════════════════════════════════════════════"
echo "  Container rebuild complete."
echo ""
echo "  Usage: $0           — Normal rebuild"
echo "         $0 --clean   — Purge cache first"
echo "════════════════════════════════════════════════"
