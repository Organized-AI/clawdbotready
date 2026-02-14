# Phase 6: PostHog Observability

## Claude Code Prompt

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md, CLAUDE.md for context.
Read the posthog-wizard skill at .claude/skills/posthog-wizard/SKILL.md for PostHog patterns.
Verify Phases 1-5 are complete.

You are integrating PostHog (Wizard + LLM Analytics + HogAI patterns) as the observability and intelligence layer for the entire OpenClaw stack.

## Reference repos:
- https://github.com/PostHog/wizard — AI-first CLI for auto-instrumenting PostHog
- https://github.com/PostHog/posthog/tree/master/products/llm_analytics — LLM trace monitoring
- https://github.com/PostHog/posthog/tree/master/ee/hogai — HogAI MaxTool agent framework

## Branch Setup
git checkout main && git pull
git checkout -b feature/posthog-analytics

## Tasks

### 1. Auto-instrument with PostHog Wizard
- Run: npx @posthog/wizard --ci (automated mode)
- This will detect the project framework and add PostHog SDK
- Configure posthog-node for server-side tracking
- Verify events are flowing to PostHog dashboard

### 2. Create event taxonomy
Create packages/analytics/src/events.ts:
```typescript
export const EVENTS = {
  // Messaging Layer (nanoclaw)
  MESSAGE_RECEIVED: 'message_received',
  MESSAGE_SENT: 'message_sent',
  GROUP_CREATED: 'group_created',
  CHANNEL_CONNECTED: 'channel_connected',

  // Routing Layer (ClawRouter)
  MODEL_ROUTED: 'model_routed',
  MODEL_FALLBACK: 'model_fallback',
  ROUTING_COST: 'routing_cost',
  TIER_CLASSIFIED: 'tier_classified',

  // Execution Layer (just-bash + agent-sandbox)
  COMMAND_EXECUTED: 'command_executed',
  SANDBOX_CREATED: 'sandbox_created',
  SANDBOX_DESTROYED: 'sandbox_destroyed',
  EXECUTION_TIMEOUT: 'execution_timeout',

  // Tools Layer (mcporter)
  TOOL_DISCOVERED: 'tool_discovered',
  TOOL_INVOKED: 'tool_invoked',
  TOOL_FAILED: 'tool_failed',

  // System
  HEALTH_CHECK: 'health_check',
  ERROR_OCCURRED: 'error_occurred',
  DEPLOYMENT_STARTED: 'deployment_started',
} as const;
```

### 3. Instrument all layers
For each existing package, add PostHog event emission:

**packages/sandbox/** (just-bash):
- Track: commands executed, execution time, sandbox mode, errors

**packages/nanoclaw-bridge/**:
- Track: messages in/out, channel type, group context, latency

**packages/clawrouter-bridge/**:
- Track: model selected, tier classification, cost per request, fallback events

**packages/tool-registry/**:
- Track: tools discovered, tools invoked, invocation latency, errors

**packages/agent-sandbox/**:
- Track: sandboxes created/destroyed, resource usage, cost, duration

### 4. LLM Trace Integration
Create packages/analytics/src/traces.ts:
- Wrap LLM calls with trace context (inspired by PostHog LLM Analytics)
- Track: model, tokens (input/output), latency, cost, success/error
- Chain traces for multi-step agent workflows
- Support trace visualization (parent → child spans)

### 5. Customer analytics dashboard
Create packages/analytics/src/dashboard.ts:
- Use PostHog API to create dashboards programmatically
- Default dashboard includes:
  - Message volume over time
  - Model usage breakdown and cost
  - Execution stats (commands, sandboxes)
  - Error rates and types
  - Response latency percentiles

### 6. HogAI-inspired natural language queries
Create packages/analytics/src/query-agent.ts:
- Implement MaxTool pattern from HogAI:
  - Define tool metadata, args schema, execution logic
  - Natural language → PostHog query translation
  - Return formatted results
- Example queries:
  - "How many messages did we handle yesterday?"
  - "What's our model cost this week?"
  - "Which sandbox commands fail most often?"

### 7. Agent rules generation
Create packages/analytics/src/rules-generator.ts:
- Generate .cursor/rules and .claude/ context from PostHog data
- Include: usage patterns, common errors, optimization suggestions
- Auto-update on configurable interval
- Inspired by PostHog Wizard's rules generation

### 8. Anomaly alerts
Create packages/analytics/src/alerts.ts:
- Cost spike detection (>2x daily average)
- Error rate threshold (>5% of requests)
- Latency degradation (>2x p95)
- Sandbox resource exhaustion warnings
- Alert channels: PostHog, log file, webhook (configurable)

### 9. Configuration
Create config/analytics.env:
```
POSTHOG_API_KEY=phc_...
POSTHOG_HOST=https://app.posthog.com
POSTHOG_SELF_HOSTED=false
ANALYTICS_ENABLED=true
ANALYTICS_SAMPLING_RATE=1.0
TRACE_ENABLED=true
ALERT_COST_SPIKE_MULTIPLIER=2.0
ALERT_ERROR_RATE_THRESHOLD=0.05
ALERT_LATENCY_MULTIPLIER=2.0
DASHBOARD_AUTO_CREATE=true
```

### 10. Integration tests
Create tests/analytics-integration.test.ts:
- Test event emission from all layers
- Test LLM trace creation and chaining
- Test dashboard creation via API
- Test natural language query translation
- Test anomaly detection triggers
- Test rules generation output

### 11. Git commit
git add -A
git commit -m "feat: integrate PostHog observability across entire stack

- Auto-instrumented with PostHog Wizard
- Event taxonomy for all layers (messaging, routing, execution, tools)
- LLM trace monitoring with cost tracking
- Customer-facing analytics dashboard
- HogAI-inspired natural language queries
- Anomaly alerting (cost, errors, latency)
- Agent rules generation from analytics data

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] All layers emit PostHog events
- [ ] LLM traces visible in PostHog dashboard
- [ ] Customer can query analytics in natural language (HogAI pattern)
- [ ] Cost tracking across all models and providers
- [ ] Anomaly alerts configured and firing
- [ ] Agent rules generated from analytics data
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
POSTHOG_API_KEY=phc_...
POSTHOG_HOST=https://app.posthog.com
```
