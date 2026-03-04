import { z } from 'zod/v4';
import type { PlatformType } from '../../shared/types.js';

export const ConnectionAssetSchema = z.object({
  type: z.string(),
  name: z.string(),
  id: z.string(),
  success: z.boolean(),
  message: z.string().optional(),
  timestamp: z.string(),
  platform: z.string().optional(),
  permissions: z.array(z.string()).optional(),
  directLink: z.string().optional(),
});

export const LeadsieConnectionSchema = z.object({
  user: z.string(),
  customUserId: z.string().optional(),
  clientName: z.string().optional(),
  requestUrl: z.string(),
  requestName: z.string(),
  accessLevel: z.enum(['view', 'admin']),
  status: z.enum(['SUCCESS', 'PARTIAL_SUCCESS', 'FAILED']),
  connectionAssets: z.array(ConnectionAssetSchema),
});

export const LeadsieCheckResponseSchema = z.object({
  allConnections: z.array(LeadsieConnectionSchema),
});

export type ConnectionAsset = z.infer<typeof ConnectionAssetSchema>;
export type LeadsieConnection = z.infer<typeof LeadsieConnectionSchema>;
export type LeadsieCheckResponse = z.infer<typeof LeadsieCheckResponseSchema>;

const assetTypeToPlatform: Record<string, PlatformType> = {
  'Meta Ad Account': 'meta_ads',
  'Ad Account': 'meta_ads',
  'Page': 'meta_ads',
  'Pixel': 'meta_ads',
  'Instagram Account': 'meta_ads',
  'Catalog': 'meta_ads',
  'Business Manager': 'meta_ads',
  'Google Ads Account': 'google_ads',
  'Ads Account': 'google_ads',
  'Google Analytics Account': 'google_analytics',
  'Analytics Property': 'google_analytics',
  'Tag Manager Container': 'google_tag_manager',
  'Tag Manager': 'google_tag_manager',
  'Shopify Store': 'shopify',
  'YouTube Channel': 'google_ads',
  'Search Console': 'google_analytics',
};

export function mapAssetToPlatform(assetType: string): PlatformType | undefined {
  return assetTypeToPlatform[assetType];
}

export function groupAssetsByPlatform(
  assets: ConnectionAsset[],
): Map<PlatformType, ConnectionAsset[]> {
  const grouped = new Map<PlatformType, ConnectionAsset[]>();

  for (const asset of assets) {
    const platform = mapAssetToPlatform(asset.type);
    if (!platform) continue;

    const existing = grouped.get(platform) ?? [];
    existing.push(asset);
    grouped.set(platform, existing);
  }

  return grouped;
}
