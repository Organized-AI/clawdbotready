# Phase 2: Network Configuration — COMPLETE

**Completed**: 2026-02-08
**Duration**: ~20 minutes

## What Was Done

### New Files Created
1. **`src/sandbox/network/types.ts`** — Zod schemas for `HttpMethod`, `NetworkPreset`, and `NetworkManagerConfig`
2. **`src/sandbox/network/presets.ts`** — Pre-built network allow-lists (`PRESETS` map) with 8 presets: `none`, `github`, `anthropic`, `openai`, `vercel`, `stripe`, `standard`, `full`; plus `getPreset()` function
3. **`src/sandbox/network/config-builder.ts`** — `buildNetworkConfig()` that merges presets, deduplicates URLs/methods, validates HTTPS, returns just-bash `NetworkConfig`
4. **`src/sandbox/network/index.ts`** — Barrel exports for all network types, presets, and the `createNetworkConfig` convenience alias
5. **`tests/network.test.ts`** — 22 vitest tests covering presets, getPreset, and buildNetworkConfig

### Modified Files
6. **`src/sandbox/fs-tiers/index.ts`** — `createSandbox()` now resolves network presets per tier and passes `NetworkConfig` through to tier creators
7. **`src/sandbox/fs-tiers/in-memory-tier.ts`** — Accepts optional `NetworkConfig` parameter, passes to `BashOptions.network`
8. **`src/sandbox/fs-tiers/overlay-tier.ts`** — Same network wiring as in-memory
9. **`src/sandbox/fs-tiers/read-write-tier.ts`** — Same network wiring as in-memory
10. **`src/index.ts`** — Exports all network module types, schemas, presets, and builder functions

## Architecture

### Tier Default Presets
| Tier | FS Type | Default Network Preset | Access Level |
|------|---------|----------------------|--------------|
| Tier 1 (VPS) | inmemory | `none` | No network |
| Tier 2 (Mac Mini) | overlay | `standard` | GitHub + Anthropic + OpenAI |
| Tier 3 (Mac Studio) | readwrite | `full` | All APIs + all HTTP methods |

### Preset Details
| Preset | URLs | Methods |
|--------|------|---------|
| `none` | (empty) | (empty) |
| `github` | `https://api.github.com/` | GET, HEAD |
| `anthropic` | `https://api.anthropic.com/` | GET, HEAD, POST |
| `openai` | `https://api.openai.com/` | GET, HEAD, POST |
| `vercel` | `https://api.vercel.com/` | GET, HEAD |
| `stripe` | `https://api.stripe.com/` | GET, HEAD, POST |
| `standard` | github + anthropic + openai | GET, HEAD, POST |
| `full` | all of the above | all 7 methods |

## Verification Results
- **Build**: PASS
- **Typecheck**: PASS
- **Test**: PASS (22 network tests + 14 fs-tiers tests = 33 passed, 3 skipped)
- **Lint**: PASS (0 errors)

## Key Design Decisions
- `buildNetworkConfig()` returns `undefined` for the "none" preset (network stays disabled in just-bash)
- HTTP URLs are rejected with a clear error message pointing to `dangerouslyAllowFullInternetAccess`
- URL prefixes and HTTP methods are deduplicated via `Set` when merging multiple presets
- Custom URLs are validated for HTTPS before being added to the allow-list
- Network config is resolved at `createSandbox()` time and passed through to tier creators
