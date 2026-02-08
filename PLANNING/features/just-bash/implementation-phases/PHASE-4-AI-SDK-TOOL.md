# Phase 4 — AI SDK Bash Tool Integration

## Context
Phases 0-3 are complete. The skill adapter routes commands through tier-appropriate sandboxes. Now we create the AI SDK tool that gives Claude (or any model) a sandboxed bash tool, using `just-bash`'s built-in `createBashTool()` enhanced with our tier system.

**Reference:** `just-bash/ai` exports `createBashTool()` for use with the Vercel AI SDK:
```typescript
import { createBashTool } from "just-bash/ai";
const bashTool = createBashTool({ files: { ... } });
```

## Pre-Requisites
- Phase 3 complete
- Skill adapter working
- `ai` SDK installed (add if not present: `pnpm add ai`)

## Tasks

### Task 1: Create Bash Tool Types (src/sandbox/ai-tool/types.ts)
```typescript
// BashToolConfig: { tier, customerTier?, preSeededFiles?, networkPresets?, executionLimits?, contextFiles? }
// BashToolResult: extends SkillExecResult + { toolCallId? }
// CustomerContext: { customerId, tier, rootPath?, allowedSkills?, networkOverrides? }
```
Validate with Zod.

### Task 2: Create Context File Seeder (src/sandbox/ai-tool/context-seeder.ts)
- `seedContextFiles(config: BashToolConfig): Record<string, string>`
- Pre-seed the sandbox filesystem with useful context:
  - `/home/user/.clawdbot/config.json` — customer config, tier info
  - `/home/user/.clawdbot/skills.json` — list of available skills and their descriptions
  - `/data/` directory — placeholder for customer data files
- Accept custom pre-seeded files from config
- Merge defaults with customer-specific files

### Task 3: Create Tool Factory (src/sandbox/ai-tool/tool-factory.ts)
- `createTieredBashTool(config: BashToolConfig)` — returns AI SDK compatible tool
- For InMemory/Overlay tiers: use `createBashTool()` from `just-bash/ai` with pre-seeded files and network config
- For ReadWrite tier: create bash tool manually using `ReadWriteFs` + AI SDK tool definition
- Apply execution limits based on tier:
  - Tier 1: maxCommandCount=1000, maxLoopIterations=1000
  - Tier 2: maxCommandCount=5000, maxLoopIterations=5000
  - Tier 3: maxCommandCount=10000, maxLoopIterations=10000
  - Tier 4: maxCommandCount=50000, maxLoopIterations=50000
- Inject network config from tier defaults or overrides

### Task 4: Create Customer Tool Generator (src/sandbox/ai-tool/customer-tool.ts)
- `createCustomerBashTool(customerContext: CustomerContext)` — high-level function
- Resolves customer tier → sandbox config → bash tool
- Loads customer overrides if `CUSTOMER_OVERRIDE_PATH` env var is set
- Returns a ready-to-use AI SDK tool

### Task 5: Create Tool Index (src/sandbox/ai-tool/index.ts)
- Export `createTieredBashTool`, `createCustomerBashTool`
- Export types
- Export `DEFAULT_EXECUTION_LIMITS` per tier

### Task 6: Create Integration Test (tests/ai-tool.test.ts)
**Tool factory tests:**
- Creates valid AI SDK tool for each tier
- Pre-seeded files accessible inside sandbox
- Execution limits enforced (loop exceeding limit throws)
- Network config applied correctly

**Customer tool tests:**
- Tier 1 customer gets InMemory + no network
- Tier 2 customer gets Overlay + standard network
- Tier 3 customer gets ReadWrite + full network
- Customer overrides apply correctly

**AI SDK integration test:**
- Use `generateText()` with the bash tool and a simple prompt like "List files in /data"
- Verify tool is called and returns valid result
- (Use a mock model or Claude Haiku for cost efficiency)

### Task 7: Create Example (examples/bash-agent.ts)
Create a standalone example script that:
1. Creates a Tier 2 customer bash tool
2. Pre-seeds with sample data files
3. Uses AI SDK `generateText()` with Claude Haiku
4. Prompt: "Count the JSON files in /data and summarize their contents"
5. Prints the agent's response and tool calls

Include instructions to run: `ANTHROPIC_API_KEY=... npx tsx examples/bash-agent.ts`

## Success Criteria
- [ ] `createTieredBashTool()` returns valid AI SDK tool for all tiers
- [ ] Pre-seeded files accessible from inside sandbox
- [ ] Execution limits enforced per tier
- [ ] Network config inherited from tier defaults
- [ ] Customer tool generator resolves tier correctly
- [ ] Example script runs end-to-end with real API call
- [ ] All unit tests pass via `pnpm test`
- [ ] `pnpm typecheck` passes

## On Completion
```bash
git add -A
git commit -m "Phase 4: AI SDK bash tool with tiered execution limits"
```

Then report: "Phase 4 complete. Ready for Phase 5: OpenClaw Plugin Packaging."
