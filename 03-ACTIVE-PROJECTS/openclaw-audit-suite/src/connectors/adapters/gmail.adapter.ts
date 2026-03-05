import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('gmail-adapter');

export interface GmailConfig {
  accessToken: string;
  refreshToken: string;
}

export interface GmailData {
  volumeMetrics: EmailVolumeMetrics;
  responseMetrics: ResponseMetrics;
  labelDistribution: LabelDistribution[];
}

export interface EmailVolumeMetrics {
  totalReceived: number;
  totalSent: number;
  avgDailyReceived: number;
  avgDailySent: number;
}

export interface ResponseMetrics {
  avgResponseTimeMinutes: number;
  medianResponseTimeMinutes: number;
  respondedWithin1Hour: number;
  respondedWithin24Hours: number;
  unanswered: number;
}

export interface LabelDistribution {
  label: string;
  count: number;
  percentage: number;
}

export class GmailAdapter extends BasePlatformAdapter<GmailConfig, GmailData> {
  readonly platform: PlatformType = 'gmail';
  private config?: GmailConfig;

  async connect(config: GmailConfig): Promise<ConnectionResult> {
    log.info('Connecting to Gmail (metadata only)');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: 'gmail' };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: 'gmail', error: message };
    }
  }

  async pullData(_connectionId: string): Promise<GmailData> {
    if (!this.config) throw new PlatformConnectionError('gmail', 'Not connected');
    log.info('Pulling Gmail metadata (last 90 days, no body content)');

    const [volumeMetrics, responseMetrics, labelDistribution] = await Promise.all([
      this.fetchVolumeMetrics(),
      this.fetchResponseMetrics(),
      this.fetchLabelDistribution(),
    ]);

    return { volumeMetrics, responseMetrics, labelDistribution };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('gmail', 'Not connected');
  }

  private async fetchVolumeMetrics(): Promise<EmailVolumeMetrics> {
    return { totalReceived: 0, totalSent: 0, avgDailyReceived: 0, avgDailySent: 0 };
  }
  private async fetchResponseMetrics(): Promise<ResponseMetrics> {
    return { avgResponseTimeMinutes: 0, medianResponseTimeMinutes: 0, respondedWithin1Hour: 0, respondedWithin24Hours: 0, unanswered: 0 };
  }
  private async fetchLabelDistribution(): Promise<LabelDistribution[]> { return []; }
}
