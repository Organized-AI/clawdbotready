import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('google-docs-adapter');

export interface GoogleDocsConfig {
  accessToken: string;
  refreshToken: string;
}

export interface GoogleDocsData {
  documents: DocSummary[];
  contentMetrics: ContentMetrics;
}

export interface DocSummary {
  id: string;
  title: string;
  lastModified: string;
  wordCount: number;
  collaborators: number;
  isTemplate: boolean;
}

export interface ContentMetrics {
  totalDocuments: number;
  staleDocuments: number;
  avgLastModifiedDays: number;
  templateCount: number;
}

export class GoogleDocsAdapter extends BasePlatformAdapter<GoogleDocsConfig, GoogleDocsData> {
  readonly platform: PlatformType = 'google_docs';
  private config?: GoogleDocsConfig;

  async connect(config: GoogleDocsConfig): Promise<ConnectionResult> {
    log.info('Connecting to Google Docs');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: 'docs' };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: 'docs', error: message };
    }
  }

  async pullData(_connectionId: string): Promise<GoogleDocsData> {
    if (!this.config) throw new PlatformConnectionError('google_docs', 'Not connected');
    log.info('Pulling Google Docs data');

    const [documents, contentMetrics] = await Promise.all([
      this.fetchDocuments(),
      this.fetchContentMetrics(),
    ]);

    return { documents, contentMetrics };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('google_docs', 'Not connected');
  }

  private async fetchDocuments(): Promise<DocSummary[]> { return []; }
  private async fetchContentMetrics(): Promise<ContentMetrics> {
    return { totalDocuments: 0, staleDocuments: 0, avgLastModifiedDays: 0, templateCount: 0 };
  }
}
