export interface IndustryBenchmark {
  avgCtr: number;
  avgCpc: number;
  avgCpa: number;
  avgRoas: number;
  avgConversionRate: number;
  avgBounceRate: number;
  avgFrequency: number;
}

// Source: WordStream, Databox, HubSpot aggregated 2025/2026 benchmarks
const benchmarks: Record<string, IndustryBenchmark> = {
  ecommerce: {
    avgCtr: 0.0286, avgCpc: 1.16, avgCpa: 45.27,
    avgRoas: 4.0, avgConversionRate: 0.0177, avgBounceRate: 0.47, avgFrequency: 2.5,
  },
  saas: {
    avgCtr: 0.0222, avgCpc: 3.8, avgCpa: 86.0,
    avgRoas: 3.0, avgConversionRate: 0.0295, avgBounceRate: 0.42, avgFrequency: 3.0,
  },
  lead_gen: {
    avgCtr: 0.0261, avgCpc: 2.56, avgCpa: 53.52,
    avgRoas: 3.5, avgConversionRate: 0.0318, avgBounceRate: 0.55, avgFrequency: 2.8,
  },
  default: {
    avgCtr: 0.025, avgCpc: 2.0, avgCpa: 55.0,
    avgRoas: 3.5, avgConversionRate: 0.025, avgBounceRate: 0.50, avgFrequency: 2.8,
  },
};

export function getBenchmark(industry: string = 'default'): IndustryBenchmark {
  return benchmarks[industry] ?? benchmarks['default']!;
}

export const qualityScoreThresholds = {
  poor: 4,
  belowAverage: 6,
  average: 7,
  good: 8,
  excellent: 10,
};

export const audienceOverlapThreshold = 0.40;
export const creativeFatigueFrequencyMultiplier = 3;
export const wastedSpendMinimum = 50;
export const negativeKeywordSpendThreshold = 100;
