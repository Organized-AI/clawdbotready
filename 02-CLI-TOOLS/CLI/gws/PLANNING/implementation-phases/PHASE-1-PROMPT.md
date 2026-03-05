# Phase 1 — Auth & GCP

## Context
Read CLAUDE.md and PHASE-0-COMPLETE.md first.

## Tasks
1. Run `gws auth setup` interactively — walk through GCP project config
2. Enable APIs: Drive, Gmail, Calendar, Sheets, Admin SDK
3. Run `gws auth login` to complete OAuth
4. Verify with: `gws drive files list --params '{"pageSize":5}'`
5. Verify with: `gws gmail users messages list --params '{"userId":"me","maxResults":3}'`
6. Document full auth flow in DOCUMENTATION/auth-setup.md (step by step, no secrets)
7. Copy gws-config.template.json → gws-config.json (populate non-secret fields)

## Success Criteria
- [ ] gws auth login completes successfully
- [ ] Drive list command returns results
- [ ] Gmail list command returns results
- [ ] DOCUMENTATION/auth-setup.md written
