import { BaseAuditEngine, type Finding } from './base.js';
import type { PlatformType, OpportunityScore } from '../shared/types.js';
import type { GoogleAdsData } from '../connectors/adapters/google-ads.adapter.js';
import { scoreOpportunity } from './utils/scoring.js';
import { getBenchmark, qualityScoreThresholds } from './utils/benchmarks.js';

export class GoogleAdsAuditEngine extends BaseAuditEngine<GoogleAdsData, Finding> {
  readonly platform: PlatformType = 'google_ads';

  scoreFinding(finding: Finding): OpportunityScore {
    return finding.score;
  }

  protected async analyze(data: GoogleAdsData): Promise<Finding[]> {
    const findings: Finding[] = [];
    const bench = getBenchmark();

    findings.push(...this.checkQualityScoreGaps(data));
    findings.push(...this.checkNegativeKeywordGaps(data, bench));
    findings.push(...this.checkBidWaste(data, bench));
    findings.push(...this.checkMatchTypeWaste(data));
    findings.push(...this.checkSmartBidding(data));
    findings.push(...this.checkExtensionGaps(data));

    return findings;
  }

  private checkQualityScoreGaps(data: GoogleAdsData): Finding[] {
    const findings: Finding[] = [];
    const totalSpend = data.keywords.reduce((sum, k) => sum + k.spend, 0);

    const poorQsKeywords = data.keywords.filter(
      (k) => k.qualityScore !== undefined && k.qualityScore < qualityScoreThresholds.poor,
    );

    const poorSpend = poorQsKeywords.reduce((sum, k) => sum + k.spend, 0);
    const poorSpendPct = totalSpend > 0 ? poorSpend / totalSpend : 0;

    if (poorSpendPct > 0.1 && poorQsKeywords.length > 0) {
      findings.push({
        id: 'gads_low_qs',
        title: `${poorQsKeywords.length} keywords with Quality Score < ${qualityScoreThresholds.poor}`,
        description: `Low QS keywords consuming ${(poorSpendPct * 100).toFixed(1)}% of budget — paying premium CPCs`,
        severity: poorSpendPct > 0.25 ? 'critical' : 'high',
        platform: 'google_ads',
        evidence: {
          keywordCount: poorQsKeywords.length,
          spendPct: poorSpendPct,
          totalSpend: poorSpend,
        },
        recommendation: 'Improve ad relevance, landing page experience, and expected CTR for these keywords',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: poorSpendPct > 0.25 ? 'critical' : 'high',
          monthlyImpactLow: poorSpend * 0.2,
          monthlyImpactHigh: poorSpend * 0.5,
          effort: 'medium',
          agentCapability: 'google-ads-qs-optimizer',
        }),
      });
    }

    return findings;
  }

  private checkNegativeKeywordGaps(data: GoogleAdsData, _bench: ReturnType<typeof getBenchmark>): Finding[] {
    const findings: Finding[] = [];

    const wastedKeywords = data.keywords.filter(
      (k) => k.spend > 100 && k.clicks > 0 && k.matchType === 'BROAD',
    );

    if (wastedKeywords.length > 0) {
      const totalWaste = wastedKeywords.reduce((sum, k) => sum + k.spend, 0);
      findings.push({
        id: 'gads_negative_gaps',
        title: `${wastedKeywords.length} broad match terms with high spend and no conversion data`,
        description: `$${totalWaste.toFixed(2)} spent on broad match terms that need negative keyword review`,
        severity: totalWaste > 500 ? 'critical' : 'high',
        platform: 'google_ads',
        evidence: { keywords: wastedKeywords.length, totalSpend: totalWaste },
        recommendation: 'Review search terms report and add negatives for irrelevant queries',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: totalWaste > 500 ? 'critical' : 'high',
          monthlyImpactLow: totalWaste * 0.3,
          monthlyImpactHigh: totalWaste * 0.6,
          effort: 'low',
          agentCapability: 'google-ads-negative-keyword-builder',
        }),
      });
    }

    return findings;
  }

  private checkBidWaste(data: GoogleAdsData, bench: ReturnType<typeof getBenchmark>): Finding[] {
    const findings: Finding[] = [];

    for (const campaign of data.campaigns) {
      if (campaign.costPerConversion > bench.avgCpa * 2 && campaign.conversions > 0) {
        findings.push({
          id: `gads_bid_waste_${campaign.id}`,
          title: `High CPA on "${campaign.name}"`,
          description: `CPA of $${campaign.costPerConversion.toFixed(2)} is ${(campaign.costPerConversion / bench.avgCpa).toFixed(1)}x industry average`,
          severity: campaign.costPerConversion > bench.avgCpa * 3 ? 'critical' : 'high',
          platform: 'google_ads',
          evidence: {
            campaignId: campaign.id,
            cpa: campaign.costPerConversion,
            benchmarkCpa: bench.avgCpa,
          },
          recommendation: 'Review bid strategy, ad relevance, and landing page conversion rate',
          score: scoreOpportunity({
            category: 'revenue_saving',
            severity: campaign.costPerConversion > bench.avgCpa * 3 ? 'critical' : 'high',
            monthlyImpactLow: campaign.spend * 0.2,
            monthlyImpactHigh: campaign.spend * 0.5,
            effort: 'medium',
            agentCapability: 'google-ads-bid-optimizer',
          }),
        });
      }
    }

    return findings;
  }

  private checkMatchTypeWaste(data: GoogleAdsData): Finding[] {
    const findings: Finding[] = [];
    const broadKeywords = data.keywords.filter((k) => k.matchType === 'BROAD');
    const totalKeywords = data.keywords.length;

    if (totalKeywords > 0 && broadKeywords.length / totalKeywords > 0.5) {
      findings.push({
        id: 'gads_match_type_heavy',
        title: 'Over 50% broad match keywords',
        description: `${broadKeywords.length}/${totalKeywords} keywords are broad match — likely capturing irrelevant traffic`,
        severity: 'medium',
        platform: 'google_ads',
        evidence: { broadCount: broadKeywords.length, total: totalKeywords },
        recommendation: 'Convert top broad match terms to phrase or exact match with proper negatives',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: 'medium',
          monthlyImpactLow: 100,
          monthlyImpactHigh: 1000,
          effort: 'medium',
          agentCapability: 'google-ads-keyword-optimizer',
        }),
      });
    }

    return findings;
  }

  private checkSmartBidding(data: GoogleAdsData): Finding[] {
    const findings: Finding[] = [];
    const manualCampaigns = data.campaigns.filter((c) => c.type === 'MANUAL_CPC' || c.type === 'ENHANCED_CPC');

    if (manualCampaigns.length > 0) {
      findings.push({
        id: 'gads_no_smart_bidding',
        title: `${manualCampaigns.length} campaigns using manual/enhanced CPC`,
        description: 'Smart bidding (tROAS/tCPA) typically outperforms manual bidding with sufficient conversion data',
        severity: 'medium',
        platform: 'google_ads',
        evidence: { campaignCount: manualCampaigns.length },
        recommendation: 'Test Target ROAS or Target CPA bidding on campaigns with >30 conversions/month',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'medium',
          monthlyImpactLow: 200,
          monthlyImpactHigh: 2000,
          effort: 'low',
          agentCapability: 'google-ads-bidding-strategist',
        }),
      });
    }

    return findings;
  }

  private checkExtensionGaps(_data: GoogleAdsData): Finding[] {
    // Would check for missing ad extensions in real implementation
    return [];
  }
}
