import { BaseAuditEngine, type Finding } from './base.js';
import type { PlatformType, OpportunityScore } from '../shared/types.js';
import type { GTMData, GTMTag } from '../connectors/adapters/gtm.adapter.js';
import { scoreOpportunity } from './utils/scoring.js';

export class GTMAuditEngine extends BaseAuditEngine<GTMData, Finding> {
  readonly platform: PlatformType = 'google_tag_manager';

  scoreFinding(finding: Finding): OpportunityScore {
    return finding.score;
  }

  protected async analyze(data: GTMData): Promise<Finding[]> {
    const findings: Finding[] = [];

    findings.push(...this.checkRedundantTags(data));
    findings.push(...this.checkPerformanceDrag(data));
    findings.push(...this.checkConsentViolations(data));
    findings.push(...this.checkVersionBloat(data));
    findings.push(...this.checkServerSideOpportunity(data));
    findings.push(...this.checkConsentModeV2(data));

    return findings;
  }

  private checkRedundantTags(data: GTMData): Finding[] {
    const findings: Finding[] = [];
    const tagsByType = new Map<string, GTMTag[]>();

    for (const tag of data.tags) {
      const existing = tagsByType.get(tag.type) ?? [];
      existing.push(tag);
      tagsByType.set(tag.type, existing);
    }

    for (const [type, tags] of tagsByType) {
      if (tags.length > 1) {
        findings.push({
          id: `gtm_redundant_${type}`,
          title: `${tags.length} duplicate "${type}" tags`,
          description: `Multiple tags of the same type may fire redundant events, inflating metrics`,
          severity: tags.length > 3 ? 'high' : 'medium',
          platform: 'google_tag_manager',
          evidence: { type, tags: tags.map((t) => t.name) },
          recommendation: 'Consolidate duplicate tags and verify data isn\'t double-counted',
          score: scoreOpportunity({
            category: 'revenue_saving',
            severity: tags.length > 3 ? 'high' : 'medium',
            monthlyImpactLow: 50,
            monthlyImpactHigh: 500,
            effort: 'low',
            agentCapability: 'gtm-tag-cleanup',
          }),
        });
      }
    }

    return findings;
  }

  private checkPerformanceDrag(data: GTMData): Finding[] {
    const allPagesTags = data.tags.filter(
      (t) => !t.paused && t.firingTriggerId.length === 0,
    );

    if (allPagesTags.length > 5) {
      return [{
        id: 'gtm_perf_drag',
        title: `${allPagesTags.length} tags firing on all pages without specific triggers`,
        description: 'Tags without scoped triggers slow page load and waste bandwidth',
        severity: allPagesTags.length > 10 ? 'high' : 'medium',
        platform: 'google_tag_manager',
        evidence: { tags: allPagesTags.map((t) => t.name) },
        recommendation: 'Add specific triggers to limit tag firing to relevant pages only',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: allPagesTags.length > 10 ? 'high' : 'medium',
          monthlyImpactLow: 100,
          monthlyImpactHigh: 1000,
          effort: 'medium',
          agentCapability: 'gtm-performance-optimizer',
        }),
      }];
    }
    return [];
  }

  private checkConsentViolations(data: GTMData): Finding[] {
    const noConsent = data.tags.filter(
      (t) => !t.paused && !t.consentSettings,
    );

    if (noConsent.length > 0) {
      return [{
        id: 'gtm_no_consent',
        title: `${noConsent.length} tags without consent configuration`,
        description: 'Tags firing without consent checks may violate GDPR/CCPA',
        severity: 'critical',
        platform: 'google_tag_manager',
        evidence: { tags: noConsent.map((t) => t.name), count: noConsent.length },
        recommendation: 'Configure consent settings on all tags and implement Consent Mode v2',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: 'critical',
          monthlyImpactLow: 500,
          monthlyImpactHigh: 50000,
          effort: 'high',
          agentCapability: 'consent-mode-setup',
        }),
      }];
    }
    return [];
  }

  private checkVersionBloat(data: GTMData): Finding[] {
    if (data.versions.length > 20) {
      return [{
        id: 'gtm_version_bloat',
        title: `${data.versions.length} container versions`,
        description: 'Large number of versions may indicate frequent unreviewed changes',
        severity: 'low',
        platform: 'google_tag_manager',
        evidence: { versionCount: data.versions.length },
        recommendation: 'Review change management process and add descriptions to versions',
        score: scoreOpportunity({
          category: 'revenue_saving',
          severity: 'low',
          monthlyImpactLow: 0,
          monthlyImpactHigh: 100,
          effort: 'low',
          agentCapability: 'gtm-governance',
        }),
      }];
    }
    return [];
  }

  private checkServerSideOpportunity(data: GTMData): Finding[] {
    const clientSideTags = data.tags.filter((t) =>
      ['Google Analytics', 'Meta Pixel', 'Google Ads Conversion'].some((name) =>
        t.type.includes(name) || t.name.includes(name),
      ),
    );

    if (clientSideTags.length >= 3) {
      return [{
        id: 'gtm_sgtm_opportunity',
        title: 'Server-side GTM opportunity',
        description: `${clientSideTags.length} client-side tracking tags could benefit from server-side deployment`,
        severity: 'medium',
        platform: 'google_tag_manager',
        evidence: { tags: clientSideTags.map((t) => t.name) },
        recommendation: 'Migrate to server-side GTM for improved data quality and site speed',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'medium',
          monthlyImpactLow: 200,
          monthlyImpactHigh: 2000,
          effort: 'high',
          agentCapability: 'sgtm-setup',
        }),
      }];
    }
    return [];
  }

  private checkConsentModeV2(data: GTMData): Finding[] {
    const hasConsentMode = data.tags.some((t) =>
      t.consentSettings && Object.keys(t.consentSettings).length > 0,
    );

    if (!hasConsentMode && data.tags.length > 0) {
      return [{
        id: 'gtm_no_consent_mode',
        title: 'Consent Mode v2 not implemented',
        description: 'Required for EU advertising — without it, conversion modeling is disabled',
        severity: 'high',
        platform: 'google_tag_manager',
        evidence: { tagCount: data.tags.length },
        recommendation: 'Implement Google Consent Mode v2 with a CMP (e.g., Cookiebot, OneTrust)',
        score: scoreOpportunity({
          category: 'revenue_generating',
          severity: 'high',
          monthlyImpactLow: 300,
          monthlyImpactHigh: 5000,
          effort: 'medium',
          agentCapability: 'consent-mode-setup',
        }),
      }];
    }
    return [];
  }
}
