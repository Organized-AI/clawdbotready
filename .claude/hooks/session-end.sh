#!/usr/bin/env bash
# Project-level hook: Run on session end
# Exports Claude Code sessions to sync location

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_SCRIPT="$PROJECT_ROOT/CLI/claude-auto-sync.sh"

if [[ -x "$SYNC_SCRIPT" ]]; then
    "$SYNC_SCRIPT" end
fi
