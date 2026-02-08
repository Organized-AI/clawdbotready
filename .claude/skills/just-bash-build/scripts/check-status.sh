#!/usr/bin/env bash
set -euo pipefail

# Quick phase completion scanner for just-bash sandbox build
# Usage: ./check-status.sh [phases_dir]

PHASES_DIR="${1:-PLANNING/features/just-bash/implementation-phases}"

# Phase definitions
declare -a PHASE_NAMES=(
  "Project Setup"
  "Filesystem Tiers"
  "Network Security"
  "AgentSkill Adapter"
  "AI SDK Tool"
  "OpenClaw Plugin"
  "Permissions"
  "Integration Testing"
)

TOTAL=${#PHASE_NAMES[@]}
COMPLETED=0
NEXT_PHASE=-1

echo ""
echo "═══════════════════════════════════════════"
echo "  JUST-BASH SANDBOX — Phase Status"
echo "═══════════════════════════════════════════"
echo ""

for i in $(seq 0 $((TOTAL - 1))); do
  COMPLETE_FILE="${PHASES_DIR}/PHASE-${i}-COMPLETE.md"
  if [[ -f "$COMPLETE_FILE" ]]; then
    echo "  Phase ${i}: ${PHASE_NAMES[$i]}  ✅ Complete"
    COMPLETED=$((COMPLETED + 1))
  else
    if [[ $NEXT_PHASE -eq -1 ]]; then
      NEXT_PHASE=$i
      echo "  Phase ${i}: ${PHASE_NAMES[$i]}  ➡️  Next"
    else
      echo "  Phase ${i}: ${PHASE_NAMES[$i]}  ⬜ Pending"
    fi
  fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "  Progress: ${COMPLETED}/${TOTAL} phases complete"

if [[ $COMPLETED -eq $TOTAL ]]; then
  echo "  Status: 🎉 ALL PHASES COMPLETE"
elif [[ $NEXT_PHASE -ge 0 ]]; then
  echo "  Next: Phase ${NEXT_PHASE} — ${PHASE_NAMES[$NEXT_PHASE]}"
fi

echo "═══════════════════════════════════════════"
echo ""

exit 0
