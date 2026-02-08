# Phase 0 — Project Setup & just-bash Install

## Context
You are setting up a new TypeScript project that integrates Vercel's `just-bash` (a simulated bash environment with in-memory virtual filesystem) into the OpenClaw/Clawdbot Ready stack. This will serve as a secure sandbox layer for AI agent skill execution.

**Source repo for reference:** https://github.com/vercel-labs/just-bash

## Pre-Requisites
- Node.js >= 20
- pnpm installed

## Tasks

### Task 1: Initialize Project
```bash
mkdir -p clawdbot-sandbox && cd clawdbot-sandbox
pnpm init
```

Set package.json name to `@clawdbot-ready/sandbox` with these scripts:
- `build`: `tsc`
- `dev`: `tsx watch src/index.ts`
- `test`: `vitest run`
- `test:watch`: `vitest`
- `typecheck`: `tsc --noEmit`
- `lint`: `biome check .`

### Task 2: Install Dependencies

**Core:**
```bash
pnpm add just-bash zod dotenv
```

**Dev:**
```bash
pnpm add -D typescript tsx vitest @biomejs/biome @types/node
```

### Task 3: Create tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### Task 4: Create Directory Structure
```
src/
├── index.ts
├── sandbox/
│   ├── fs-tiers/
│   ├── network/
│   ├── skill-adapter/
│   ├── ai-tool/
│   ├── permissions/
│   └── types.ts
├── plugin/
tests/
logs/
config/
.claude/
PLANNING/
├── implementation-phases/
ARCHITECTURE/
DOCUMENTATION/
```

### Task 5: Create Entry Point (src/index.ts)
Create a basic entry point that:
1. Imports `Bash` from `just-bash`
2. Creates a new Bash instance
3. Executes `echo "Clawdbot Sandbox initialized"` via `env.exec()`
4. Prints stdout to console
5. Exports the Bash class and key types for downstream usage

### Task 6: Create .env.example
```env
SANDBOX_DEFAULT_TIER=overlay
SANDBOX_MAX_CALL_DEPTH=100
SANDBOX_MAX_COMMAND_COUNT=10000
SANDBOX_MAX_LOOP_ITERATIONS=10000
SANDBOX_AUDIT_LOG_PATH=./logs/sandbox-audit.log
SANDBOX_NETWORK_ALLOW_GITHUB=true
SANDBOX_NETWORK_ALLOW_ANTHROPIC=true
SANDBOX_NETWORK_ALLOW_OPENAI=true
SANDBOX_NETWORK_CUSTOM_URLS=
CUSTOMER_TIER=2
CUSTOMER_ID=
CUSTOMER_OVERRIDE_PATH=./config/customer-overrides.json
```

### Task 7: Create biome.json
Standard biome config with TypeScript support, formatter and linter enabled.

### Task 8: Verify Everything Works
```bash
pnpm install
pnpm build
pnpm typecheck
npx tsx src/index.ts
```

## Success Criteria
- [ ] `pnpm install` completes without errors
- [ ] `pnpm build` compiles to dist/
- [ ] `pnpm typecheck` passes with no errors
- [ ] `npx tsx src/index.ts` prints "Clawdbot Sandbox initialized"
- [ ] All directories created
- [ ] .env.example present

## On Completion
```bash
git init
git add -A
git commit -m "Phase 0: Project setup with just-bash dependency"
```

Then report: "Phase 0 complete. Ready for Phase 1: Sandbox Core — Filesystem Tiers."
