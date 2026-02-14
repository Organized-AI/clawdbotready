# Phase 5: E2B Agent Sandbox

## Claude Code Prompt

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md, CLAUDE.md for context.
Verify Phases 1-4 are complete.

You are integrating agent-sandbox-skill (https://github.com/Organized-AI/agent-sandbox-skill) as the E2B isolated execution environment for advanced agent workloads.

## Branch Setup
git checkout main && git pull
git checkout -b feature/agent-sandbox

## Tasks

### 1. Add agent-sandbox-skill to project
- git submodule add https://github.com/Organized-AI/agent-sandbox-skill.git packages/agent-sandbox
- Review architecture: Python 3.12+, E2B API, Playwright, Vue + FastAPI + SQLite
- Install deps: cd packages/agent-sandbox && pip install -r requirements.txt

### 2. Create execution router
Create packages/execution-router/src/index.ts:
- Route execution requests to appropriate backend:
  - Quick commands (ls, grep, jq, etc.) → just-bash sandbox (Phase 1)
  - Full-stack development, browser testing → E2B agent-sandbox (this phase)
- Classification criteria:
  - Command complexity (simple vs multi-step)
  - Resource requirements (CPU, memory, network)
  - Duration estimate (seconds vs minutes)
  - Filesystem persistence needs

### 3. Sandbox provisioning automation
Create packages/agent-sandbox/src/provisioner.ts:
- Create E2B sandbox on demand
- Configure sandbox with customer-specific settings
- Pre-install common tools and frameworks
- Set resource limits (CPU, memory, disk, timeout)
- Handle sandbox lifecycle (create, pause, resume, destroy)

### 4. Browser automation integration
Create packages/agent-sandbox/src/browser.ts:
- Wire Playwright for browser automation within E2B sandboxes
- Support UI testing workflows
- Screenshot capture for verification
- Network request interception for debugging

### 5. Full-stack scaffolding
Create packages/agent-sandbox/src/scaffolder.ts:
- Templates for Vue + FastAPI + SQLite (default)
- Templates for React + Express + PostgreSQL (alternative)
- Templates for static sites (HTML/CSS/JS)
- Each template includes Dockerfile for hosting

### 6. Configuration
Create config/agent-sandbox.env:
```
E2B_API_KEY=
SANDBOX_DEFAULT_TIMEOUT_MS=300000
SANDBOX_MAX_CONCURRENT=5
SANDBOX_CPU_LIMIT=2
SANDBOX_MEMORY_LIMIT_MB=2048
SANDBOX_DISK_LIMIT_MB=5120
EXECUTION_ROUTER_THRESHOLD=complex
```

### 7. Cost tracking
- Track E2B sandbox usage per customer
- Set budget limits and alerts
- Prefer just-bash for simple tasks (free)
- Report sandbox costs alongside model costs

### 8. Integration tests
Create tests/agent-sandbox-integration.test.ts:
- Test execution routing (simple → just-bash, complex → E2B)
- Test sandbox provisioning and teardown
- Test full-stack scaffolding
- Test browser automation
- Test resource limits enforcement
- Test cost tracking

### 9. Git commit
git add -A
git commit -m "feat: integrate E2B agent sandbox for advanced execution

- Execution router: just-bash for quick, E2B for heavy workloads
- Sandbox provisioning with resource limits
- Playwright browser automation
- Full-stack scaffolding templates
- Per-customer cost tracking

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] Agents can create isolated E2B sandboxes
- [ ] Full-stack apps scaffoldable (Vue + FastAPI + SQLite)
- [ ] Browser automation working via Playwright
- [ ] Sandbox context persists across agent turns
- [ ] Cost tracking for sandbox usage
- [ ] Execution router correctly classifies simple vs complex
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
E2B_API_KEY=e2b_...
```
