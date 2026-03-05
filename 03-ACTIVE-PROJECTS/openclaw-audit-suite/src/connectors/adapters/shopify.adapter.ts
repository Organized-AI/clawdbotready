import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('shopify-adapter');

export interface ShopifyConfig {
  shopDomain: string;
  accessToken: string;
}

export interface ShopifyData {
  orders: ShopifyOrder[];
  products: ShopifyProduct[];
  customers: ShopifyCustomerMetrics;
  abandonedCarts: ShopifyAbandonedCart[];
  discountCodes: ShopifyDiscount[];
  revenue: ShopifyRevenue;
}

export interface ShopifyOrder {
  id: string;
  totalPrice: number;
  createdAt: string;
  fulfillmentStatus: string;
  financialStatus: string;
  lineItemCount: number;
}

export interface ShopifyProduct {
  id: string;
  title: string;
  status: string;
  inventoryQuantity: number;
  variants: number;
  totalSold: number;
  revenue: number;
}

export interface ShopifyCustomerMetrics {
  totalCustomers: number;
  returningRate: number;
  avgOrderValue: number;
  avgLifetimeValue: number;
}

export interface ShopifyAbandonedCart {
  id: string;
  totalPrice: number;
  createdAt: string;
  recoveryUrl: string;
  recovered: boolean;
}

export interface ShopifyDiscount {
  id: string;
  code: string;
  usageCount: number;
  totalSavings: number;
  status: string;
}

export interface ShopifyRevenue {
  total: number;
  last30Days: number;
  last7Days: number;
  currency: string;
  avgOrderValue: number;
}

export class ShopifyAdapter extends BasePlatformAdapter<ShopifyConfig, ShopifyData> {
  readonly platform: PlatformType = 'shopify';
  private config?: ShopifyConfig;

  async connect(config: ShopifyConfig): Promise<ConnectionResult> {
    log.info({ shop: config.shopDomain }, 'Connecting to Shopify');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: config.shopDomain };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.shopDomain, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<ShopifyData> {
    if (!this.config) throw new PlatformConnectionError('shopify', 'Not connected');
    log.info('Pulling Shopify data (last 90 days)');

    const [orders, products, customers, abandonedCarts, discountCodes, revenue] = await Promise.all([
      this.fetchOrders(),
      this.fetchProducts(),
      this.fetchCustomerMetrics(),
      this.fetchAbandonedCarts(),
      this.fetchDiscountCodes(),
      this.fetchRevenue(),
    ]);

    return { orders, products, customers, abandonedCarts, discountCodes, revenue };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('shopify', 'Not connected');
  }

  private async fetchOrders(): Promise<ShopifyOrder[]> { return []; }
  private async fetchProducts(): Promise<ShopifyProduct[]> { return []; }
  private async fetchCustomerMetrics(): Promise<ShopifyCustomerMetrics> {
    return { totalCustomers: 0, returningRate: 0, avgOrderValue: 0, avgLifetimeValue: 0 };
  }
  private async fetchAbandonedCarts(): Promise<ShopifyAbandonedCart[]> { return []; }
  private async fetchDiscountCodes(): Promise<ShopifyDiscount[]> { return []; }
  private async fetchRevenue(): Promise<ShopifyRevenue> {
    return { total: 0, last30Days: 0, last7Days: 0, currency: 'USD', avgOrderValue: 0 };
  }
}
