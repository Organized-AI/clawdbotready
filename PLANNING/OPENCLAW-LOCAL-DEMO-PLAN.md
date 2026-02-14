# OpenClaw Local Demo Plan: Hardware & Setup Guide

## Hardware Comparison: Mac Studio M3 Ultra vs NVIDIA DGX Spark

### Head-to-Head Specs

| Specification | Mac Studio M3 Ultra (256GB) | NVIDIA DGX Spark |
|---|---|---|
| **Price** | ~$6,999 (256GB config) | $3,999 |
| **CPU** | 32-core (24P + 8E) Apple Silicon | 20-core Arm Neoverse (Grace) |
| **GPU** | 80-core Apple GPU (integrated) | Blackwell GPU, 6,144 CUDA cores |
| **Memory** | 256GB Unified (shared CPU/GPU) | 128GB LPDDR5x (shared CPU/GPU) |
| **Memory Bandwidth** | 819 GB/s | 273 GB/s |
| **Neural/AI Engine** | 32-core Neural Engine | 1 petaFLOP FP4 inference |
| **Storage** | 1TB–8TB SSD (configurable) | 128GB internal + NVMe expansion |
| **Power** | ~150W typical | ~250W (estimated) |
| **OS** | macOS Sequoia | Ubuntu Linux (DGX OS) |
| **Form Factor** | Compact desktop (3.7" tall) | Compact desktop |
| **Availability** | Available now | Mid-2025 (announced GTC 2025) |

### LLM Inference Performance

| Model | Mac Studio M3 Ultra | DGX Spark |
|---|---|---|
| **Llama 3.3 70B (Q4_K_M)** | 12–18 tok/s (Ollama), ~23 tok/s (MLX) | ~15 tok/s (bandwidth-limited) |
| **Llama 3.1 8B (Q4)** | 80–120 tok/s | 60–80 tok/s |
| **Mixtral 8x7B (MoE)** | ~20 tok/s | ~38 tok/s (MoE-optimized) |
| **Maximum model size** | 600B+ at 4-bit quant | 300B+ at 4-bit quant |
| **Prompt processing** | Fast (GPU parallel) | Faster (CUDA cores) |
| **Token generation** | Faster (3x bandwidth advantage) | Slower on dense models |
| **Best inference tool** | MLX / LM Studio / Ollama | TensorRT-LLM / Ollama |
| **Multi-model serving** | Yes (memory permits 2–3 models) | Limited by 128GB |

### Key Differences for OpenClaw

**Mac Studio M3 Ultra Advantages:**
- 3x memory bandwidth (819 vs 273 GB/s) — the bottleneck for token generation
- 2x RAM (256 vs 128 GB) — can load larger models or multiple models simultaneously
- macOS native — OpenClaw already targets macOS with Lume hypervisor
- Available today — DGX Spark ships mid-2025
- Mature ecosystem — MLX, LM Studio, Ollama all optimized for Apple Silicon
- Silent operation — no fans for client-facing demo environments

**DGX Spark Advantages:**
- Half the price ($3,999 vs ~$6,999)
- Superior at MoE models (Mixtral) and FP4 inference
- CUDA ecosystem — broader model compatibility for exotic architectures
- Better prompt processing throughput (useful for batch operations)
- Linkable — two DGX Sparks can NVLink together for 256GB combined
- Native Linux — no VM overhead for containerized workloads

### Recommendation

**For OpenClaw client demos: Mac Studio M3 Ultra (256GB)**

Rationale:
1. OpenClaw is built for macOS — no adaptation needed
2. 819 GB/s bandwidth delivers consistently faster token generation for the interactive demo experience clients expect
3. 256GB unified memory allows running a 70B model for "smart" tasks AND an 8B model for "fast" tasks simultaneously
4. Silent operation matters in client-facing environments
5. Lume VM isolation works natively — no need to rearchitect for Linux
6. The 256GB headroom means you can demo the full stack (Gateway + local models + monitoring) without memory pressure

**For a budget-conscious second demo station or batch processing: DGX Spark**

If budget allows both, a two-machine setup gives you a Mac Studio for interactive demos and a DGX Spark for background batch processing, MoE model experimentation, and Linux-native workloads.

---

## Local Model Strategy for Client Demos

### Model Selection: Simple Capabilities

For client test-runs, we want models that are fast, reliable, and demonstrate core capabilities without requiring massive compute.

| Role | Model | Size | Purpose | Expected Speed (M3 Ultra) |
|---|---|---|---|---|
| **Fast Responder** | Llama 3.2 3B (Q8) | ~3.5GB | Quick answers, simple tasks, chat | 150+ tok/s |
| **General Worker** | Llama 3.1 8B (Q6_K) | ~6.5GB | Code, analysis, tool use | 80–120 tok/s |
| **Smart Thinker** | Llama 3.3 70B (Q4_K_M) | ~40GB | Complex reasoning, planning | 12–23 tok/s |
| **Code Specialist** | Qwen 2.5 Coder 7B (Q6) | ~6GB | Code generation, debugging | 80–100 tok/s |
| **Embedding** | nomic-embed-text | ~275MB | RAG, semantic search | N/A (batch) |

**Total VRAM for full stack: ~56GB** — leaves 200GB headroom on the 256GB Mac Studio for OS, OpenClaw services, and monitoring.

### ClawRouter Local Tier Mapping

ClawRouter's 14-dimension scoring maps to local models:

| ClawRouter Tier | Cloud Model | Local Equivalent | When Used |
|---|---|---|---|
| SIMPLE | Haiku, GPT-4o-mini | Llama 3.2 3B | Quick answers, greetings, simple lookups |
| MEDIUM | Sonnet, GPT-4o | Llama 3.1 8B | Standard tasks, code review, analysis |
| COMPLEX | Opus, GPT-4 | Llama 3.3 70B | Deep reasoning, multi-step planning |
| REASONING | o1, DeepSeek-R1 | Llama 3.3 70B (with CoT prompt) | Math, logic, complex code |
| CODE | Claude + tools | Qwen 2.5 Coder 7B | Pure code generation tasks |

### Inference Stack

```
Ollama (primary)          — Model serving, API-compatible
├── ollama serve          — Runs on startup
├── ollama pull           — Pre-loads demo models
└── /api/chat             — OpenAI-compatible endpoint

LM Studio (backup)        — GUI for client visibility
└── Local server mode     — Same API interface

MLX (performance)         — Apple Silicon optimized
└── mlx_lm.server        — Fastest inference for Apple
```

**Primary choice: Ollama** — widest model support, OpenAI-compatible API, trivial to integrate with ClawRouter.

---

## Plugin Adaptation for OpenClaw

### Tier 1: Core Infrastructure (Bundle with every OpenClaw deployment)

| Plugin | Current Purpose | OpenClaw Adaptation |
|---|---|---|
| **boris** | Verification-first methodology | Quality gate for all agent outputs — verify before delivering to client |
| **long-runner** | Multi-context orchestration | Handle complex client requests spanning multiple turns/contexts |
| **openclaw-session-learning** | Session history analysis | Learn from past client interactions, improve over time |
| **openclaw-onboarding** | Deployment guidance | Automated setup wizard for new client environments |
| **methodology** | Dev methodology routing | Route to appropriate workflow based on task type |
| **tech-stack-orchestrator** | Stack analysis/recommendations | Analyze client infrastructure, recommend integrations |
| **phased-build** | Multi-phase execution | Break large client projects into trackable phases |
| **phase-0-template** | Project bootstrapping | Standardized project setup for client deliverables |
| **gsd-mode** | Fresh-context orchestration | Prevent context rot on long-running client tasks |

### Tier 2: Client-Facing Capabilities (Select based on client vertical)

| Plugin | Client Use Case | Vertical |
|---|---|---|
| **marketing suite** (brand-voice, campaign-planning, content-creation, competitive-analysis, performance-analytics) | Full marketing automation | Marketing agencies, brands |
| **sales suite** (account-research, call-prep, competitive-intelligence, draft-outreach, daily-briefing) | Sales enablement | Sales teams, consultancies |
| **product-management suite** (feature-spec, roadmap-management, metrics-tracking, stakeholder-comms, user-research-synthesis) | Product ops automation | SaaS companies, startups |
| **data suite** (data-exploration, data-visualization, statistical-analysis, sql-queries, interactive-dashboard-builder) | Data analysis automation | Analytics teams, data-driven orgs |

### Tier 3: Specialized Modules (Add-ons)

| Plugin | Use Case |
|---|---|
| **gtm-ai-plugin** (+ tidy-gtm, linkedin-capi-setup) | Google Tag Manager automation for martech clients |
| **blade-linkedin-plugin** | LinkedIn Insight Tag + CAPI deployment |
| **data-audit** | Meta Ads account auditing |
| **stripe** | Payment integration for SaaS clients |
| **resume-manager** | HR/recruiting use cases |
| **content-insights** | Social media analytics |
| **skill-creator-enhanced** | Custom capability development per client |

### Plugin Loading Strategy

```typescript
// config/plugins.json — per-client configuration
{
  "client_id": "demo-client-001",
  "tier": "pro",
  "core_plugins": [
    "boris", "long-runner", "methodology",
    "openclaw-session-learning", "openclaw-onboarding",
    "tech-stack-orchestrator", "phased-build", "gsd-mode"
  ],
  "vertical_plugins": ["marketing"],  // or "sales", "product", "data"
  "addon_plugins": [],                // client-specific add-ons
  "local_models": {
    "fast": "llama3.2:3b",
    "general": "llama3.1:8b",
    "smart": "llama3.3:70b",
    "code": "qwen2.5-coder:7b"
  }
}
```

---

## Local Demo Setup Procedure

### Phase A: Base Machine Setup

```bash
# 1. System requirements verified
# macOS Sequoia 15.0+, Apple Silicon M3 Ultra, 256GB RAM

# 2. Install Homebrew + core tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install node@20 pnpm git jq

# 3. Install Ollama
brew install ollama

# 4. Pull demo models (one-time, ~55GB total)
ollama pull llama3.2:3b
ollama pull llama3.1:8b
ollama pull llama3.3:70b-instruct-q4_K_M
ollama pull qwen2.5-coder:7b
ollama pull nomic-embed-text

# 5. Verify inference
ollama run llama3.2:3b "Say hello in 10 words"
```

### Phase B: OpenClaw Stack Deployment

```bash
# 1. Clone and setup
git clone https://github.com/organized-ai/clawdbot-ready.git
cd clawdbot-ready
pnpm install

# 2. Configure for local mode
cp config/local-demo.env.example .env
# Edit .env:
#   ROUTING_MODE=local
#   OLLAMA_HOST=http://localhost:11434
#   DEFAULT_TIER=MEDIUM
#   LOCAL_MODEL_FAST=llama3.2:3b
#   LOCAL_MODEL_GENERAL=llama3.1:8b
#   LOCAL_MODEL_SMART=llama3.3:70b-instruct-q4_K_M
#   LOCAL_MODEL_CODE=qwen2.5-coder:7b

# 3. Start services
pnpm run gateway:start       # OpenClaw Gateway
pnpm run sandbox:start       # just-bash execution
pnpm run router:start        # ClawRouter (local mode)
pnpm run tools:start         # mcporter tool discovery
```

### Phase C: Client Demo Script

**Demo Flow (30 minutes):**

1. **Intro (5 min)** — Show the OpenClaw dashboard, explain architecture
2. **Chat Demo (10 min)** — Client sends messages via WhatsApp/web interface
   - Simple question → routed to 3B model (instant response)
   - Code task → routed to Coder 7B (fast, accurate)
   - Complex analysis → routed to 70B (thorough, detailed)
   - Show routing decisions in real-time
3. **Tool Demo (5 min)** — Agent discovers and uses MCP tools
   - File operations via just-bash sandbox
   - Web research via available MCP servers
4. **Analytics Demo (5 min)** — PostHog dashboard showing
   - Message volume, model costs, response times
   - Natural language query: "What models did we use today?"
5. **Customization (5 min)** — Show plugin system
   - Enable marketing/sales/data vertical
   - Configure model preferences
   - Set budget limits

### Phase D: Client-Specific Configuration

```bash
# Create client profile
./scripts/create-client-profile.sh \
  --name "Acme Corp" \
  --vertical marketing \
  --tier pro \
  --budget-daily 50 \
  --models local

# This generates:
# - config/clients/acme-corp.json (plugin + model config)
# - data/clients/acme-corp/ (isolated data directory)
# - Sandbox instance (isolated execution environment)
```

---

## Service Tier Mapping (Local Demo Edition)

| Tier | Monthly Price | What's Included | Local Models |
|---|---|---|---|
| **Starter** | $997/mo | Gateway + just-bash + basic chat | 3B fast only |
| **Pro** | $2,497/mo | + nanoclaw messaging + ClawRouter + 1 vertical | 3B + 8B + 70B |
| **Premium** | $4,997/mo | + mcporter tools + E2B sandbox + PostHog + all verticals | Full model stack |
| **Enterprise** | Custom | + dedicated hardware + custom plugins + SLA | Cloud + local hybrid |

---

## Network Architecture (Local Demo)

```
┌─────────────────────────────────────────────────────────┐
│                   Mac Studio M3 Ultra                    │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Ollama      │  │  OpenClaw    │  │   PostHog    │ │
│  │  :11434       │  │  Gateway     │  │  (self-host) │ │
│  │              │  │  :3000       │  │  :8000       │ │
│  │  3B  8B  70B │  │              │  │              │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                 │                 │         │
│  ┌──────┴─────────────────┴─────────────────┴───────┐ │
│  │              Internal Network (localhost)          │ │
│  └──────┬─────────────────┬─────────────────┬───────┘ │
│         │                 │                 │         │
│  ┌──────┴───────┐  ┌─────┴──────┐  ┌──────┴───────┐ │
│  │  ClawRouter   │  │ just-bash  │  │  mcporter    │ │
│  │  (local tier) │  │ sandbox    │  │  tool disc.  │ │
│  └──────────────┘  └────────────┘  └──────────────┘ │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Lume VM (optional isolation layer)              │   │
│  │  - nanoclaw messaging containers                 │   │
│  │  - Per-client sandboxed environments             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────┴────────┐
              │   Tailscale    │
              │   (optional)   │
              └───────┬────────┘
                      │
         ┌────────────┴────────────┐
         │     Client Access       │
         │  WhatsApp / Web / API   │
         └─────────────────────────┘
```

---

## Claude Code Prompt: Local Demo Infrastructure

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md, PLANNING/OPENCLAW-LOCAL-DEMO-PLAN.md, CLAUDE.md for context.

You are building the local demo infrastructure for OpenClaw on Mac Studio M3 Ultra (256GB).

## Branch Setup
git checkout main && git pull
git checkout -b feature/local-demo-infra

## Tasks

### 1. Create Ollama integration layer
Create packages/local-inference/src/index.ts:
- OllamaClient class wrapping Ollama REST API
- Model health checking (is model loaded?)
- Auto-pull models if not present
- OpenAI-compatible API adapter
- Model switching based on ClawRouter tier decisions

### 2. Extend ClawRouter for local mode
Modify packages/clawrouter-bridge/src/index.ts:
- Add ROUTING_MODE=local configuration
- Map tiers to local Ollama models:
  - SIMPLE → llama3.2:3b
  - MEDIUM → llama3.1:8b
  - COMPLEX → llama3.3:70b
  - CODE → qwen2.5-coder:7b
- Hybrid mode: try local first, fallback to cloud API
- Track local vs cloud routing decisions

### 3. Create client profile manager
Create packages/client-manager/src/index.ts:
- CRUD for client profiles (JSON-based)
- Per-client plugin configuration
- Per-client model preferences
- Per-client budget tracking
- Isolated data directories per client

### 4. Create demo dashboard
Create packages/demo-dashboard/src/index.ts:
- Real-time model routing visualization
- Token/cost counter (local = $0, cloud = actual cost)
- Active plugins display
- Message history with routing decisions
- Serve as static HTML on :3001

### 5. Plugin loader system
Create packages/plugin-loader/src/index.ts:
- Scan available plugins from .claude/skills/ and .local-plugins/
- Load plugins based on client profile configuration
- Provide plugin manifest to Gateway
- Hot-reload plugins without restart

### 6. Demo setup script
Create scripts/setup-local-demo.sh:
- Check system requirements (macOS, Apple Silicon, RAM)
- Install Ollama if not present
- Pull required models
- Generate default .env
- Create sample client profile
- Run smoke test
- Print demo-ready status

### 7. Integration tests
Create tests/local-demo-integration.test.ts:
- Test Ollama model health checking
- Test local routing (tier → model mapping)
- Test client profile CRUD
- Test plugin loading
- Test demo dashboard serves correctly
- Test full message flow: input → route → local model → response

### 8. Git commit
git add -A
git commit -m "feat: local demo infrastructure for Mac Studio deployments

- Ollama integration layer with OpenAI-compatible API
- ClawRouter local mode (tier → local model mapping)
- Client profile manager with per-client isolation
- Real-time demo dashboard
- Plugin loader system
- Automated setup script

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] Ollama models serve responses via OpenClaw Gateway
- [ ] ClawRouter correctly routes to local models by tier
- [ ] Client profiles isolate data and plugin configurations
- [ ] Demo dashboard shows real-time routing decisions
- [ ] Setup script gets a fresh Mac Studio demo-ready
- [ ] Full message flow works end-to-end with local models
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
ROUTING_MODE=local
OLLAMA_HOST=http://localhost:11434
LOCAL_MODEL_FAST=llama3.2:3b
LOCAL_MODEL_GENERAL=llama3.1:8b
LOCAL_MODEL_SMART=llama3.3:70b-instruct-q4_K_M
LOCAL_MODEL_CODE=qwen2.5-coder:7b
```
