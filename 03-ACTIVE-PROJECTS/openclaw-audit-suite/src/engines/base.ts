import type {
  PlatformType,
  AuditResult,
  OpportunityScore,
  Severity,
} from '../shared/types.js';

export interface Finding {
  id: string;
  title: string;
  description: string;
  severity: Severity;
  platform: PlatformType;
  evidence: Record<string, unknown>;
  recommendation: string;
  score: OpportunityScore;
}

export interface AuditEngine<TData = unknown, TFindings extends Finding = Finding> {
  readonly platform: PlatformType;
  audit(data: TData, orgId: string): Promise<AuditResult<TFindings>>;
  scoreFinding(finding: TFindings): OpportunityScore;
}

export abstract class BaseAuditEngine<TData = unknown, TFindings extends Finding = Finding>
  implements AuditEngine<TData, TFindings>
{
  abstract readonly platform: PlatformType;

  async audit(data: TData, orgId: string): Promise<AuditResult<TFindings>> {
    const startedAt = new Date();
    const findings = await this.analyze(data);
    const completedAt = new Date();

    const scored = findings.map((f) => ({
      ...f,
      score: this.scoreFinding(f),
    }));

    let revenueSaving = 0;
    let revenueGenerating = 0;
    let criticalCount = 0;
    let highCount = 0;
    let mediumCount = 0;
    let lowCount = 0;

    for (const f of scored) {
      if (f.score.category === 'revenue_saving') revenueSaving++;
      else revenueGenerating++;

      switch (f.severity) {
        case 'critical': criticalCount++; break;
        case 'high': highCount++; break;
        case 'medium': mediumCount++; break;
        case 'low': lowCount++; break;
      }
    }

    return {
      orgId,
      platform: this.platform,
      startedAt,
      completedAt,
      findings: scored,
      summary: {
        totalFindings: scored.length,
        revenueSaving,
        revenueGenerating,
        criticalCount,
        highCount,
        mediumCount,
        lowCount,
      },
    };
  }

  abstract scoreFinding(finding: TFindings): OpportunityScore;
  protected abstract analyze(data: TData): Promise<TFindings[]>;
}
