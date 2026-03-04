import { createChildLogger } from '../../shared/logger.js';
import { LeadsieApiError } from '../../shared/errors.js';
import {
  LeadsieCheckResponseSchema,
  type LeadsieConnection,
} from './types.js';

const log = createChildLogger('leadsie-client');

const LEADSIE_API_BASE = 'https://app.leadsie.com/api';

export interface LeadsieClientConfig {
  apiKey: string;
}

export class LeadsieClient {
  private readonly apiKey: string;

  constructor(config: LeadsieClientConfig) {
    this.apiKey = config.apiKey;
  }

  async checkUserStatus(customUserId: string): Promise<LeadsieConnection[]> {
    log.info({ customUserId }, 'Checking Leadsie user status');

    const response = await fetch(`${LEADSIE_API_BASE}/checkUserStatus`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        apiKey: this.apiKey,
        customUserId,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new LeadsieApiError(
        `Leadsie API returned ${response.status}: ${text}`,
        response.status,
      );
    }

    const raw: unknown = await response.json();
    const parsed = LeadsieCheckResponseSchema.safeParse(raw);

    if (!parsed.success) {
      log.error({ error: parsed.error }, 'Invalid Leadsie API response');
      throw new LeadsieApiError('Invalid response format from Leadsie API');
    }

    log.info(
      { connections: parsed.data.allConnections.length },
      'Leadsie status check complete',
    );

    return parsed.data.allConnections;
  }

  async getConnectedPlatforms(customUserId: string): Promise<LeadsieConnection[]> {
    const connections = await this.checkUserStatus(customUserId);
    return connections.filter(
      (c) => c.status === 'SUCCESS' || c.status === 'PARTIAL_SUCCESS',
    );
  }

  async getSuccessfulAssets(customUserId: string) {
    const connections = await this.getConnectedPlatforms(customUserId);
    return connections.flatMap((c) =>
      c.connectionAssets.filter((a) => a.success),
    );
  }
}

export function createLeadsieClient(apiKey: string): LeadsieClient {
  return new LeadsieClient({ apiKey });
}
