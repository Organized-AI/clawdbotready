# Phase 2 — Network Security Layer

## Context
Phases 0-1 are complete. Filesystem tiers are working. Now we build the network allow-list manager that controls which URLs each skill can access via `curl` inside the sandbox.

**Reference:** `just-bash` network config:
```typescript
new Bash({
  network: {
    allowedUrlPrefixes: ["https://api.github.com/"],
    allowedMethods: ["GET", "HEAD", "POST"],
  }
});
```
Network access is disabled by default. The `curl` command only exists when network is configured.

## Pre-Requisites
- Phase 1 complete
- Filesystem tiers working

## Tasks

### Task 1: Create Allow-List Types (src/sandbox/network/types.ts)
```typescript
// NetworkPreset: { name, description, allowedUrlPrefixes, allowedMethods }
// NetworkConfig: { presets: NetworkPreset[], customUrls?: string[], dangerouslyAllowAll?: boolean }
// NetworkRule: { urlPrefix, methods, description }
```
Validate with Zod schemas.

### Task 2: Create Presets (src/sandbox/network/presets.ts)
Define pre-built allow-lists:

**github:** `https://api.github.com/` — GET, HEAD
**anthropic:** `https://api.anthropic.com/` — GET, HEAD, POST
**openai:** `https://api.openai.com/` — GET, HEAD, POST
**vercel:** `https://api.vercel.com/` — GET, HEAD
**whoop:** `https://api.prod.whoop.com/` — GET, HEAD
**homeassistant:** Configurable base URL — GET, HEAD, POST
**stripe:** `https://api.stripe.com/` — GET, HEAD, POST
**none:** Empty — no network access (Tier 1 default)
**standard:** github + anthropic + openai (Tier 2 default)
**full:** All presets combined (Tier 3/4 default)

Export as a `PRESETS` map and a `getPreset(name: string)` function.

### Task 3: Create Network Config Builder (src/sandbox/network/config-builder.ts)
- `buildNetworkConfig(presetNames: string[], customUrls?: string[]): just-bash NetworkConfig`
- Merges multiple presets into a single allow-list
- Deduplicates URL prefixes
- Validates all URLs are HTTPS (reject HTTP unless explicitly flagged)
- Returns the config object that plugs directly into `new Bash({ network: ... })`

### Task 4: Create Network Manager (src/sandbox/network/index.ts)
- Export `createNetworkConfig(config: NetworkConfig): BashNetworkOption`
- Export all presets and builder
- Integrate with the tier system from Phase 1:
  - Tier 1 (InMemory) → `none` preset
  - Tier 2 (Overlay) → `standard` preset
  - Tier 3 (ReadWrite) → `full` preset
  - Tier 4 (Agency) → `full` + custom URLs

### Task 5: Update Tier Factory (src/sandbox/fs-tiers/index.ts)
- Modify `createSandbox()` to accept network config
- Pass network config through to `new Bash()` constructor
- Default network preset based on tier if not explicitly provided

### Task 6: Create Unit Tests (tests/network.test.ts)
**Preset tests:**
- Each preset has valid HTTPS URLs
- `getPreset()` returns correct preset by name
- Unknown preset name throws

**Config builder tests:**
- Single preset builds valid config
- Multiple presets merge correctly
- Custom URLs append to preset URLs
- HTTP URLs rejected by default
- Deduplication works

**Integration tests:**
- InMemory sandbox with `none` preset: `curl` command not found
- Overlay sandbox with `standard` preset: can reach allowed URLs
- Blocked URLs return clear error message
- Redirect to non-allowed domain is caught

## Success Criteria
- [ ] All presets defined with valid HTTPS URLs
- [ ] Config builder merges presets correctly
- [ ] Tier factory integrates network config
- [ ] Sandboxes without network config have no `curl`
- [ ] Sandboxes with network config can only reach allowed URLs
- [ ] All unit tests pass via `pnpm test`
- [ ] `pnpm typecheck` passes

## On Completion
```bash
git add -A
git commit -m "Phase 2: Network security layer with allow-list presets"
```

Then report: "Phase 2 complete. Ready for Phase 3: AgentSkill Adapter."
