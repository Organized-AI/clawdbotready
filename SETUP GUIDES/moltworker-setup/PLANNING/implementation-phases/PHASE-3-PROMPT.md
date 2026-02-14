# Phase 3: Deploy to Cloudflare Workers

**Safety Level:** 🟠 Caution (deploys to production, creates cloud resources)
**Estimated Tasks:** 3
**Dependencies:** Phase 1 complete (Phase 2 recommended but optional)

---

## Pre-Execution Safety Check

This phase will:
1. Deploy the moltworker to Cloudflare Workers
2. Create a Sandbox container (billed at ~$34.50/month if always-on)
3. Make your worker publicly accessible at `*.workers.dev`

**Cost implications:**
- The Sandbox container starts billing immediately
- Set `SANDBOX_SLEEP_AFTER` in settings.env to reduce costs
- You can tear down at any time with `./scripts/teardown.sh`

Before proceeding, verify:
- [ ] Phase 1 is complete (secrets configured)
- [ ] You accept the cost (~$34.50/month always-on, or less with sleep timer)
- [ ] You want to deploy to production

---

## Context Files to Read First

```
READ: PLANNING/PHASE-1-COMPLETE.md
READ: config/settings.env (check SANDBOX_SLEEP_AFTER)
```

---

## Tasks

### Task 1: Deploy

```bash
cd "$MOLTWORKER_DIR"

echo "Deploying to Cloudflare Workers..."
npm run deploy

echo ""
echo "Deployment complete."
echo "Check output above for your worker URL."
```

**Expected Output:**
- Wrangler uploads the worker code
- Creates the Sandbox container
- Returns the worker URL: `https://moltworker.<your-subdomain>.workers.dev`

---

### Task 2: Save Worker URL

```bash
# The URL should appear in the deploy output
# Save it for reference

WORKER_URL="https://moltworker.<your-subdomain>.workers.dev"
echo "$WORKER_URL" > .worker_url
echo "Worker URL saved: $WORKER_URL"
```

---

### Task 3: Basic Health Check

```bash
WORKER_URL=$(cat .worker_url 2>/dev/null || echo "")

if [[ -n "$WORKER_URL" ]]; then
    echo "Checking worker health..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "$WORKER_URL/")
    echo "HTTP response: $HTTP_CODE"

    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]] || [[ "$HTTP_CODE" == "401" ]]; then
        echo "Worker is responding!"
    else
        echo "Worker returned $HTTP_CODE"
        echo "This may be normal - containers take 1-2 minutes for cold start"
        echo "Wait and try again: curl -I $WORKER_URL/"
    fi
else
    echo "Worker URL not found. Check the deploy output."
fi
```

**Note:** First request may take 1-2 minutes (cold start). This is normal.

---

## Success Criteria

- [ ] `npm run deploy` completed without errors
- [ ] Worker URL obtained and saved
- [ ] Health check returns HTTP 200/302/401
- [ ] Worker accessible in browser

---

## Troubleshooting

### `npm run dev` fails with `Unauthorized`
- Enable Containers in the Containers dashboard

### Deploy fails
- Check `npx wrangler whoami` — are you authenticated?
- Check your Workers Paid plan is active

### Health check returns 000 (timeout)
- Container is still starting (cold start: 1-2 min)
- Wait and retry

---

## Rollback

```bash
# Delete the worker and sandbox
npx wrangler delete moltworker --force

# Or use the teardown script
./scripts/teardown.sh
```

---

## Phase 3 Completion

```bash
WORKER_URL=$(cat .worker_url 2>/dev/null || echo "unknown")
cat > PLANNING/PHASE-3-COMPLETE.md << EOF
# Phase 3 Complete

**Completed:** $(date)

## Results
- Worker deployed to: $WORKER_URL
- Sandbox container running
- If Phase 2 was skipped: go back and configure Cloudflare Access now
EOF
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-4-PROMPT.md and execute"
```
