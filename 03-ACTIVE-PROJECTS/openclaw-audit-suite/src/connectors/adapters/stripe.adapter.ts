import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('stripe-adapter');

export interface StripeConfig {
  accountId: string;
  accessToken: string;
}

export interface StripeData {
  charges: StripeCharge[];
  subscriptions: StripeSubscription[];
  failedPayments: StripeFailedPayment[];
  disputes: StripeDispute[];
  revenueSummary: StripeRevenueSummary;
}

export interface StripeCharge {
  id: string;
  amount: number;
  currency: string;
  status: string;
  created: string;
  refunded: boolean;
}

export interface StripeSubscription {
  id: string;
  status: string;
  planAmount: number;
  interval: string;
  canceledAt?: string;
  currentPeriodEnd: string;
}

export interface StripeFailedPayment {
  id: string;
  amount: number;
  failureCode: string;
  failureMessage: string;
  created: string;
  recovered: boolean;
}

export interface StripeDispute {
  id: string;
  amount: number;
  reason: string;
  status: string;
  created: string;
}

export interface StripeRevenueSummary {
  mrr: number;
  arr: number;
  churnRate: number;
  failedPaymentRate: number;
  refundRate: number;
  currency: string;
}

export class StripeAdapter extends BasePlatformAdapter<StripeConfig, StripeData> {
  readonly platform: PlatformType = 'stripe';
  private config?: StripeConfig;

  async connect(config: StripeConfig): Promise<ConnectionResult> {
    log.info({ accountId: config.accountId }, 'Connecting to Stripe');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: config.accountId };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.accountId, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<StripeData> {
    if (!this.config) throw new PlatformConnectionError('stripe', 'Not connected');
    log.info('Pulling Stripe data (last 90 days)');

    const [charges, subscriptions, failedPayments, disputes, revenueSummary] = await Promise.all([
      this.fetchCharges(),
      this.fetchSubscriptions(),
      this.fetchFailedPayments(),
      this.fetchDisputes(),
      this.fetchRevenueSummary(),
    ]);

    return { charges, subscriptions, failedPayments, disputes, revenueSummary };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('stripe', 'Not connected');
  }

  private async fetchCharges(): Promise<StripeCharge[]> { return []; }
  private async fetchSubscriptions(): Promise<StripeSubscription[]> { return []; }
  private async fetchFailedPayments(): Promise<StripeFailedPayment[]> { return []; }
  private async fetchDisputes(): Promise<StripeDispute[]> { return []; }
  private async fetchRevenueSummary(): Promise<StripeRevenueSummary> {
    return { mrr: 0, arr: 0, churnRate: 0, failedPaymentRate: 0, refundRate: 0, currency: 'USD' };
  }
}
