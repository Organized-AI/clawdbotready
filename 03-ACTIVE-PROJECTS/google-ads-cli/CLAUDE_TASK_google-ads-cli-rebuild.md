# CLAUDE TASK: Google Ads CLI Rebuild

**Status**: Ready to Execute
**Created**: 2026-02-05
**Estimated Time**: 3.75 hours
**Priority**: High (business-critical bot functionality)

---

## Quick Context

**Problem**: Original google-ads-pro Python skill had 15,923 files in venv, caused OpenClaw file watcher to open 10,267 file descriptors → EMFILE error → Telegram bot broken

**Solution**: Rebuild as lightweight CLI tool using Node.js/TypeScript (1 file in skills/ vs 15,923)

**Plan Location**: `/Users/jordaaan/.claude/plans/luminous-scribbling-piglet.md`

---

## Prerequisites

- [x] M1 Mac Mini accessible via SSH: `openclaw@100.66.145.48`
- [x] Original skill archived at: `~/.openclaw-backup/skills/google-ads-pro/`
- [x] Credentials extracted from archived skill
- [x] OpenClaw Gateway running and stable (56 file descriptors)
- [x] EMFILE issue fixed (LaunchAgent limits increased)

---

## Execution Checklist

### Phase 1: Project Setup (15 min)
- [ ] SSH to M1 Mac Mini
- [ ] Create `~/google-ads-cli` directory
- [ ] Initialize Node.js project (`npm init -y`)
- [ ] Install dependencies:
  - [ ] `google-ads-api` (v18+)
  - [ ] `commander` (CLI parsing)
  - [ ] `dotenv` (config)
  - [ ] TypeScript + tsx (dev)
- [ ] Create directory structure (`src/{commands,lib,types}`)

### Phase 2: Core Implementation (2 hours)
- [ ] Implement `src/index.ts` (CLI entry point with commander)
- [ ] Implement `src/lib/client.ts` (Google Ads API wrapper)
- [ ] Implement `src/commands/list-campaigns.ts`
- [ ] Implement `src/commands/get-cpa-metrics.ts` (replaces Python script)
- [ ] Implement `src/commands/update-budget.ts`
- [ ] Implement `src/commands/generate-report.ts`
- [ ] Implement `src/commands/manage-campaign.ts` (create/pause/enable)
- [ ] Add TypeScript config (`tsconfig.json`)

### Phase 3: Configuration & Installation (30 min)
- [ ] Create `~/.google-ads-cli/` config directory
- [ ] Migrate credentials from archived skill:
  ```bash
  cp ~/.openclaw-backup/skills/google-ads-pro/config/credentials.json ~/.google-ads-cli/config.json
  ```
- [ ] Build TypeScript: `npm run build`
- [ ] Install globally: `npm link`
- [ ] Verify CLI available: `which google-ads-cli`

### Phase 4: OpenClaw Integration (30 min)
- [ ] Create `~/.openclaw/skills/google-ads-pro/skill.md` (thin wrapper)
- [ ] Verify only 1 file in skills directory
- [ ] Check file descriptors: `lsof -p $(pgrep openclaw-gateway) | wc -l`
- [ ] Should still be ~56 (no increase from skill)

### Phase 5: Testing & Verification (30 min)
- [ ] Test CLI standalone:
  ```bash
  google-ads-cli campaigns:list --filter "Blade"
  google-ads-cli metrics:cpa --filter "Blade" --date TODAY
  ```
- [ ] Test multi-account support:
  ```bash
  google-ads-cli campaigns:list --customer-id <other-account>
  ```
- [ ] Test budget update:
  ```bash
  google-ads-cli budget:update --campaign-id 12345 --amount 500
  ```
- [ ] Test OpenClaw integration via Telegram:
  - [ ] Send: "Show me CPA metrics for Blade campaigns today"
  - [ ] Verify Claude executes CLI and returns results
- [ ] Verify file descriptor stability:
  ```bash
  # Before and after using skill
  lsof -p $(pgrep openclaw-gateway) | wc -l
  # Should stay at ~56
  ```
- [ ] Update health monitor script:
  - [ ] Add `check_google_ads_cli()` function
  - [ ] Test health check runs successfully
- [ ] Check for EMFILE errors:
  ```bash
  tail -50 ~/.openclaw/logs/gateway.err.log | grep EMFILE
  # Should be empty
  ```

---

## Commands to Copy-Paste

### SSH to Mac Mini
```bash
ssh openclaw@100.66.145.48
```

### Project Setup
```bash
mkdir -p ~/google-ads-cli
cd ~/google-ads-cli
npm init -y
npm install google-ads-api commander dotenv --save
npm install -D typescript @types/node tsx --save-dev
mkdir -p src/{commands,lib,types} config
```

### After Implementation
```bash
# Build
npm run build

# Install globally
npm link

# Test
google-ads-cli --version
google-ads-cli campaigns:list --filter "Blade"
```

### Migrate Credentials
```bash
mkdir -p ~/.google-ads-cli
cp ~/.openclaw-backup/skills/google-ads-pro/config/credentials.json ~/.google-ads-cli/config.json
```

### Create Skill Wrapper
```bash
mkdir -p ~/.openclaw/skills/google-ads-pro
# Then create skill.md with content from plan
```

### Verify File Descriptors
```bash
# Check current
lsof -p $(pgrep openclaw-gateway) | wc -l

# Should be ~56 (not 10,267 like before)
```

---

## Expected Outcomes

**Before (Python Skill)**:
- Files in skills/: 15,923
- File descriptors: 10,267
- Bot status: Broken (EMFILE errors)

**After (CLI Tool)**:
- Files in skills/: 1 (skill.md)
- File descriptors: ~56 (no change)
- Bot status: ✅ Working
- Features: CPA metrics + budget + reporting + campaigns

---

## Verification Script

```bash
#!/bin/bash
# Run this after implementation

echo "=== Verification Report ==="
echo ""

echo "1. CLI Installed:"
which google-ads-cli && echo "✅ Found" || echo "❌ Not found"

echo ""
echo "2. Files in Skills Directory:"
FILE_COUNT=$(find ~/.openclaw/skills/google-ads-pro -type f 2>/dev/null | wc -l)
echo "$FILE_COUNT files (expected: 1)"
[ "$FILE_COUNT" -eq 1 ] && echo "✅ Pass" || echo "❌ Fail"

echo ""
echo "3. File Descriptors:"
FD_COUNT=$(lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l)
echo "$FD_COUNT FDs (expected: <100)"
[ "$FD_COUNT" -lt 100 ] && echo "✅ Pass" || echo "❌ Fail"

echo ""
echo "4. CLI Test:"
google-ads-cli --version &>/dev/null && echo "✅ CLI responds" || echo "❌ CLI error"

echo ""
echo "5. Config Present:"
[ -f ~/.google-ads-cli/config.json ] && echo "✅ Config found" || echo "❌ Config missing"

echo ""
echo "6. Gateway Running:"
pgrep openclaw-gateway &>/dev/null && echo "✅ Gateway running" || echo "❌ Gateway not running"

echo ""
echo "7. Recent EMFILE Errors:"
EMFILE_COUNT=$(tail -50 ~/.openclaw/logs/gateway.err.log 2>/dev/null | grep -c EMFILE)
echo "$EMFILE_COUNT recent errors (expected: 0)"
[ "$EMFILE_COUNT" -eq 0 ] && echo "✅ No errors" || echo "❌ Has errors"
```

---

## Troubleshooting

### If CLI command not found
```bash
# Re-link
cd ~/google-ads-cli
npm link

# Verify symlink
ls -la /usr/local/bin/google-ads-cli
```

### If auth errors
```bash
# Verify credentials
cat ~/.google-ads-cli/config.json

# Should have:
# - developer_token
# - client_id
# - client_secret
# - refresh_token
# - login_customer_id
```

### If file descriptors spike
```bash
# Check what's using FDs
lsof -p $(pgrep openclaw-gateway) | head -50

# If venv files appear, skill was restored to wrong location
ls -la ~/.openclaw/skills/google-ads-pro/
# Should ONLY see skill.md, NOT venv/
```

### If Telegram bot breaks
```bash
# Check gateway logs
tail -50 ~/.openclaw/logs/gateway.log

# Check for errors
tail -50 ~/.openclaw/logs/gateway.err.log

# Restart gateway if needed
launchctl stop ai.openclaw.gateway
launchctl start ai.openclaw.gateway
```

---

## Rollback Plan

If implementation fails:

1. **Remove CLI tool**:
   ```bash
   npm unlink -g google-ads-cli
   rm -rf ~/google-ads-cli
   ```

2. **Remove skill wrapper**:
   ```bash
   rm -rf ~/.openclaw/skills/google-ads-pro
   ```

3. **Verify gateway still healthy**:
   ```bash
   lsof -p $(pgrep openclaw-gateway) | wc -l
   # Should be ~56
   ```

4. **Alternative**: Use HTTP endpoint instead (see plan for details)

---

## Post-Implementation

After successful implementation:

- [ ] Update `DOCUMENTATION/OPENCLAW-SKILLS-FILE-WATCHER-FIX.md` with CLI solution
- [ ] Archive old Python skill permanently:
  ```bash
  mv ~/.openclaw-backup/skills/google-ads-pro ~/.openclaw-backup/skills/google-ads-pro.OLD-ARCHIVED-2026-02-05
  ```
- [ ] Create README in CLI project:
  ```bash
  cat > ~/google-ads-cli/README.md << 'EOF'
  # Google Ads CLI
  Lightweight CLI for Google Ads API access from OpenClaw Gateway.
  Replaces Python skill that caused EMFILE errors (15,923 files → 1 file).
  See: CLAUDE_TASK_google-ads-cli-rebuild.md for full context.
  EOF
  ```
- [ ] Test thoroughly for 24 hours
- [ ] If stable, commit changes to git

---

## Notes for Tomorrow Morning

**You**: Pick up this task by reading:
1. This file (CLAUDE_TASK_google-ads-cli-rebuild.md)
2. The plan file (luminous-scribbling-piglet.md)
3. Current status: EMFILE fixed, bot working, ready to implement CLI

**Claude**: To resume:
1. Read this task file
2. Read the plan file
3. SSH to M1 Mac Mini
4. Start with Phase 1 (Project Setup)
5. Follow checklist above

**Estimated completion**: 3.75 hours of focused work

**Success criteria**:
- CLI tool working
- 1 file in skills/ (vs 15,923)
- File descriptors stable (~56)
- Telegram bot functional with full Google Ads features

---

## Related Documentation

- [OPENCLAW-EMFILE-TROUBLESHOOTING.md](./DOCUMENTATION/OPENCLAW-EMFILE-TROUBLESHOOTING.md) - File descriptor limits fix
- [OPENCLAW-SKILLS-FILE-WATCHER-FIX.md](./DOCUMENTATION/OPENCLAW-SKILLS-FILE-WATCHER-FIX.md) - Original issue analysis
- [TELEGRAM-CHANNEL-TROUBLESHOOTING.md](./DOCUMENTATION/TELEGRAM-CHANNEL-TROUBLESHOOTING.md) - Bot troubleshooting
- Plan file: `/Users/jordaaan/.claude/plans/luminous-scribbling-piglet.md`

---

**Created**: 2026-02-05 18:00 PST
**Last Updated**: 2026-02-05 18:00 PST
**Status**: Ready to Execute
**Priority**: High
