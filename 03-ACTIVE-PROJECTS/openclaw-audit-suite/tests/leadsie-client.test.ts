import { describe, it, expect, vi, beforeEach } from 'vitest';
import { LeadsieClient } from '../src/connectors/leadsie/client.js';

const mockSuccessResponse = {
  allConnections: [
    {
      user: 'test_user',
      customUserId: 'org_123',
      requestUrl: 'https://app.leadsie.com/connect/openclaw',
      requestName: 'OpenClaw Audit Access',
      accessLevel: 'admin' as const,
      status: 'SUCCESS' as const,
      connectionAssets: [
        {
          type: 'Meta Ad Account',
          name: 'Acme Ad Account',
          id: 'act_123456789',
          success: true,
          timestamp: '2026-03-03T12:00:00Z',
        },
        {
          type: 'Google Analytics Account',
          name: 'Acme GA4',
          id: 'properties/123456',
          success: true,
          timestamp: '2026-03-03T12:00:00Z',
        },
      ],
    },
  ],
};

const mockPartialResponse = {
  allConnections: [
    {
      user: 'test_user',
      customUserId: 'org_456',
      requestUrl: 'https://app.leadsie.com/connect/openclaw',
      requestName: 'OpenClaw Audit Access',
      accessLevel: 'view' as const,
      status: 'PARTIAL_SUCCESS' as const,
      connectionAssets: [
        {
          type: 'Meta Ad Account',
          name: 'Acme Ad Account',
          id: 'act_123456789',
          success: true,
          timestamp: '2026-03-03T12:00:00Z',
        },
        {
          type: 'Pixel',
          name: 'Acme Pixel',
          id: 'px_999',
          success: false,
          message: 'Insufficient permissions',
          timestamp: '2026-03-03T12:00:00Z',
        },
      ],
    },
  ],
};

describe('LeadsieClient', () => {
  let client: LeadsieClient;

  beforeEach(() => {
    client = new LeadsieClient({ apiKey: 'test-api-key' });
    vi.restoreAllMocks();
  });

  it('should parse a successful response', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify(mockSuccessResponse), { status: 200 }),
    );

    const connections = await client.checkUserStatus('org_123');
    expect(connections).toHaveLength(1);
    expect(connections[0]!.status).toBe('SUCCESS');
    expect(connections[0]!.connectionAssets).toHaveLength(2);
  });

  it('should filter to connected platforms only', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify(mockPartialResponse), { status: 200 }),
    );

    const connected = await client.getConnectedPlatforms('org_456');
    expect(connected).toHaveLength(1);
    expect(connected[0]!.status).toBe('PARTIAL_SUCCESS');
  });

  it('should return only successful assets', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify(mockPartialResponse), { status: 200 }),
    );

    const assets = await client.getSuccessfulAssets('org_456');
    expect(assets).toHaveLength(1);
    expect(assets[0]!.success).toBe(true);
  });

  it('should throw on API error', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response('Unauthorized', { status: 401 }),
    );

    await expect(client.checkUserStatus('org_123')).rejects.toThrow(
      'Leadsie API returned 401',
    );
  });

  it('should throw on invalid response format', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ unexpected: 'format' }), { status: 200 }),
    );

    await expect(client.checkUserStatus('org_123')).rejects.toThrow(
      'Invalid response format',
    );
  });
});
