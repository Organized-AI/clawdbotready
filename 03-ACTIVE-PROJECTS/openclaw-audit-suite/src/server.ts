import Fastify from 'fastify';
import cors from '@fastify/cors';
import { env } from './config/env.js';
import { createChildLogger } from './shared/logger.js';
import { registerLeadsieWebhook } from './connectors/leadsie/webhook.js';
import { createLeadsieClient } from './connectors/leadsie/client.js';
import type { LeadsieConnection } from './connectors/leadsie/types.js';
import { groupAssetsByPlatform } from './connectors/leadsie/types.js';

const log = createChildLogger('server');

export async function buildServer() {
  const app = Fastify({
    logger: false,
  });

  await app.register(cors, { origin: true });

  const leadsieClient = createLeadsieClient(env.LEADSIE_API_KEY);

  // Health check
  app.get('/health', async () => ({
    status: 'ok',
    version: '0.1.0',
    uptime: process.uptime(),
  }));

  // Manual audit trigger
  app.get<{ Params: { orgId: string } }>(
    '/api/status/:orgId',
    async (request) => {
      const { orgId } = request.params;
      const connections = await leadsieClient.checkUserStatus(orgId);
      return { orgId, connections };
    },
  );

  app.post<{ Params: { orgId: string } }>(
    '/api/audit/:orgId',
    async (request) => {
      const { orgId } = request.params;
      const assets = await leadsieClient.getSuccessfulAssets(orgId);
      const platforms = groupAssetsByPlatform(assets);

      // TODO: Phase 2-3 — route to platform-specific audit engines
      return {
        orgId,
        platforms: [...platforms.keys()],
        assetCount: assets.length,
        message: 'Audit pipeline queued (engines not yet implemented)',
      };
    },
  );

  // Leadsie webhook
  registerLeadsieWebhook(app, {
    secret: env.LEADSIE_WEBHOOK_SECRET,
    onAccessGranted: async (connection: LeadsieConnection) => {
      const orgId = connection.customUserId ?? connection.user;
      log.info({ orgId, status: connection.status }, 'Access granted — queuing audit');
      // TODO: Phase 2-3 — trigger full audit pipeline
    },
    onAccessRevoked: async (connection: LeadsieConnection) => {
      const orgId = connection.customUserId ?? connection.user;
      log.info({ orgId }, 'Access revoked — marking inactive');
      // TODO: mark org connections as inactive
    },
  });

  return app;
}

export async function startServer() {
  const app = await buildServer();

  const shutdown = async () => {
    log.info('Shutting down gracefully...');
    await app.close();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);

  try {
    await app.listen({ port: env.PORT, host: '0.0.0.0' });
    log.info({ port: env.PORT }, 'OpenClaw Audit Suite running');
  } catch (err) {
    log.error({ err }, 'Failed to start server');
    process.exit(1);
  }
}

// Direct execution
const isDirectRun = process.argv[1]?.endsWith('server.ts') ||
  process.argv[1]?.endsWith('server.js');
if (isDirectRun) {
  startServer();
}
