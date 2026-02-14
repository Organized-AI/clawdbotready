import { GoogleAdsClient, validateNumericId } from "../lib/client.js";
import { campaignStatusName } from "../lib/enums.js";
import * as fmt from "../lib/format.js";
import { enums } from "google-ads-api";

interface ManageCampaignOptions {
  customerId?: string;
  action: string;
  campaignId?: string;
  verbose?: boolean;
  json?: boolean;
}

const VALID_ACTIONS = ["pause", "enable"];

export async function manageCampaign(
  options: ManageCampaignOptions
): Promise<void> {
  const client = new GoogleAdsClient();
  const config = client.getConfig();
  const customerId = options.customerId || config.login_customer_id;

  if (!customerId) {
    throw new Error(
      "Customer ID is required. Provide --customer-id or set login_customer_id in config."
    );
  }

  if (!VALID_ACTIONS.includes(options.action)) {
    throw new Error(
      `Invalid action: ${options.action}. Must be one of: ${VALID_ACTIONS.join(", ")}`
    );
  }

  if (!options.campaignId) {
    throw new Error(
      `Campaign ID is required. Use --campaign-id <id>`
    );
  }

  const validatedId = validateNumericId(options.campaignId, "campaign-id");
  const customer = client.getCustomer(customerId);

  // Fetch current campaign state
  const query = `
    SELECT
      campaign.id,
      campaign.name,
      campaign.status,
      campaign.resource_name
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

  const campaign = (results[0] as any).campaign;
  const currentStatus = campaignStatusName(campaign?.status ?? 0);
  const resourceName = String(campaign?.resource_name ?? "");
  const campaignName = String(campaign?.name ?? "N/A");

  const targetStatus =
    options.action === "pause"
      ? enums.CampaignStatus.PAUSED
      : enums.CampaignStatus.ENABLED;
  const targetStatusName = options.action === "pause" ? "PAUSED" : "ENABLED";

  if (currentStatus === targetStatusName) {
    const result = {
      campaign_id: validatedId,
      campaign_name: campaignName,
      status: currentStatus,
      action: "none",
      message: `Campaign is already ${targetStatusName}.`,
    };
    if (options.json) {
      console.log(fmt.json(result));
    } else {
      console.log(`\nCampaign: ${campaignName} (ID: ${validatedId})`);
      console.log(`Status: ${currentStatus}`);
      console.log(`Already ${targetStatusName}. No action needed.\n`);
    }
    return;
  }

  if (options.verbose) {
    console.log(`Mutating ${resourceName} to ${targetStatusName}`);
  }

  // Execute the mutation
  const mutationResult = await customer.mutateResources([
    {
      entity: "campaign",
      operation: "update",
      resource: {
        resource_name: resourceName,
        status: targetStatus,
      },
    } as any,
  ]);

  const result = {
    campaign_id: validatedId,
    campaign_name: campaignName,
    previous_status: currentStatus,
    new_status: targetStatusName,
    action: options.action,
    success: true,
    mutation_result: mutationResult,
  };

  if (options.json) {
    console.log(fmt.json(result));
  } else {
    console.log(`\nCampaign: ${campaignName} (ID: ${validatedId})`);
    console.log(`Previous Status: ${currentStatus}`);
    console.log(`New Status: ${targetStatusName}`);
    console.log(`Action: ${options.action} — SUCCESS\n`);
  }
}
