export interface PlatformThresholds {
  wastedSpendMinimum: number;
  highCpaMultiplier: number;
  lowCtrThreshold: number;
  highFrequencyThreshold: number;
  audienceOverlapMax: number;
  staleContentDays: number;
}

const platformDefaults: Record<string, PlatformThresholds> = {
  meta_ads: {
    wastedSpendMinimum: 50,
    highCpaMultiplier: 2,
    lowCtrThreshold: 0.01,
    highFrequencyThreshold: 3,
    audienceOverlapMax: 0.4,
    staleContentDays: 90,
  },
  google_ads: {
    wastedSpendMinimum: 100,
    highCpaMultiplier: 2,
    lowCtrThreshold: 0.02,
    highFrequencyThreshold: 5,
    audienceOverlapMax: 0.5,
    staleContentDays: 90,
  },
  google_analytics: {
    wastedSpendMinimum: 0,
    highCpaMultiplier: 1,
    lowCtrThreshold: 0,
    highFrequencyThreshold: 0,
    audienceOverlapMax: 0,
    staleContentDays: 30,
  },
  google_tag_manager: {
    wastedSpendMinimum: 0,
    highCpaMultiplier: 1,
    lowCtrThreshold: 0,
    highFrequencyThreshold: 0,
    audienceOverlapMax: 0,
    staleContentDays: 30,
  },
  shopify: {
    wastedSpendMinimum: 0,
    highCpaMultiplier: 1,
    lowCtrThreshold: 0,
    highFrequencyThreshold: 0,
    audienceOverlapMax: 0,
    staleContentDays: 90,
  },
};

export function getThresholds(platform: string): PlatformThresholds {
  return platformDefaults[platform] ?? platformDefaults['meta_ads']!;
}
