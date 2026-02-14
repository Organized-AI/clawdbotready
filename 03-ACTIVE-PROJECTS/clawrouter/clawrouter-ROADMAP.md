# ClawRouter — Roadmap

**Created:** 2026-02-12

---

## Phase 1: Core Integration
- Fork/submodule ClawRouter from Organized-AI/ClawRouter
- Create `feature/clawrouter` branch
- Wire ClawRouter between OpenClaw Gateway and model APIs
- Configure 14-dimension scoring with default weights
- Set up local mode with Ollama tier mapping:
  - SIMPLE → llama3.2:3b
  - MEDIUM → llama3.1:8b
  - COMPLEX → llama3.3:70b
  - CODE → qwen2.5-coder:7b

## Phase 2: Cloud & Hybrid Modes
- Cloud mode with OpenRouter / direct API keys
- Hybrid mode: local-first, cloud fallback for overflow
- 70B queue strategy (max 2 concurrent, queue with timeout)
- Fallback chain (if preferred model fails, try next tier)

## Phase 3: Cost Tracking & Analytics
- Per-request cost logging (local = $0, cloud = actual)
- PostHog event emission for routing decisions
- Daily/weekly cost reports
- Budget limits per client profile

## Phase 4: Customer Configuration
- Per-client model preferences in client profile JSON
- Tier threshold overrides
- Cloud budget caps
- Routing mode selection (local / cloud / hybrid)

## Phase 5: Advanced Features
- x402 cryptocurrency micropayments (opt-in)
- Speculative 8B (start 8B while 70B queues)
- Time-of-day shaping for multi-timezone clients
- A/B testing between models for quality comparison
