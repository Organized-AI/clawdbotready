# Phase 1 — Sandbox Core: Filesystem Tiers

## Context
Phase 0 is complete. The project `@clawdbot-ready/sandbox` is initialized with `just-bash` installed. Now we build the configurable filesystem tier system that maps to Clawdbot Ready pricing tiers.

**Reference:** `just-bash` provides three filesystem implementations:
- `InMemoryFs` — Pure in-memory, no disk access (default)
- `OverlayFs` — Copy-on-write over a real directory (reads from disk, writes stay in memory)
- `ReadWriteFs` — Direct read-write access to a real directory

## Pre-Requisites
- Phase 0 complete
- `pnpm build` passes
- `just-bash` importable

## Tasks

### Task 1: Create Shared Types (src/sandbox/types.ts)
Define the following types:
```typescript
// SandboxTier enum: 'inmemory' | 'overlay' | 'readwrite'
// SandboxConfig: { tier, rootPath?, cwd?, env?, executionLimits?, networkConfig? }
// SandboxResult: { stdout, stderr, exitCode, duration }
// TierConfig: { tier, description, allowedOperations, maxFileSize? }
```
Use Zod schemas for runtime validation of configs.

### Task 2: Create InMemory Tier (src/sandbox/fs-tiers/in-memory-tier.ts)
- Import `Bash` from `just-bash`
- Create factory function `createInMemoryBash(config: SandboxConfig): Bash`
- Pre-seed with default files: `/home/user/.bashrc`, `/tmp/` directory
- Apply execution limits from config
- No filesystem root needed — everything lives in memory
- This is the **Tier 1 (VPS)** default

### Task 3: Create Overlay Tier (src/sandbox/fs-tiers/overlay-tier.ts)
- Import `Bash` and `OverlayFs` from `just-bash` and `just-bash/fs/overlay-fs`
- Create factory function `createOverlayBash(config: SandboxConfig): Bash`
- Requires `rootPath` in config — the real directory to overlay
- Reads come from disk, writes stay in memory
- Apply execution limits from config
- This is the **Tier 2 (Mac Mini)** default

### Task 4: Create ReadWrite Tier (src/sandbox/fs-tiers/read-write-tier.ts)
- Import `Bash` and `ReadWriteFs` from `just-bash` and `just-bash/fs/read-write-fs`
- Create factory function `createReadWriteBash(config: SandboxConfig): Bash`
- Requires `rootPath` in config — scoped to this directory ONLY
- Validate that rootPath exists and is within allowed boundaries
- Apply execution limits from config
- This is the **Tier 3 (Mac Studio)** default

### Task 5: Create Tier Factory (src/sandbox/fs-tiers/index.ts)
- Export `createSandbox(config: SandboxConfig): Bash`
- Switch on `config.tier` to call the correct factory
- Throw clear error for invalid tier
- Export all individual tier factories
- Export types

### Task 6: Create Unit Tests (tests/fs-tiers.test.ts)
Test each tier:

**InMemory tests:**
- Writing a file then reading it back works
- Files don't persist between new Bash instances
- Cannot access real filesystem paths

**Overlay tests:**
- Can read files from the real rootPath
- Writing creates in-memory copy (original unchanged)
- New files exist only in memory

**ReadWrite tests:**
- Can read and write to rootPath
- Cannot escape rootPath directory
- Changes persist to real filesystem

**Factory tests:**
- Returns correct tier for each config string
- Throws on invalid tier
- Defaults work when optional config omitted

## Success Criteria
- [ ] All three tier factories create valid Bash instances
- [ ] InMemory tier has zero disk interaction
- [ ] Overlay tier reads real files but writes stay in memory
- [ ] ReadWrite tier is scoped and cannot escape root
- [ ] Factory correctly routes by tier string
- [ ] All unit tests pass via `pnpm test`
- [ ] `pnpm typecheck` passes

## On Completion
```bash
git add -A
git commit -m "Phase 1: Filesystem tier system (InMemory, Overlay, ReadWrite)"
```

Then report: "Phase 1 complete. Ready for Phase 2: Network Security Layer."
