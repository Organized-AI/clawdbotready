# Phase 3 — AgentSkill Adapter

## Context
Phases 0-2 are complete. Filesystem tiers and network security are working. Now we create the adapter layer that wraps existing OpenClaw AgentSkills to execute through `just-bash` instead of directly on the host OS.

**Key insight:** OpenClaw's 121 AgentSkills execute shell commands for file management, web automation, and data processing. This adapter intercepts those commands and routes them through the sandboxed Bash environment.

## Pre-Requisites
- Phase 2 complete
- Filesystem tiers + network layer working
- Understand OpenClaw skill execution pattern (skill receives a command string, returns stdout/stderr/exitCode)

## Tasks

### Task 1: Create Skill Types (src/sandbox/skill-adapter/types.ts)
```typescript
// SkillTrustLevel: 'untrusted' | 'standard' | 'trusted' | 'admin'
// SkillDefinition: { id, name, trustLevel, requiredTier?, requiredNetworkPresets?, description }
// SkillExecRequest: { skillId, command, args?, env?, workingDir? }
// SkillExecResult: { stdout, stderr, exitCode, duration, sandboxTier, skillId, timestamp }
```
Validate with Zod.

### Task 2: Create Skill Registry (src/sandbox/skill-adapter/skill-registry.ts)
- `SkillRegistry` class that maps skill IDs to their `SkillDefinition`
- Methods: `register(skill)`, `get(skillId)`, `getAll()`, `getTierForSkill(skillId)`
- Pre-register common skill categories with default trust levels:
  - **File read skills** (cat, ls, find, grep) → `untrusted` / InMemory or Overlay
  - **File write skills** (mkdir, cp, mv, tee) → `standard` / Overlay
  - **Data transform skills** (jq, sed, awk, sort) → `untrusted` / InMemory
  - **Web fetch skills** (curl) → `standard` / Overlay + network preset
  - **System skills** (env, hostname, date) → `untrusted` / InMemory
  - **Destructive skills** (rm, chmod) → `trusted` / ReadWrite only
- Allow runtime registration for custom skills

### Task 3: Create Result Handler (src/sandbox/skill-adapter/result-handler.ts)
- `handleResult(raw: BashExecResult, request: SkillExecRequest): SkillExecResult`
- Parse stdout/stderr into structured result
- Capture duration (start/end timing around exec)
- Detect common error patterns (command not found, permission denied, timeout)
- Sanitize output (strip ANSI codes, truncate extremely long output)
- Add metadata: timestamp, sandbox tier used, skill ID

### Task 4: Create Adapter Core (src/sandbox/skill-adapter/adapter.ts)
- `SkillAdapter` class:
  - Constructor takes `SandboxConfig` and `SkillRegistry`
  - `execute(request: SkillExecRequest): Promise<SkillExecResult>`
  - Flow:
    1. Look up skill in registry
    2. Determine required tier (skill default or request override)
    3. Determine required network presets
    4. Create sandbox with correct tier + network
    5. Execute command via `bash.exec()`
    6. Process result through result handler
    7. Return structured result
  - Cache Bash instances per tier to avoid re-creation overhead
  - Dispose method to clean up cached instances

### Task 5: Create Adapter Index (src/sandbox/skill-adapter/index.ts)
- Export `SkillAdapter`, `SkillRegistry`, types
- Export convenience function `createAdapter(config?: Partial<SandboxConfig>): SkillAdapter`
- Pre-configure with default registry

### Task 6: Create Unit Tests (tests/skill-adapter.test.ts)
**Registry tests:**
- Register and retrieve skills
- Unknown skill ID throws
- Trust level determines minimum tier

**Result handler tests:**
- Successful result parsed correctly
- Error result captures stderr
- Long output truncated
- Duration captured

**Adapter tests:**
- File read skill executes through InMemory sandbox
- Data transform skill (pipe jq) works in sandbox
- Web fetch skill gets correct network preset
- Destructive skill rejected below required tier
- Cached Bash instances reused

**Integration test (3 representative skills):**
1. `cat /data/config.json` — file read through overlay (pre-seed file)
2. `curl -s https://api.github.com/zen` — web fetch through sandbox with network
3. `echo '{"a":1}' | jq '.a'` — data transform through in-memory

## Success Criteria
- [ ] Registry maps skills to tiers correctly
- [ ] Adapter routes commands through correct sandbox tier
- [ ] Result handler produces structured, clean output
- [ ] Skills execute without modification to their command strings
- [ ] Error handling captures stderr and non-zero exit codes
- [ ] Three representative skills pass integration test
- [ ] All unit tests pass via `pnpm test`
- [ ] `pnpm typecheck` passes

## On Completion
```bash
git add -A
git commit -m "Phase 3: AgentSkill adapter with registry and trust levels"
```

Then report: "Phase 3 complete. Ready for Phase 4: AI SDK Bash Tool Integration."
