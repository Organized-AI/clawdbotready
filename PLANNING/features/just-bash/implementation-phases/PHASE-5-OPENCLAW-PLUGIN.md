# Phase 5 — OpenClaw Plugin Packaging

## Context
Phases 0-4 are complete. The sandbox system works standalone with AI SDK integration. Now we package everything as an OpenClaw plugin so it can be enabled/disabled via `openclaw plugins enable`.

**Reference:** OpenClaw plugin structure (from docs.openclaw.ai/plugin):
- Plugins are npm packages or bundled modules
- Enabled/disabled via `openclaw plugins enable <id>` or config JSON
- Config lives in the plugins section of OpenClaw's main config
- Plugins hook into the skill execution pipeline

## Pre-Requisites
- Phase 4 complete
- AI SDK bash tool working
- Familiarity with OpenClaw plugin API

## Tasks

### Task 1: Create Plugin Manifest (src/plugin/manifest.ts)
Define the plugin metadata:
```typescript
export const PLUGIN_MANIFEST = {
  id: "clawdbot-sandbox",
  name: "Clawdbot Sandbox",
  version: "0.1.0",
  description: "Secure sandboxed execution for AgentSkills via just-bash",
  author: "Organized AI",
  homepage: "https://github.com/organized-ai/clawdbot-sandbox",
  config: {
    tier: { type: "string", default: "overlay", enum: ["inmemory", "overlay", "readwrite"] },
    networkPresets: { type: "array", default: ["standard"] },
    customNetworkUrls: { type: "array", default: [] },
    executionLimits: { type: "object", default: {} },
    auditLog: { type: "boolean", default: true },
    auditLogPath: { type: "string", default: "./logs/sandbox-audit.log" },
  }
};
```

### Task 2: Create Plugin Config Schema (src/plugin/config.ts)
- Zod schema for plugin configuration
- Validate tier, network presets, execution limits
- Merge with defaults for any missing values
- `loadPluginConfig(rawConfig: unknown): PluginConfig` — validates and returns typed config
- `getDefaultConfig(): PluginConfig` — returns tier-2 defaults

### Task 3: Create Plugin Hooks (src/plugin/hooks.ts)
Create hooks that intercept OpenClaw's skill execution:

**`onSkillExecute` hook:**
- Intercepts every skill execution request
- Looks up skill in registry for tier requirements
- Creates sandboxed Bash instance with correct tier + network
- Executes command in sandbox instead of host
- Returns result in OpenClaw's expected format

**`onPluginEnable` hook:**
- Initialize sandbox system
- Load config
- Pre-warm Bash instances for each tier
- Register default skills in registry
- Start audit log if enabled

**`onPluginDisable` hook:**
- Dispose all cached Bash instances
- Flush and close audit log
- Clean up temp files

**`onConfigChange` hook:**
- Reload config without restart
- Recreate sandbox instances with new config
- Log config change to audit

### Task 4: Create Plugin Entry Point (src/plugin/index.ts)
- Export the plugin object that OpenClaw expects:
```typescript
export default {
  ...PLUGIN_MANIFEST,
  hooks: {
    onSkillExecute,
    onPluginEnable,
    onPluginDisable,
    onConfigChange,
  }
};
```
- Also export standalone functions for use outside OpenClaw

### Task 5: Create Plugin Readme (src/plugin/README.md)
Document:
- What the plugin does
- Installation: `openclaw plugins install @clawdbot-ready/sandbox`
- Configuration example in OpenClaw config JSON
- Available tiers and what each provides
- Network presets and how to add custom URLs
- Audit log location and format

### Task 6: Update package.json Exports
Add exports map so the plugin can be imported:
```json
{
  "exports": {
    ".": "./dist/index.js",
    "./plugin": "./dist/plugin/index.js",
    "./ai": "./dist/sandbox/ai-tool/index.js"
  }
}
```

### Task 7: Create Unit Tests (tests/plugin.test.ts)
**Manifest tests:**
- Manifest has required fields
- Config schema has all keys with defaults

**Config tests:**
- Valid config passes validation
- Invalid tier rejected
- Defaults applied for missing values

**Hook tests:**
- `onPluginEnable` initializes sandbox system
- `onSkillExecute` routes through sandbox
- `onPluginDisable` cleans up resources
- `onConfigChange` reloads without errors

**Integration test:**
- Simulate enable → execute skill → disable lifecycle
- Verify skill ran in sandbox (not on host)
- Verify audit log entry created

## Success Criteria
- [ ] Plugin manifest complete with all metadata
- [ ] Config schema validates and applies defaults
- [ ] Hooks intercept skill execution correctly
- [ ] Plugin enable/disable lifecycle works
- [ ] Package.json exports configured
- [ ] Plugin README documents usage
- [ ] All unit tests pass via `pnpm test`
- [ ] `pnpm typecheck` passes

## On Completion
```bash
git add -A
git commit -m "Phase 5: OpenClaw plugin packaging with hooks and config"
```

Then report: "Phase 5 complete. Ready for Phase 6: Tier-Based Permission System."
