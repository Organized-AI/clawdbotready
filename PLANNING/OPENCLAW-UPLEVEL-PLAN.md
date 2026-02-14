# OpenClaw Uplevel Plan — Done-For-You Service

**Created:** 2026-02-09
**Project:** Clawdbot Ready → OpenClaw Premium
**Approach:** Feature branches off main, phased integration

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                   OpenClaw Premium Stack                  │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  PostHog     │  │  PostHog     │  │  PostHog       │  │
│  │  LLM         │  │  HogAI       │  │  Wizard        │  │
│  │  Analytics   │  │  (Max Agent) │  │  (Auto-Setup)  │  │
│  └──────┬───────┘  └──────┬───────┘  └───────┬────────┘  │
│         └──────────────┬──┘───────────────────┘           │
│                        │                                  │
│              ┌─────────▼──────────┐                       │
│              │   OBSERVABILITY    │                       │
│              │   LAYER            │                       │
│              └─────────┬──────────┘                       │
│                        │                                  │
│  ┌─────────────────────▼─────────────────────────┐       │
│  │              OpenClaw Gateway (Core)            │       │
│  │    VM-Isolated or Native macOS Deployment       │       │
│  └─────────────────────┬─────────────────────────┘       │
│                        │                                  │
│    ┌───────────────────┼───────────────────┐              │
│    │                   │                   │              │
│    ▼                   ▼                   ▼              │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐      │
│  │ nanoclaw │  │  ClawRouter  │  │   mcporter    │      │
│  │ Message  │  │  Model       │  │   MCP Tool    │      │
│  │ Gateway  │  │  Router      │  │   Discovery   │      │
│  └────┬─────┘  └──────┬───────┘  └───────┬───────┘      │
│       │                │                   │              │
│       │         ┌──────▼───────────────────▼──────┐      │
│       │         │      EXECUTION LAYER             │      │
│       │         │  ┌───────────┐ ┌──────────────┐ │      │
│       │         │  │ just-bash │ │ agent-sandbox │ │      │
│       │         │  │ Sandboxed │ │ E2B Isolated  │ │      │
│       │         │  │ Shell     │ │ Environments  │ │      │
│       │         │  └───────────┘ └──────────────┘ │      │
│       │         └─────────────────────────────────┘      │
│       │                                                   │
│       ▼                                                   │
│  ┌──────────────────────────────┐                        │
│  │     MESSAGING CHANNELS       │                        │
│  │  WhatsApp · iMessage · TG    │                        │
│  └──────────────────────────────┘                        │
└──────────────────────────────────────────────────────────┘
```

---

## Branch Strategy

Each feature is developed on its own branch, tested independently, then merged:

| Branch | Source Repo | Layer | Priority |
|--------|-------------|-------|----------|
| `feature/just-bash-sandbox` | Organized-AI/just-bash | Execution | P0 — Foundation |
| `feature/nanoclaw-messaging` | Organized-AI/nanoclaw | Messaging | P1 — Core |
| `feature/clawrouter` | Organized-AI/ClawRouter | Routing | P2 — Optimization |
| `feature/mcporter-tools` | Organized-AI/mcporter | Tools | P3 — Composition |
| `feature/agent-sandbox` | Organized-AI/agent-sandbox-skill | Execution | P4 — Advanced |
| `feature/posthog-analytics` | PostHog/wizard + llm_analytics + hogai | Observability | P5 — Intelligence |

---

## Integration Order & Rationale

### Phase 1: Sandboxed Execution Foundation (`feature/just-bash-sandbox`)
**Why first:** Safe command execution is the foundation everything else builds on. Agents need a sandbox before they can be trusted with tools.

**What it adds:**
- In-memory virtual bash shell for AI agents
- 60+ commands without host filesystem access
- Pipes, redirects, loops, functions, glob patterns
- Optional network access with URL allowlists
- Vercel Sandbox API compatibility
- Four filesystem modes (InMemory, Overlay, ReadWrite, Mountable)

**Integration points:**
- OpenClaw Gateway exec-approvals → just-bash as execution backend
- Replace risky shell execution with sandboxed alternative
- Create `@clawdbot-ready/sandbox` package

### Phase 2: Messaging Gateway (`feature/nanoclaw-messaging`)
**Why second:** The messaging layer is the primary user interface — customers interact with their agent through WhatsApp/iMessage/Telegram.

**What it adds:**
- WhatsApp messaging interface via nanoclaw
- Isolated group contexts with per-group memory
- Sandboxed filesystems per conversation
- Scheduled tasks (Claude runs on cron)
- Web access (search + fetch) for agents
- Container isolation (Apple Container or Docker)
- AI-native customization (via code, not config files)

**Integration points:**
- nanoclaw → OpenClaw Gateway as the agent runtime
- just-bash → nanoclaw's sandboxed execution layer
- Container isolation maps to VM-isolated deployment model

### Phase 3: Intelligent Model Routing (`feature/clawrouter`)
**Why third:** Once messaging and execution are working, optimize costs by routing to the cheapest capable model.

**What it adds:**
- 14-dimension weighted scoring for request classification
- 30+ model routing (OpenAI, Anthropic, Google, DeepSeek, xAI, etc.)
- x402 cryptocurrency micropayments (USDC on Base)
- 100% local routing (<1ms, zero API calls)
- 4 tiers: SIMPLE → MEDIUM → COMPLEX → REASONING
- Average 96% cost savings on typical workloads

**Integration points:**
- ClawRouter sits between nanoclaw/Gateway and model APIs
- Replace hardcoded Claude API calls with router
- x402 payments optional (can use standard API keys)
- Cost dashboard feeds into PostHog analytics

### Phase 4: MCP Tool Discovery (`feature/mcporter-tools`)
**Why fourth:** With execution, messaging, and routing in place, add dynamic tool discovery so agents can compose capabilities.

**What it adds:**
- Zero-config MCP server discovery from Cursor, Claude, Codex, Windsurf, VS Code
- CLI generation for any MCP server (bundled/compiled)
- TypeScript type emission (.d.ts) for type-safe tool calling
- Function-call style syntax with auto-correction
- OAuth caching and stdio/HTTP transport ergonomics
- Daemon mode for stateful servers
- Fuzzy matching and "Did you mean?" suggestions

**Integration points:**
- mcporter discovers and composes MCP tools for agents
- Agent sandbox uses mcporter to call tools type-safely
- Gateway exposes discovered tools as agent capabilities
- CLI generation enables customer-specific tooling

### Phase 5: E2B Agent Sandbox (`feature/agent-sandbox`)
**Why fifth:** Extends execution capabilities with full isolated environments — agents can scaffold, build, host, and test applications.

**What it adds:**
- E2B isolated sandbox execution environments
- Full-stack app scaffolding (Vue + FastAPI + SQLite)
- Browser automation and UI testing via Playwright
- Persistent sandbox context across agent turns
- Backslash commands: `\sandbox`, `\plan-full-stack`, `\build`, `\host`, `\test`
- Pre-built prompt templates (easy → hard complexity)

**Integration points:**
- agent-sandbox → complements just-bash for heavy workloads
- just-bash for quick commands, agent-sandbox for full-stack dev
- mcporter discovers sandbox as a tool
- PostHog tracks sandbox usage patterns

### Phase 6: PostHog Observability (`feature/posthog-analytics`)
**Why last:** Observability wraps around everything, so it needs all layers in place to instrument.

**What it adds from PostHog Wizard:**
- Auto-setup PostHog in any project via `npx @posthog/wizard`
- CI/CD mode for automated installations
- MCP server management for Claude integration
- Agent rules generation (.cursor/rules)
- Deterministic LLM prompting patterns

**What it adds from LLM Analytics:**
- Trace monitoring for LLM request/response chains
- Performance metrics (token usage, latency, error rates)
- Agent behavior pattern analysis
- Decision chain visualization

**What it adds from HogAI:**
- MaxTool framework for defining agent capabilities
- Natural language query understanding
- Execute HogQL queries, create/edit dashboards autonomously
- Session recording analysis and summarization
- Multi-step reasoning with tool use

**Integration points:**
- PostHog Wizard auto-instruments all OpenClaw components
- LLM Analytics traces ClawRouter decisions and model performance
- HogAI provides customer-facing analytics dashboard
- Every layer emits events: messaging, routing, execution, tool use

---

## Done-For-You Service Tiers

### Tier 1: OpenClaw Base (Current)
- OpenClaw Gateway deployment (VM or Native)
- Security hardening
- Basic monitoring

### Tier 2: OpenClaw Pro (Phase 1-3)
- Everything in Base
- Sandboxed execution (just-bash)
- Messaging gateway (nanoclaw → WhatsApp/iMessage/Telegram)
- Intelligent model routing (ClawRouter → 96% cost savings)

### Tier 3: OpenClaw Premium (Phase 4-6)
- Everything in Pro
- Dynamic tool discovery (mcporter)
- Full-stack agent sandbox (E2B)
- PostHog LLM Analytics dashboard
- HogAI natural language analytics
- Custom agent rules and configurations

---

## Phase Implementation Details

### Phase 1: just-bash Sandbox Integration

**Branch:** `feature/just-bash-sandbox`
**Source:** https://github.com/Organized-AI/just-bash
**Depends on:** None (foundation)

**Tasks:**
1. Fork/submodule just-bash into project
2. Create `@clawdbot-ready/sandbox` wrapper package
3. Configure InMemoryFs as default (most secure)
4. Wire sandbox into Gateway exec-approvals pipeline
5. Add URL allowlist configuration for network access
6. Create sandbox health check script
7. Write integration tests
8. Document sandbox configuration options

**Success Criteria:**
- [ ] Agents execute commands in sandbox, not host
- [ ] exec-approvals routes to sandbox by default
- [ ] Network access disabled unless allowlisted
- [ ] 60+ bash commands working in sandbox
- [ ] All existing Gateway tests still pass

---

### Phase 2: nanoclaw Messaging Integration

**Branch:** `feature/nanoclaw-messaging`
**Source:** https://github.com/Organized-AI/nanoclaw
**Depends on:** Phase 1 (sandbox)

**Tasks:**
1. Fork/submodule nanoclaw into project
2. Configure nanoclaw to use OpenClaw Gateway as runtime
3. Set up WhatsApp Business API integration
4. Configure per-group context isolation
5. Wire just-bash sandbox as execution backend
6. Set up scheduled task system
7. Configure web access with URL allowlists
8. Create messaging channel setup guides
9. Write integration tests

**Success Criteria:**
- [ ] WhatsApp messages reach agent via nanoclaw
- [ ] Each group has isolated context and filesystem
- [ ] Commands execute through just-bash sandbox
- [ ] Scheduled tasks run on configured intervals
- [ ] iMessage support working on macOS deployments

---

### Phase 3: ClawRouter Model Routing

**Branch:** `feature/clawrouter`
**Source:** https://github.com/Organized-AI/ClawRouter
**Depends on:** Phase 2 (messaging)

**Tasks:**
1. Fork/submodule ClawRouter into project
2. Configure 14-dimension scoring for request classification
3. Set up model provider API keys (or x402 wallet)
4. Wire ClawRouter between Gateway and model APIs
5. Create routing configuration UI/config file
6. Implement fallback chain (if preferred model fails)
7. Add cost tracking and reporting
8. Create model preference configuration per customer
9. Write routing integration tests

**Success Criteria:**
- [ ] Requests route to cheapest capable model
- [ ] Routing happens locally in <1ms
- [ ] Cost savings visible in logs/reporting
- [ ] Fallback works when models are unavailable
- [ ] Customer can configure model preferences

---

### Phase 4: mcporter MCP Tool Discovery

**Branch:** `feature/mcporter-tools`
**Source:** https://github.com/Organized-AI/mcporter
**Depends on:** Phase 3 (routing)

**Tasks:**
1. Fork/submodule mcporter into project
2. Configure auto-discovery for installed MCP servers
3. Generate TypeScript types for discovered tools
4. Create agent-accessible tool registry
5. Wire tool calling through ClawRouter for model selection
6. Implement daemon mode for stateful servers
7. Create customer-facing tool configuration
8. Write tool discovery integration tests

**Success Criteria:**
- [ ] Agent discovers available MCP tools automatically
- [ ] Tools are callable with type-safe interfaces
- [ ] Tool calls route through ClawRouter for cost optimization
- [ ] Stateful servers stay warm via daemon mode
- [ ] Customer can configure which tools are available

---

### Phase 5: E2B Agent Sandbox

**Branch:** `feature/agent-sandbox`
**Source:** https://github.com/Organized-AI/agent-sandbox-skill
**Depends on:** Phase 4 (tools)

**Tasks:**
1. Fork/submodule agent-sandbox-skill into project
2. Configure E2B API integration
3. Create sandbox provisioning automation
4. Wire Playwright browser automation
5. Integrate full-stack scaffolding templates
6. Connect sandbox to mcporter tool registry
7. Create sandbox management dashboard
8. Write sandbox integration tests

**Success Criteria:**
- [ ] Agents can create isolated E2B sandboxes
- [ ] Full-stack apps scaffoldable (Vue + FastAPI + SQLite)
- [ ] Browser automation working via Playwright
- [ ] Sandbox context persists across agent turns
- [ ] Cost tracking for sandbox usage

---

### Phase 6: PostHog Observability

**Branch:** `feature/posthog-analytics`
**Source:** PostHog/wizard + llm_analytics + hogai
**Depends on:** All previous phases

**Tasks:**
1. Run PostHog Wizard to instrument the stack (`npx @posthog/wizard --ci`)
2. Configure LLM Analytics for model traces
3. Set up event tracking for all layers:
   - Messaging events (messages sent/received, channels)
   - Routing events (model selection, cost, latency)
   - Execution events (commands run, sandbox usage)
   - Tool events (MCP calls, discovery, errors)
4. Create customer-facing analytics dashboard
5. Implement HogAI MaxTool patterns for natural language queries
6. Generate agent rules (.cursor/rules) for ongoing AI context
7. Set up alerts for anomalies (cost spikes, errors, latency)
8. Write analytics integration tests

**Success Criteria:**
- [ ] All layers emit PostHog events
- [ ] LLM traces visible in PostHog dashboard
- [ ] Customer can query analytics in natural language (HogAI)
- [ ] Cost tracking across all models and providers
- [ ] Anomaly alerts configured and firing

---

## Git Workflow

```bash
# For each phase:
git checkout main
git checkout -b feature/[branch-name]

# Work on feature...
# When complete:
git add .
git commit -m "feat: integrate [component] into OpenClaw"
git push origin feature/[branch-name]

# Create PR, review, merge
gh pr create --title "feat: [component] integration" --base main
```

---

## Environment Variables

```bash
# Required for all phases
ANTHROPIC_API_KEY=sk-ant-...

# Phase 2: nanoclaw
WHATSAPP_TOKEN=...
WHATSAPP_PHONE_ID=...

# Phase 3: ClawRouter (choose one)
OPENAI_API_KEY=...
GOOGLE_AI_KEY=...
DEEPSEEK_API_KEY=...
# OR for x402 payments:
WALLET_PRIVATE_KEY=...

# Phase 5: agent-sandbox
E2B_API_KEY=...

# Phase 6: PostHog
POSTHOG_API_KEY=phc_...
POSTHOG_HOST=https://app.posthog.com
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| just-bash doesn't cover all agent needs | Dual execution: just-bash for quick, agent-sandbox for heavy |
| ClawRouter x402 payments add complexity | x402 is optional — standard API keys work as fallback |
| E2B costs for agent-sandbox | Budget limits per customer, just-bash for simple tasks |
| PostHog data volume | Self-host option for high-volume, sampling for cost control |
| Branch conflicts on merge | Feature flags, integration branch, CI/CD pipeline |
| nanoclaw container isolation overlap with VM | nanoclaw containers run inside VM for defense-in-depth |

---

## Verification Checklist (Per Phase)

Before merging each branch:
- [ ] All tests pass
- [ ] Security audit performed
- [ ] Documentation updated
- [ ] Integration with previous phases verified
- [ ] Performance benchmarked
- [ ] Customer-facing configuration documented
- [ ] Rollback procedure documented
