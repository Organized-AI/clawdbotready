# Phase 7 — Integration Testing & Hardening

## Context
Phases 0-6 are complete. The full system — sandbox, network, skill adapter, AI SDK tool, OpenClaw plugin, and tier-based permissions — is implemented and unit-tested. Now we write integration tests that verify the components work together, add error handling and security hardening, and prepare the package for release.

**Key insight:** Unit tests prove individual components work. Integration tests prove the full execution path works: tier selection → permission check → sandbox creation → command execution → result handling. This phase also adds the error hierarchy, performance benchmarks, and package documentation.

## Pre-Requisites
- All phases 0-6 complete with passing tests
- Full sandbox system functional
- Permission system enforcing tier boundaries

## Tasks

### Task 1: Create Integration Test Suite (tests/integration.test.ts)

**Tier lifecycle tests:**
- Create SkillAdapter at Tier 1 → execute read-only command → verify InMemory sandbox used → verify result
- Upgrade to Tier 2 → execute write command → verify Overlay sandbox → verify file persists in overlay
- Upgrade to Tier 3 → execute destructive command in scoped dir → verify ReadWrite sandbox
- Downgrade to Tier 1 → verify previously-allowed write command is now denied

**Skill routing tests:**
- Register 3 skills with different trust levels → execute each → verify correct sandbox tier
- Execute skill with network requirement → verify network preset applied
- Execute unknown skill ID → verify graceful error

**Plugin lifecycle tests:**
- Call `onPluginEnable` → verify sandbox system initialized
- Execute skill through `onSkillExecute` → verify sandboxed execution
- Call `onConfigChange` with new tier → verify sandbox recreated
- Call `onPluginDisable` → verify cleanup (no Bash instances leaked)

**Security boundary tests:**
- Tier 1: attempt `rm` → verify denied with exitCode 126
- Tier 2: attempt `curl` to non-allowed host → verify denied
- Tier 1: attempt ReadWrite filesystem → verify denied
- Command injection: `echo hello; rm -rf /` → verify each segment checked
- Path traversal: `cat ../../etc/passwd` → verify blocked (overlay/inmemory don't expose host)
- Environment escape: verify sandbox env vars don't leak host secrets

### Task 2: Create E2E Test with Real AI (tests/e2e-ai.test.ts)
- Skip if `ANTHROPIC_API_KEY` not set (`describe.skipIf`)
- Use Claude Haiku for cost efficiency
- Test flow:
  1. Create AI SDK tool via `createSandboxBashTool()`
  2. Send prompt: "List the files in the current directory"
  3. Verify tool was called with `ls` or equivalent
  4. Verify result contains expected sandbox filesystem content
  5. Verify no host filesystem leaked into result
- Timeout: 30 seconds
- Mark as `@slow` test category

### Task 3: Create Custom Error Classes (src/sandbox/errors.ts)
Define error hierarchy:
```typescript
// SandboxError (base) — code: string, cause?: Error
//   ├── PermissionDeniedError — tier, command, reason
//   ├── SandboxCreationError — fsType, cause
//   ├── CommandExecutionError — command, exitCode, stderr
//   ├── NetworkBlockedError — url, tier, allowedPresets
//   ├── ConfigValidationError — field, value, expected
//   └── PluginLifecycleError — hook, phase, cause
```
- Each error has a unique `code` string (e.g., `SANDBOX_PERMISSION_DENIED`)
- All errors extend a base `SandboxError` class
- `toJSON()` method on base class for structured logging
- Update existing code to throw these instead of generic errors

### Task 4: Create Performance Benchmarks (tests/benchmarks.test.ts)
Measure and assert:
- Sandbox creation time per tier (target: < 50ms for InMemory, < 100ms for Overlay)
- Command execution overhead vs direct `child_process.exec` (target: < 2x)
- Permission check latency (target: < 1ms per check)
- Bash instance reuse benefit (cached vs fresh creation)
- Memory usage per tier (log but don't assert — informational)
- Use `performance.now()` for timing
- Mark as `@benchmark` test category

### Task 5: Create Package Exports & Entry Points
Update `src/index.ts` to be the comprehensive public API:
```typescript
// Core
export { Bash } from 'just-bash';
export { SandboxConfig, createSandbox } from './sandbox/fs-tiers';
export { NetworkConfig } from './sandbox/network';

// Skill Adapter
export { SkillAdapter, SkillRegistry, createAdapter } from './sandbox/skill-adapter';

// AI SDK Tool
export { createSandboxBashTool } from './sandbox/ai-tool';

// Permissions
export { PermissionManager, TierLevel } from './sandbox/permissions';

// Plugin
export { default as plugin } from './plugin';

// Errors
export * from './sandbox/errors';

// Types
export type { SkillDefinition, SkillExecRequest, SkillExecResult } from './sandbox/skill-adapter/types';
export type { PermissionCheckResult, TierPermissions } from './sandbox/permissions/types';
```

Update `package.json` exports map:
```json
{
  "exports": {
    ".": "./dist/index.js",
    "./plugin": "./dist/plugin/index.js",
    "./ai": "./dist/sandbox/ai-tool/index.js",
    "./permissions": "./dist/sandbox/permissions/index.js"
  }
}
```

### Task 6: Create Architecture Documentation (ARCHITECTURE/sandbox-architecture.md)
Document:
- System architecture diagram (ASCII)
- Data flow: request → permission check → sandbox → execution → result
- Tier matrix (filesystem, network, commands per tier)
- Security model: what each layer prevents
- Extension points: custom commands, custom presets, custom skills
- Performance characteristics

### Task 7: Create Project README (README.md in clawdbot-sandbox root)
Include:
- What it does (1 paragraph)
- Quick start (install, basic usage)
- Tier overview table
- API reference (key exports with 1-line descriptions)
- Configuration reference
- OpenClaw plugin usage
- AI SDK integration example
- Contributing guidelines
- License

### Task 8: Final Verification
Run full suite and generate coverage:
```bash
pnpm build
pnpm typecheck
pnpm test -- --coverage
pnpm lint
```
- Target: > 80% code coverage
- All tests must pass (unit, integration, E2E if API key present)
- Zero typecheck errors
- Zero lint errors

## Success Criteria
- [ ] Integration tests cover tier lifecycle, skill routing, plugin lifecycle, security boundaries
- [ ] E2E test with real AI works (when API key present)
- [ ] Custom error classes replace all generic errors
- [ ] Performance benchmarks pass targets
- [ ] Package exports are comprehensive and correct
- [ ] Architecture documentation complete
- [ ] README complete with usage examples
- [ ] Code coverage > 80%
- [ ] `pnpm build && pnpm typecheck && pnpm test && pnpm lint` all pass

## On Completion
```bash
git add -A
git commit -m "Phase 7: Integration tests, error hierarchy, benchmarks, and documentation"
```

Then report: "Phase 7 complete. All 8 phases done. The @clawdbot-ready/sandbox package is ready for release."
