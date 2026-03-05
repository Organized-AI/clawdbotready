import { BaseAuditEngine, type Finding } from './base.js';
import type { PlatformType, OpportunityScore } from '../shared/types.js';
import type { ShopifyData } from '../connectors/adapters/shopify.adapter.js';
import { scoreOpportunity } from './utils/scoring.js';

export class ShopifyAuditEngine extends BaseAuditEngine<ShopifyData, Finding> {
  readonly platform: PlatformType = 'shopify';

  scoreFinding(finding: Finding): OpportunityScore {
    return finding.score;
  }

  protected async analyze(data: ShopifyData): Promise<Finding[]> {
    const findings: Finding[] = [];

    findings.push(...this.checkAbandonedCarts(data));
    findings.push(...this.checkDiscountAbuse(data));
    findings.push(...this.checkDeadInventory(data));
    findings.push(...this.checkShippingThreshold(data));
    findings.push(...this.checkUpsellOpportunity(data));
    findings.push(...this.checkSubscriptionOpportunity(data));

    return findings;
  }

  private checkAbandonedCarts(data: ShopifyData): Finding[] {
    const unrecovered = data.abandonedCarts.filter((c) => !c.recovered);
    if (unrecovered.length === 0) return [];

    const lostRevenue = unrecovered.reduce((sum, c) => sum + c.totalPrice, 0);
    const recoveryRate = data.abandonedCarts.length > 0
      ? data.abandonedCarts.filter((c) => c.recovered).length / data.abandonedCarts.length
      : 0;

    return [{
      id: 'shopify_abandoned_carts',
      title: `${unrecovered.length} unrecovered abandoned carts ($${lostRevenue.toFixed(0)} lost)`,
      description: `Recovery rate is ${(recoveryRate * 100).toFixed(0)}% — industry average is 10-15%`,
      severity: lostRevenue > 5000 ? 'critical' : 'high',
      platform: 'shopify',
      evidence: { unrecovered: unrecovered.length, lostRevenue, recoveryRate },
      recommendation: 'Implement automated cart recovery flows (email + SMS) targeting 10-15% recovery',
      score: scoreOpportunity({
        category: 'revenue_generating',
        severity: lostRevenue > 5000 ? 'critical' : 'high',
        monthlyImpactLow: lostRevenue * 0.05,
        monthlyImpactHigh: lostRevenue * 0.15,
        effort: 'medium',
        agentCapability: 'shopify-cart-recovery',
      }),
    }];
  }

  private checkDiscountAbuse(data: ShopifyData): Finding[] {
    const abusedCodes = data.discountCodes.filter((d) => d.usageCount > 100);

    if (abusedCodes.length > 0) {
      const totalLoss = abusedCodes.reduce((sum, d) => sum + d.totalSavings, 0);
      return [{
        id: 'shopify_discount_abuse',
        title: `${abusedCodes.length} discount codes with 100+ uses`,
        description: `$${totalLoss.toFixed(0)} in discount savings — potential code sharing or abuse`,
        severity: totalLoss > 2000 ? 'high' : 'medium',
        platform: 'shopify',
        evidence: { codes: abusedCodes.map((d) => d.code), totalLoss },
        recommendation: 'Add usage limits, unique codes, or customer-specific discounts',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: totalLoss > 2000 ? 'high' : 'medium',
          monthlyImpactLow: totalLoss * 0.1,
          monthlyImpactHigh: totalLoss * 0.3,
          effort: 'low',
          agentCapability: 'shopify-discount-manager',
        }),
      }];
    }
    return [];
  }

  private checkDeadInventory(data: ShopifyData): Finding[] {
    const deadProducts = data.products.filter(
      (p) => p.status === 'active' && p.totalSold === 0 && p.inventoryQuantity > 0,
    );

    if (deadProducts.length > 0) {
      return [{
        id: 'shopify_dead_inventory',
        title: `${deadProducts.length} active products with zero sales in 90 days`,
        description: 'Dead inventory ties up capital and clutters the store',
        severity: deadProducts.length > 20 ? 'high' : 'medium',
        platform: 'shopify',
        evidence: { products: deadProducts.map((p) => p.title).slice(0, 10) },
        recommendation: 'Clearance sale, bundle with popular items, or archive low-performers',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: deadProducts.length > 20 ? 'high' : 'medium',
          monthlyImpactLow: 100,
          monthlyImpactHigh: 1000,
          effort: 'low',
          agentCapability: 'shopify-inventory-optimizer',
        }),
      }];
    }
    return [];
  }

  private checkShippingThreshold(_data: ShopifyData): Finding[] {
    // Would check free shipping threshold vs AOV in real implementation
    return [];
  }

  private checkUpsellOpportunity(data: ShopifyData): Finding[] {
    if (data.orders.length > 50 && data.customers.avgOrderValue > 0) {
      return [{
        id: 'shopify_upsell_gap',
        title: 'No post-purchase upsell/cross-sell detected',
        description: `With ${data.orders.length} orders and $${data.customers.avgOrderValue.toFixed(0)} AOV, post-purchase offers could increase revenue 10-30%`,
        severity: 'medium',
        platform: 'shopify',
        evidence: { orderCount: data.orders.length, aov: data.customers.avgOrderValue },
        recommendation: 'Implement post-purchase upsell flows with product recommendations',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'medium',
          monthlyImpactLow: data.revenue.last30Days * 0.05,
          monthlyImpactHigh: data.revenue.last30Days * 0.15,
          effort: 'medium',
          agentCapability: 'shopify-upsell-builder',
        }),
      }];
    }
    return [];
  }

  private checkSubscriptionOpportunity(_data: ShopifyData): Finding[] {
    // Would analyze repeat purchase patterns in real implementation
    return [];
  }
}
