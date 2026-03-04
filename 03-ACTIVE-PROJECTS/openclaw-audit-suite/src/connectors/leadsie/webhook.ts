import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { createChildLogger } from '../../shared/logger.js';
import { LeadsieConnectionSchema, groupAssetsByPlatform } from './types.js';
import type { LeadsieConnection } from './types.js';

const log = createChildLogger('leadsie-webhook');

export interface WebhookConfig {
  secret?: string;
  onAccessGranted: (connection: LeadsieConnection) => Promise<void>;
  onAccessRevoked?: (connection: LeadsieConnection) => Promise<void>;
}

export function registerLeadsieWebhook(
  app: FastifyInstance,
  config: WebhookConfig,
) {
  app.post(
    '/webhooks/leadsie',
    async (request: FastifyRequest, reply: FastifyReply) => {
      log.info('Received Leadsie webhook');

      const parsed = LeadsieConnectionSchema.safeParse(request.body);
      if (!parsed.success) {
        log.warn({ error: parsed.error }, 'Invalid webhook payload');
        return reply.status(400).send({ error: 'Invalid payload' });
      }

      const connection = parsed.data;
      log.info(
        {
          user: connection.user,
          status: connection.status,
          assets: connection.connectionAssets.length,
        },
        'Webhook payload validated',
      );

      // Return 200 immediately, process async
      void reply.status(200).send({ received: true });

      // Process in background
      try {
        if (connection.status === 'FAILED') {
          log.warn({ user: connection.user }, 'Connection failed, skipping audit');
          if (config.onAccessRevoked) {
            await config.onAccessRevoked(connection);
          }
          return;
        }

        const platforms = groupAssetsByPlatform(connection.connectionAssets);
        log.info(
          { platforms: [...platforms.keys()] },
          'Platforms identified from webhook',
        );

        await config.onAccessGranted(connection);
      } catch (err) {
        log.error({ err }, 'Error processing webhook');
      }
    },
  );
}
