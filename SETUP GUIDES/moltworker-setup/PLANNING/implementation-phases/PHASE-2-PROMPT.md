# Phase 2: Configure Cloudflare Access

**Safety Level:** 🟡 Review (configures authentication for admin UI)
**Estimated Tasks:** 4
**Dependencies:** Phase 1 complete

---

## Pre-Execution Safety Check

This phase will:
1. Guide you through enabling Cloudflare Access on your worker
2. Set the CF_ACCESS_TEAM_DOMAIN and CF_ACCESS_AUD secrets
3. Protect the admin UI with identity-based authentication

**Why this matters:** Without Cloudflare Access, your admin UI (`/_admin/`) is unprotected. Anyone with the URL could approve device pairings and control your agent.

Before proceeding, verify:
- [ ] Phase 1 is complete
- [ ] You can access the Cloudflare Zero Trust dashboard

---

## Context Files to Read First

```
READ: PLANNING/PHASE-1-COMPLETE.md (verify Phase 1 done)
```

---

## Tasks

### Task 1: Enable Cloudflare Access on Workers.dev

This is a **manual step** in the Cloudflare dashboard:

1. Go to **Workers & Pages** dashboard
2. Select your worker (it may not exist yet — that's OK, do this after Phase 3 deploy)
3. Go to **Settings** → **Domains & Routes**
4. Find the `workers.dev` row
5. Click **Enable Cloudflare Access**

```bash
echo "=== Manual Step ==="
echo ""
echo "1. Open: https://dash.cloudflare.com"
echo "2. Go to: Workers & Pages → [your worker] → Settings → Domains & Routes"
echo "3. Enable Cloudflare Access on the workers.dev row"
echo ""
echo "If the worker doesn't exist yet, skip to Phase 3 (Deploy) first,"
echo "then come back to this phase."
```

---

### Task 2: Configure Access Application

1. Go to **Zero Trust** → **Access** → **Applications**
2. Find the auto-created application for your worker
3. Add your email address to the allow list
4. Copy the **Application Audience (AUD)** tag

```bash
echo "=== Manual Step ==="
echo ""
echo "1. Open: https://one.dash.cloudflare.com"
echo "2. Go to: Access → Applications"
echo "3. Find your worker application"
echo "4. Add your email to the allow list"
echo "5. Copy the Application Audience (AUD) tag"
echo ""
echo "Your team domain is typically: <team-name>.cloudflareaccess.com"
echo "Find it at: Settings → Custom Pages → Team domain"
```

---

### Task 3: Set Access Secrets

```bash
cd "$MOLTWORKER_DIR"

# Set team domain
echo "Setting CF_ACCESS_TEAM_DOMAIN..."
echo "$CF_ACCESS_TEAM_DOMAIN" | npx wrangler secret put CF_ACCESS_TEAM_DOMAIN
# Example: myteam.cloudflareaccess.com

# Set AUD tag
echo "Setting CF_ACCESS_AUD..."
echo "$CF_ACCESS_AUD" | npx wrangler secret put CF_ACCESS_AUD

echo ""
echo "Cloudflare Access secrets configured."
```

---

### Task 4: Verify Access Configuration

```bash
echo "=== Verification ==="
echo ""
echo "After deploying (Phase 3), test by visiting:"
echo "  https://your-worker.workers.dev/_admin/"
echo ""
echo "You should be redirected to Cloudflare Access login."
echo "After authenticating with your email, you should see the admin UI."
echo ""
echo "If you get a 403 error:"
echo "  - Check your email is in the Access allow list"
echo "  - Verify the AUD tag matches your application"
echo "  - Ensure the team domain is correct"
```

---

## Success Criteria

- [ ] Cloudflare Access enabled on workers.dev route
- [ ] Access application configured with your email
- [ ] CF_ACCESS_TEAM_DOMAIN secret set
- [ ] CF_ACCESS_AUD secret set

---

## Optional: Skip This Phase

If you want to proceed without Cloudflare Access:
- The admin UI will be accessible to anyone with the URL
- Device pairing will still require the gateway token
- You can add Cloudflare Access later

---

## Rollback

```bash
# Remove the Access application from Zero Trust dashboard
# Zero Trust → Access → Applications → Delete
```

---

## Phase 2 Completion

```bash
cat > PLANNING/PHASE-2-COMPLETE.md << 'EOF'
# Phase 2 Complete

**Completed:** $(date)

## Results
- Cloudflare Access configured (or skipped)
- Admin UI will be protected by identity-based auth
EOF
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-3-PROMPT.md and execute"
```
