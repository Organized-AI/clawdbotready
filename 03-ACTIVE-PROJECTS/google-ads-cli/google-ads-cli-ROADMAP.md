# Google Ads CLI Rebuild - Roadmap

## Milestone 1: CLI Tool Implementation
**Target**: Lightweight Node.js CLI with Google Ads API integration

### Phase 1: Project Setup (15 min)
- SSH to M1 Mac Mini (openclaw@100.66.145.48)
- Initialize Node.js project at ~/google-ads-cli
- Install dependencies (google-ads-api, commander, dotenv, TypeScript)
- Create directory structure

### Phase 2: Core Implementation (2 hours)
- Build CLI entry point with commander
- Implement Google Ads API client wrapper
- Implement 5 core commands:
  - list-campaigns
  - get-cpa-metrics (critical - replaces Python script)
  - update-budget
  - generate-report
  - manage-campaign (create/pause/enable)

### Phase 3: Configuration & Installation (30 min)
- Set up ~/.google-ads-cli/ config directory
- Migrate credentials from archived Python skill
- Build TypeScript and install globally via npm link
- Verify CLI command availability

## Milestone 2: OpenClaw Integration
**Target**: Single-file skill wrapper + stable gateway

### Phase 4: OpenClaw Integration (30 min)
- Create thin skill.md wrapper in ~/.openclaw/skills/google-ads-pro/
- Verify file count (must be exactly 1 file)
- Monitor file descriptors (must stay ~56)

### Phase 5: Testing & Verification (30 min)
- Test CLI standalone (all 5 commands)
- Test multi-account support
- Test OpenClaw integration via Telegram
- Verify file descriptor stability
- Confirm zero EMFILE errors
- Update health monitor script

## Rollback Strategy
If any phase fails:
1. Remove CLI tool (npm unlink, rm -rf ~/google-ads-cli)
2. Remove skill wrapper
3. Verify gateway still healthy (~56 FDs)
4. Fall back to HTTP endpoint alternative (see plan)

## Post-Implementation
- Update OPENCLAW-SKILLS-FILE-WATCHER-FIX.md with solution
- Archive old Python skill permanently
- Create README in CLI project
- Run 24-hour stability test
- Commit changes to git
