# Phase 6 — Tier-Based Permission System

## Context
Phases 0-5 are complete. The sandbox, network layer, skill adapter, AI SDK tool, and OpenClaw plugin are all working. Now we add the permission system that maps customer tiers (1-4) to allowed commands, filesystem types, and network access. This is the security backbone — it determines what each customer can actually execute.

**Key insight:** Permissions are checked as a pre-execution gate inside `SkillAdapter.execute()`. If a command or resource access isn't permitted for the customer's tier, execution is rejected before reaching the sandbox.

## Pre-Requisites
- Phase 5 complete
- Plugin packaging with hooks working
- Understanding of tier mapping from MASTER-PLAN.md:
  - Tier 1 (VPS): InMemoryFs, no network, read-only commands
  - Tier 2 (Mac Mini): OverlayFs, standard network presets, standard commands
  - Tier 3 (Mac Studio): ReadWriteFs (scoped), full network presets, all standard commands
  - Tier 4 (Agency): ReadWriteFs + custom commands, unrestricted network

## Tasks

### Task 1: Create Permission Types (src/sandbox/permissions/types.ts)
Define with Zod:
```typescript
// PermissionLevel: 'deny' | 'allow' | 'allow_with_audit'
// TierLevel: 1 | 2 | 3 | 4
// CommandPermission: { pattern: string (glob), level: PermissionLevel, description: string }
// TierPermissions: { tier: TierLevel, commands: CommandPermission[], filesystem: FsType[], networkPresets: string[], maxConcurrent: number, maxExecTime: number }
// PermissionCheckResult: { allowed: boolean, reason: string, tier: TierLevel, auditRequired: boolean }
```

### Task 2: Create Command Allowlist (src/sandbox/permissions/command-allowlist.ts)
Define per-tier command permissions:

**Tier 1 — Read-only:**
- Allow: `echo`, `cat`, `head`, `tail`, `grep`, `find`, `ls`, `wc`, `sort`, `uniq`, `date`, `env`, `pwd`, `whoami`
- Deny: Everything else

**Tier 2 — Standard:**
- Allow: All Tier 1 + `mkdir`, `cp`, `mv`, `tee`, `sed`, `awk`, `jq`, `curl` (to allowed hosts), `wget` (to allowed hosts), `tar`, `gzip`, `gunzip`
- Deny: `rm`, `chmod`, `chown`, `kill`, `pkill`, `dd`, `mkfs`, network tools beyond allow-list

**Tier 3 — Full:**
- Allow: All Tier 2 + `rm` (scoped to workdir), `chmod`, `npm`, `node`, `python3`, `pip`, `git` (read-only)
- Deny: `rm -rf /`, system directories, `sudo`, `su`, `mount`, `umount`

**Tier 4 — Agency:**
- Allow: All Tier 3 + custom commands registered at runtime + `git` (full), unrestricted `curl`/`wget`
- Deny: `sudo`, `su`, `mount`, `umount`, `mkfs`, `dd` (destructive flags)

Export `getCommandAllowlist(tier: TierLevel): CommandPermission[]`.

### Task 3: Create Filesystem Permission Guard (src/sandbox/permissions/fs-guard.ts)
- `FsGuard` class
- `checkFsAccess(tier: TierLevel, requestedFs: FsType): PermissionCheckResult`
- Mapping:
  - Tier 1 → only `inmemory`
  - Tier 2 → `inmemory` or `overlay`
  - Tier 3 → `inmemory`, `overlay`, or `readwrite` (scoped)
  - Tier 4 → all types including `readwrite` with custom paths
- Reject requests for filesystem types above the customer's tier
- Return structured `PermissionCheckResult` with reason

### Task 4: Create Network Permission Guard (src/sandbox/permissions/network-guard.ts)
- `NetworkGuard` class
- `checkNetworkAccess(tier: TierLevel, requestedPresets: string[]): PermissionCheckResult`
- Mapping:
  - Tier 1 → no network (`[]`)
  - Tier 2 → `standard` preset only (GitHub API, Anthropic, OpenAI)
  - Tier 3 → `standard` + `extended` presets (add npm registry, PyPI, Docker Hub)
  - Tier 4 → unrestricted (any URL) + custom presets
- Reject requests for presets above the customer's tier

### Task 5: Create PermissionManager (src/sandbox/permissions/manager.ts)
- `PermissionManager` class combining all guards:
  - Constructor takes `tier: TierLevel` and optional `customPermissions`
  - `checkCommand(command: string): PermissionCheckResult` — parse command, match against allowlist
  - `checkFilesystem(fsType: FsType): PermissionCheckResult` — delegate to FsGuard
  - `checkNetwork(presets: string[]): PermissionCheckResult` — delegate to NetworkGuard
  - `checkAll(request: SkillExecRequest): PermissionCheckResult` — combined check
  - Command parsing: extract base command from string (handle pipes, `&&`, `;` — check each segment)
  - Audit logging: if `allow_with_audit`, log the command before allowing

### Task 6: Integrate with SkillAdapter (src/sandbox/skill-adapter/adapter.ts)
- Add `PermissionManager` as constructor dependency
- In `execute()`, call `permissionManager.checkAll(request)` before sandbox execution
- If denied, return `SkillExecResult` with exitCode 126, stderr = denial reason
- If `allow_with_audit`, log to audit file before executing
- Add `setTier(tier: TierLevel)` method to change tier at runtime

### Task 7: Create Unit Tests (tests/permissions.test.ts)
**Command allowlist tests:**
- Tier 1 allows `echo hello`
- Tier 1 denies `rm -rf /tmp`
- Tier 2 allows `curl https://api.github.com/zen`
- Tier 2 denies `rm important.txt`
- Tier 3 allows `rm ./workdir/temp.txt`
- Tier 4 allows custom registered command

**Filesystem guard tests:**
- Tier 1 can only use InMemory
- Tier 2 can use InMemory or Overlay
- Tier 3 can use all three types
- Tier 4 can use all types

**Network guard tests:**
- Tier 1 denied all network
- Tier 2 allowed standard only
- Tier 3 allowed standard + extended
- Tier 4 unrestricted

**PermissionManager tests:**
- Combined check: Tier 2 command + overlay fs + standard network → allowed
- Combined check: Tier 1 command + readwrite fs → denied (fs violation)
- Piped command: `cat file | grep pattern` → each segment checked
- Chained command: `mkdir foo && cd foo` → each segment checked

**Integration with SkillAdapter:**
- Denied command returns exitCode 126
- Audit-required command is logged before execution
- Tier change at runtime updates permissions

## Success Criteria
- [ ] All four tiers have correct command allowlists
- [ ] Filesystem guard enforces tier → fs-type mapping
- [ ] Network guard enforces tier → preset mapping
- [ ] PermissionManager parses compound commands (pipes, chains)
- [ ] SkillAdapter rejects denied commands with clear error message
- [ ] Audit logging works for `allow_with_audit` commands
- [ ] All unit tests pass via `pnpm test`
- [ ] `pnpm typecheck` passes

## On Completion
```bash
git add -A
git commit -m "Phase 6: Tier-based permission system with command/fs/network guards"
```

Then report: "Phase 6 complete. Ready for Phase 7: Integration Testing & Hardening."
