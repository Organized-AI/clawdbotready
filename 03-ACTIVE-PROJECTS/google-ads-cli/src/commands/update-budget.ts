import { GoogleAdsClient, validateNumericId } from "../lib/client.js";
import { campaignStatusName } from "../lib/enums.js";
import * as fmt from "../lib/format.js";

interface UpdateBudgetOptions {
  customerId?: string;
  campaignId: string;
  amount: string;
  dryRun?: boolean;
  verbose?: boolean;
  json?: boolean;
}

export async function updateBudget(
  options: UpdateBudgetOptions
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
  const dollars = Number(options.amount);

  if (isNaN(dollars) || dollars <= 0) {
    throw new Error(
      "Amount must be a positive number in dollars (e.g. --amount 500 for $500/day)."
    );
  }

  if (dollars > 10000) {
    console.warn(
      `WARNING: Budget of $${dollars.toLocaleString()} seems very high. ` +
        `The --amount flag accepts dollars, not micros. ` +
        `Did you mean $${(dollars / 1_000_000).toFixed(2)}?`
    );
  }

  const newMicros = fmt.dollarsToMicros(dollars);
  const validatedId = validateNumericId(options.campaignId, "campaign-id");

  // Fetch current campaign + budget
  const query = `
    SELECT
      campaign.id,
      campaign.name,
      campaign.status,
      campaign_budget.amount_micros,
      campaign_budget.resource_name
    FROM campaign
    WHERE campaign.id = ${validatedId}
  `;

  if (options.verbose) {
    console.log("Executing query:", query);
  }

  const results = await customer.query(query);

  if (results.length === 0) {
    throw new Error(`Campaign ${options.campaignId} not found.`);
  }

  const row = results[0] as any;
  const campaign = row.campaign;
  const budget = row.campaign_budget;
  const oldMicros = Number(budget?.amount_micros || 0);
  const oldDollars = fmt.microsToDollars(oldMicros);
  const budgetResourceName = String(budget?.resource_name ?? "");
  const campaignName = String(campaign?.name ?? "N/A");
  const campaignStatus = campaignStatusName(campaign?.status ?? 0);

  if (!budgetResourceName) {
    throw new Error("Could not find budget resource for this campaign.");
  }

  const change = dollars - oldDollars;
  const changeSign = change >= 0 ? "+" : "-";

  const preview = {
    campaign_id: validatedId,
    campaign_name: campaignName,
    campaign_status: campaignStatus,
    current_budget: oldDollars,
    new_budget: dollars,
    change: change,
    current_micros: oldMicros,
    new_micros: newMicros,
  };

  if (options.dryRun) {
    if (options.json) {
      console.log(fmt.json({ ...preview, dry_run: true }));
    } else {
      console.log(`\nDRY RUN — Budget Preview`);
      console.log(`Campaign: ${campaignName} (${campaignStatus})`);
      console.log(`Current Budget: $${oldDollars.toFixed(2)}/day`);
      console.log(`New Budget:     $${dollars.toFixed(2)}/day`);
      console.log(
        `Change:         ${changeSign}$${Math.abs(change).toFixed(2)}`
      );
      console.log(`\nNo changes applied. Remove --dry-run to apply.\n`);
    }
    return;
  }

  if (options.verbose) {
    console.log(
      `Mutating ${budgetResourceName} from ${oldMicros} to ${newMicros} micros`
    );
  }

  // Execute the mutation
  const mutationResult = await customer.mutateResources([
    {
      entity: "campaign_budget",
      operation: "update",
      resource: {
        resource_name: budgetResourceName,
        amount_micros: newMicros,
      },
    } as any,
  ]);

  const result = {
    ...preview,
    success: true,
    mutation_result: mutationResult,
  };

  if (options.json) {
    console.log(fmt.json(result));
  } else {
    console.log(`\nBudget Updated`);
    console.log(`Campaign: ${campaignName} (${campaignStatus})`);
    console.log(`Previous: $${oldDollars.toFixed(2)}/day`);
    console.log(`New:      $${dollars.toFixed(2)}/day`);
    console.log(`Change:   ${changeSign}$${Math.abs(change).toFixed(2)}`);
    console.log(`Status:   SUCCESS\n`);
  }
}
