#!/usr/bin/env bash
set -euo pipefail

# Setup Meta Ads CLI on Mac Mini (openclaw@100.66.145.48)
# Run this script FROM your local machine — it deploys via SSH/SCP.

REMOTE_HOST="openclaw@100.66.145.48"
REMOTE_DIR="~/meta-ads-cli"
LOCAL_DIR="$(cd "$(dirname "$0")/../03-ACTIVE-PROJECTS/meta-ads-cli" && pwd)"

echo "=== Meta Ads CLI — Mac Mini Deployment ==="
echo "Local:  $LOCAL_DIR"
echo "Remote: $REMOTE_HOST:$REMOTE_DIR"
echo ""

# Step 1: Verify local build
echo "[1/6] Verifying local build..."
if [ ! -f "$LOCAL_DIR/dist/index.js" ]; then
    echo "  Building locally first..."
    cd "$LOCAL_DIR" && npm run build
fi
echo "  ✓ Build verified"

# Step 2: Create remote directory
echo "[2/6] Creating remote directory..."
ssh "$REMOTE_HOST" "mkdir -p $REMOTE_DIR"
echo "  ✓ Directory ready"

# Step 3: Copy project files (exclude node_modules, .git)
echo "[3/6] Copying project files..."
rsync -avz --delete \
    --exclude 'node_modules' \
    --exclude '.git' \
    "$LOCAL_DIR/" "$REMOTE_HOST:$REMOTE_DIR/"
echo "  ✓ Files synced"

# Step 4: Install dependencies and build on remote
echo "[4/6] Installing dependencies on Mac Mini..."
ssh "$REMOTE_HOST" "cd $REMOTE_DIR && npm install && npm run build"
echo "  ✓ Dependencies installed and built"

# Step 5: Create wrapper script in ~/bin/
echo "[5/6] Creating wrapper script..."
ssh "$REMOTE_HOST" 'mkdir -p ~/bin && cat > ~/bin/meta-ads-cli << '\''WRAPPER'\''
#!/usr/bin/env bash
exec /opt/homebrew/bin/node ~/meta-ads-cli/dist/index.js "$@"
WRAPPER
chmod +x ~/bin/meta-ads-cli'
echo "  ✓ Wrapper at ~/bin/meta-ads-cli"

# Step 6: Verify installation
echo "[6/6] Verifying installation..."
VERSION=$(ssh "$REMOTE_HOST" "~/bin/meta-ads-cli --version" 2>&1)
echo "  ✓ meta-ads-cli v$VERSION installed"

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "  1. Configure credentials:"
echo "     ssh $REMOTE_HOST"
echo "     mkdir -p ~/.meta-ads-cli"
echo "     # Add config.json with app_id and app_secret"
echo "     # Or set META_ACCESS_TOKEN in the environment"
echo ""
echo "  2. Update TOOLS.md on Mac Mini:"
echo "     Append meta-ads-cli section to ~/.openclaw/workspace/TOOLS.md"
echo ""
echo "  3. Test:"
echo "     ssh $REMOTE_HOST '~/bin/meta-ads-cli token-status'"
echo "     ssh $REMOTE_HOST '~/bin/meta-ads-cli accounts'"
