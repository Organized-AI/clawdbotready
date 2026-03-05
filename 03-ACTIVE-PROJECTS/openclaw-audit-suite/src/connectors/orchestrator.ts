import type { PlatformType } from '../shared/types.js';
import { createChildLogger } from '../shared/logger.js';
import type { AdapterRegistry } from './adapters/registry.js';
import { groupAssetsByPlatform } from './leadsie/types.js';
import type { LeadsieClient } from './leadsie/client.js';

const log = createChildLogger('orchestrator');

export interface PlatformPullResult {
  platform: PlatformType;
  success: boolean;
  data?: unknown;
  error?: string;
  durationMs: number;
}

export interface AuditDataBundle {
  orgId: string;
  pulledAt: Date;
  results: PlatformPullResult[];
  successfulPlatforms: PlatformType[];
  failedPlatforms: PlatformType[];
}

export class DataPullOrchestrator {
  constructor(
    private readonly registry: AdapterRegistry,
    private readonly leadsieClient: LeadsieClient,
  ) {}

  async pullAll(orgId: string): Promise<AuditDataBundle> {
    log.info({ orgId }, 'Starting parallel data pull');

    const assets = await this.leadsieClient.getSuccessfulAssets(orgId);
    const platformAssets = groupAssetsByPlatform(assets);
    const platforms = [...platformAssets.keys()];

    log.info({ orgId, platforms }, 'Pulling from connected platforms');

    const pullPromises = platforms.map(async (platform): Promise<PlatformPullResult> => {
      const start = Date.now();
      const adapter = this.registry.get(platform);

      if (!adapter) {
        log.warn({ platform }, 'No adapter registered');
        return {
          platform,
          success: false,
          error: `No adapter registered for ${platform}`,
          durationMs: Date.now() - start,
        };
      }

      try {
        const data = await adapter.pullData(orgId);
        return {
          platform,
          success: true,
          data,
          durationMs: Date.now() - start,
        };
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : 'Unknown error';
        log.error({ platform, err }, 'Pull failed');
        return {
          platform,
          success: false,
          error: errorMsg,
          durationMs: Date.now() - start,
        };
      }
    });

    const results = await Promise.allSettled(pullPromises);
    const pullResults = results.map((r) =>
      r.status === 'fulfilled'
        ? r.value
        : { platform: 'meta_ads' as PlatformType, success: false, error: 'Promise rejected', durationMs: 0 },
    );

    const bundle: AuditDataBundle = {
      orgId,
      pulledAt: new Date(),
      results: pullResults,
      successfulPlatforms: pullResults.filter((r) => r.success).map((r) => r.platform),
      failedPlatforms: pullResults.filter((r) => !r.success).map((r) => r.platform),
    };

    log.info(
      {
        orgId,
        success: bundle.successfulPlatforms.length,
        failed: bundle.failedPlatforms.length,
      },
      'Data pull complete',
    );

    return bundle;
  }
}
