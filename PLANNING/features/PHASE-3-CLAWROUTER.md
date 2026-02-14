# Phase 3: ClawRouter Model Routing

## Claude Code Prompt

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md, CLAUDE.md for context.
Verify Phases 1-2 are complete (packages/sandbox, packages/nanoclaw-bridge).

You are integrating ClawRouter (https://github.com/Organized-AI/ClawRouter) as the intelligent model routing layer for OpenClaw.

## Branch Setup
git checkout main && git pull
git checkout -b feature/clawrouter

## Tasks

### 1. Add ClawRouter to project
- git submodule add https://github.com/Organized-AI/ClawRouter.git packages/clawrouter
- Review its architecture: TypeScript, 14-dimension scoring, x402 payments
- Build and verify: cd packages/clawrouter && npm install && npm run build

### 2. Create routing integration layer
Create packages/clawrouter-bridge/src/index.ts:
- Intercept all LLM API calls from Gateway
- Score each request using ClawRouter's 14-dimension analysis:
  - reasoning markers, code presence, complexity, token estimate, etc.
- Route to cheapest capable model based on tier:
  - SIMPLE → fast/cheap models (Haiku, GPT-4o-mini, etc.)
  - MEDIUM → balanced models (Sonnet, GPT-4o, etc.)
  - COMPLEX → powerful models (Opus, GPT-4, etc.)
  - REASONING → specialized reasoning models
- Return response transparently to caller

### 3. Configure model providers
Create config/routing.env:
```
# Routing mode: standard (API keys) or x402 (crypto micropayments)
ROUTING_MODE=standard

# Standard API keys (use whichever models you want available)
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
GOOGLE_AI_KEY=
DEEPSEEK_API_KEY=
XAI_API_KEY=

# x402 crypto payments (optional, alternative to API keys)
X402_WALLET_PRIVATE_KEY=
X402_NETWORK=base

# Routing preferences
DEFAULT_TIER=MEDIUM
FALLBACK_MODEL=claude-sonnet-4-20250514
MAX_COST_PER_REQUEST_USD=0.50
COST_TRACKING_ENABLED=true
```

### 4. Implement fallback chain
- If preferred model fails (429, 500, timeout) → fall to next model in tier
- If entire tier fails → escalate to next tier
- If all models fail → return error with explanation
- Log all routing decisions for analytics

### 5. Cost tracking and reporting
Create src/cost-tracker.ts:
- Track per-request cost (tokens × price)
- Track routing decisions (which model, why)
- Daily/weekly cost summaries
- Per-customer cost breakdown (if multi-tenant)
- Output format compatible with PostHog events (Phase 6)

### 6. Customer model preferences
Create config/model-preferences.json:
```json
{
  "default": {
    "preferred_provider": "anthropic",
    "max_cost_per_day": 50.00,
    "blocked_models": [],
    "tier_overrides": {}
  }
}
```

### 7. Integration tests
Create tests/clawrouter-integration.test.ts:
- Test request classification (SIMPLE/MEDIUM/COMPLEX/REASONING)
- Test routing to correct model tier
- Test fallback chain on model failure
- Test cost tracking accuracy
- Test customer preference overrides
- Test local routing latency (<1ms)

### 8. Git commit
git add -A
git commit -m "feat: integrate ClawRouter for intelligent model routing

- 14-dimension request classification
- Route to cheapest capable model (30+ models)
- Standard API keys or x402 crypto payments
- Fallback chain for reliability
- Per-request cost tracking
- Customer model preferences

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] Requests route to cheapest capable model
- [ ] Routing happens locally in <1ms
- [ ] Cost savings visible in logs/reporting
- [ ] Fallback works when models are unavailable
- [ ] Customer can configure model preferences
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
ROUTING_MODE=standard
DEFAULT_TIER=MEDIUM
```
