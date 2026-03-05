import { describe, it, expect, vi } from 'vitest';
import { AdapterRegistry } from '../src/connectors/adapters/registry.js';
import { MetaAdsAdapter } from '../src/connectors/adapters/meta-ads.adapter.js';
import { GoogleAdsAdapter } from '../src/connectors/adapters/google-ads.adapter.js';
import { GoogleAnalyticsAdapter } from '../src/connectors/adapters/google-analytics.adapter.js';
import { GTMAdapter } from '../src/connectors/adapters/gtm.adapter.js';
import { ShopifyAdapter } from '../src/connectors/adapters/shopify.adapter.js';
import { StripeAdapter } from '../src/connectors/adapters/stripe.adapter.js';
import { GoogleDriveAdapter } from '../src/connectors/adapters/google-drive.adapter.js';
import { GoogleDocsAdapter } from '../src/connectors/adapters/google-docs.adapter.js';
import { GmailAdapter } from '../src/connectors/adapters/gmail.adapter.js';
import { SlackAdapter } from '../src/connectors/adapters/slack.adapter.js';
import { WhatsAppAdapter } from '../src/connectors/adapters/whatsapp.adapter.js';

describe('Platform Adapters', () => {
  it('MetaAdsAdapter implements PlatformAdapter', () => {
    const adapter = new MetaAdsAdapter();
    expect(adapter.platform).toBe('meta_ads');
    expect(typeof adapter.connect).toBe('function');
    expect(typeof adapter.pullData).toBe('function');
    expect(typeof adapter.healthCheck).toBe('function');
    expect(typeof adapter.disconnect).toBe('function');
  });

  it('GoogleAdsAdapter implements PlatformAdapter', () => {
    const adapter = new GoogleAdsAdapter();
    expect(adapter.platform).toBe('google_ads');
  });

  it('GoogleAnalyticsAdapter implements PlatformAdapter', () => {
    const adapter = new GoogleAnalyticsAdapter();
    expect(adapter.platform).toBe('google_analytics');
  });

  it('GTMAdapter implements PlatformAdapter', () => {
    const adapter = new GTMAdapter();
    expect(adapter.platform).toBe('google_tag_manager');
  });

  it('ShopifyAdapter implements PlatformAdapter', () => {
    const adapter = new ShopifyAdapter();
    expect(adapter.platform).toBe('shopify');
  });

  it('StripeAdapter implements PlatformAdapter', () => {
    const adapter = new StripeAdapter();
    expect(adapter.platform).toBe('stripe');
  });

  it('GoogleDriveAdapter implements PlatformAdapter', () => {
    const adapter = new GoogleDriveAdapter();
    expect(adapter.platform).toBe('google_drive');
  });

  it('GoogleDocsAdapter implements PlatformAdapter', () => {
    const adapter = new GoogleDocsAdapter();
    expect(adapter.platform).toBe('google_docs');
  });

  it('GmailAdapter implements PlatformAdapter', () => {
    const adapter = new GmailAdapter();
    expect(adapter.platform).toBe('gmail');
  });

  it('SlackAdapter implements PlatformAdapter', () => {
    const adapter = new SlackAdapter();
    expect(adapter.platform).toBe('slack');
  });

  it('WhatsAppAdapter implements PlatformAdapter', () => {
    const adapter = new WhatsAppAdapter();
    expect(adapter.platform).toBe('whatsapp_business');
  });

  it('All 11 adapters can be registered', () => {
    const registry = new AdapterRegistry();
    registry.register(new MetaAdsAdapter());
    registry.register(new GoogleAdsAdapter());
    registry.register(new GoogleAnalyticsAdapter());
    registry.register(new GTMAdapter());
    registry.register(new ShopifyAdapter());
    registry.register(new StripeAdapter());
    registry.register(new GoogleDriveAdapter());
    registry.register(new GoogleDocsAdapter());
    registry.register(new GmailAdapter());
    registry.register(new SlackAdapter());
    registry.register(new WhatsAppAdapter());

    expect(registry.getPlatforms()).toHaveLength(11);
  });
});

describe('AdapterRegistry', () => {
  it('should register and retrieve adapters', () => {
    const registry = new AdapterRegistry();
    const adapter = new MetaAdsAdapter();
    registry.register(adapter);

    expect(registry.get('meta_ads')).toBe(adapter);
    expect(registry.has('meta_ads')).toBe(true);
    expect(registry.has('google_ads')).toBe(false);
  });

  it('should return all registered platforms', () => {
    const registry = new AdapterRegistry();
    registry.register(new MetaAdsAdapter());
    registry.register(new GoogleAdsAdapter());

    expect(registry.getPlatforms()).toEqual(
      expect.arrayContaining(['meta_ads', 'google_ads']),
    );
  });

  it('should health check all adapters', async () => {
    const registry = new AdapterRegistry();
    const meta = new MetaAdsAdapter();
    const google = new GoogleAdsAdapter();
    registry.register(meta);
    registry.register(google);

    const results = await registry.healthCheckAll();
    expect(results.size).toBe(2);
  });
});
