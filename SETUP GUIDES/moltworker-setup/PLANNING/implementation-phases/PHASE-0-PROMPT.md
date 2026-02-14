# Phase 0: Prerequisites Verification

**Safety Level:** 🟢 Safe (read-only operations only)
**Estimated Tasks:** 4
**Dependencies:** None

---

## Pre-Execution Safety Check

Before running this phase, verify:

- [ ] You have a Cloudflare account
- [ ] You have a payment method on file (Workers Paid plan: $5/month)
- [ ] You have an Anthropic API key (or plan to use AI Gateway)

**This phase only READS information. It does NOT modify anything.**

---

## Context Files to Read First

```
READ: config/settings.env
READ: README.md
```

---

## Tasks

### Task 1: Verify Node.js and npm

```bash
echo "=== Node.js ==="
node --version
# Required: v18+

echo ""
echo "=== npm ==="
npm --version

echo ""
echo "=== Git ==="
git --version
```

**Expected Output:**
- Node.js v18 or later
- npm 9+ (any recent version)
- Git installed

---

### Task 2: Check Wrangler CLI

```bash
echo "=== Wrangler ==="
npx wrangler --version 2>/dev/null || echo "Not installed (will use npx)"

echo ""
echo "=== Cloudflare Auth ==="
npx wrangler whoami 2>/dev/null || echo "Not logged in - will need to run: npx wrangler login"
```

**Expected:** Wrangler available (via npx is fine). Auth status shown.

---

### Task 3: Verify Configuration File

```bash
echo "=== Configuration ==="
if [[ -f config/settings.env ]]; then
    echo "settings.env found"
    echo ""
    # Show which required values are set (without showing actual secrets)
    grep -E "^(ANTHROPIC_API_KEY|MOLTBOT_GATEWAY_TOKEN|CF_ACCESS)" config/settings.env | \
        sed 's/=.*/=<check>/'
else
    echo "ERROR: config/settings.env not found"
    echo "Copy from the template and fill in your values"
fi
```

**Expected:** Config file exists with at least ANTHROPIC_API_KEY populated.

---

### Task 4: Verify Cloudflare Account

```bash
echo "=== Cloudflare Account Check ==="
echo ""
echo "Manual verification needed:"
echo "  1. Log into https://dash.cloudflare.com"
echo "  2. Confirm Workers & Pages is visible in sidebar"
echo "  3. Confirm you have a Workers Paid plan ($5/month)"
echo "     Go to: Workers & Pages → Plans"
echo "  4. Confirm Containers is enabled"
echo "     Go to: Containers dashboard"
echo ""
echo "If not yet set up:"
echo "  - Workers Paid plan: Workers & Pages → Plans → Subscribe"
echo "  - Containers: Visit the Containers dashboard to enable"
```

---

## Success Criteria

- [ ] Node.js 18+ installed
- [ ] npm available
- [ ] Git available
- [ ] Wrangler accessible (via npx)
- [ ] config/settings.env exists with ANTHROPIC_API_KEY
- [ ] Cloudflare account with Workers Paid plan confirmed

---

## Phase 0 Completion

```bash
cat > PLANNING/PHASE-0-COMPLETE.md << 'EOF'
# Phase 0 Complete

**Completed:** $(date)

## Results
- Node.js version verified
- npm available
- Git available
- Wrangler accessible
- Configuration file present
- Cloudflare account confirmed
EOF
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-1-PROMPT.md and execute"
```
