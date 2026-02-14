import { GoogleAdsClient, sanitizeGaqlString } from "../lib/client.js";
import { campaignStatusName } from "../lib/enums.js";
import * as fmt from "../lib/format.js";

interface ListCampaignsOptions {
  customerId?: string;
  filter?: string;
  verbose?: boolean;
  json?: boolean;
  activeOnly?: boolean;
}

export async function listCampaigns(
  options: ListCampaignsOptions
): Promise<void> {
  const client = new GoogleAdsClient();
  const config = client.getConfig();
  const customerId = options.customerId || config.login_customer_id;

  if (!customerId) {
    throw new Error(
      "Customer ID is required. Provide --customer-id or set login_customer_id in config."
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
      campaign_budget.amount_micros
    FROM campaign
    WHERE ${statusFilter}
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
      console.log(fmt.json([]));
    } else {
      console.log("No campaigns found.");
    }
    return;
  }

  if (options.json) {
    const data = results.map((row: any) => ({
      id: String(row.campaign?.id ?? ""),
      name: String(row.campaign?.name ?? ""),
      status: campaignStatusName(row.campaign?.status ?? 0),
      budget_dollars: fmt.microsToDollars(
        Number(row.campaign_budget?.amount_micros ?? 0)
      ),
      budget_micros: Number(row.campaign_budget?.amount_micros ?? 0),
    }));
    console.log(fmt.json(data));
    return;
  }

  const label = options.activeOnly ? "Active Campaigns" : "Campaigns";
  console.log(`\n${label}:`);

  const rows = results.map((row: any) => [
    String(row.campaign?.id ?? "N/A"),
    String(row.campaign?.name ?? "N/A").substring(0, 35),
    campaignStatusName(row.campaign?.status ?? 0),
    fmt.currency(Number(row.campaign_budget?.amount_micros ?? 0)),
  ]);

  console.log(fmt.table(["ID", "Name", "Status", "Budget/Day"], rows));
  console.log(`\nTotal: ${results.length} campaign(s)\n`);
}
