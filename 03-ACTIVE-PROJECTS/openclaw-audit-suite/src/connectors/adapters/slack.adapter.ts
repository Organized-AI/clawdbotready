import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('slack-adapter');

export interface SlackConfig {
  accessToken: string;
  teamId: string;
}

export interface SlackData {
  channels: SlackChannel[];
  integrations: SlackIntegration[];
  activityMetrics: SlackActivityMetrics;
}

export interface SlackChannel {
  id: string;
  name: string;
  memberCount: number;
  messagesLast30Days: number;
  isArchived: boolean;
  purpose: string;
}

export interface SlackIntegration {
  id: string;
  name: string;
  type: string;
  lastUsed?: string;
  isActive: boolean;
}

export interface SlackActivityMetrics {
  totalChannels: number;
  activeChannels: number;
  dormantChannels: number;
  totalIntegrations: number;
  activeIntegrations: number;
  avgMessagesPerDay: number;
}

export class SlackAdapter extends BasePlatformAdapter<SlackConfig, SlackData> {
  readonly platform: PlatformType = 'slack';
  private config?: SlackConfig;

  async connect(config: SlackConfig): Promise<ConnectionResult> {
    log.info({ teamId: config.teamId }, 'Connecting to Slack');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: config.teamId };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.teamId, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<SlackData> {
    if (!this.config) throw new PlatformConnectionError('slack', 'Not connected');
    log.info('Pulling Slack data');

    const [channels, integrations, activityMetrics] = await Promise.all([
      this.fetchChannels(),
      this.fetchIntegrations(),
      this.fetchActivityMetrics(),
    ]);

    return { channels, integrations, activityMetrics };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('slack', 'Not connected');
  }

  private async fetchChannels(): Promise<SlackChannel[]> { return []; }
  private async fetchIntegrations(): Promise<SlackIntegration[]> { return []; }
  private async fetchActivityMetrics(): Promise<SlackActivityMetrics> {
    return { totalChannels: 0, activeChannels: 0, dormantChannels: 0, totalIntegrations: 0, activeIntegrations: 0, avgMessagesPerDay: 0 };
  }
}
