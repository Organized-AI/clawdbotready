#!/usr/bin/env bash
# mac-mini-power-setup.sh - Configure Mac Mini to stay on indefinitely

set -euo pipefail

echo "====================================="
echo "Mac Mini Power Configuration"
echo "====================================="
echo ""

echo "This script will:"
echo "  1. Prevent system sleep"
echo "  2. Allow display sleep (saves energy)"
echo "  3. Prevent disk sleep"
echo ""
echo "Note: You'll need to enter your password"
echo ""

# Configure power settings
echo "Configuring power settings..."
sudo pmset -a sleep 0 displaysleep 10 disksleep 0

echo ""
echo "✓ Power settings configured!"
echo ""
echo "Current settings:"
pmset -g | grep -E '(sleep|displaysleep|disksleep)'
echo ""
echo "Your Mac Mini will now stay on indefinitely."
