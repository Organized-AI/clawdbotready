import { describe, it, expect } from 'vitest';
import { TokenVault } from '../src/connectors/token-vault.js';

describe('TokenVault', () => {
  const vault = new TokenVault('test-secret-key-for-vault');

  it('should encrypt and decrypt a token', () => {
    const original = 'EAABsbCS1iZAMBO...my-secret-access-token';
    const encrypted = vault.encrypt(original);

    expect(encrypted).not.toBe(original);
    expect(typeof encrypted).toBe('string');

    const decrypted = vault.decrypt(encrypted);
    expect(decrypted).toBe(original);
  });

  it('should produce different ciphertexts for same input (random IV)', () => {
    const token = 'same-token-value';
    const encrypted1 = vault.encrypt(token);
    const encrypted2 = vault.encrypt(token);

    expect(encrypted1).not.toBe(encrypted2);

    expect(vault.decrypt(encrypted1)).toBe(token);
    expect(vault.decrypt(encrypted2)).toBe(token);
  });

  it('should store and retrieve tokens', () => {
    vault.store('org_1', 'meta_ads', 'my-access-token');
    const retrieved = vault.retrieve('org_1', 'meta_ads');
    expect(retrieved).toBe('my-access-token');
  });

  it('should return undefined for missing tokens', () => {
    expect(vault.retrieve('org_999', 'meta_ads')).toBeUndefined();
  });

  it('should return undefined for expired tokens', () => {
    const pastDate = new Date(Date.now() - 60000);
    vault.store('org_2', 'stripe', 'expired-token', pastDate);
    expect(vault.retrieve('org_2', 'stripe')).toBeUndefined();
  });

  it('should remove tokens', () => {
    vault.store('org_3', 'slack', 'slack-token');
    expect(vault.has('org_3', 'slack')).toBe(true);
    vault.remove('org_3', 'slack');
    expect(vault.has('org_3', 'slack')).toBe(false);
  });

  it('should fail to decrypt with wrong vault', () => {
    const vault2 = new TokenVault('different-secret');
    const encrypted = vault.encrypt('sensitive-data');

    expect(() => vault2.decrypt(encrypted)).toThrow();
  });
});
