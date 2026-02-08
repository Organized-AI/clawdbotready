# Phase 4: AI SDK Bash Tool Integration — COMPLETE

**Completed**: 2026-02-08
**Duration**: ~30 minutes (Agent Team execution)

## What Was Done

### New Files Created
1. **`src/sandbox/ai-tool/types.ts`** — Zod schemas for `BashToolConfig`, `BashToolResult`, `CustomerContext`, and `DEFAULT_EXECUTION_LIMITS` tiered constants
2. **`src/sandbox/ai-tool/context-seeder.ts`** — `seedContextFiles()` and `seedCustomerFiles()` for pre-seeding sandbox filesystem with config, skills, and customer data
3. **`src/sandbox/ai-tool/tool-factory.ts`** — `createTieredBashTool()` returning AI SDK `Tool<>` with tiered execution limits, network config, and `createBashForConfig()` test helper
4. **`src/sandbox/ai-tool/customer-tool.ts`** — `createCustomerBashTool()` high-level entry point mapping customer context to a ready-to-use AI SDK tool
5. **`src/sandbox/ai-tool/index.ts`** — Barrel exports for all ai-tool public API
6. **`tests/ai-tool.test.ts`** — 33 vitest tests across 8 describe blocks

### Modified Files
7. **`src/index.ts`** — Added ai-tool exports (types + values)
8. **`package.json`** — Added `ai` v6.0.77 and `@ai-sdk/provider` v3.0.8 dependencies

## Architecture

### Tiered Execution Limits
| Tier | maxCommandCount | maxLoopIterations | maxCallDepth |
|------|----------------|-------------------|-------------|
| `inmemory` | 1,000 | 1,000 | 50 |
| `overlay` | 5,000 | 5,000 | 75 |
| `readwrite` | 10,000 | 10,000 | 100 |

### Default Network Presets per Tier
| Tier | Default Preset | Description |
|------|---------------|-------------|
| `inmemory` | `none` | No network access |
| `overlay` | `standard` | Allowlisted URLs only |
| `readwrite` | `full` | Unrestricted network |

### Customer Tool Pipeline
```
CustomerContext → BashToolConfig.parse() → seedCustomerFiles() → createTieredBashTool() → Tool<>
```

### Pre-seeded Filesystem
- `/home/user/.clawdbot/config.json` — tier, version, sandbox flag
- `/home/user/.clawdbot/skills.json` — 9 available skill definitions
- `/home/user/.clawdbot/customer.json` — customer ID and context (via seedCustomerFiles)

## Key Design Decisions

### No `just-bash/ai` export
The phase prompt assumed `createBashTool()` from `just-bash/ai` existed — it doesn't in v2.9.6. We built the complete AI SDK tool wrapper ourselves using:
- `Tool<INPUT, OUTPUT>` type from `ai` package
- `zodSchema()` wrapper for Zod v4 compatibility
- Direct `Bash` class instantiation with our config

### AI SDK v6 Integration
- Uses `inputSchema` property (not `parameters`) — the `tool()` helper maps internally but direct `Tool` objects require `inputSchema`
- Explicit return type annotations (`Tool<{ command: string }, BashToolResult>`) to avoid pnpm module resolution issues with inferred types
- `zodSchema()` from `ai` wraps Zod v4 schemas for AI SDK compatibility

## Verification Results
| Gate | Status |
|------|--------|
| Build (`tsc`) | PASS |
| Typecheck (`tsc --noEmit`) | PASS |
| Tests (vitest) | PASS — 104 passed, 3 skipped (4 test files) |
| Lint (biome) | PASS |

## Test Coverage (33 tests)
- **seedContextFiles** (4): defaults, tier config, merge custom, override defaults
- **seedCustomerFiles** (2): customer.json, merge context files
- **DEFAULT_EXECUTION_LIMITS** (4): all tiers, restrictive, permissive, ordering
- **createBashForConfig** (4): creation, pre-seeded files, default context, custom env
- **createTieredBashTool** (5): description, execute fn, structured result, all tiers, error capture
- **createCustomerBashTool** (5): inmemory, overlay, context files, customer.json, defaults
- **AI Tool Integration** (4): jq piping, ls files, grep search, find+wc count
- **Schema Validation** (5): valid config, invalid tier, defaults, valid customer, required fields
