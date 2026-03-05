import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('google-analytics-adapter');

export interface GoogleAnalyticsConfig {
  propertyId: string;
  accessToken: string;
}

export interface GoogleAnalyticsData {
  events: GAEvent[];
  conversions: GAConversion[];
  trafficSources: GATrafficSource[];
  userProperties: GAUserProperty[];
  isGA4: boolean;
  migrationStatus: 'ga4_only' | 'ua_and_ga4' | 'ua_only';
}

export interface GAEvent {
  name: string;
  count: number;
  isConversion: boolean;
  isCustom: boolean;
}

export interface GAConversion {
  name: string;
  count: number;
  value: number;
  source: string;
}

export interface GATrafficSource {
  source: string;
  medium: string;
  sessions: number;
  conversions: number;
  bounceRate: number;
}

export interface GAUserProperty {
  name: string;
  type: string;
  isCustom: boolean;
}

export class GoogleAnalyticsAdapter extends BasePlatformAdapter<GoogleAnalyticsConfig, GoogleAnalyticsData> {
  readonly platform: PlatformType = 'google_analytics';
  private config?: GoogleAnalyticsConfig;

  async connect(config: GoogleAnalyticsConfig): Promise<ConnectionResult> {
    log.info({ propertyId: config.propertyId }, 'Connecting to Google Analytics');
    this.config = config;

    try {
      await this.ping();
      return { success: true, platformId: config.propertyId };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.propertyId, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<GoogleAnalyticsData> {
    if (!this.config) throw new PlatformConnectionError('google_analytics', 'Not connected');
    log.info('Pulling Google Analytics data (last 90 days)');

    const [events, conversions, trafficSources, userProperties] = await Promise.all([
      this.fetchEvents(),
      this.fetchConversions(),
      this.fetchTrafficSources(),
      this.fetchUserProperties(),
    ]);

    return {
      events,
      conversions,
      trafficSources,
      userProperties,
      isGA4: true,
      migrationStatus: 'ga4_only',
    };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
    log.info('Disconnected from Google Analytics');
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('google_analytics', 'Not connected');
  }

  private async fetchEvents(): Promise<GAEvent[]> { return []; }
  private async fetchConversions(): Promise<GAConversion[]> { return []; }
  private async fetchTrafficSources(): Promise<GATrafficSource[]> { return []; }
  private async fetchUserProperties(): Promise<GAUserProperty[]> { return []; }
}
