# OpenClaw + Paperclip Integration Plan

> **Status**: Draft
> **Created**: 2026-03-08
> **Context**: Using [Paperclip](https://github.com/paperclipai/paperclip) to orchestrate OpenClaw Gateway agents as an autonomous business unit

---

## Executive Summary

**Paperclip** is an open-source AI agent orchestration platform that manages teams of agents as autonomous companies. Its tagline captures the relationship perfectly:

> "If OpenClaw is an _employee_, Paperclip is the _company_."

This plan outlines how to integrate Paperclip with our existing OpenClaw Gateway deployment to unlock multi-agent orchestration, budgeting, governance, and observability — all managed through Paperclip's dashboard.

---

## Why Paperclip + OpenClaw?

| Capability | OpenClaw Alone | OpenClaw + Paperclip |
|---|---|---|
| Single agent execution | Yes | Yes |
| Multi-agent coordination | Manual | Automated org charts |
| Budget/cost controls | None | Per-agent budgets with throttling |
| Task management | Ad-hoc | Ticket-based with threaded conversations |
| Governance | exec-approvals only | Approval gates + rollback |
| Audit trail | Logs | Immutable audit logs with tool-call tracing |
| Scheduling | Cron/manual | Heartbeat-based periodic execution |
| Dashboard | CLI only | React UI (mobile-ready) |
| Multi-tenant | Single instance | Unlimited companies with data isolation |

### The Core Value Proposition

OpenClaw handles the _runtime_ — executing agent tasks, managing messaging channels (WhatsApp, Telegram, iMessage, etc.), and enforcing security policies. Paperclip handles the _organization_ — coordinating multiple OpenClaw agents toward shared business goals with budgets, governance, and observability.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                 PAPERCLIP SERVER                      │
│            (localhost:3100 / cloud)                   │
│                                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Org Chart │  │ Budgets  │  │ Goal Hierarchies │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Tickets  │  │ Auditing │  │ Governance Gates  │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│                                                       │
│  ┌─── Agent Registry ───────────────────────────┐    │
│  │                                               │    │
│  │  ┌─────────┐ ┌─────────┐ ┌───────────────┐  │    │
│  │  │ Agent A │ │ Agent B │ │ Agent C       │  │    │
│  │  │ (Sales) │ │ (Ops)   │ │ (Engineering) │  │    │
│  │  └────┬────┘ └────┬────┘ └──────┬────────┘  │    │
│  └───────┼───────────┼─────────────┼────────────┘    │
└──────────┼───────────┼─────────────┼─────────────────┘
           │           │             │
     ┌─────▼─────┐ ┌──▼──────┐ ┌───▼─────────┐
     │ OpenClaw  │ │ OpenClaw│ │ OpenClaw    │
     │ Gateway   │ │ Gateway │ │ Gateway     │
     │ (VM #1)   │ │ (VM #2) │ │ (Native)    │
     │           │ │         │ │             │
     │ WhatsApp  │ │Telegram │ │ iMessage    │
     │ Slack     │ │ Discord │ │ WebChat     │
     └───────────┘ └─────────┘ └─────────────┘
```

Paperclip acts as the control plane. Each OpenClaw Gateway instance registers as an agent in Paperclip's registry. Paperclip dispatches tasks, enforces budgets, and tracks progress.

---

## Integration Phases

### Phase 0: Prerequisites & Local Paperclip Setup
**Goal**: Get Paperclip running alongside an existing OpenClaw Gateway instance.

**Steps**:
1. Verify Node.js 20+ and pnpm 9.15+ are installed
2. Clone Paperclip repository
3. Run `pnpm install && pnpm dev`
4. Confirm Paperclip API responds at `localhost:3100`
5. Confirm Paperclip UI loads in browser
6. Verify existing OpenClaw Gateway is healthy (port 18789)

**Validation**: Both services running simultaneously, accessible from the host.

**Estimated time**: 15-20 minutes

---

### Phase 1: Register OpenClaw as a Paperclip Agent
**Goal**: Connect OpenClaw Gateway to Paperclip's agent registry.

Paperclip supports a "Bring Your Own Agent" model. OpenClaw can be registered as an agent type with its own capabilities and constraints.

**Steps**:
1. Create a Paperclip "company" for the deployment
2. Define an agent type for OpenClaw Gateway:
   - Capabilities: messaging, tool execution, multi-channel
   - Budget constraints: token limits per model
   - Reporting structure: who this agent reports to
3. Register the running OpenClaw instance as an agent
4. Configure the connection method (HTTP or WebSocket to OpenClaw's control plane on `localhost:18789`)
5. Verify Paperclip can reach and interact with the agent

**Key Decision**: Paperclip communicates with agents via HTTP endpoints or CLI commands. We need to either:
- **Option A**: Use OpenClaw's WebSocket control plane directly (requires a thin adapter)
- **Option B**: Use HTTP bridge — a lightweight Express server that translates Paperclip HTTP calls to OpenClaw WebSocket commands
- **Option C**: Register OpenClaw as a CLI-based agent (Paperclip executes `openclaw` CLI commands)

**Recommendation**: Start with **Option C** (CLI-based) for simplicity, migrate to **Option A** for production.

**Validation**: Paperclip dashboard shows OpenClaw agent as online. Can dispatch a simple task and see it execute.

---

### Phase 2: Skills & Task Mapping
**Goal**: Map OpenClaw's capabilities into Paperclip's skill system.

**Steps**:
1. Inventory OpenClaw's installed skills (via `openclaw skills list`)
2. Create Paperclip skill definitions for each OpenClaw capability:
   - Messaging skills: send/receive on WhatsApp, Telegram, iMessage, etc.
   - Tool execution skills: code execution, file operations
   - Integration skills: Google Ads, analytics, etc.
3. Configure runtime skill injection (Paperclip can inject skills without retraining)
4. Map Paperclip tickets → OpenClaw tasks
5. Set up task deduplication (Paperclip's atomic execution prevents duplicate work)

**Validation**: Create a ticket in Paperclip, see it assigned to the OpenClaw agent, and verify it executes the correct skill.

---

### Phase 3: Budgets & Governance
**Goal**: Set up financial controls and approval workflows.

**Steps**:
1. Configure per-agent monthly budgets in Paperclip:
   - Token spend limits per model (Claude, GPT-4, etc.)
   - API call quotas for external services
2. Set up governance gates:
   - Which tasks require human approval before execution?
   - Auto-approve routine tasks (e.g., scheduled health checks)
   - Require approval for sensitive tasks (e.g., sending messages to new contacts)
3. Configure rollback policies:
   - When should a task be rolled back?
   - What constitutes a failed task?
4. Layer Paperclip governance ON TOP of OpenClaw's exec-approvals:
   - exec-approvals = runtime command-level security (deny-by-default)
   - Paperclip governance = business-level approval gates

**Validation**: Agent hits budget limit and is throttled. A governed task requires approval before proceeding.

---

### Phase 4: Observability & Dashboard
**Goal**: Full visibility into agent operations through Paperclip's UI.

**Steps**:
1. Configure Paperclip's immutable audit logging
2. Set up tool-call tracing for OpenClaw operations
3. Enable the mobile-ready dashboard
4. Create custom views:
   - Message volume by channel
   - Token spend by model
   - Task completion rate
   - Error/failure tracking
5. Set up alerting for anomalies (budget spikes, task failures, agent disconnections)
6. Integrate with existing OpenClaw health monitoring (scripts/openclaw-health-monitor.sh)

**Validation**: Dashboard shows live agent activity. Audit trail captures all tool calls. Alerts fire on test scenarios.

---

### Phase 5: Multi-Agent Orchestration
**Goal**: Deploy multiple OpenClaw agents with different roles, managed by Paperclip.

**Steps**:
1. Define the org chart:
   - **Customer Support Agent** — handles inbound WhatsApp/Telegram messages
   - **Operations Agent** — runs health checks, monitors systems
   - **Business Development Agent** — manages outbound campaigns
2. Spin up additional OpenClaw instances (VMs or native):
   - Each with its own messaging channels
   - Each with its own exec-approvals tailored to its role
3. Register all agents in Paperclip under the same company
4. Set up reporting lines and goal hierarchies
5. Configure cross-agent task delegation (one agent can create tickets for another)
6. Enable heartbeat scheduling for periodic tasks

**Validation**: Multiple agents visible in Paperclip. Tasks flow between agents. Each operates within its role's constraints.

---

### Phase 6: Production Hardening
**Goal**: Prepare the integrated stack for production use.

**Steps**:
1. Move Paperclip from embedded Postgres to external Postgres
2. Set up TLS for Paperclip API (reverse proxy or built-in)
3. Configure Paperclip behind the same SSH tunnel pattern used for OpenClaw
4. Set up backups for Paperclip's Postgres database
5. Create LaunchAgent for Paperclip auto-start on macOS
6. Add Paperclip to the health monitoring system
7. Create emergency-stop procedure that halts both Paperclip and all OpenClaw agents
8. Document the full stack for operations team

**Security Layering**:
```
Paperclip Governance ──→ Business-level approval gates
         │
OpenClaw exec-approvals ──→ Command-level deny-by-default
         │
VM/Native Isolation ──→ OS-level sandboxing
         │
Network Restrictions ──→ SSH tunnels, localhost only
```

**Validation**: Full stack survives restart. Health monitoring covers both services. Backup/restore works. Emergency stop kills everything cleanly.

---

## Deployment Topology Options

### Option A: Single-Machine (Development/Small)
```
Mac Mini (M4)
├── Paperclip Server (native, port 3100)
├── Paperclip Postgres (embedded)
└── OpenClaw Gateway (VM or native, port 18789)
```
- Simplest setup
- Good for development and small deployments
- Limited by single machine resources

### Option B: Split-Machine (Production)
```
Mac Mini #1 (Management)          Mac Mini #2+ (Workers)
├── Paperclip Server              ├── OpenClaw Gateway (VM)
├── Paperclip Postgres            ├── OpenClaw Gateway (VM)
└── Tailscale mesh                └── Tailscale mesh
```
- Paperclip on one machine, OpenClaw agents on others
- Connected via Tailscale VPN mesh
- Scales horizontally by adding worker machines

### Option C: Hybrid Cloud (Enterprise)
```
Cloud (Vercel/Railway)            Mac Mini Farm
├── Paperclip Server              ├── OpenClaw Agent #1 (VM)
├── Managed Postgres              ├── OpenClaw Agent #2 (VM)
└── Public dashboard              └── OpenClaw Agent #N (Native)
```
- Paperclip in the cloud for always-on dashboard access
- OpenClaw agents on local hardware (required for iMessage)
- Best of both worlds

**Recommendation**: Start with **Option A** for development, migrate to **Option B** when scaling.

---

## Integration Code: Agent Adapter (Phase 1)

A thin adapter script is needed to bridge Paperclip's agent protocol with OpenClaw's control plane. The initial CLI-based approach:

```bash
#!/usr/bin/env bash
# openclaw-paperclip-adapter.sh
# Bridges Paperclip task dispatch to OpenClaw Gateway execution
set -euo pipefail

TASK_ID="$1"
TASK_PAYLOAD="$2"
OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"

# Execute task via OpenClaw CLI
result=$(openclaw execute --task "$TASK_PAYLOAD" --format json 2>&1)
exit_code=$?

# Report result back to Paperclip
echo "{\"task_id\": \"$TASK_ID\", \"exit_code\": $exit_code, \"output\": $(echo "$result" | jq -Rs .)}"
```

This will evolve into a proper TypeScript adapter in Phase 5 for WebSocket-native integration.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Version conflicts (Node.js/pnpm) | Medium | Low | Pin versions, use nvm |
| Port conflicts (3100 vs 18789) | Low | Low | Different ports, no conflict |
| Paperclip API breaking changes | Medium | Medium | Pin Paperclip version, test before upgrading |
| Budget enforcement gaps | Low | High | Layer with exec-approvals as fallback |
| Data isolation between companies | Low | High | Separate Postgres schemas (built-in) |
| Network exposure | Low | Critical | SSH tunnel pattern for both services |
| Agent disconnection | Medium | Medium | Heartbeat monitoring + auto-reconnect |

---

## Success Criteria

1. **Phase 0-1**: Paperclip running, OpenClaw registered as agent, simple task executes end-to-end
2. **Phase 2-3**: Skills mapped, budgets enforced, governance gates working
3. **Phase 4**: Full dashboard visibility with audit trail
4. **Phase 5**: Multiple agents with different roles, cross-agent task delegation
5. **Phase 6**: Production-hardened, auto-starting, monitored, backed up

---

## Timeline Estimate

| Phase | Dependencies | Complexity |
|---|---|---|
| Phase 0: Prerequisites | Existing OpenClaw deployment | Low |
| Phase 1: Agent Registration | Phase 0 | Medium |
| Phase 2: Skills Mapping | Phase 1 | Medium |
| Phase 3: Budgets & Governance | Phase 1 | Low |
| Phase 4: Observability | Phase 1 | Low |
| Phase 5: Multi-Agent | Phase 2, 3, 4 | High |
| Phase 6: Production Hardening | Phase 5 | Medium |

Phases 2, 3, and 4 can run in parallel after Phase 1 is complete.

---

## Next Steps

1. Review and approve this plan
2. Verify prerequisites (Node.js 20+, pnpm 9.15+)
3. Clone Paperclip and get it running locally
4. Start Phase 0 implementation

---

## References

- [Paperclip Repository](https://github.com/paperclipai/paperclip)
- [OpenClaw Gateway Documentation](DOCUMENTATION/openclaw/)
- [VM Setup Phases](SETUP%20GUIDES/openclaw-vm-setup/PLANNING/)
- [Security Model](SETUP%20GUIDES/openclaw-vm-setup/config/exec-approvals.json)
