# Phase 6: Tier-Based Permission System — COMPLETE

**Completed**: 2026-02-08
**Duration**: ~15 minutes (Agent Team execution)

## What Was Done

### New Files Created
1. **`src/sandbox/permissions/types.ts`** — Zod schemas: PermissionLevel, TierLevel (1-4), CommandPermission, TierPermissions, PermissionCheckResult
2. **`src/sandbox/permissions/command-allowlist.ts`** — Per-tier command allowlists (18 T1 + 20 T2 + 9 T3 + 3 T4 + 10 universal deny), `getCommandAllowlist()`, `matchCommand()`
3. **`src/sandbox/permissions/fs-guard.ts`** — `checkFsAccess()`: Tier 1→inmemory, Tier 2→+overlay, Tier 3/4→+readwrite
4. **`src/sandbox/permissions/network-guard.ts`** — `checkNetworkAccess()`: Tier 1→none, Tier 2→standard, Tier 3→+extended, Tier 4→unrestricted
5. **`src/sandbox/permissions/manager.ts`** — `PermissionManager` class with `checkCommand()`, `checkFilesystem()`, `checkNetwork()`, `checkAll()`, `setTier()`, compound command parsing
6. **`src/sandbox/permissions/index.ts`** — Barrel exports
7. **`tests/permissions.test.ts`** — 44 vitest tests across 8 describe blocks

### Modified Files
8. **`src/sandbox/skill-adapter/adapter.ts`** — Added optional `PermissionManager` dependency, pre-execution permission gate (exitCode 126 on deny), `setPermissionManager()` method
9. **`src/index.ts`** — Added permissions exports

## Architecture

### Tier Capabilities
| Tier | Filesystem | Network | Commands | Use Case |
|------|-----------|---------|----------|----------|
| 1 (VPS) | inmemory only | none | 18 read-only | Cheapest, safest |
| 2 (Mac Mini) | inmemory, overlay | standard | +20 write ops | Standard customers |
| 3 (Mac Studio) | all types | standard, extended | +9 dev tools (audited) | Power users |
| 4 (Agency) | all types | unrestricted | +3 system tools (audited) | Full access |

### Universal Deny List (all tiers)
`sudo`, `su`, `mount`, `umount`, `mkfs`, `dd`, `shutdown`, `reboot`, `systemctl`, `launchctl`

### Permission Check Flow
```
SkillAdapter.execute(request)
  → PermissionManager.checkAll(command, fsType, networkPresets)
    → checkCommand(): parse pipes/chains, match each segment
    → checkFilesystem(): tier→fs-type mapping
    → checkNetwork(): tier→preset mapping
  → If denied: return { exitCode: 126, stderr: "Permission denied: ..." }
  → If allowed: proceed to sandbox execution
```

### Compound Command Parsing
Splits on `|`, `||`, `&&`, `;` and checks each command segment independently. If any segment is denied, the entire command is rejected.

## Verification Results
| Gate | Status |
|------|--------|
| Build (`tsc`) | PASS |
| Typecheck (`tsc --noEmit`) | PASS |
| Tests (vitest) | PASS — 170 passed, 3 skipped (6 test files) |
| Lint (biome) | PASS |

## Test Coverage (44 tests)
- **getCommandAllowlist** (6): T1 read-only, T1 no write, T2 inherited, T3 audit, T4 docker, universal deny
- **matchCommand** (3): allowed, denied priority, unknown
- **checkFsAccess** (5): T1-T4 access, denial reason
- **checkNetworkAccess** (5): T1-T4 access, denial message
- **parseCommandSegments** (7): simple, pipes, &&, ;, ||, empty, complex
- **PermissionManager** (14): T1/T2/T3 allow/deny, sudo, pipes, chains, combined checks, setTier, custom commands
- **SkillAdapter integration** (4): denied exitCode 126, allowed exec, no-PM bypass, runtime PM change
