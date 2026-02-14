# Phase 1: Clone Moltworker and Configure Secrets

**Safety Level:** 🟡 Review (downloads code, installs npm packages, sets secrets)
**Estimated Tasks:** 5
**Dependencies:** Phase 0 complete

---

## Pre-Execution Safety Check

This phase will:
1. Clone the moltworker repository from GitHub
2. Install npm dependencies
3. Log you into Cloudflare (if needed)
4. Generate a gateway access token
5. Set core wrangler secrets (API key, gateway token)

Before proceeding, verify:
- [ ] Phase 0 is complete
- [ ] You have your Anthropic API key ready
- [ ] You understand npm packages will be installed

---

## Context Files to Read First

```
READ: PLANNING/PHASE-0-COMPLETE.md (verify Phase 0 done)
READ: config/settings.env (your configuration)
```

---

## Tasks

### Task 1: Clone Moltworker Repository

```bash
# Default location: ../../../moltworker (sibling to Clawdbot Ready project)
# Change MOLTWORKER_DIR in settings.env to customize

MOLTWORKER_DIR="${MOLTWORKER_DIR:-../../../moltworker}"

if [[ -d "$MOLTWORKER_DIR" ]]; then
    echo "Moltworker already cloned at: $(cd "$MOLTWORKER_DIR" && pwd)"
else
    echo "Cloning moltworker..."
    git clone https://github.com/cloudflare/moltworker.git "$MOLTWORKER_DIR"
    echo "Cloned to: $(cd "$MOLTWORKER_DIR" && pwd)"
fi
```

---

### Task 2: Install Dependencies

```bash
cd "$MOLTWORKER_DIR"
npm install

echo ""
echo "=== Installed packages ==="
ls node_modules/.package-lock.json 2>/dev/null && echo "Dependencies installed" || echo "Check npm install output"
```

---

### Task 3: Authenticate with Cloudflare

```bash
# Check if already logged in
if npx wrangler whoami 2>/dev/null; then
    echo "Already authenticated with Cloudflare"
else
    echo "Opening browser for Cloudflare authentication..."
    npx wrangler login
fi
```

**Note:** This opens a browser window for OAuth. Approve the Wrangler CLI access.

---

### Task 4: Generate Gateway Token

```bash
# Generate a secure random token for Control UI access
GATEWAY_TOKEN=$(openssl rand -hex 32)

echo ""
echo "=== SAVE THIS TOKEN ==="
echo ""
echo "Gateway Token: $GATEWAY_TOKEN"
echo ""
echo "You need this to access the Control UI at:"
echo "  https://your-worker.workers.dev/?token=$GATEWAY_TOKEN"
echo ""
echo "========================"

# Save for reference
echo "$GATEWAY_TOKEN" > .gateway_token
echo "Token saved to .gateway_token"
```

**IMPORTANT:** Save this token somewhere secure. You cannot retrieve it later.

---

### Task 5: Set Core Secrets

```bash
cd "$MOLTWORKER_DIR"

# Set Anthropic API key
echo "Setting ANTHROPIC_API_KEY..."
echo "$ANTHROPIC_API_KEY" | npx wrangler secret put ANTHROPIC_API_KEY

# Set gateway token
echo "Setting MOLTBOT_GATEWAY_TOKEN..."
echo "$GATEWAY_TOKEN" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN

echo ""
echo "Core secrets configured."
```

---

## Success Criteria

- [ ] Moltworker repository cloned
- [ ] npm dependencies installed
- [ ] Authenticated with Cloudflare
- [ ] Gateway token generated and saved
- [ ] ANTHROPIC_API_KEY secret set in wrangler
- [ ] MOLTBOT_GATEWAY_TOKEN secret set in wrangler

---

## Rollback

```bash
# Remove the moltworker clone
rm -rf "$MOLTWORKER_DIR"
```

---

## Phase 1 Completion

```bash
cat > PLANNING/PHASE-1-COMPLETE.md << 'EOF'
# Phase 1 Complete

**Completed:** $(date)

## Results
- Moltworker cloned and dependencies installed
- Cloudflare authentication confirmed
- Gateway token generated and saved
- Core secrets (API key, gateway token) configured
EOF
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-2-PROMPT.md and execute"
```
