import { describe, it, expect, vi, beforeEach } from 'vitest';
import { buildServer } from '../src/server.js';

// Mock env before importing server
vi.mock('../src/config/env.js', () => ({
  env: {
    PORT: 3100,
    LEADSIE_API_KEY: 'test-api-key',
    LEADSIE_WEBHOOK_SECRET: 'test-secret',
    NODE_ENV: 'test',
    LOG_LEVEL: 'error',
  },
}));

describe('Server', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('should respond to health check', async () => {
    const app = await buildServer();

    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.payload);
    expect(body.status).toBe('ok');
    expect(body.version).toBe('0.1.0');
    expect(typeof body.uptime).toBe('number');
  });

  it('should accept webhook POST at /webhooks/leadsie', async () => {
    const app = await buildServer();

    const response = await app.inject({
      method: 'POST',
      url: '/webhooks/leadsie',
      payload: {
        user: 'test',
        requestUrl: 'https://app.leadsie.com/connect/openclaw',
        requestName: 'Test',
        accessLevel: 'admin',
        status: 'SUCCESS',
        connectionAssets: [],
      },
    });

    expect(response.statusCode).toBe(200);
  });

  it('should have status endpoint', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(
        JSON.stringify({
          allConnections: [
            {
              user: 'test',
              requestUrl: 'https://app.leadsie.com/connect/openclaw',
              requestName: 'Test',
              accessLevel: 'admin',
              status: 'SUCCESS',
              connectionAssets: [],
            },
          ],
        }),
        { status: 200 },
      ),
    );

    const app = await buildServer();

    const response = await app.inject({
      method: 'GET',
      url: '/api/status/org_123',
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.payload);
    expect(body.orgId).toBe('org_123');
  });
});
