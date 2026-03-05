import { describe, it, expect } from 'vitest';
import { MetaAdsAuditEngine } from '../src/engines/meta-ads.engine.js';
import { GoogleAdsAuditEngine } from '../src/engines/google-ads.engine.js';
import { GoogleAnalyticsAuditEngine } from '../src/engines/google-analytics.engine.js';
import { GTMAuditEngine } from '../src/engines/gtm.engine.js';
import { ShopifyAuditEngine } from '../src/engines/shopify.engine.js';
import type { MetaAdsData } from '../src/connectors/adapters/meta-ads.adapter.js';
import type { GoogleAdsData } from '../src/connectors/adapters/google-ads.adapter.js';
import type { GoogleAnalyticsData } from '../src/connectors/adapters/google-analytics.adapter.js';
import type { GTMData } from '../src/connectors/adapters/gtm.adapter.js';
import type { ShopifyData } from '../src/connectors/adapters/shopify.adapter.js';

describe('MetaAdsAuditEngine', () => {
  const engine = new MetaAdsAuditEngine();

  it('should handle empty data gracefully', async () => {
    const emptyData: MetaAdsData = {
      campaigns: [], adSets: [], ads: [], audiences: [],
      spendSummary: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD' },
    };

    const result = await engine.audit(emptyData, 'org_test');
    expect(result.orgId).toBe('org_test');
    expect(result.platform).toBe('meta_ads');
    expect(result.findings).toBeDefined();
  });

  it('should detect creative fatigue', async () => {
    const data: MetaAdsData = {
      campaigns: [],
      adSets: [],
      ads: [{
        id: 'ad_1', adSetId: 'as_1', name: 'High Freq Ad', status: 'ACTIVE',
        creativeId: 'cr_1', spend: 500, impressions: 10000, clicks: 200, frequency: 7.5,
      }],
      audiences: [],
      spendSummary: { total: 500, last30Days: 500, last7Days: 200, currency: 'USD' },
    };

    const result = await engine.audit(data, 'org_test');
    const fatigue = result.findings.filter((f) => f.id.includes('fatigue'));
    expect(fatigue.length).toBeGreaterThan(0);
    expect(fatigue[0]!.score.category).toBe('revenue_saving');
  });

  it('should detect missing lookalike audiences', async () => {
    const data: MetaAdsData = {
      campaigns: [],
      adSets: [],
      ads: [],
      audiences: [
        { id: 'aud_1', name: 'Purchasers', type: 'custom', size: 5000 },
      ],
      spendSummary: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD' },
    };

    const result = await engine.audit(data, 'org_test');
    const lookalike = result.findings.find((f) => f.id === 'meta_no_lookalike');
    expect(lookalike).toBeDefined();
    expect(lookalike!.score.category).toBe('revenue_generating');
  });
});

describe('GoogleAdsAuditEngine', () => {
  const engine = new GoogleAdsAuditEngine();

  it('should handle empty data gracefully', async () => {
    const emptyData: GoogleAdsData = {
      campaigns: [], adGroups: [], keywords: [],
      spendSummary: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD', avgCpc: 0, avgCpa: 0 },
    };

    const result = await engine.audit(emptyData, 'org_test');
    expect(result.findings).toBeDefined();
  });

  it('should detect low quality score keywords', async () => {
    const data: GoogleAdsData = {
      campaigns: [],
      adGroups: [],
      keywords: [
        { id: 'k1', adGroupId: 'ag1', text: 'bad keyword', matchType: 'BROAD', qualityScore: 2, impressions: 1000, clicks: 10, spend: 500, status: 'ENABLED' },
        { id: 'k2', adGroupId: 'ag1', text: 'good keyword', matchType: 'EXACT', qualityScore: 9, impressions: 5000, clicks: 200, spend: 300, status: 'ENABLED' },
      ],
      spendSummary: { total: 800, last30Days: 800, last7Days: 200, currency: 'USD', avgCpc: 2.5, avgCpa: 40 },
    };

    const result = await engine.audit(data, 'org_test');
    const qsFindings = result.findings.filter((f) => f.id.includes('qs'));
    expect(qsFindings.length).toBeGreaterThan(0);
  });
});

describe('GoogleAnalyticsAuditEngine', () => {
  const engine = new GoogleAnalyticsAuditEngine();

  it('should detect broken conversion events', async () => {
    const data: GoogleAnalyticsData = {
      events: [
        { name: 'purchase', count: 0, isConversion: true, isCustom: false },
        { name: 'page_view', count: 5000, isConversion: false, isCustom: false },
      ],
      conversions: [],
      trafficSources: [],
      userProperties: [],
      isGA4: true,
      migrationStatus: 'ga4_only',
    };

    const result = await engine.audit(data, 'org_test');
    const brokenEvents = result.findings.find((f) => f.id === 'ga_broken_events');
    expect(brokenEvents).toBeDefined();
    expect(brokenEvents!.severity).toBe('critical');
  });

  it('should detect high direct traffic', async () => {
    const data: GoogleAnalyticsData = {
      events: [],
      conversions: [],
      trafficSources: [
        { source: '(direct)', medium: '(none)', sessions: 6000, conversions: 10, bounceRate: 0.3 },
        { source: 'google', medium: 'organic', sessions: 3000, conversions: 20, bounceRate: 0.4 },
        { source: 'facebook', medium: 'cpc', sessions: 1000, conversions: 5, bounceRate: 0.5 },
      ],
      userProperties: [],
      isGA4: true,
      migrationStatus: 'ga4_only',
    };

    const result = await engine.audit(data, 'org_test');
    const directFinding = result.findings.find((f) => f.id === 'ga_high_direct');
    expect(directFinding).toBeDefined();
  });
});

describe('GTMAuditEngine', () => {
  const engine = new GTMAuditEngine();

  it('should detect tags without consent settings', async () => {
    const data: GTMData = {
      containers: [],
      tags: [
        { id: 't1', name: 'GA4', type: 'Google Analytics', firingTriggerId: ['1'], blockingTriggerId: [], paused: false },
        { id: 't2', name: 'Meta Pixel', type: 'Custom HTML', firingTriggerId: ['1'], blockingTriggerId: [], paused: false },
      ],
      triggers: [],
      variables: [],
      versions: [],
    };

    const result = await engine.audit(data, 'org_test');
    const consent = result.findings.find((f) => f.id === 'gtm_no_consent');
    expect(consent).toBeDefined();
    expect(consent!.severity).toBe('critical');
  });

  it('should handle empty GTM data', async () => {
    const data: GTMData = { containers: [], tags: [], triggers: [], variables: [], versions: [] };
    const result = await engine.audit(data, 'org_test');
    expect(result.findings).toHaveLength(0);
  });
});

describe('ShopifyAuditEngine', () => {
  const engine = new ShopifyAuditEngine();

  it('should detect abandoned carts', async () => {
    const data: ShopifyData = {
      orders: [],
      products: [],
      customers: { totalCustomers: 100, returningRate: 0.2, avgOrderValue: 50, avgLifetimeValue: 75 },
      abandonedCarts: [
        { id: 'c1', totalPrice: 100, createdAt: '2026-03-01', recoveryUrl: 'https://...', recovered: false },
        { id: 'c2', totalPrice: 200, createdAt: '2026-03-02', recoveryUrl: 'https://...', recovered: false },
      ],
      discountCodes: [],
      revenue: { total: 10000, last30Days: 5000, last7Days: 1500, currency: 'USD', avgOrderValue: 50 },
    };

    const result = await engine.audit(data, 'org_test');
    const cartFinding = result.findings.find((f) => f.id === 'shopify_abandoned_carts');
    expect(cartFinding).toBeDefined();
    expect(cartFinding!.score.category).toBe('revenue_generating');
  });

  it('should detect dead inventory', async () => {
    const data: ShopifyData = {
      orders: [],
      products: [
        { id: 'p1', title: 'Dead Product', status: 'active', inventoryQuantity: 50, variants: 1, totalSold: 0, revenue: 0 },
      ],
      customers: { totalCustomers: 0, returningRate: 0, avgOrderValue: 0, avgLifetimeValue: 0 },
      abandonedCarts: [],
      discountCodes: [],
      revenue: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD', avgOrderValue: 0 },
    };

    const result = await engine.audit(data, 'org_test');
    const dead = result.findings.find((f) => f.id === 'shopify_dead_inventory');
    expect(dead).toBeDefined();
  });

  it('should handle empty Shopify data', async () => {
    const data: ShopifyData = {
      orders: [], products: [],
      customers: { totalCustomers: 0, returningRate: 0, avgOrderValue: 0, avgLifetimeValue: 0 },
      abandonedCarts: [], discountCodes: [],
      revenue: { total: 0, last30Days: 0, last7Days: 0, currency: 'USD', avgOrderValue: 0 },
    };

    const result = await engine.audit(data, 'org_test');
    expect(result.findings).toHaveLength(0);
  });
});

describe('Audit Summary Calculations', () => {
  it('should correctly categorize revenue_saving vs revenue_generating', async () => {
    const engine = new MetaAdsAuditEngine();
    const data: MetaAdsData = {
      campaigns: [],
      adSets: [],
      ads: [
        { id: 'ad_1', adSetId: 'as_1', name: 'Fatigued Ad', status: 'ACTIVE', creativeId: 'cr_1', spend: 500, impressions: 10000, clicks: 200, frequency: 8 },
      ],
      audiences: [
        { id: 'aud_1', name: 'Buyers', type: 'custom', size: 5000 },
      ],
      spendSummary: { total: 500, last30Days: 500, last7Days: 200, currency: 'USD' },
    };

    const result = await engine.audit(data, 'org_test');
    expect(result.summary.revenueSaving).toBeGreaterThan(0);
    expect(result.summary.revenueGenerating).toBeGreaterThan(0);
    expect(result.summary.totalFindings).toBe(result.summary.revenueSaving + result.summary.revenueGenerating);
  });
});
