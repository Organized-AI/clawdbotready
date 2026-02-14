# ClawRouter — Intelligent Model Routing

**Project:** ClawRouter Integration into OpenClaw Premium Stack
**Source:** https://github.com/Organized-AI/ClawRouter
**Priority:** P2 — Optimization Layer
**Status:** Planning
**Created:** 2026-02-12

---

## Problem

OpenClaw Gateway currently hardcodes a single model (Claude 3.5 Sonnet via OpenRouter). Every request — from "hi" to "analyze this 200-page contract" — hits the same expensive model. This wastes money on simple tasks and limits access to specialized models.

## Solution

ClawRouter sits between the Gateway and model APIs, routing each request to the cheapest capable model based on 14-dimension weighted scoring. 100% local routing (<1ms, zero API calls). Supports 30+ models across OpenAI, Anthropic, Google, DeepSeek, xAI, and local Ollama.

---

## Key Features

- **14-dimension scoring**: Analyzes request complexity, domain, length, urgency, etc.
- **4 routing tiers**: SIMPLE → MEDIUM → COMPLEX → REASONING
- **30+ model support**: OpenAI, Anthropic, Google, DeepSeek, xAI, local Ollama
- **x402 micropayments**: Optional cryptocurrency payments (USDC on Base)
- **100% local routing**: Scoring happens locally in <1ms with zero API calls
- **Average 96% cost savings**: On typical mixed workloads
- **Fallback chains**: Automatic retry on next-tier model if preferred model fails

---

## Architecture

```
Client Request
     │
     ▼
┌─────────────┐
│  OpenClaw   │
│  Gateway    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│        ClawRouter           │
│                             │
│  14-dim scoring → tier map  │
│  SIMPLE  → 3B / Haiku      │
│  MEDIUM  → 8B / Sonnet     │
│  COMPLEX → 70B / Opus      │
│  CODE    → Coder 7B        │
│                             │
│  Local mode: Ollama         │
│  Cloud mode: API keys       │
│  Hybrid: local-first + API  │
└──────┬──────────────────────┘
       │
       ▼
  Model Provider API
  (Ollama / OpenRouter / Direct)
```

---

## Integration Points

- **Gateway → ClawRouter**: Replace hardcoded Claude API calls with router
- **ClawRouter → Ollama**: Local model serving on Mac Studio / Mac Mini
- **ClawRouter → OpenRouter/Direct**: Cloud fallback for overflow or unavailable local models
- **ClawRouter → PostHog**: Cost tracking and routing decision analytics
- **ClawRouter → just-bash**: Sandbox commands still execute locally; only LLM calls route

---

## Dependencies

- **Depends on**: OpenClaw Gateway (running)
- **Optional**: Ollama (for local model serving)
- **Optional**: x402 wallet (for cryptocurrency micropayments)
- **Enhances**: nanoclaw messaging, mcporter tool discovery

---

## Success Criteria

- [ ] Requests route to cheapest capable model
- [ ] Routing happens locally in <1ms
- [ ] Cost savings visible in logs/reporting
- [ ] Fallback works when models are unavailable
- [ ] Customer can configure model preferences
- [ ] Hybrid mode: local-first with cloud overflow
