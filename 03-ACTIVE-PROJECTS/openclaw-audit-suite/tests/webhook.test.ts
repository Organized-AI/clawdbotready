import { describe, it, expect, vi } from 'vitest';
import Fastify from 'fastify';
import { registerLeadsieWebhook } from '../src/connectors/leadsie/webhook.js';

const validPayload = {
  user: 'test_user',
  customUserId: 'org_123',
  clientName: 'Acme Corp',
  requestUrl: 'https://app.leadsie.com/connect/openclaw',
  requestName: 'OpenClaw Audit Access',
  accessLevel: 'admin',
  status: 'SUCCESS',
  connectionAssets: [
    {
      type: 'Meta Ad Account',
      name: 'Acme Ad Account',
      id: 'act_123456789',
      success: true,
      timestamp: '2026-03-03T12:00:00Z',
    },
  ],
};

describe('Leadsie Webhook Handler', () => {
  it('should accept a valid webhook payload', async () => {
    const app = Fastify();
    const onAccessGranted = vi.fn().mockResolvedValue(undefined);
    registerLeadsieWebhook(app, { onAccessGranted });

    const response = await app.inject({
      method: 'POST',
      url: '/webhooks/leadsie',
      payload: validPayload,
    });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.payload)).toEqual({ received: true });
  });

  it('should reject an invalid payload', async () => {
    const app = Fastify();
    const onAccessGranted = vi.fn();
    registerLeadsieWebhook(app, { onAccessGranted });

    const response = await app.inject({
      method: 'POST',
      url: '/webhooks/leadsie',
      payload: { invalid: 'data' },
    });

    expect(response.statusCode).toBe(400);
    expect(onAccessGranted).not.toHaveBeenCalled();
  });

  it('should reject payload with missing required fields', async () => {
    const app = Fastify();
    const onAccessGranted = vi.fn();
    registerLeadsieWebhook(app, { onAccessGranted });

    const response = await app.inject({
      method: 'POST',
      url: '/webhooks/leadsie',
      payload: { user: 'test', status: 'SUCCESS' },
    });

    expect(response.statusCode).toBe(400);
  });

  it('should call onAccessRevoked for FAILED connections', async () => {
    const app = Fastify();
    const onAccessGranted = vi.fn();
    const onAccessRevoked = vi.fn().mockResolvedValue(undefined);
    registerLeadsieWebhook(app, { onAccessGranted, onAccessRevoked });

    const failedPayload = {
      ...validPayload,
      status: 'FAILED',
      connectionAssets: [],
    };

    const response = await app.inject({
      method: 'POST',
      url: '/webhooks/leadsie',
      payload: failedPayload,
    });

    expect(response.statusCode).toBe(200);
    // Give async processing a tick
    await new Promise((r) => setTimeout(r, 50));
    expect(onAccessRevoked).toHaveBeenCalled();
    expect(onAccessGranted).not.toHaveBeenCalled();
  });
});
