const CAMPAIGN_STATUS_MAP: Record<number, string> = {
  0: "UNSPECIFIED",
  1: "UNKNOWN",
  2: "ENABLED",
  3: "PAUSED",
  4: "REMOVED",
};

export function campaignStatusName(code: number | string): string {
  const n = typeof code === "string" ? parseInt(code, 10) : code;
  return CAMPAIGN_STATUS_MAP[n] ?? String(code);
}
