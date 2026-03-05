import { BaseAuditEngine, type Finding } from './base.js';
import type { PlatformType, OpportunityScore } from '../shared/types.js';
import type { GoogleAnalyticsData } from '../connectors/adapters/google-analytics.adapter.js';
import { scoreOpportunity } from './utils/scoring.js';

export class GoogleAnalyticsAuditEngine extends BaseAuditEngine<GoogleAnalyticsData, Finding> {
  readonly platform: PlatformType = 'google_analytics';

  scoreFinding(finding: Finding): OpportunityScore {
    return finding.score;
  }

  protected async analyze(data: GoogleAnalyticsData): Promise<Finding[]> {
    const findings: Finding[] = [];

    findings.push(...this.checkMigrationStatus(data));
    findings.push(...this.checkBrokenEvents(data));
    findings.push(...this.checkAttributionGaps(data));
    findings.push(...this.checkHighBounceRate(data));
    findings.push(...this.checkAudienceCreation(data));
    findings.push(...this.checkEcommerceGaps(data));

    return findings;
  }

  private checkMigrationStatus(data: GoogleAnalyticsData): Finding[] {
    if (data.migrationStatus === 'ua_only') {
      return [{
        id: 'ga_ua_only',
        title: 'Still using Universal Analytics only',
        description: 'UA has been sunset — data collection has stopped. GA4 migration is critical.',
        severity: 'critical',
        platform: 'google_analytics',
        evidence: { migrationStatus: data.migrationStatus },
        recommendation: 'Immediate GA4 setup required — historical data is being lost',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: 'critical',
          monthlyImpactLow: 500,
          monthlyImpactHigh: 5000,
          effort: 'high',
          agentCapability: 'ga4-migration-agent',
        }),
      }];
    }
    return [];
  }

  private checkBrokenEvents(data: GoogleAnalyticsData): Finding[] {
    const findings: Finding[] = [];
    const configuredNotFiring = data.events.filter((e) => e.isConversion && e.count === 0);

    if (configuredNotFiring.length > 0) {
      findings.push({
        id: 'ga_broken_events',
        title: `${configuredNotFiring.length} conversion events configured but not firing`,
        description: 'Conversion events are set up but reporting 0 counts — tracking is broken',
        severity: 'critical',
        platform: 'google_analytics',
        evidence: { events: configuredNotFiring.map((e) => e.name) },
        recommendation: 'Debug event firing in GA4 DebugView and fix tag configuration',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: 'critical',
          monthlyImpactLow: 200,
          monthlyImpactHigh: 2000,
          effort: 'medium',
          agentCapability: 'analytics-debugger',
        }),
      });
    }

    return findings;
  }

  private checkAttributionGaps(data: GoogleAnalyticsData): Finding[] {
    const findings: Finding[] = [];
    const totalSessions = data.trafficSources.reduce((sum, s) => sum + s.sessions, 0);
    const directSessions = data.trafficSources
      .filter((s) => s.source === '(direct)' || s.source === 'direct')
      .reduce((sum, s) => sum + s.sessions, 0);

    const directPct = totalSessions > 0 ? directSessions / totalSessions : 0;

    if (directPct > 0.4) {
      findings.push({
        id: 'ga_high_direct',
        title: `${(directPct * 100).toFixed(0)}% of traffic is "Direct"`,
        description: 'High direct traffic usually indicates broken UTM tracking, not actual direct visits',
        severity: 'high',
        platform: 'google_analytics',
        evidence: { directPct, directSessions, totalSessions },
        recommendation: 'Audit UTM parameters on all marketing channels, fix redirects stripping parameters',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: 'high',
          monthlyImpactLow: 100,
          monthlyImpactHigh: 1000,
          effort: 'medium',
          agentCapability: 'utm-auditor',
        }),
      });
    }

    return findings;
  }

  private checkHighBounceRate(data: GoogleAnalyticsData): Finding[] {
    const highBounce = data.trafficSources.filter((s) => s.bounceRate > 0.8 && s.sessions > 100);

    return highBounce.map((source) => ({
      id: `ga_bounce_${source.source}_${source.medium}`,
      title: `High bounce rate from ${source.source}/${source.medium}`,
      description: `${(source.bounceRate * 100).toFixed(0)}% bounce rate on ${source.sessions} sessions — likely UX or relevance issue`,
      severity: 'medium' as const,
      platform: 'google_analytics' as PlatformType,
      evidence: { source: source.source, medium: source.medium, bounceRate: source.bounceRate },
      recommendation: 'Review landing pages for this traffic source — improve relevance or speed',
      score: scoreOpportunity({
        category: 'revenue_saving',
        severity: 'medium',
        monthlyImpactLow: 50,
        monthlyImpactHigh: 500,
        effort: 'medium',
        agentCapability: 'landing-page-optimizer',
      }),
    }));
  }

  private checkAudienceCreation(data: GoogleAnalyticsData): Finding[] {
    const highValueSources = data.trafficSources.filter(
      (s) => s.conversions > 10 && s.sessions > 100,
    );

    if (highValueSources.length > 0) {
      return [{
        id: 'ga_audience_opportunity',
        title: `${highValueSources.length} high-converting traffic sources without audience export`,
        description: 'Users from these sources convert well but aren\'t in remarketing audiences',
        severity: 'medium',
        platform: 'google_analytics',
        evidence: { sources: highValueSources.map((s) => `${s.source}/${s.medium}`) },
        recommendation: 'Create GA4 audiences and export to Google Ads for RLSA campaigns',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'medium',
          monthlyImpactLow: 200,
          monthlyImpactHigh: 2000,
          effort: 'low',
          agentCapability: 'audience-builder',
        }),
      }];
    }
    return [];
  }

  private checkEcommerceGaps(data: GoogleAnalyticsData): Finding[] {
    const hasPurchase = data.events.some((e) => e.name === 'purchase');
    const hasBeginCheckout = data.events.some((e) => e.name === 'begin_checkout');
    const hasAddToCart = data.events.some((e) => e.name === 'add_to_cart');

    if (hasPurchase && (!hasBeginCheckout || !hasAddToCart)) {
      return [{
        id: 'ga_funnel_gaps',
        title: 'Incomplete ecommerce funnel tracking',
        description: 'Purchase events exist but missing add_to_cart or begin_checkout — can\'t analyze funnel drop-off',
        severity: 'high',
        platform: 'google_analytics',
        evidence: { hasPurchase, hasBeginCheckout, hasAddToCart },
        recommendation: 'Implement full enhanced ecommerce funnel events',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'high',
          monthlyImpactLow: 300,
          monthlyImpactHigh: 3000,
          effort: 'medium',
          agentCapability: 'ecommerce-tracking-setup',
        }),
      }];
    }
    return [];
  }
}
