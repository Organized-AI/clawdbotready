import type { OpportunityCategory, EffortLevel, OpportunityScore, Severity } from '../../shared/types.js';

export interface ScoringInput {
  category: OpportunityCategory;
  severity: Severity;
  monthlyImpactLow: number;
  monthlyImpactHigh: number;
  effort: EffortLevel;
  agentCapability: string;
}

export function scoreOpportunity(input: ScoringInput): OpportunityScore {
  const { category, severity, monthlyImpactLow, monthlyImpactHigh, effort, agentCapability } = input;

  const annualLow = monthlyImpactLow * 12;
  const annualHigh = monthlyImpactHigh * 12;
  const annualMid = (annualLow + annualHigh) / 2;

  const confidence = severityToConfidence(severity);

  return {
    category,
    confidence,
    estimatedImpact: {
      low: annualLow,
      mid: annualMid,
      high: annualHigh,
    },
    effort,
    agentCapability,
  };
}

function severityToConfidence(severity: Severity): number {
  switch (severity) {
    case 'critical': return 0.95;
    case 'high': return 0.8;
    case 'medium': return 0.6;
    case 'low': return 0.4;
  }
}

export function estimateWastedSpend(
  spend: number,
  conversions: number,
  benchmarkCpa: number,
): { wasted: number; severity: Severity } {
  if (conversions === 0 && spend > 0) {
    return { wasted: spend, severity: spend > 500 ? 'critical' : 'high' };
  }

  const actualCpa = spend / conversions;
  const excessRatio = actualCpa / benchmarkCpa;

  if (excessRatio > 3) return { wasted: spend * 0.66, severity: 'critical' };
  if (excessRatio > 2) return { wasted: spend * 0.5, severity: 'high' };
  if (excessRatio > 1.5) return { wasted: spend * 0.33, severity: 'medium' };
  return { wasted: 0, severity: 'low' };
}
