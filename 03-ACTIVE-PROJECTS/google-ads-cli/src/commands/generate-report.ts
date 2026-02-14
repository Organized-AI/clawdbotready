import { GoogleAdsClient } from "../lib/client.js";
import { campaignStatusName } from "../lib/enums.js";
import * as fmt from "../lib/format.js";

interface GenerateReportOptions {
  customerId?: string;
  dateRange?: string;
  metrics?: string[];
  verbose?: boolean;
  json?: boolean;
  activeOnly?: boolean;
}

const DEFAULT_METRICS = [
  "impressions",
  "clicks",
  "conversions",
  "cost_micros",
  "average_cpc",
  "ctr",
];

const DATE_RANGES = [
  "TODAY",
  "YESTERDAY",
  "LAST_7_DAYS",
  "LAST_30_DAYS",
  "THIS_MONTH",
  "LAST_MONTH",
];

export async function generateReport(
  options: GenerateReportOptions
): Promise<void> {
  const client = new GoogleAdsClient();
  const config = client.getConfig();
  const customerId = options.customerId || config.login_customer_id;

  if (!customerId) {
    throw new Error(
      "Customer ID is required. Provide --customer-id or set login_customer_id in config."
    );
  }

  const dateRange = options.dateRange || "LAST_7_DAYS";
  if (!DATE_RANGES.includes(dateRange)) {
    throw new Error(
      `Invalid date range. Must be one of: ${DATE_RANGES.join(", ")}`
    );
  }

  const metrics = options.metrics || DEFAULT_METRICS;
  const customer = client.getCustomer(customerId);
  const metricsQuery = metrics.map((m) => `metrics.${m}`).join(", ");

  const statusFilter = options.activeOnly
    ? `campaign.status = 'ENABLED'`
    : `campaign.status != 'REMOVED'`;

  const query = `
    SELECT
      campaign.id,
      campaign.name,
      campaign.status,
      ${metricsQuery}
    FROM campaign
    WHERE ${statusFilter}
      AND segments.date DURING ${dateRange}
    ORDER BY metrics.cost_micros DESC
  `;

  if (options.verbose) {
    console.log("Executing query:", query);
  }

  const results = await customer.query(query);

  if (results.length === 0) {
    if (options.json) {
      console.log(fmt.json({ campaigns: [], summary: {} }));
    } else {
      console.log("No campaigns found.");
    }
    return;
  }

  let totalImpressions = 0;
  let totalClicks = 0;
  let totalConversions = 0;
  let totalCost = 0;

  const campaigns = results.map((row: any) => {
    const impressions = Number(row.metrics?.impressions || 0);
    const clicks = Number(row.metrics?.clicks || 0);
    const conversions = Number(row.metrics?.conversions || 0);
    const costMicros = Number(row.metrics?.cost_micros || 0);
    const cost = fmt.microsToDollars(costMicros);
    const cpc = fmt.microsToDollars(Number(row.metrics?.average_cpc || 0));
    const cpa = conversions > 0 ? cost / conversions : 0;
    const ctr = Number(row.metrics?.ctr || 0);

    totalImpressions += impressions;
    totalClicks += clicks;
    totalConversions += conversions;
    totalCost += cost;

    return {
      id: String(row.campaign?.id ?? ""),
      name: String(row.campaign?.name ?? ""),
      status: campaignStatusName(row.campaign?.status ?? 0),
      impressions,
      clicks,
      conversions,
      cost,
      cpc,
      cpa,
      ctr,
    };
  });

  const summary = {
    total_campaigns: campaigns.length,
    total_impressions: totalImpressions,
    total_clicks: totalClicks,
    total_conversions: totalConversions,
    total_cost: totalCost,
    avg_cpa: totalConversions > 0 ? totalCost / totalConversions : 0,
    avg_cpc: totalClicks > 0 ? totalCost / totalClicks : 0,
    avg_ctr: totalImpressions > 0 ? totalClicks / totalImpressions : 0,
    conversion_rate: totalClicks > 0 ? totalConversions / totalClicks : 0,
  };

  if (options.json) {
    console.log(fmt.json({ campaigns, summary }));
    return;
  }

  const label = options.activeOnly ? "ACTIVE CAMPAIGNS ONLY" : "ALL CAMPAIGNS";
  console.log(
    "\n" +
      fmt.header(
        `GOOGLE ADS PERFORMANCE REPORT — ${dateRange}\n  Customer: ${customerId} | ${label}\n  Generated: ${new Date().toISOString()}`
      )
  );

  for (const c of campaigns) {
    console.log(`\n  ${c.name} (${c.status})`);
    console.log(
      fmt.kv([
        ["ID", c.id],
        ["Impressions", fmt.num(c.impressions)],
        ["Clicks", fmt.num(c.clicks)],
        ["CTR", fmt.pct(c.ctr)],
        ["Conversions", c.conversions.toFixed(2)],
        ["Cost", `$${c.cost.toFixed(2)}`],
        ["Avg CPC", `$${c.cpc.toFixed(2)}`],
        ["Avg CPA", c.conversions > 0 ? `$${c.cpa.toFixed(2)}` : "N/A"],
      ])
    );
  }

  console.log("\n" + fmt.header("SUMMARY"));
  console.log(
    fmt.kv([
      ["Total Campaigns", String(summary.total_campaigns)],
      ["Total Impressions", fmt.num(summary.total_impressions)],
      ["Total Clicks", fmt.num(summary.total_clicks)],
      ["Total Conversions", summary.total_conversions.toFixed(2)],
      ["Total Spend", `$${summary.total_cost.toFixed(2)}`],
      ["Avg CTR", fmt.pct(summary.avg_ctr)],
      ["Avg CPC", `$${summary.avg_cpc.toFixed(2)}`],
      [
        "Avg CPA",
        summary.total_conversions > 0
          ? `$${summary.avg_cpa.toFixed(2)}`
          : "N/A",
      ],
      ["Conv Rate", fmt.pct(summary.conversion_rate)],
    ]) + "\n"
  );
}
