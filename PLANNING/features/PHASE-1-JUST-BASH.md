# Phase 1: just-bash Sandbox Integration

## Claude Code Prompt

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md and CLAUDE.md for full context.

You are integrating the just-bash sandboxed shell (https://github.com/Organized-AI/just-bash) into the Clawdbot Ready / OpenClaw project as the secure execution layer.

## Branch Setup
git checkout main && git pull
git checkout -b feature/just-bash-sandbox

## Tasks

### 1. Add just-bash as dependency
- Clone or add as git submodule: git submodule add https://github.com/Organized-AI/just-bash.git packages/just-bash
- OR add via npm if published: pnpm add @organized-ai/just-bash
- Verify the package builds and tests pass

### 2. Create @clawdbot-ready/sandbox wrapper
Create packages/sandbox/ with:
- src/index.ts — exports SandboxShell class wrapping just-bash
- src/config.ts — sandbox configuration (filesystem mode, network allowlist, execution limits)
- src/types.ts — TypeScript interfaces for sandbox options
- package.json — @clawdbot-ready/sandbox package
- tsconfig.json — TypeScript config extending root

The wrapper should:
- Default to InMemoryFs (most secure, no host access)
- Support configurable filesystem modes (InMemory, Overlay, ReadWrite, Mountable)
- Accept URL allowlists for optional network access
- Enforce execution timeouts and loop protection
- Log all executed commands for audit trail

### 3. Wire into exec-approvals pipeline
Modify the Gateway's exec-approvals system:
- When a command is approved, route to just-bash sandbox instead of host shell
- Commands in exec-approvals.json allowlist → sandbox execution
- Commands NOT in allowlist → denied (fail closed)
- Log execution results back to Gateway

### 4. Create configuration
Add to config/sandbox.env:
```
SANDBOX_FS_MODE=inmemory
SANDBOX_NETWORK_ENABLED=false
SANDBOX_NETWORK_ALLOWLIST=
SANDBOX_TIMEOUT_MS=30000
SANDBOX_MAX_OUTPUT_BYTES=1048576
```

### 5. Health check script
Create scripts/sandbox-health.sh that:
- Verifies just-bash is importable
- Runs basic command suite (ls, cat, echo, grep)
- Tests network isolation (should fail to fetch when disabled)
- Tests timeout enforcement
- Reports sandbox version and capabilities

### 6. Integration tests
Create tests/sandbox.test.ts:
- Test InMemoryFs isolation (files don't persist between sessions)
- Test command execution (ls, cat, grep, jq, python3)
- Test pipes and redirects
- Test network isolation
- Test timeout enforcement
- Test exec-approvals integration

### 7. Documentation
Create DOCUMENTATION/openclaw/sandbox-configuration.md:
- What the sandbox provides
- Configuration options
- Security guarantees
- Troubleshooting

### 8. Git commit
git add -A
git commit -m "feat: integrate just-bash sandbox as secure execution layer

- Add @clawdbot-ready/sandbox wrapper package
- Wire sandbox into exec-approvals pipeline
- Default to InMemoryFs (most secure)
- Configurable network allowlist
- Execution timeout enforcement
- Health check and integration tests

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] Agents execute commands in sandbox, not host
- [ ] exec-approvals routes to sandbox by default
- [ ] Network access disabled unless allowlisted
- [ ] 60+ bash commands working in sandbox
- [ ] All existing Gateway tests still pass
- [ ] Health check script passes
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
```

No additional env vars needed for this phase — just-bash runs entirely in-process.
