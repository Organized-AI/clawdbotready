# OpenClaw QMD Memory - Current State

**Last Updated**: 2026-02-09
**Current Phase**: Ready to Execute
**Mode**: Sequential remote execution via SSH

## Status Summary
✅ Research complete — QMD architecture, config, and enablement process fully documented
⏸️ Ready to begin Phase 1 (Prerequisites Check)

## Completed
- [x] QMD memory system researched (source code analysis of openclaw/openclaw)
- [x] Configuration format and defaults documented
- [x] Embedding provider options evaluated (OpenAI, Gemini, Voyage, local)
- [x] Session export pipeline understood (JSONL → markdown → indexed)
- [x] Dual-provider strategy chosen (OpenAI primary + local GGUF fallback)
- [x] Project planning docs created

## In Progress
- [ ] None — waiting to begin execution

## Blockers
- None

## Key Decisions Made

### Decision 1: QMD over Builtin Backend
**Rationale**:
- QMD combines BM25 keyword search + vector embeddings + reranking
- Supports custom document collections (not just memory files)
- Session export pipeline converts JSONL to searchable markdown
- Graceful fallback to builtin if QMD fails — zero risk

### Decision 2: OpenAI Primary + Local GGUF Fallback
**Rationale**:
- OpenAI API key already active on Mac Mini (updated 2026-02-09)
- `text-embedding-3-small` is fast and cheap
- Local GGUF (`embeddinggemma-300M-Q8_0.gguf`, ~600MB) ensures search works if API key expires or network is down
- Both providers tested in production by OpenClaw team (Feb 2026 commits)

### Decision 3: Deny-Default Scope with Direct Chat Allow
**Rationale**:
- Prevents memory injection from group chats or channels
- Only direct (1:1) Telegram messages trigger memory search
- Matches security principle of least privilege

### Decision 4: 30-Day Session Retention
**Rationale**:
- Balances recall depth vs storage growth
- ~36 sessions currently in history — well within limits
- Can increase later if storage proves manageable

### Decision 5: Non-Blocking Boot Sync
**Rationale**:
- `waitForBootSync: false` ensures gateway starts immediately
- QMD indexes in background after boot
- Avoids adding latency to gateway startup

## Open Questions
- None — configuration is well-defined

## Next Actions
1. SSH to Mac Mini, run prerequisites check
2. Install Bun + QMD CLI
3. Configure `~/.openclaw/openclaw.json` with QMD backend
4. Pre-warm the index
5. Restart gateway and verify

## Remote Execution Context
- **Target Machine**: M1 Mac Mini (openclaw@100.66.145.48 via Tailscale)
- **User**: openclaw
- **Gateway Version**: v2026.2.1
- **Gateway Config**: ~/.openclaw/openclaw.json
- **Session Files**: ~/.openclaw/agents/main/sessions/*.jsonl
- **Workspace**: ~/.openclaw/workspace/
- **OpenAI Key**: Active (updated 2026-02-09)
- **Node.js**: /opt/homebrew/bin/node (v25.5.0)
- **Current FD Count**: ~64 (stable)
