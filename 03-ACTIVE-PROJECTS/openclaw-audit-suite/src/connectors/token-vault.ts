import { createCipheriv, createDecipheriv, randomBytes, scryptSync } from 'node:crypto';
import { createChildLogger } from '../shared/logger.js';

const log = createChildLogger('token-vault');

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const TAG_LENGTH = 16;
const SALT_LENGTH = 32;
const KEY_LENGTH = 32;

export interface StoredToken {
  orgId: string;
  platform: string;
  encryptedToken: string;
  expiresAt?: Date;
  refreshToken?: string;
}

export class TokenVault {
  private tokens = new Map<string, StoredToken>();
  private readonly masterKey: Buffer;

  constructor(secret: string) {
    const salt = scryptSync(secret, 'openclaw-audit-vault', SALT_LENGTH);
    this.masterKey = scryptSync(secret, salt, KEY_LENGTH);
  }

  encrypt(plaintext: string): string {
    const iv = randomBytes(IV_LENGTH);
    const cipher = createCipheriv(ALGORITHM, this.masterKey, iv);
    const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, encrypted]).toString('base64');
  }

  decrypt(ciphertext: string): string {
    const buffer = Buffer.from(ciphertext, 'base64');
    const iv = buffer.subarray(0, IV_LENGTH);
    const tag = buffer.subarray(IV_LENGTH, IV_LENGTH + TAG_LENGTH);
    const encrypted = buffer.subarray(IV_LENGTH + TAG_LENGTH);
    const decipher = createDecipheriv(ALGORITHM, this.masterKey, iv);
    decipher.setAuthTag(tag);
    return decipher.update(encrypted) + decipher.final('utf8');
  }

  store(orgId: string, platform: string, token: string, expiresAt?: Date): void {
    const key = `${orgId}:${platform}`;
    const encryptedToken = this.encrypt(token);
    this.tokens.set(key, { orgId, platform, encryptedToken, expiresAt });
    log.info({ orgId, platform }, 'Token stored');
  }

  retrieve(orgId: string, platform: string): string | undefined {
    const key = `${orgId}:${platform}`;
    const stored = this.tokens.get(key);
    if (!stored) return undefined;

    if (stored.expiresAt && stored.expiresAt < new Date()) {
      log.warn({ orgId, platform }, 'Token expired');
      return undefined;
    }

    return this.decrypt(stored.encryptedToken);
  }

  remove(orgId: string, platform: string): boolean {
    const key = `${orgId}:${platform}`;
    return this.tokens.delete(key);
  }

  has(orgId: string, platform: string): boolean {
    const key = `${orgId}:${platform}`;
    return this.tokens.has(key);
  }
}
