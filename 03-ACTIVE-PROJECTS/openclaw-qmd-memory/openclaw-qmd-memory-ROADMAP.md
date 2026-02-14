# OpenClaw QMD Memory Enablement - Roadmap

## Milestone 1: QMD Installation & Configuration
**Target**: QMD CLI installed, memory backend configured, dual embeddings active

### Phase 1: Prerequisites Check (10 min)
- SSH to M1 Mac Mini (`openclaw@100.66.145.48`)
- Verify OpenClaw Gateway version (v2026.2.1)
- Check if Bun runtime is installed
- Verify OpenAI API key is active
- Read current `~/.openclaw/openclaw.json` memory config
- Snapshot FD count: `lsof -p $(pgrep -f openclaw) | wc -l`
- Snapshot gateway health: check logs for errors

### Phase 2: Install QMD CLI (15 min)
- Install Bun if missing: `curl -fsSL https://bun.sh/install | bash`
- Install QMD globally: `bun install -g https://github.com/tobi/qmd`
- Verify: `qmd --version`
- Add to PATH in `~/.zprofile` if needed (for non-interactive shells)
- Verify PATH: `ssh openclaw@100.66.145.48 'which qmd'`

### Phase 3: Configure Memory Backend (15 min)
- Back up config: `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d)`
- Edit `~/.openclaw/openclaw.json`:
  - Set `memory.backend: "qmd"`
  - Enable sessions (30-day retention)
  - Enable default memory file indexing
  - Add custom TOOLS.md collection
  - Set deny-default scope with direct chat allow rule
  - Set 5m update interval, boot sync enabled (non-blocking)
- Configure embedding providers:
  - Primary: OpenAI `text-embedding-3-small`
  - Fallback: local GGUF
- Validate JSON syntax: `cat ~/.openclaw/openclaw.json | python3 -m json.tool`

## Milestone 2: Indexing & Verification
**Target**: All documents indexed, search works via Telegram, no regressions

### Phase 4: Pre-warm Index (10 min)
- Set QMD environment for agent:
  ```
  export XDG_CONFIG_HOME=~/.openclaw/agents/main/qmd/xdg-config
  export XDG_CACHE_HOME=~/.openclaw/agents/main/qmd/xdg-cache
  ```
- Register collections if needed: `qmd collection add`
- Index documents: `qmd update`
- Generate embeddings: `qmd embed`
- Test search: `qmd query "Google Ads" --json`
- Verify session export directory exists

### Phase 5: Restart & Verify (15 min)
- Restart OpenClaw Gateway
- Monitor startup logs for:
  - "QMD backend initialized" (success)
  - "QMD binary not found, falling back to builtin" (failure indicator)
- Check FD count after restart — must be ~64 (not spiking)
- Test via Telegram: ask agent about a past conversation topic
- Verify `memory_search` tool is being invoked in agent logs
- Test custom doc search: ask about something only in TOOLS.md
- Confirm 5-minute sync cycle is running (check logs after 5+ min)

## Milestone 3: Documentation & Hardening
**Target**: Deployment documented, resilience verified

### Phase 6: Documentation & Wrap-up (10 min)
- Verify fallback: temporarily break QMD → confirm builtin takes over
- Document the deployment in project completion files
- Update MEMORY.md with QMD config details
- Update STATE.md with completion status
- Mark project complete

## Rollback Strategy
If QMD causes any issues:
1. `ssh openclaw@100.66.145.48`
2. Edit `~/.openclaw/openclaw.json`: set `memory.backend: "builtin"`
3. Restart gateway
4. Builtin SQLite backend auto-recovers — zero data loss
5. QMD files remain on disk for later retry

## Post-Implementation
- Monitor FD count over 24 hours
- Check QMD disk usage after 1 week
- Evaluate session retention (30 days may need adjustment)
- Consider adding more custom collections based on usage patterns
- Feed results into gateway-insights skill for optimization
