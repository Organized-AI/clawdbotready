import { describe, it, expect } from 'vitest';
import {
  mapAssetToPlatform,
  groupAssetsByPlatform,
  type ConnectionAsset,
} from '../src/connectors/leadsie/types.js';

describe('Asset Type Mapping', () => {
  it('should map Meta Ad Account to meta_ads', () => {
    expect(mapAssetToPlatform('Meta Ad Account')).toBe('meta_ads');
  });

  it('should map Page to meta_ads', () => {
    expect(mapAssetToPlatform('Page')).toBe('meta_ads');
  });

  it('should map Pixel to meta_ads', () => {
    expect(mapAssetToPlatform('Pixel')).toBe('meta_ads');
  });

  it('should map Google Ads Account to google_ads', () => {
    expect(mapAssetToPlatform('Google Ads Account')).toBe('google_ads');
  });

  it('should map Analytics Property to google_analytics', () => {
    expect(mapAssetToPlatform('Analytics Property')).toBe('google_analytics');
  });

  it('should map Tag Manager Container to google_tag_manager', () => {
    expect(mapAssetToPlatform('Tag Manager Container')).toBe('google_tag_manager');
  });

  it('should map Shopify Store to shopify', () => {
    expect(mapAssetToPlatform('Shopify Store')).toBe('shopify');
  });

  it('should return undefined for unknown asset types', () => {
    expect(mapAssetToPlatform('Unknown Platform')).toBeUndefined();
  });
});

describe('groupAssetsByPlatform', () => {
  it('should group assets by platform', () => {
    const assets: ConnectionAsset[] = [
      {
        type: 'Meta Ad Account',
        name: 'Account 1',
        id: 'act_1',
        success: true,
        timestamp: '2026-03-03T12:00:00Z',
      },
      {
        type: 'Page',
        name: 'Page 1',
        id: 'page_1',
        success: true,
        timestamp: '2026-03-03T12:00:00Z',
      },
      {
        type: 'Google Ads Account',
        name: 'Google Ads 1',
        id: 'gads_1',
        success: true,
        timestamp: '2026-03-03T12:00:00Z',
      },
    ];

    const grouped = groupAssetsByPlatform(assets);
    expect(grouped.get('meta_ads')).toHaveLength(2);
    expect(grouped.get('google_ads')).toHaveLength(1);
    expect(grouped.has('shopify')).toBe(false);
  });

  it('should skip unknown asset types', () => {
    const assets: ConnectionAsset[] = [
      {
        type: 'Unknown Thing',
        name: 'Mystery',
        id: 'x_1',
        success: true,
        timestamp: '2026-03-03T12:00:00Z',
      },
    ];

    const grouped = groupAssetsByPlatform(assets);
    expect(grouped.size).toBe(0);
  });

  it('should handle empty array', () => {
    const grouped = groupAssetsByPlatform([]);
    expect(grouped.size).toBe(0);
  });
});
