import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DataPullOrchestrator } from '../src/connectors/orchestrator.js';
import { AdapterRegistry } from '../src/connectors/adapters/registry.js';
import { MetaAdsAdapter } from '../src/connectors/adapters/meta-ads.adapter.js';
import { GoogleAdsAdapter } from '../src/connectors/adapters/google-ads.adapter.js';
import { ShopifyAdapter } from '../src/connectors/adapters/shopify.adapter.js';
import { LeadsieClient } from '../src/connectors/leadsie/client.js';

const mockLeadsieResponse = {
  allConnections: [
    {
      user: 'test_user',
      customUserId: 'org_123',
      requestUrl: 'https://app.leadsie.com/connect/openclaw',
      requestName: 'Test',
      accessLevel: 'admin' as const,
      status: 'SUCCESS' as const,
      connectionAssets: [
        { type: 'Meta Ad Account', name: 'Test', id: 'act_1', success: true, timestamp: '2026-03-03T12:00:00Z' },
        { type: 'Google Ads Account', name: 'Test', id: 'gads_1', success: true, timestamp: '2026-03-03T12:00:00Z' },
        { type: 'Shopify Store', name: 'Test', id: 'shop_1', success: true, timestamp: '2026-03-03T12:00:00Z' },
      ],
    },
  ],
};

describe('DataPullOrchestrator', () => {
  let registry: AdapterRegistry;
  let leadsieClient: LeadsieClient;
  let orchestrator: DataPullOrchestrator;

  beforeEach(() => {
    vi.restoreAllMocks();
    registry = new AdapterRegistry();

    const meta = new MetaAdsAdapter();
    const google = new GoogleAdsAdapter();
    const shopify = new ShopifyAdapter();

    // Stub pullData to return empty data (avoids "Not connected" errors)
    vi.spyOn(meta, 'pullData').mockResolvedValue({
      campaigns: [], adSets: [], ads: [], audiences: [],
      spendSummary: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD' },
    });
    vi.spyOn(google, 'pullData').mockResolvedValue({
      campaigns: [], adGroups: [], keywords: [],
      spendSummary: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD', avgCpc: 0, avgCpa: 0 },
    });
    vi.spyOn(shopify, 'pullData').mockResolvedValue({
      orders: [], products: [],
      customers: { totalCustomers: 0, returningRate: 0, avgOrderValue: 0, avgLifetimeValue: 0 },
      abandonedCarts: [], discountCodes: [],
      revenue: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD', avgOrderValue: 0 },
    });

    registry.register(meta);
    registry.register(google);
    registry.register(shopify);

    leadsieClient = new LeadsieClient({ apiKey: 'test-key' });
    orchestrator = new DataPullOrchestrator(registry, leadsieClient);
  });

  it('should pull from 3+ adapters in parallel', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify(mockLeadsieResponse), { status: 200 }),
    );

    const bundle = await orchestrator.pullAll('org_123');

    expect(bundle.orgId).toBe('org_123');
    expect(bundle.results).toHaveLength(3);
    expect(bundle.successfulPlatforms).toHaveLength(3);
    expect(bundle.failedPlatforms).toHaveLength(0);
  });

  it('should handle partial failures gracefully', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify(mockLeadsieResponse), { status: 200 }),
    );

    // Override meta adapter to throw
    const metaAdapter = registry.get('meta_ads')!;
    vi.spyOn(metaAdapter, 'pullData').mockRejectedValue(new Error('API down'));

    const bundle = await orchestrator.pullAll('org_123');

    expect(bundle.results).toHaveLength(3);
    expect(bundle.successfulPlatforms).toHaveLength(2);
    expect(bundle.failedPlatforms).toHaveLength(1);
    expect(bundle.failedPlatforms).toContain('meta_ads');
  });

  it('should handle missing adapters', async () => {
    const emptyRegistry = new AdapterRegistry();
    const orch = new DataPullOrchestrator(emptyRegistry, leadsieClient);

    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify(mockLeadsieResponse), { status: 200 }),
    );

    const bundle = await orch.pullAll('org_123');

    expect(bundle.results).toHaveLength(3);
    expect(bundle.failedPlatforms).toHaveLength(3);
    expect(bundle.successfulPlatforms).toHaveLength(0);
  });
});
