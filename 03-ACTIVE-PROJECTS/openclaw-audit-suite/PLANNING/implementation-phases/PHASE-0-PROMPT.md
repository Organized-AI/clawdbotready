# Phase 0: Project Setup + Leadsie Core

## Prerequisites
- Node.js 20+, pnpm
- Leadsie API key (PRO or Enterprise plan)
- GitHub: organized-ai/openclaw-audit-suite

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md

## Tasks

### Task 1: Initialize Project
```bash
mkdir openclaw-audit-suite && cd openclaw-audit-suite
pnpm init
pnpm add fastify @fastify/cors @fastify/websocket @fastify/static zod dotenv
pnpm add -D typescript @types/node tsx vitest
npx tsc --init
```

Create `tsconfig.json` with strict mode, ES2022 target, NodeNext module resolution.

### Task 2: Project Structure
```
src/
├── server.ts                    # Fastify entrypoint
├── config/
│   └── env.ts                   # Zod-validated env config
├── connectors/
│   ├── leadsie/
│   │   ├── client.ts            # Leadsie API client
│   │   ├── webhook.ts           # Webhook handler
│   │   └── types.ts             # Leadsie response types
│   └── adapters/                # Platform adapters (Phase 1)
│       └── base.ts              # Abstract adapter interface
├── engines/                     # Audit engines (Phase 2-3)
│   └── base.ts                  # Abstract engine interface
├── scoring/                     # Opportunity scorer (Phase 4)
├── dashboard/                   # React app (Phase 5)
├── reports/                     # Report generation (Phase 5)
├── proposals/                   # Agent proposals (Phase 6)
└── shared/
    ├── types.ts                 # Shared type definitions
    ├── logger.ts                # Structured logging (pino)
    └── errors.ts                # Custom error classes
```

### Task 3: Leadsie API Client
Build `src/connectors/leadsie/client.ts`:
- `checkUserStatus(customUserId: string)` → POST to `https://app.leadsie.com/api/checkUserStatus`
- Parse response into typed `LeadsieConnection[]`
- Handle `SUCCESS`, `PARTIAL_SUCCESS`, `FAILED` statuses
- Extract `connectionAssets` (Ad Account, Page, Pixel, Instagram, Catalog, etc.)
- Map each asset to internal platform enum

### Task 4: Leadsie Webhook Handler
Build `src/connectors/leadsie/webhook.ts`:
- Fastify route `POST /webhooks/leadsie`
- Validate payload signature
- On access granted: queue audit pipeline for connected platforms
- On access revoked: mark org connection as inactive
- Return 200 immediately, process async

### Task 5: Leadsie Types
Build `src/connectors/leadsie/types.ts` with Zod schemas:
```typescript
const ConnectionAsset = z.object({
  type: z.enum(['Ad Account', 'Page', 'Pixel', 'Instagram Account', 'Catalog', 'Tag Manager', 'Analytics Property', 'Shopify Store']),
  name: z.string(),
  id: z.string(),
  success: z.boolean(),
  message: z.string().optional(),
  timestamp: z.string()
});

const LeadsieConnection = z.object({
  user: z.string(),
  customUserId: z.string().optional(),
  requestUrl: z.string(),
  requestName: z.string(),
  accessLevel: z.enum(['view', 'admin']),
  status: z.enum(['SUCCESS', 'PARTIAL_SUCCESS', 'FAILED']),
  connectionAssets: z.array(ConnectionAsset)
});
```

### Task 6: Base Adapter Interface
Build `src/connectors/adapters/base.ts`:
```typescript
export interface PlatformAdapter<TConfig, TData> {
  platform: PlatformType;
  connect(config: TConfig): Promise<ConnectionResult>;
  pullData(connectionId: string): Promise<TData>;
  healthCheck(): Promise<HealthStatus>;
  disconnect(connectionId: string): Promise<void>;
}
```

### Task 7: Base Engine Interface
Build `src/engines/base.ts`:
```typescript
export interface AuditEngine<TData, TFindings> {
  platform: PlatformType;
  audit(data: TData): Promise<AuditResult<TFindings>>;
  scoreFinding(finding: TFindings): OpportunityScore;
}

export interface OpportunityScore {
  category: 'revenue_saving' | 'revenue_generating';
  confidence: number;        // 0-1
  estimatedImpact: {
    low: number;             // USD annually
    mid: number;
    high: number;
  };
  effort: 'low' | 'medium' | 'high';
  agentCapability: string;   // Which OpenClaw agent handles this
}
```

### Task 8: Fastify Server
Build `src/server.ts`:
- Register CORS, WebSocket, Static plugins
- Mount `/webhooks/leadsie` route
- Mount `/api/audit/:orgId` route (trigger manual audit)
- Mount `/api/status/:orgId` route (check connection status)
- Health check at `/health`
- Graceful shutdown

### Task 9: Environment Config
Build `src/config/env.ts` with Zod:
```typescript
const EnvSchema = z.object({
  PORT: z.coerce.number().default(3100),
  LEADSIE_API_KEY: z.string(),
  LEADSIE_WEBHOOK_SECRET: z.string().optional(),
  DATABASE_URL: z.string().optional(),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});
```

### Task 10: Tests
Write vitest tests for:
- Leadsie client with mocked responses
- Webhook handler payload validation
- Connection asset type mapping

## Success Criteria
- [ ] `pnpm build` compiles without errors
- [ ] `pnpm test` passes all tests
- [ ] Leadsie client correctly parses sample API response
- [ ] Webhook handler accepts valid payloads and rejects invalid ones
- [ ] Server starts and responds to health check
- [ ] Abstract adapter and engine interfaces exported correctly

## Completion
```bash
git add -A && git commit -m "Phase 0: Project setup + Leadsie core connector"
```
Create `PLANNING/PHASE-0-COMPLETE.md` with summary of what was built.
