import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('google-drive-adapter');

export interface GoogleDriveConfig {
  accessToken: string;
  refreshToken: string;
}

export interface GoogleDriveData {
  files: DriveFile[];
  sharingReport: SharingReport;
  storageUsage: StorageUsage;
}

export interface DriveFile {
  id: string;
  name: string;
  mimeType: string;
  size: number;
  createdTime: string;
  modifiedTime: string;
  shared: boolean;
  sharingLevel: 'private' | 'domain' | 'anyone';
  owners: string[];
}

export interface SharingReport {
  totalShared: number;
  externallyShared: number;
  publicLinks: number;
  orphanedFiles: number;
}

export interface StorageUsage {
  totalBytes: number;
  usedBytes: number;
  trashBytes: number;
}

export class GoogleDriveAdapter extends BasePlatformAdapter<GoogleDriveConfig, GoogleDriveData> {
  readonly platform: PlatformType = 'google_drive';
  private config?: GoogleDriveConfig;

  async connect(config: GoogleDriveConfig): Promise<ConnectionResult> {
    log.info('Connecting to Google Drive');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: 'drive' };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: 'drive', error: message };
    }
  }

  async pullData(_connectionId: string): Promise<GoogleDriveData> {
    if (!this.config) throw new PlatformConnectionError('google_drive', 'Not connected');
    log.info('Pulling Google Drive data');

    const [files, sharingReport, storageUsage] = await Promise.all([
      this.fetchFiles(),
      this.fetchSharingReport(),
      this.fetchStorageUsage(),
    ]);

    return { files, sharingReport, storageUsage };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('google_drive', 'Not connected');
  }

  private async fetchFiles(): Promise<DriveFile[]> { return []; }
  private async fetchSharingReport(): Promise<SharingReport> {
    return { totalShared: 0, externallyShared: 0, publicLinks: 0, orphanedFiles: 0 };
  }
  private async fetchStorageUsage(): Promise<StorageUsage> {
    return { totalBytes: 0, usedBytes: 0, trashBytes: 0 };
  }
}
