export type PlatformType =
  | 'meta_ads'
  | 'google_ads'
  | 'google_analytics'
  | 'google_tag_manager'
  | 'shopify'
  | 'stripe'
  | 'google_drive'
  | 'google_docs'
  | 'gmail'
  | 'slack'
  | 'whatsapp_business';

export interface ConnectionResult {
  success: boolean;
  platformId: string;
  error?: string;
}

export interface HealthStatus {
  platform: PlatformType;
  healthy: boolean;
  latencyMs: number;
  lastChecked: Date;
  error?: string;
}

export interface AuditResult<TFindings> {
  orgId: string;
  platform: PlatformType;
  startedAt: Date;
  completedAt: Date;
  findings: TFindings[];
  summary: AuditSummary;
}

export interface AuditSummary {
  totalFindings: number;
  revenueSaving: number;
  revenueGenerating: number;
  criticalCount: number;
  highCount: number;
  mediumCount: number;
  lowCount: number;
}

export type OpportunityCategory = 'revenue_saving' | 'revenue_generating';
export type EffortLevel = 'low' | 'medium' | 'high';
export type Severity = 'critical' | 'high' | 'medium' | 'low';

export interface OpportunityScore {
  category: OpportunityCategory;
  confidence: number;
  estimatedImpact: {
    low: number;
    mid: number;
    high: number;
  };
  effort: EffortLevel;
  agentCapability: string;
}

export interface OrgConnection {
  orgId: string;
  platform: PlatformType;
  assetId: string;
  assetName: string;
  accessLevel: 'view' | 'admin';
  connectedAt: Date;
  active: boolean;
}
