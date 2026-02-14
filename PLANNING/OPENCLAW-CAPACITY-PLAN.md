# OpenClaw Multi-Client Capacity Plan: Mac Studio M3 Ultra (256GB)

## The Short Answer

| Clients | Feasible? | Experience Quality | Key Constraint |
|---|---|---|---|
| **5 clients** | **Yes — comfortably** | Excellent | Memory: ~95GB used, ~160GB headroom |
| **10 clients** | **Yes — with smart routing** | Good (occasional slow moments on 70B) | Inference throughput: concurrent 70B requests |
| **15+ clients** | **Possible but degraded** | Acceptable for simple tasks only | Both memory and inference saturate |

---

## Memory Budget: Where Every GB Goes

### Shared Resources (Fixed Cost — Loaded Once)

| Component | Memory | Notes |
|---|---|---|
| **macOS Sequoia + system** | 10 GB | Kernel, WindowServer, background services |
| **Ollama daemon** | 500 MB | Model server process |
| **PostHog (self-hosted)** | 3 GB | ClickHouse + Django + Redis |
| **mcporter daemon** | 100 MB | MCP tool discovery, shared across clients |
| **ClawRouter engine** | 200 MB | Scoring engine + model registry |
| **Tailscale** | 50 MB | Mesh networking for remote access |
| **Subtotal (shared)** | **~14 GB** | |

### LLM Models (Shared Pool — Loaded Into GPU Memory)

Ollama keeps models resident in unified memory. Multiple clients hitting the same model share the same loaded weights — no duplication.

| Model | VRAM | Serves Role | Concurrent Capable? |
|---|---|---|---|
| Llama 3.2 3B (Q8) | 3.5 GB | SIMPLE tier — greetings, lookups, quick Q&A | Yes (OLLAMA_NUM_PARALLEL=8) |
| Llama 3.1 8B (Q6_K) | 6.5 GB | MEDIUM tier — analysis, code review, writing | Yes (OLLAMA_NUM_PARALLEL=4) |
| Llama 3.3 70B (Q4_K_M) | 40 GB | COMPLEX tier — deep reasoning, planning | Yes (OLLAMA_NUM_PARALLEL=2) |
| Qwen 2.5 Coder 7B (Q6) | 6 GB | CODE tier — pure code generation | Yes (OLLAMA_NUM_PARALLEL=4) |
| nomic-embed-text | 0.3 GB | Embeddings for RAG / semantic search | Yes (batch) |
| **Subtotal (models)** | **~56 GB** | | |

**Critical insight:** Whether you have 1 client or 10, the model pool costs the same ~56GB. The models are shared. The scaling cost is in the per-client services below.

### Per-Client Resources

Each OpenClaw client agent runs its own isolated stack:

| Component | Memory Per Client | Notes |
|---|---|---|
| **OpenClaw Gateway process** | 150 MB | Node.js event loop, request routing |
| **Plugin runtime** | 200–400 MB | Depends on vertical loaded (see below) |
| **just-bash sandbox** | 75 MB | In-memory filesystem + command interpreter |
| **Client data cache** | 50–100 MB | Conversation history, session state |
| **Lume VM (if VM-isolated)** | 2–4 GB | Full macOS VM per client (optional) |
| **Per-client total (native)** | **~500–700 MB** | Without VM isolation |
| **Per-client total (VM mode)** | **~2.5–4.5 GB** | With Lume VM isolation |

### Plugin Memory by Vertical (Organized AI Marketplace)

Each client loads plugins based on their vertical. These run as Node.js skill modules:

| Vertical | Plugins Loaded | Memory |
|---|---|---|
| **Marketing** | brand-voice, campaign-planning, content-creation, competitive-analysis, performance-analytics | ~250 MB |
| **Sales** | account-research, call-prep, competitive-intelligence, draft-outreach, daily-briefing, create-an-asset | ~200 MB |
| **Product** | feature-spec, roadmap-management, metrics-tracking, stakeholder-comms, user-research-synthesis, competitive-analysis | ~200 MB |
| **Data** | data-exploration, data-visualization, statistical-analysis, sql-queries, interactive-dashboard-builder, data-validation | ~350 MB |
| **GTM/MarTech** | gtm-ai-plugin, tidy-gtm, linkedin-capi-setup, blade-linkedin, data-audit | ~200 MB |
| **Dev/Infrastructure** | organized-codebase-applicator, stripe, frontend-design, hookify | ~150 MB |

---

## Scenario A: 5 Simultaneous Clients

### Client Profile Mix (Realistic)

| Client | Vertical | Local Model Preference | Isolation |
|---|---|---|---|
| Client 1 | Marketing agency | 8B primary, 70B for strategy | Native |
| Client 2 | SaaS startup | Product + Data | Native |
| Client 3 | E-commerce | Sales + GTM | Native |
| Client 4 | Consultancy | Marketing + Sales | Native |
| Client 5 | Dev shop | Dev/Infrastructure | Native |

### Memory Calculation (5 Clients, Native Mode)

| Category | Memory |
|---|---|
| Shared resources | 14 GB |
| LLM model pool | 56 GB |
| 5 × Gateway (150 MB each) | 0.75 GB |
| 5 × Plugin runtime (avg 250 MB) | 1.25 GB |
| 5 × Sandbox (75 MB) | 0.375 GB |
| 5 × Data cache (75 MB avg) | 0.375 GB |
| **Total** | **~73 GB** |
| **Remaining** | **~183 GB** |
| **Utilization** | **28%** |

### Memory Calculation (5 Clients, VM-Isolated Mode)

| Category | Memory |
|---|---|
| Shared resources | 14 GB |
| LLM model pool | 56 GB |
| 5 × Lume VM (3 GB avg) | 15 GB |
| 5 × Gateway + plugins + sandbox (inside VM) | 3 GB |
| **Total** | **~88 GB** |
| **Remaining** | **~168 GB** |
| **Utilization** | **34%** |

### Inference Throughput (5 Clients)

Assuming a real workload distribution where clients don't all hit 70B simultaneously:

| Request Distribution | % of Requests | Concurrent at Peak |
|---|---|---|
| SIMPLE (3B) | 50% | 2–3 requests |
| MEDIUM (8B) | 30% | 1–2 requests |
| COMPLEX (70B) | 15% | 0–1 requests |
| CODE (7B) | 5% | 0–1 requests |

| Scenario | 3B Speed | 8B Speed | 70B Speed | User Experience |
|---|---|---|---|---|
| Best case (1 concurrent) | 150 tok/s | 100 tok/s | 20 tok/s | Excellent |
| Typical (2–3 concurrent) | 80 tok/s | 50 tok/s | 15 tok/s | Great |
| Peak (all 5 active) | 40 tok/s | 25 tok/s | 8 tok/s | Good |

**Verdict: 5 clients is very comfortable.** Memory is under 35% utilization and inference speed stays excellent for typical workloads.

---

## Scenario B: 10 Simultaneous Clients

### Memory Calculation (10 Clients, Native Mode)

| Category | Memory |
|---|---|
| Shared resources | 14 GB |
| LLM model pool | 56 GB |
| 10 × Gateway (150 MB) | 1.5 GB |
| 10 × Plugin runtime (avg 250 MB) | 2.5 GB |
| 10 × Sandbox (75 MB) | 0.75 GB |
| 10 × Data cache (75 MB) | 0.75 GB |
| **Total** | **~76 GB** |
| **Remaining** | **~180 GB** |
| **Utilization** | **30%** |

### Memory Calculation (10 Clients, VM-Isolated Mode)

| Category | Memory |
|---|---|
| Shared resources | 14 GB |
| LLM model pool | 56 GB |
| 10 × Lume VM (3 GB avg) | 30 GB |
| 10 × Gateway + plugins + sandbox (inside VM) | 6 GB |
| **Total** | **~106 GB** |
| **Remaining** | **~150 GB** |
| **Utilization** | **41%** |

### The Real Bottleneck: Inference Throughput at 10 Clients

Memory is NOT the problem — even at 10 clients with VMs, you're at 41%. The constraint is **memory bandwidth contention during concurrent inference**.

The M3 Ultra's 819 GB/s bandwidth is shared across ALL active model inference. When multiple clients generate tokens simultaneously, they split that bandwidth:

| Concurrent 70B Requests | Per-Client 70B Speed | Experience |
|---|---|---|
| 1 | 18–23 tok/s | Excellent — feels instant |
| 2 | 10–14 tok/s | Good — slight wait |
| 3 | 7–10 tok/s | Acceptable — noticeable delay |
| 4 | 5–7 tok/s | Slow — 3-4 second response starts |
| 5+ | <5 tok/s | Poor — frustrating for interactive use |

**BUT — ClawRouter is the force multiplier.** In reality, with 10 clients:

| Timeframe | Likely State |
|---|---|
| Typical moment | 3 clients idle, 4 on 3B/8B, 2 on 8B, 1 on 70B |
| Busy moment | 2 idle, 3 on 3B, 3 on 8B, 2 on 70B |
| Peak (rare) | 0 idle, 4 on 3B, 3 on 8B, 3 on 70B |

3B and 8B requests are lightweight — even 6 concurrent 3B/8B requests barely dent the bandwidth. The issue is only when 3+ clients simultaneously trigger COMPLEX (70B) tasks.

**Mitigation strategies for 10 clients:**

1. **Queue 70B requests** — ClawRouter holds a queue with max 2 concurrent 70B inferences. Clients see "Thinking deeply..." while waiting.
2. **Aggressive tier routing** — Tune ClawRouter to route more aggressively to 8B, reserving 70B for truly complex tasks.
3. **Speculative 8B** — Start generating on 8B immediately while 70B queues, show the 8B response if good enough.
4. **Time-of-day shaping** — If clients are in different time zones, natural staggering reduces peak contention.

**Verdict: 10 clients works well with smart routing.** Memory is abundant. The 70B queue strategy handles the rare moments when multiple clients need deep reasoning simultaneously.

---

## Scaling Beyond: What 15 and 20 Clients Look Like

### 15 Clients (Pushing It)

| Metric | Value |
|---|---|
| Memory (native) | ~82 GB (32% utilization) |
| Memory (VM) | ~127 GB (50% utilization) |
| 70B concurrent peak | 3–5 simultaneous |
| 70B per-client at peak | 4–6 tok/s |
| Mitigation needed | Mandatory 70B queue (max 2), aggressive 8B routing |

At 15 clients you'd want to **drop the 70B model** for interactive use and route COMPLEX tasks to cloud APIs (Claude/GPT-4) instead. Keep local models for SIMPLE and MEDIUM only:

- Revised model pool: 3B + 8B + 7B Coder + embeddings = **~16GB**
- This frees 40GB and eliminates the bandwidth bottleneck
- COMPLEX tasks go to cloud with ClawRouter's hybrid mode
- Result: 15 clients with fast local responses + cloud for heavy lifting

### 20 Clients (Two-Machine Territory)

At 20 simultaneous agents, a single Mac Studio becomes the wrong architecture. Options:

1. **Two Mac Studios** — $14K total, 10 clients each, dedicated GPU bandwidth per group
2. **Mac Studio + DGX Spark** — $11K total, Mac Studio for 10 interactive clients, DGX Spark for batch processing and MoE models
3. **Mac Studio + Cloud Hybrid** — $7K hardware + cloud budget, local for speed-sensitive tasks, cloud for overflow

---

## Recommended Configuration by Client Count

### 5 Clients: "Solo Operator"

```yaml
hardware:
  machine: Mac Studio M3 Ultra 256GB
  cost: ~$6,999

models:
  fast: llama3.2:3b           # 3.5 GB
  general: llama3.1:8b        # 6.5 GB
  smart: llama3.3:70b-q4_K_M  # 40 GB
  code: qwen2.5-coder:7b      # 6 GB
  embed: nomic-embed-text      # 0.3 GB

ollama_config:
  OLLAMA_NUM_PARALLEL: 4       # concurrent requests per model
  OLLAMA_MAX_LOADED_MODELS: 5  # keep all models resident

clawrouter:
  mode: local
  70b_max_concurrent: 2
  queue_enabled: false         # not needed at 5

isolation: native              # VMs optional, plenty of headroom
memory_utilization: ~28-34%
```

### 10 Clients: "Small Agency"

```yaml
hardware:
  machine: Mac Studio M3 Ultra 256GB
  cost: ~$6,999

models:
  fast: llama3.2:3b
  general: llama3.1:8b
  smart: llama3.3:70b-q4_K_M
  code: qwen2.5-coder:7b
  embed: nomic-embed-text

ollama_config:
  OLLAMA_NUM_PARALLEL: 3
  OLLAMA_MAX_LOADED_MODELS: 5

clawrouter:
  mode: hybrid                 # local-first, cloud fallback
  70b_max_concurrent: 2        # queue after 2 concurrent
  queue_enabled: true
  queue_timeout_ms: 15000      # 15s max wait
  fallback_to_cloud: true      # Sonnet as 70B overflow
  cloud_budget_daily: $20      # cap cloud spending

isolation: native              # save memory for models
memory_utilization: ~30-41%
```

### 15 Clients: "Growing Agency"

```yaml
hardware:
  machine: Mac Studio M3 Ultra 256GB
  cost: ~$6,999

models:
  fast: llama3.2:3b
  general: llama3.1:8b
  code: qwen2.5-coder:7b
  embed: nomic-embed-text
  # NO 70B locally — cloud only for COMPLEX

ollama_config:
  OLLAMA_NUM_PARALLEL: 6
  OLLAMA_MAX_LOADED_MODELS: 4

clawrouter:
  mode: hybrid
  complex_tier: cloud_only     # route COMPLEX to Sonnet/Opus
  cloud_budget_daily: $50
  local_models_for: [SIMPLE, MEDIUM, CODE]

isolation: native
memory_utilization: ~20-25%    # much lighter without 70B
```

### 20+ Clients: "Scale Operation"

```yaml
hardware:
  primary: Mac Studio M3 Ultra 256GB   # interactive clients
  secondary: Mac Studio M3 Ultra 256GB  # overflow + batch
  # OR: DGX Spark for batch ($3,999)
  cost: ~$11,000-14,000

load_balancer:
  strategy: round_robin_with_affinity
  max_per_machine: 10
  overflow: cloud

clawrouter:
  mode: distributed_hybrid
  local_primary: machine_1
  local_overflow: machine_2
  cloud_fallback: true
  cloud_budget_daily: $100
```

---

## Per-Client Revenue vs Hardware Cost

| Metric | 5 Clients | 10 Clients |
|---|---|---|
| Hardware cost | $6,999 (one-time) | $6,999 (one-time) |
| Monthly electricity | ~$15 (150W avg) | ~$15 |
| Cloud API overflow | $0/mo | ~$200–600/mo |
| **Total monthly opex** | **~$15** | **~$215–615** |
| Revenue (Pro tier × clients) | $12,485/mo | $24,970/mo |
| Revenue (Starter × clients) | $4,985/mo | $9,970/mo |
| **Margin (Pro tier)** | **99.8%** | **97.5%+** |
| **Hardware payback** | **< 1 month** | **< 1 month** |

The economics are outstanding. A single $7K machine serving 5 clients at $2,497/mo each generates $12,485/mo in revenue at near-zero marginal cost. Even at the Starter tier ($997/mo), payback is under 2 months.

---

## Plugin Concurrency: How the Organized AI Marketplace Plugins Scale

Each client loads their own plugin set, but plugins are stateless skill modules — they don't hold persistent processes. The flow:

```
Client request arrives
  → ClawRouter selects tier + model
  → Gateway checks which plugins are active for this client
  → Plugin skill is invoked ON DEMAND (not always running)
  → Skill generates prompt augmentation / tool calls
  → Model inference happens (shared Ollama pool)
  → Response returned
  → Plugin memory released
```

This means plugins don't multiply memory linearly per client in practice. A marketing plugin that isn't actively processing a request costs near-zero. Only the plugin that's currently handling a request for a specific client is active in memory.

**Worst case** (all 10 clients invoke heavy data plugins with pandas simultaneously): temporary spike of ~2–3GB additional. The 180GB headroom absorbs this trivially.

---

## Summary

The Mac Studio M3 Ultra (256GB) is **dramatically over-provisioned for 5 clients** and **comfortably handles 10 clients** with smart routing. Memory is never the constraint — you could load every model twice over and still have room. The only real bottleneck is concurrent 70B inference, and ClawRouter's queuing + hybrid cloud fallback solves that cleanly.

The architecture scales to 15 by dropping 70B to cloud-only, and beyond 20 by adding a second machine. At every tier, the unit economics are exceptional — hardware pays for itself in the first billing cycle.
