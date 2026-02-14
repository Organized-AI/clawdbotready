# Phase 4: R2 Persistence and Chat Channels

**Safety Level:** 🟡 Review (sets secrets, enables integrations)
**Estimated Tasks:** 5
**Dependencies:** Phase 3 complete

---

## Pre-Execution Safety Check

This phase will:
1. Configure R2 persistent storage (so data survives restarts)
2. Set up chat channel integrations (Telegram, Discord, Slack)
3. Optionally enable browser automation (CDP)
4. Optionally configure AI Gateway
5. Redeploy with new configuration

Before proceeding, verify:
- [ ] Phase 3 is complete (worker deployed)
- [ ] You have your R2 API token ready (if using persistence)
- [ ] You have your chat bot tokens ready (if connecting channels)

---

## Context Files to Read First

```
READ: PLANNING/PHASE-3-COMPLETE.md
READ: config/settings.env
```

---

## Tasks

### Task 1: Configure R2 Persistent Storage

**Why R2 matters:** Without R2, all conversations, pairings, and settings are lost when the container restarts. With R2, data syncs every 5 minutes and auto-restores on startup.

**Create R2 API Token:**
1. Go to **R2** in Cloudflare Dashboard
2. Click **Manage R2 API Tokens**
3. Create a token with **Object Read & Write** permissions
4. Bucket: `moltbot-data` (auto-created on first deploy)
5. Copy the Access Key ID and Secret Access Key

```bash
cd "$MOLTWORKER_DIR"

# Set R2 credentials
echo "$R2_ACCESS_KEY_ID" | npx wrangler secret put R2_ACCESS_KEY_ID
echo "$R2_SECRET_ACCESS_KEY" | npx wrangler secret put R2_SECRET_ACCESS_KEY
echo "$CF_ACCOUNT_ID" | npx wrangler secret put CF_ACCOUNT_ID

echo "R2 storage configured."
```

**Finding your Account ID:**
Dashboard → 3-dot menu → "Copy Account ID"

---

### Task 2: Configure Telegram (Optional)

1. Message **@BotFather** on Telegram
2. Create a new bot with `/newbot`
3. Copy the bot token

```bash
cd "$MOLTWORKER_DIR"

echo "$TELEGRAM_BOT_TOKEN" | npx wrangler secret put TELEGRAM_BOT_TOKEN

# Optional: set DM policy
# "pairing" = require admin approval (default, more secure)
# "open" = allow all DMs immediately
echo "pairing" | npx wrangler secret put TELEGRAM_DM_POLICY

echo "Telegram configured."
```

---

### Task 3: Configure Discord (Optional)

1. Go to **Discord Developer Portal**
2. Create a new application → Bot
3. Copy the bot token
4. Invite bot to your server with Message Content intent

```bash
cd "$MOLTWORKER_DIR"

echo "$DISCORD_BOT_TOKEN" | npx wrangler secret put DISCORD_BOT_TOKEN
echo "pairing" | npx wrangler secret put DISCORD_DM_POLICY

echo "Discord configured."
```

---

### Task 4: Configure Browser Automation (Optional)

Enables Chrome DevTools Protocol for screenshots and video generation.

```bash
cd "$MOLTWORKER_DIR"

# Generate a CDP secret
CDP_SECRET=$(openssl rand -hex 32)
echo "$CDP_SECRET" | npx wrangler secret put CDP_SECRET

# Set worker URL (needed for CDP to call back)
WORKER_URL=$(cat .worker_url)
echo "$WORKER_URL" | npx wrangler secret put WORKER_URL

echo ""
echo "CDP configured. Test with:"
echo "  curl '${WORKER_URL}/cdp/json/version?secret=${CDP_SECRET}'"
```

---

### Task 5: Redeploy with New Configuration

```bash
cd "$MOLTWORKER_DIR"

echo "Redeploying with new secrets..."
npm run deploy

echo ""
echo "Deployment updated with:"
echo "  R2 Storage: $([ -n "${R2_ACCESS_KEY_ID:-}" ] && echo 'Enabled' || echo 'Disabled')"
echo "  Telegram:   $([ -n "${TELEGRAM_BOT_TOKEN:-}" ] && echo 'Enabled' || echo 'Disabled')"
echo "  Discord:    $([ -n "${DISCORD_BOT_TOKEN:-}" ] && echo 'Enabled' || echo 'Disabled')"
echo "  CDP:        $([ -n "${CDP_SECRET:-}" ] && echo 'Enabled' || echo 'Disabled')"
```

---

## Success Criteria

- [ ] R2 storage configured (or consciously skipped)
- [ ] At least one chat channel configured
- [ ] Worker redeployed with new secrets
- [ ] R2 sync working (check admin UI for backup status)

---

## Rollback

Secrets can be overwritten with new values or removed by redeploying without them. R2 bucket needs manual deletion from the dashboard.

---

## Phase 4 Completion

```bash
cat > PLANNING/PHASE-4-COMPLETE.md << 'EOF'
# Phase 4 Complete

**Completed:** $(date)

## Results
- R2 persistent storage: [Configured/Skipped]
- Telegram: [Configured/Skipped]
- Discord: [Configured/Skipped]
- Slack: [Configured/Skipped]
- Browser (CDP): [Configured/Skipped]
- Worker redeployed with new configuration
EOF
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-5-PROMPT.md and execute"
```
