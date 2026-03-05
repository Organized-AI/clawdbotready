import type { PlatformType } from '../../shared/types.js';
import type { PlatformAdapter } from './base.js';
import { createChildLogger } from '../../shared/logger.js';

const log = createChildLogger('adapter-registry');

export class AdapterRegistry {
  private adapters = new Map<PlatformType, PlatformAdapter>();

  register(adapter: PlatformAdapter): void {
    log.info({ platform: adapter.platform }, 'Registering adapter');
    this.adapters.set(adapter.platform, adapter);
  }

  get(platform: PlatformType): PlatformAdapter | undefined {
    return this.adapters.get(platform);
  }

  has(platform: PlatformType): boolean {
    return this.adapters.has(platform);
  }

  getAll(): PlatformAdapter[] {
    return [...this.adapters.values()];
  }

  getPlatforms(): PlatformType[] {
    return [...this.adapters.keys()];
  }

  async healthCheckAll(): Promise<Map<PlatformType, boolean>> {
    const results = new Map<PlatformType, boolean>();

    const checks = [...this.adapters.entries()].map(async ([platform, adapter]) => {
      const status = await adapter.healthCheck();
      results.set(platform, status.healthy);
    });

    await Promise.allSettled(checks);
    return results;
  }
}

let defaultRegistry: AdapterRegistry | undefined;

export function getDefaultRegistry(): AdapterRegistry {
  if (!defaultRegistry) {
    defaultRegistry = new AdapterRegistry();
  }
  return defaultRegistry;
}
