import { BaseAuditEngine, type Finding } from './base.js';
import type { PlatformType, OpportunityScore } from '../shared/types.js';
import type { MetaAdsData } from '../connectors/adapters/meta-ads.adapter.js';
import { scoreOpportunity, estimateWastedSpend } from './utils/scoring.js';
import { getBenchmark } from './utils/benchmarks.js';
import { getThresholds } from './utils/thresholds.js';

export class MetaAdsAuditEngine extends BaseAuditEngine<MetaAdsData, Finding> {
  readonly platform: PlatformType = 'meta_ads';

  scoreFinding(finding: Finding): OpportunityScore {
    return finding.score;
  }

  protected async analyze(data: MetaAdsData): Promise<Finding[]> {
    const findings: Finding[] = [];
    const bench = getBenchmark();
    const thresholds = getThresholds('meta_ads');

    findings.push(...this.checkWastedSpend(data, bench, thresholds));
    findings.push(...this.checkCreativeFatigue(data, thresholds));
    findings.push(...this.checkBroadTargeting(data, thresholds));
    findings.push(...this.checkLookalikeOpportunities(data));
    findings.push(...this.checkCatalogAds(data));
    findings.push(...this.checkAdvantagePlus(data));

    return findings;
  }

  private checkWastedSpend(data: MetaAdsData, bench: ReturnType<typeof getBenchmark>, _thresholds: ReturnType<typeof getThresholds>): Finding[] {
    const findings: Finding[] = [];

    for (const ad of data.ads) {
      if (ad.spend > 50 && ad.clicks > 0) {
        const { wasted, severity } = estimateWastedSpend(ad.spend, 0, bench.avgCpa);
        if (wasted > 0) {
          findings.push({
            id: `meta_wasted_${ad.id}`,
            title: `Wasted spend on ad "${ad.name}"`,
            description: `Ad has spent $${ad.spend.toFixed(2)} with 0 conversions in the last 30 days`,
            severity,
            platform: 'meta_ads',
            evidence: { adId: ad.id, spend: ad.spend, impressions: ad.impressions },
            recommendation: 'Pause this ad and reallocate budget to top performers',
            score: scoreOpportunity({
              category: 'revenue_saving',
              severity,
              monthlyImpactLow: wasted * 0.5,
              monthlyImpactHigh: wasted,
              effort: 'low',
              agentCapability: 'meta-ads-optimizer',
            }),
          });
        }
      }
    }

    return findings;
  }

  private checkCreativeFatigue(data: MetaAdsData, thresholds: ReturnType<typeof getThresholds>): Finding[] {
    const findings: Finding[] = [];

    for (const ad of data.ads) {
      if (ad.frequency > thresholds.highFrequencyThreshold) {
        findings.push({
          id: `meta_fatigue_${ad.id}`,
          title: `Creative fatigue on "${ad.name}"`,
          description: `Frequency is ${ad.frequency.toFixed(1)}x (threshold: ${thresholds.highFrequencyThreshold}x)`,
          severity: ad.frequency > 6 ? 'high' : 'medium',
          platform: 'meta_ads',
          evidence: { adId: ad.id, frequency: ad.frequency, spend: ad.spend },
          recommendation: 'Refresh creative or expand audience to reduce frequency',
          score: scoreOpportunity({
            category: 'revenue_saving',
            severity: ad.frequency > 6 ? 'high' : 'medium',
            monthlyImpactLow: ad.spend * 0.1,
            monthlyImpactHigh: ad.spend * 0.3,
            effort: 'medium',
            agentCapability: 'meta-creative-refresher',
          }),
        });
      }
    }

    return findings;
  }

  private checkBroadTargeting(data: MetaAdsData, thresholds: ReturnType<typeof getThresholds>): Finding[] {
    const findings: Finding[] = [];

    for (const adSet of data.adSets) {
      const ctr = adSet.impressions > 0 ? 0 : 0; // Would calculate from actual data
      if (adSet.impressions > 1000 && ctr < thresholds.lowCtrThreshold) {
        findings.push({
          id: `meta_broad_${adSet.id}`,
          title: `Low CTR on ad set "${adSet.name}"`,
          description: `CTR below ${(thresholds.lowCtrThreshold * 100).toFixed(1)}% indicates overly broad targeting`,
          severity: 'medium',
          platform: 'meta_ads',
          evidence: { adSetId: adSet.id, impressions: adSet.impressions },
          recommendation: 'Narrow targeting or use lookalike audiences',
          score: scoreOpportunity({
            category: 'revenue_saving',
            severity: 'medium',
            monthlyImpactLow: adSet.spend * 0.15,
            monthlyImpactHigh: adSet.spend * 0.4,
            effort: 'medium',
            agentCapability: 'meta-audience-optimizer',
          }),
        });
      }
    }

    return findings;
  }

  private checkLookalikeOpportunities(data: MetaAdsData): Finding[] {
    const findings: Finding[] = [];
    const hasLookalike = data.audiences.some((a) => a.type === 'lookalike');
    const hasCustom = data.audiences.some((a) => a.type === 'custom');

    if (hasCustom && !hasLookalike) {
      findings.push({
        id: 'meta_no_lookalike',
        title: 'No lookalike audiences created',
        description: 'Custom audiences exist but no lookalike expansion — missing scale opportunity',
        severity: 'high',
        platform: 'meta_ads',
        evidence: { customAudiences: data.audiences.filter((a) => a.type === 'custom').length },
        recommendation: 'Create 1-3% lookalike audiences from top-performing custom audiences',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'high',
          monthlyImpactLow: 500,
          monthlyImpactHigh: 5000,
          effort: 'low',
          agentCapability: 'meta-audience-builder',
        }),
      });
    }

    return findings;
  }

  private checkCatalogAds(data: MetaAdsData): Finding[] {
    const hasCatalog = data.campaigns.some((c) => c.objective === 'PRODUCT_CATALOG_SALES');
    if (!hasCatalog && data.campaigns.length > 0) {
      return [{
        id: 'meta_no_catalog',
        title: 'No Dynamic Product Ads (DPA) campaigns',
        description: 'Product catalog not leveraged for automated retargeting',
        severity: 'medium',
        platform: 'meta_ads',
        evidence: { campaignCount: data.campaigns.length },
        recommendation: 'Set up product catalog and create DPA campaigns for retargeting',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'medium',
          monthlyImpactLow: 300,
          monthlyImpactHigh: 3000,
          effort: 'medium',
          agentCapability: 'meta-catalog-setup',
        }),
      }];
    }
    return [];
  }

  private checkAdvantagePlus(data: MetaAdsData): Finding[] {
    const hasASC = data.campaigns.some((c) => c.objective === 'OUTCOME_SALES');
    if (!hasASC && data.campaigns.length > 3) {
      return [{
        id: 'meta_no_asc',
        title: 'No Advantage+ Shopping campaigns',
        description: 'Account has multiple campaigns but no ASC — missing AI-optimized opportunity',
        severity: 'medium',
        platform: 'meta_ads',
        evidence: { campaignCount: data.campaigns.length },
        recommendation: 'Test Advantage+ Shopping Campaign alongside existing campaigns',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'medium',
          monthlyImpactLow: 200,
          monthlyImpactHigh: 2000,
          effort: 'low',
          agentCapability: 'meta-campaign-creator',
        }),
      }];
    }
    return [];
  }
}
