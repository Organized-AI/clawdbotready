import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('gtm-adapter');

export interface GTMConfig {
  containerId: string;
  accountId: string;
  accessToken: string;
}

export interface GTMData {
  containers: GTMContainer[];
  tags: GTMTag[];
  triggers: GTMTrigger[];
  variables: GTMVariable[];
  versions: GTMVersion[];
}

export interface GTMContainer {
  id: string;
  name: string;
  publicId: string;
  domainName: string[];
}

export interface GTMTag {
  id: string;
  name: string;
  type: string;
  firingTriggerId: string[];
  blockingTriggerId: string[];
  consentSettings?: Record<string, unknown>;
  paused: boolean;
}

export interface GTMTrigger {
  id: string;
  name: string;
  type: string;
  filter: Record<string, unknown>[];
}

export interface GTMVariable {
  id: string;
  name: string;
  type: string;
}

export interface GTMVersion {
  id: string;
  name: string;
  description: string;
  fingerprint: string;
  tagCount: number;
}

export class GTMAdapter extends BasePlatformAdapter<GTMConfig, GTMData> {
  readonly platform: PlatformType = 'google_tag_manager';
  private config?: GTMConfig;

  async connect(config: GTMConfig): Promise<ConnectionResult> {
    log.info({ containerId: config.containerId }, 'Connecting to GTM');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: config.containerId };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.containerId, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<GTMData> {
    if (!this.config) throw new PlatformConnectionError('google_tag_manager', 'Not connected');
    log.info('Pulling GTM data');

    const [containers, tags, triggers, variables, versions] = await Promise.all([
      this.fetchContainers(),
      this.fetchTags(),
      this.fetchTriggers(),
      this.fetchVariables(),
      this.fetchVersions(),
    ]);

    return { containers, tags, triggers, variables, versions };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('google_tag_manager', 'Not connected');
  }

  private async fetchContainers(): Promise<GTMContainer[]> { return []; }
  private async fetchTags(): Promise<GTMTag[]> { return []; }
  private async fetchTriggers(): Promise<GTMTrigger[]> { return []; }
  private async fetchVariables(): Promise<GTMVariable[]> { return []; }
  private async fetchVersions(): Promise<GTMVersion[]> { return []; }
}
