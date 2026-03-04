# OpenClaw Audit Suite — Phase 0 Quick Start

## Claude Code Prompt (copy-paste directly)

```
claude --dangerously-skip-permissions
```

Then paste:

```
Read PLANNING/IMPLEMENTATION-MASTER-PLAN.md and PLANNING/implementation-phases/PHASE-0-PROMPT.md, then execute all tasks in Phase 0.

Key context:
- This is the OpenClaw Audit Suite — a sales tool that connects to customer platforms via Leadsie API, runs automated audits, and surfaces revenue opportunities in a React dashboard
- Leadsie API: POST https://app.leadsie.com/api/checkUserStatus with {apiKey, customUserId} — returns connection status and assets
- Leadsie webhooks: POST to our endpoint when client grants access — payload includes user, clientName, accessLevel (view/admin), status (SUCCESS/PARTIAL_SUCCESS/FAILED), and connectionAssets[] with type, name, id, success, timestamp
- Non-expiring access (no token refresh needed for Leadsie-native platforms)
- Tech stack: TypeScript, Fastify, Zod, Vitest
- Target repo: github.com/organized-ai/openclaw-audit-suite
- Build the project structure, Leadsie client, webhook handler, base adapter/engine interfaces, and Fastify server
- All tasks detailed in the phase prompt
```

## Environment Variables

```env
PORT=3100
LEADSIE_API_KEY=your_leadsie_api_key
LEADSIE_WEBHOOK_SECRET=your_webhook_secret
NODE_ENV=development
```

## Claude Code Web Environment Variables

```
PORT=3100
LEADSIE_API_KEY=<your_leadsie_api_key>
LEADSIE_WEBHOOK_SECRET=<your_webhook_secret>
NODE_ENV=development
```

## Project Path

```
/Users/supabowl/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/Windsurf/openclaw-audit-suite
```

## GitHub

```
Organization: organized-ai
Repo: openclaw-audit-suite
```
