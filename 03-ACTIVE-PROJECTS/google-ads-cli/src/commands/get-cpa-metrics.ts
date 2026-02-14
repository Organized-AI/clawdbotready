import { GoogleAdsClient, sanitizeGaqlString } from "../lib/client.js";
import { campaignStatusName } from "../lib/enums.js";
import * as fmt from "../lib/format.js";

interface CpaMetricsOptions {
  customerId?: string;
  dateRange?: string;
  filter?: string;
  verbose?: boolean;
  json?: boolean;
  activeOnly?: boolean;
}

const DATE_RANGES = [
  "TODAY",
  "YESTERDAY",
  "LAST_7_DAYS",
  "LAST_30_DAYS",
  "THIS_MONTH",
  "LAST_MONTH",
];

export async function getCpaMetrics(
  options: CpaMetricsOptions
): Promise<void> {
  const client = new GoogleAdsClient();
  const config = client.getConfig();
  const customerId = options.customerId || config.login_customer_id;

  if (!customerId) {
    throw new Error(
      "Customer ID is required. Provide --customer-id or set login_customer_id in config."
    );
  }

  const dateRange = options.dateRange || "TODAY";
  if (!DATE_RANGES.includes(dateRange)) {
    throw new Error(
      `Invalid date range. Must be one of: ${DATE_RANGES.join(", ")}`
    );
  }

  const customer = client.getCustomer(customerId);

  const statusFilter = options.activeOnly
    ? `campaign.status = 'ENABLED'`
    : `campaign.status != 'REMOVED'`;

  let query = `
    SELECT
      campaign.id,
      campaign.name,
      campaign.status,
      metrics.impressions,
      metrics.clicks,
      metrics.conversions,
      metrics.cost_micros
    FROM campaign
    WHERE ${statusFilter}
      AND segments.date DURING ${dateRange}
  `;

  if (options.filter) {
    query += ` AND campaign.name LIKE "%${sanitizeGaqlString(options.filter)}%"`;
  }

  query += ` ORDER BY campaign.name`;

  if (options.verbose) {
    console.log("Executing query:", query);
  }

  const results = await customer.query(query);

  if (results.length === 0) {
    if (options.json) {
      console.log(fmt.json({ campaigns: [], summary: {} }));
    } else {
      console.log("No campaigns found with metrics.");
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
    const cpa = conversions > 0 ? cost / conversions : 0;

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
      cpa,
    };
  });

  const summary = {
    total_campaigns: campaigns.length,
    total_impressions: totalImpressions,
    total_clicks: totalClicks,
    total_conversions: totalConversions,
    total_cost: totalCost,
    avg_cpa: totalConversions > 0 ? totalCost / totalConversions : 0,
    ctr: totalImpressions > 0 ? totalClicks / totalImpressions : 0,
    conversion_rate: totalClicks > 0 ? totalConversions / totalClicks : 0,
  };

  if (options.json) {
    console.log(fmt.json({ campaigns, summary }));
    return;
  }

  const label = options.activeOnly
    ? `CPA Metrics — Active Only (${dateRange})`
    : `CPA Metrics (${dateRange})`;
  console.log(`\n${label}:`);

  const rows = campaigns.map((c) => [
    c.name.substring(0, 30),
    fmt.num(c.impressions),
    fmt.num(c.clicks),
    c.conversions.toFixed(2),
    `$${c.cost.toFixed(2)}`,
    c.conversions > 0 ? `$${c.cpa.toFixed(2)}` : "N/A",
  ]);

  console.log(
    fmt.table(
      ["Campaign", "Impressions", "Clicks", "Conv", "Cost", "CPA"],
      rows
    )
  );

  console.log(
    "\n" +
      fmt.kv([
        ["Total Spend", `$${totalCost.toFixed(2)}`],
        ["Total Conversions", totalConversions.toFixed(2)],
        [
          "Avg CPA",
          totalConversions > 0
            ? `$${summary.avg_cpa.toFixed(2)}`
            : "N/A",
        ],
        ["CTR", fmt.pct(summary.ctr)],
        ["Conv Rate", fmt.pct(summary.conversion_rate)],
      ]) +
      "\n"
  );
}
