import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('meta-ads-adapter');

export interface MetaAdsConfig {
  accessToken: string;
  adAccountId: string;
}

export interface MetaAdsData {
  campaigns: MetaCampaign[];
  adSets: MetaAdSet[];
  ads: MetaAd[];
  audiences: MetaAudience[];
  spendSummary: SpendSummary;
}

export interface MetaCampaign {
  id: string;
  name: string;
  status: string;
  objective: string;
  dailyBudget?: number;
  lifetimeBudget?: number;
  spend: number;
  impressions: number;
  clicks: number;
  conversions: number;
  cpa: number;
  roas: number;
}

export interface MetaAdSet {
  id: string;
  campaignId: string;
  name: string;
  status: string;
  targeting: Record<string, unknown>;
  spend: number;
  impressions: number;
}

export interface MetaAd {
  id: string;
  adSetId: string;
  name: string;
  status: string;
  creativeId: string;
  spend: number;
  impressions: number;
  clicks: number;
  frequency: number;
}

export interface MetaAudience {
  id: string;
  name: string;
  type: 'custom' | 'lookalike' | 'saved';
  size: number;
  lastUsed?: string;
}

export interface SpendSummary {
  total: number;
  last30Days: number;
  last7Days: number;
  currency: string;
}

export class MetaAdsAdapter extends BasePlatformAdapter<MetaAdsConfig, MetaAdsData> {
  readonly platform: PlatformType = 'meta_ads';
  private config?: MetaAdsConfig;

  async connect(config: MetaAdsConfig): Promise<ConnectionResult> {
    log.info({ adAccountId: config.adAccountId }, 'Connecting to Meta Ads');
    this.config = config;

    try {
      await this.ping();
      return { success: true, platformId: config.adAccountId };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.adAccountId, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<MetaAdsData> {
    if (!this.config) throw new PlatformConnectionError('meta_ads', 'Not connected');
    log.info('Pulling Meta Ads data (last 90 days)');

    const [campaigns, adSets, ads, audiences, spendSummary] = await Promise.all([
      this.fetchCampaigns(),
      this.fetchAdSets(),
      this.fetchAds(),
      this.fetchAudiences(),
      this.fetchSpendSummary(),
    ]);

    return { campaigns, adSets, ads, audiences, spendSummary };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
    log.info('Disconnected from Meta Ads');
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('meta_ads', 'Not connected');
    const resp = await fetch(
      `https://graph.facebook.com/v21.0/${this.config.adAccountId}?access_token=${this.config.accessToken}&fields=name`,
    );
    if (!resp.ok) throw new PlatformConnectionError('meta_ads', `API returned ${resp.status}`);
  }

  private async fetchCampaigns(): Promise<MetaCampaign[]> {
    // TODO: implement with real Meta Marketing API calls
    return [];
  }

  private async fetchAdSets(): Promise<MetaAdSet[]> {
    return [];
  }

  private async fetchAds(): Promise<MetaAd[]> {
    return [];
  }

  private async fetchAudiences(): Promise<MetaAudience[]> {
    return [];
  }

  private async fetchSpendSummary(): Promise<SpendSummary> {
    return { total: 0, last30Days: 0, last7Days: 0, currency: 'USD' };
  }
}
