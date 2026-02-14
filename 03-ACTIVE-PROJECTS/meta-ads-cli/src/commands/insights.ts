import type { Command } from "commander";
import { getAccessToken } from "../lib/auth.js";
import { makeApiRequest, ensureActPrefix } from "../lib/client.js";
import * as fmt from "../lib/format.js";

interface InsightRow {
  campaign_name?: string;
  campaign_id?: string;
  adset_name?: string;
  adset_id?: string;
  ad_name?: string;
  ad_id?: string;
  impressions?: string;
  clicks?: string;
  ctr?: string;
  spend?: string;
  reach?: string;
  frequency?: string;
  cpc?: string;
  cpm?: string;
  cpp?: string;
  actions?: { action_type: string; value: string }[];
  cost_per_action_type?: { action_type: string; value: string }[];
  date_start?: string;
  date_stop?: string;
  [key: string]: unknown;
}

function parseTimeRange(range: string): Record<string, unknown> {
  // Custom date range: YYYY-MM-DD:YYYY-MM-DD
  if (range.includes(":") && range.length > 10) {
    const [since, until] = range.split(":");
    return { time_range: { since, until } };
  }

  // Preset ranges
  const presets: Record<string, string> = {
    today: "today",
    yesterday: "yesterday",
    last_3d: "last_3d",
    last_7d: "last_7d",
    last_14d: "last_14d",
    last_30d: "last_30d",
    last_90d: "last_90d",
    this_month: "this_month",
    last_month: "last_month",
    this_quarter: "this_quarter",
    last_quarter: "last_quarter",
    this_year: "this_year",
    last_year: "last_year",
    maximum: "maximum",
  };

  const key = range.toLowerCase().replace(/-/g, "_");
  if (presets[key]) {
    return { date_preset: presets[key] };
  }

  return { date_preset: "last_7d" };
}

function getConversions(row: InsightRow): number {
  if (!row.actions) return 0;
  const conversionTypes = [
    "offsite_conversion.fb_pixel_purchase",
    "offsite_conversion.fb_pixel_lead",
    "lead",
    "purchase",
    "complete_registration",
    "onsite_conversion.messaging_conversation_started_7d",
  ];
  for (const t of conversionTypes) {
    const action = row.actions.find((a) => a.action_type === t);
    if (action) return parseFloat(action.value);
  }
  // Fall back to total actions
  const total = row.actions.find((a) => a.action_type === "actions:omni_total_actions");
  return total ? parseFloat(total.value) : 0;
}

function getCpa(row: InsightRow): number {
  if (!row.cost_per_action_type) return 0;
  const conversionTypes = [
    "offsite_conversion.fb_pixel_purchase",
    "offsite_conversion.fb_pixel_lead",
    "lead",
    "purchase",
  ];
  for (const t of conversionTypes) {
    const action = row.cost_per_action_type.find((a) => a.action_type === t);
    if (action) return parseFloat(action.value);
  }
  return 0;
}

export function registerInsightCommands(program: Command): void {
  program
    .command("insights")
    .description("Get performance insights for a campaign, ad set, ad, or account")
    .requiredOption("--object-id <id>", "Object ID (account, campaign, ad set, or ad)")
    .option("--time-range <range>", "Time range: today, yesterday, last_7d, last_30d, maximum, or YYYY-MM-DD:YYYY-MM-DD", "last_7d")
    .option("--breakdown <type>", "Breakdown: age, gender, country, device_platform, publisher_platform")
    .option("--level <level>", "Aggregation level: account, campaign, adset, ad", "campaign")
    .option("--limit <n>", "Max rows", "25")
    .action(async (opts: {
      objectId: string;
      timeRange: string;
      breakdown?: string;
      level: string;
      limit: string;
    }) => {
      const token = getAccessToken();

      // Auto-prefix act_ if it looks like an account ID
      let objectId = opts.objectId;
      if (/^\d+$/.test(objectId) && opts.level === "campaign") {
        objectId = ensureActPrefix(objectId);
      }

      const timeParams = parseTimeRange(opts.timeRange);
      const params: Record<string, unknown> = {
        fields: "campaign_name,campaign_id,adset_name,adset_id,ad_name,ad_id,impressions,clicks,ctr,spend,reach,frequency,cpc,cpm,actions,cost_per_action_type",
        level: opts.level,
        limit: opts.limit,
        ...timeParams,
      };

      if (opts.breakdown) {
        params.breakdowns = opts.breakdown;
        params.fields += `,${opts.breakdown}`;
      }

      const res = await makeApiRequest(`${objectId}/insights`, token, params);
      const rows = (res.data ?? []) as InsightRow[];

      if (program.opts().json) {
        console.log(fmt.json(rows));
        return;
      }

      if (rows.length === 0) {
        console.log("No insight data for the specified time range.");
        return;
      }

      console.log(fmt.header(`INSIGHTS — ${opts.timeRange.toUpperCase()}`));
      console.log();

      const tableRows = rows.map((r) => {
        const name = r.campaign_name ?? r.adset_name ?? r.ad_name ?? "—";
        const conversions = getConversions(r);
        const cpa = getCpa(r);
        return [
          name.slice(0, 30),
          r.impressions ? fmt.num(r.impressions) : "0",
          r.clicks ? fmt.num(r.clicks) : "0",
          r.ctr ? fmt.pct(r.ctr) : "0.00%",
          r.spend ? `$${parseFloat(r.spend).toFixed(2)}` : "$0.00",
          conversions > 0 ? conversions.toFixed(1) : "0",
          cpa > 0 ? `$${cpa.toFixed(2)}` : "—",
        ];
      });

      console.log(
        fmt.table(
          ["Name", "Impressions", "Clicks", "CTR", "Spend", "Conversions", "CPA"],
          tableRows
        )
      );

      // Summary
      const totals = rows.reduce(
        (acc, r) => {
          acc.impressions += parseInt(r.impressions ?? "0", 10);
          acc.clicks += parseInt(r.clicks ?? "0", 10);
          acc.spend += parseFloat(r.spend ?? "0");
          acc.conversions += getConversions(r);
          return acc;
        },
        { impressions: 0, clicks: 0, spend: 0, conversions: 0 }
      );

      const ctr = totals.impressions > 0 ? (totals.clicks / totals.impressions) * 100 : 0;
      const avgCpa = totals.conversions > 0 ? totals.spend / totals.conversions : 0;

      console.log();
      console.log(fmt.section("SUMMARY"));
      console.log(
        fmt.kv([
          ["Total Impressions", fmt.num(totals.impressions)],
          ["Total Clicks", fmt.num(totals.clicks)],
          ["CTR", fmt.pct(ctr)],
          ["Total Spend", `$${totals.spend.toFixed(2)}`],
          ["Total Conversions", totals.conversions.toFixed(1)],
          ["Avg CPA", avgCpa > 0 ? `$${avgCpa.toFixed(2)}` : "—"],
        ])
      );
    });

  program
    .command("report")
    .description("Generate a formatted performance report for an ad account")
    .requiredOption("--account-id <id>", "Ad account ID")
    .option("--date <range>", "Date range: today, yesterday, last_7d, last_30d, this_month, maximum", "last_7d")
    .action(async (opts: { accountId: string; date: string }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const timeParams = parseTimeRange(opts.date);

      // Get campaign-level insights
      const res = await makeApiRequest(`${actId}/insights`, token, {
        fields: "campaign_name,campaign_id,impressions,clicks,ctr,spend,reach,frequency,cpc,cpm,actions,cost_per_action_type",
        level: "campaign",
        limit: "100",
        ...timeParams,
      });

      const rows = (res.data ?? []) as InsightRow[];

      if (program.opts().json) {
        console.log(fmt.json(rows));
        return;
      }

      const label = opts.date.toUpperCase().replace(/_/g, " ");

      console.log(fmt.divider("═"));
      console.log(`  META ADS PERFORMANCE REPORT — ${label}`);
      console.log(`  Account: ${actId}`);
      console.log(`  Generated: ${new Date().toISOString()}`);
      console.log(fmt.divider("═"));

      if (rows.length === 0) {
        console.log("\n  No performance data for this time range.\n");
        console.log(fmt.divider("═"));
        return;
      }

      let totalImpressions = 0;
      let totalClicks = 0;
      let totalSpend = 0;
      let totalConversions = 0;
      let totalReach = 0;

      for (const r of rows) {
        const impressions = parseInt(r.impressions ?? "0", 10);
        const clicks = parseInt(r.clicks ?? "0", 10);
        const spend = parseFloat(r.spend ?? "0");
        const reach = parseInt(r.reach ?? "0", 10);
        const conversions = getConversions(r);
        const cpa = getCpa(r);
        const ctr = r.ctr ? parseFloat(r.ctr) : 0;
        const cpc = r.cpc ? parseFloat(r.cpc) : 0;

        totalImpressions += impressions;
        totalClicks += clicks;
        totalSpend += spend;
        totalConversions += conversions;
        totalReach += reach;

        console.log();
        console.log(`  Campaign: ${r.campaign_name ?? "Unknown"} (ID: ${r.campaign_id ?? "?"})`);
        console.log(`    Impressions: ${fmt.num(impressions)}    Reach: ${fmt.num(reach)}`);
        console.log(`    Clicks: ${fmt.num(clicks)}    CTR: ${fmt.pct(ctr)}`);
        console.log(`    Spend: $${spend.toFixed(2)}    CPC: $${cpc.toFixed(2)}`);
        if (conversions > 0) {
          console.log(`    Conversions: ${conversions.toFixed(1)}    CPA: $${cpa.toFixed(2)}`);
        }
      }

      const overallCtr = totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0;
      const overallCpc = totalClicks > 0 ? totalSpend / totalClicks : 0;
      const overallCpa = totalConversions > 0 ? totalSpend / totalConversions : 0;

      console.log();
      console.log(fmt.divider("═"));
      console.log("  SUMMARY");
      console.log(fmt.divider("═"));
      console.log(`  Campaigns:        ${rows.length}`);
      console.log(`  Total Impressions: ${fmt.num(totalImpressions)}`);
      console.log(`  Total Reach:       ${fmt.num(totalReach)}`);
      console.log(`  Total Clicks:      ${fmt.num(totalClicks)}`);
      console.log(`  Overall CTR:       ${fmt.pct(overallCtr)}`);
      console.log(`  Total Spend:       $${totalSpend.toFixed(2)}`);
      console.log(`  Avg CPC:           $${overallCpc.toFixed(2)}`);
      if (totalConversions > 0) {
        console.log(`  Total Conversions: ${totalConversions.toFixed(1)}`);
        console.log(`  Avg CPA:           $${overallCpa.toFixed(2)}`);
      }
      console.log(fmt.divider("═"));
    });
}
