import type { PlatformType, ConnectionResult, HealthStatus } from '../../shared/types.js';

export interface PlatformAdapter<TConfig = unknown, TData = unknown> {
  readonly platform: PlatformType;
  connect(config: TConfig): Promise<ConnectionResult>;
  pullData(connectionId: string): Promise<TData>;
  healthCheck(): Promise<HealthStatus>;
  disconnect(connectionId: string): Promise<void>;
}

export abstract class BasePlatformAdapter<TConfig = unknown, TData = unknown>
  implements PlatformAdapter<TConfig, TData>
{
  abstract readonly platform: PlatformType;

  abstract connect(config: TConfig): Promise<ConnectionResult>;
  abstract pullData(connectionId: string): Promise<TData>;
  abstract disconnect(connectionId: string): Promise<void>;

  async healthCheck(): Promise<HealthStatus> {
    const start = Date.now();
    try {
      await this.ping();
      return {
        platform: this.platform,
        healthy: true,
        latencyMs: Date.now() - start,
        lastChecked: new Date(),
      };
    } catch (err) {
      return {
        platform: this.platform,
        healthy: false,
        latencyMs: Date.now() - start,
        lastChecked: new Date(),
        error: err instanceof Error ? err.message : 'Unknown error',
      };
    }
  }

  protected abstract ping(): Promise<void>;
}
