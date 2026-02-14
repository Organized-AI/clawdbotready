import type { Command } from "commander";
import { getAccessToken } from "../lib/auth.js";
import { makeApiRequest, ensureActPrefix } from "../lib/client.js";
import * as fmt from "../lib/format.js";

const CAMPAIGN_FIELDS = "id,name,objective,status,effective_status,daily_budget,lifetime_budget,buying_type,start_time,stop_time,created_time,updated_time,bid_strategy";

const VALID_OBJECTIVES = [
  "OUTCOME_AWARENESS",
  "OUTCOME_TRAFFIC",
  "OUTCOME_ENGAGEMENT",
  "OUTCOME_LEADS",
  "OUTCOME_SALES",
  "OUTCOME_APP_PROMOTION",
];

export function registerCampaignCommands(program: Command): void {
  program
    .command("campaigns")
    .description("List campaigns for an ad account")
    .requiredOption("--account-id <id>", "Ad account ID")
    .option("--status <status>", "Filter by status (ACTIVE, PAUSED, ARCHIVED)")
    .option("--objective <obj>", "Filter by objective")
    .option("--limit <n>", "Max campaigns to return", "25")
    .action(async (opts: { accountId: string; status?: string; objective?: string; limit: string }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const params: Record<string, unknown> = {
        fields: CAMPAIGN_FIELDS,
        limit: opts.limit,
      };

      if (opts.status) {
        params.effective_status = JSON.stringify([opts.status.toUpperCase()]);
      }

      if (opts.objective) {
        params.filtering = JSON.stringify([{
          field: "objective",
          operator: "IN",
          value: [opts.objective.toUpperCase()],
        }]);
      }

      const res = await makeApiRequest(`${actId}/campaigns`, token, params);
      const campaigns = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(campaigns));
        return;
      }

      if (campaigns.length === 0) {
        console.log("No campaigns found.");
        return;
      }

      console.log(fmt.header(`CAMPAIGNS — ${actId}`));
      console.log();

      const rows = campaigns.map((c) => [
        String(c.id ?? ""),
        String(c.name ?? ""),
        String(c.objective ?? ""),
        String(c.effective_status ?? c.status ?? ""),
        c.daily_budget ? fmt.currency(c.daily_budget as string) : "—",
        c.lifetime_budget ? fmt.currency(c.lifetime_budget as string) : "—",
      ]);

      console.log(
        fmt.table(["Campaign ID", "Name", "Objective", "Status", "Daily Budget", "Lifetime Budget"], rows)
      );
      console.log();
      console.log(`${campaigns.length} campaign(s) found.`);
    });

  program
    .command("campaign-details")
    .description("Get details for a specific campaign")
    .requiredOption("--campaign-id <id>", "Campaign ID")
    .action(async (opts: { campaignId: string }) => {
      const token = getAccessToken();
      const res = await makeApiRequest(opts.campaignId, token, {
        fields: CAMPAIGN_FIELDS + ",special_ad_categories,spend_cap,budget_remaining",
      });

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(fmt.header(`CAMPAIGN: ${res.name ?? opts.campaignId}`));
      console.log();
      console.log(
        fmt.kv([
          ["Campaign ID", String(res.id ?? "")],
          ["Name", String(res.name ?? "")],
          ["Objective", String(res.objective ?? "")],
          ["Status", String(res.effective_status ?? res.status ?? "")],
          ["Buying Type", String(res.buying_type ?? "")],
          ["Bid Strategy", String(res.bid_strategy ?? "—")],
          ["Daily Budget", res.daily_budget ? fmt.currency(res.daily_budget as string) : "—"],
          ["Lifetime Budget", res.lifetime_budget ? fmt.currency(res.lifetime_budget as string) : "—"],
          ["Budget Remaining", res.budget_remaining ? fmt.currency(res.budget_remaining as string) : "—"],
          ["Spend Cap", res.spend_cap ? fmt.currency(res.spend_cap as string) : "No cap"],
          ["Start Time", String(res.start_time ?? "—")],
          ["Stop Time", String(res.stop_time ?? "—")],
          ["Created", String(res.created_time ?? "")],
          ["Updated", String(res.updated_time ?? "")],
        ])
      );
    });

  // --- Write operations ---

  program
    .command("create-campaign")
    .description("Create a new campaign (defaults to PAUSED)")
    .requiredOption("--account-id <id>", "Ad account ID")
    .requiredOption("--name <name>", "Campaign name")
    .requiredOption("--objective <obj>", `Objective: ${VALID_OBJECTIVES.join(", ")}`)
    .option("--status <status>", "Initial status", "PAUSED")
    .option("--daily-budget <amount>", "Daily budget in cents")
    .option("--lifetime-budget <amount>", "Lifetime budget in cents")
    .option("--bid-strategy <strategy>", "Bid strategy (LOWEST_COST_WITHOUT_CAP, LOWEST_COST_WITH_BID_CAP, COST_CAP)")
    .option("--special-ad-categories <cats>", "Comma-separated: CREDIT, EMPLOYMENT, HOUSING, SOCIAL_ISSUES_ELECTIONS_POLITICS")
    .action(async (opts: {
      accountId: string;
      name: string;
      objective: string;
      status: string;
      dailyBudget?: string;
      lifetimeBudget?: string;
      bidStrategy?: string;
      specialAdCategories?: string;
    }) => {
      const objective = opts.objective.toUpperCase();
      if (!VALID_OBJECTIVES.includes(objective)) {
        console.error(`Invalid objective: ${opts.objective}`);
        console.error(`Valid: ${VALID_OBJECTIVES.join(", ")}`);
        process.exit(1);
      }

      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const params: Record<string, unknown> = {
        name: opts.name,
        objective,
        status: opts.status.toUpperCase(),
        special_ad_categories: opts.specialAdCategories
          ? JSON.stringify(opts.specialAdCategories.split(",").map((s) => s.trim()))
          : "[]",
      };

      if (opts.dailyBudget) params.daily_budget = opts.dailyBudget;
      if (opts.lifetimeBudget) params.lifetime_budget = opts.lifetimeBudget;
      if (opts.bidStrategy) params.bid_strategy = opts.bidStrategy.toUpperCase();

      const res = await makeApiRequest(`${actId}/campaigns`, token, params, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Campaign created successfully.`);
      console.log(`  ID:     ${res.id}`);
      console.log(`  Name:   ${opts.name}`);
      console.log(`  Status: ${opts.status.toUpperCase()}`);
    });

  program
    .command("update-campaign")
    .description("Update an existing campaign")
    .requiredOption("--campaign-id <id>", "Campaign ID")
    .option("--name <name>", "New campaign name")
    .option("--status <status>", "New status (ACTIVE, PAUSED, ARCHIVED)")
    .option("--daily-budget <amount>", "New daily budget in cents")
    .option("--lifetime-budget <amount>", "New lifetime budget in cents")
    .option("--bid-strategy <strategy>", "New bid strategy")
    .option("--spend-cap <amount>", "Spend cap in cents")
    .action(async (opts: {
      campaignId: string;
      name?: string;
      status?: string;
      dailyBudget?: string;
      lifetimeBudget?: string;
      bidStrategy?: string;
      spendCap?: string;
    }) => {
      const params: Record<string, unknown> = {};
      if (opts.name) params.name = opts.name;
      if (opts.status) params.status = opts.status.toUpperCase();
      if (opts.dailyBudget) params.daily_budget = opts.dailyBudget;
      if (opts.lifetimeBudget) params.lifetime_budget = opts.lifetimeBudget;
      if (opts.bidStrategy) params.bid_strategy = opts.bidStrategy.toUpperCase();
      if (opts.spendCap) params.spend_cap = opts.spendCap;

      if (Object.keys(params).length === 0) {
        console.error("No update fields provided. Use --name, --status, --daily-budget, etc.");
        process.exit(1);
      }

      const token = getAccessToken();
      const res = await makeApiRequest(opts.campaignId, token, params, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Campaign ${opts.campaignId} updated.`);
      for (const [key, value] of Object.entries(params)) {
        console.log(`  ${key}: ${value}`);
      }
    });
}
