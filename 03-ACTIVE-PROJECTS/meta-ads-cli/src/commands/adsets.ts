import type { Command } from "commander";
import { getAccessToken } from "../lib/auth.js";
import { makeApiRequest, ensureActPrefix } from "../lib/client.js";
import * as fmt from "../lib/format.js";

const ADSET_FIELDS = "id,name,status,effective_status,campaign_id,optimization_goal,billing_event,daily_budget,lifetime_budget,bid_amount,bid_strategy,start_time,end_time,targeting,is_dynamic_creative,frequency_control_specs{event,interval_days,max_frequency}";

export function registerAdsetCommands(program: Command): void {
  program
    .command("adsets")
    .description("List ad sets for an account or campaign")
    .requiredOption("--account-id <id>", "Ad account ID")
    .option("--campaign-id <id>", "Filter by campaign ID")
    .option("--limit <n>", "Max ad sets to return", "25")
    .action(async (opts: { accountId: string; campaignId?: string; limit: string }) => {
      const token = getAccessToken();

      let endpoint: string;
      if (opts.campaignId) {
        endpoint = `${opts.campaignId}/adsets`;
      } else {
        endpoint = `${ensureActPrefix(opts.accountId)}/adsets`;
      }

      const res = await makeApiRequest(endpoint, token, {
        fields: ADSET_FIELDS,
        limit: opts.limit,
      });

      const adsets = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(adsets));
        return;
      }

      if (adsets.length === 0) {
        console.log("No ad sets found.");
        return;
      }

      console.log(fmt.header("AD SETS"));
      console.log();

      const rows = adsets.map((a) => [
        String(a.id ?? ""),
        String(a.name ?? "").slice(0, 40),
        String(a.effective_status ?? a.status ?? ""),
        String(a.optimization_goal ?? ""),
        a.daily_budget ? fmt.currency(a.daily_budget as string) : "—",
        a.lifetime_budget ? fmt.currency(a.lifetime_budget as string) : "—",
      ]);

      console.log(
        fmt.table(["Ad Set ID", "Name", "Status", "Optimization", "Daily Budget", "Lifetime Budget"], rows)
      );
      console.log();
      console.log(`${adsets.length} ad set(s) found.`);
    });

  program
    .command("adset-details")
    .description("Get details for a specific ad set")
    .requiredOption("--adset-id <id>", "Ad set ID")
    .action(async (opts: { adsetId: string }) => {
      const token = getAccessToken();
      const res = await makeApiRequest(opts.adsetId, token, {
        fields: ADSET_FIELDS + ",promoted_object,destination_type",
      });

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(fmt.header(`AD SET: ${res.name ?? opts.adsetId}`));
      console.log();

      const targeting = res.targeting as Record<string, unknown> | undefined;
      let targetingSummary = "—";
      if (targeting) {
        const parts: string[] = [];
        if (targeting.age_min || targeting.age_max) {
          parts.push(`Age: ${targeting.age_min ?? "?"}–${targeting.age_max ?? "?"}`);
        }
        if (targeting.genders) {
          const g = targeting.genders as number[];
          const labels = g.map((v) => (v === 1 ? "Male" : v === 2 ? "Female" : "All"));
          parts.push(`Gender: ${labels.join(", ")}`);
        }
        if (targeting.geo_locations) {
          const geo = targeting.geo_locations as Record<string, unknown>;
          if (geo.countries) parts.push(`Countries: ${(geo.countries as string[]).join(", ")}`);
        }
        targetingSummary = parts.join(" | ") || JSON.stringify(targeting).slice(0, 100);
      }

      console.log(
        fmt.kv([
          ["Ad Set ID", String(res.id ?? "")],
          ["Name", String(res.name ?? "")],
          ["Status", String(res.effective_status ?? res.status ?? "")],
          ["Campaign ID", String(res.campaign_id ?? "")],
          ["Optimization", String(res.optimization_goal ?? "")],
          ["Billing Event", String(res.billing_event ?? "")],
          ["Bid Strategy", String(res.bid_strategy ?? "—")],
          ["Bid Amount", res.bid_amount ? fmt.currency(res.bid_amount as string) : "—"],
          ["Daily Budget", res.daily_budget ? fmt.currency(res.daily_budget as string) : "—"],
          ["Lifetime Budget", res.lifetime_budget ? fmt.currency(res.lifetime_budget as string) : "—"],
          ["Dynamic Creative", String(res.is_dynamic_creative ?? false)],
          ["Start Time", String(res.start_time ?? "—")],
          ["End Time", String(res.end_time ?? "—")],
          ["Targeting", targetingSummary],
        ])
      );
    });

  // --- Write operations ---

  program
    .command("create-adset")
    .description("Create a new ad set (defaults to PAUSED)")
    .requiredOption("--account-id <id>", "Ad account ID")
    .requiredOption("--campaign-id <id>", "Parent campaign ID")
    .requiredOption("--name <name>", "Ad set name")
    .requiredOption("--optimization-goal <goal>", "Optimization goal (REACH, LINK_CLICKS, IMPRESSIONS, OFFSITE_CONVERSIONS, LEAD_GENERATION, etc.)")
    .requiredOption("--billing-event <event>", "Billing event (IMPRESSIONS, LINK_CLICKS, etc.)")
    .option("--status <status>", "Initial status", "PAUSED")
    .option("--daily-budget <amount>", "Daily budget in cents")
    .option("--lifetime-budget <amount>", "Lifetime budget in cents")
    .option("--targeting <json>", "Targeting spec as JSON string")
    .option("--bid-amount <amount>", "Bid amount in cents")
    .option("--bid-strategy <strategy>", "Bid strategy")
    .option("--start-time <time>", "Start time (ISO 8601)")
    .option("--end-time <time>", "End time (ISO 8601)")
    .option("--promoted-object <json>", "Promoted object as JSON string")
    .option("--dynamic-creative", "Enable dynamic creative")
    .action(async (opts: {
      accountId: string;
      campaignId: string;
      name: string;
      optimizationGoal: string;
      billingEvent: string;
      status: string;
      dailyBudget?: string;
      lifetimeBudget?: string;
      targeting?: string;
      bidAmount?: string;
      bidStrategy?: string;
      startTime?: string;
      endTime?: string;
      promotedObject?: string;
      dynamicCreative?: boolean;
    }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const params: Record<string, unknown> = {
        campaign_id: opts.campaignId,
        name: opts.name,
        optimization_goal: opts.optimizationGoal.toUpperCase(),
        billing_event: opts.billingEvent.toUpperCase(),
        status: opts.status.toUpperCase(),
      };

      if (opts.dailyBudget) params.daily_budget = opts.dailyBudget;
      if (opts.lifetimeBudget) params.lifetime_budget = opts.lifetimeBudget;
      if (opts.targeting) params.targeting = opts.targeting;
      if (opts.bidAmount) params.bid_amount = opts.bidAmount;
      if (opts.bidStrategy) params.bid_strategy = opts.bidStrategy.toUpperCase();
      if (opts.startTime) params.start_time = opts.startTime;
      if (opts.endTime) params.end_time = opts.endTime;
      if (opts.promotedObject) params.promoted_object = opts.promotedObject;
      if (opts.dynamicCreative) params.is_dynamic_creative = true;

      const res = await makeApiRequest(`${actId}/adsets`, token, params, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Ad set created successfully.`);
      console.log(`  ID:     ${res.id}`);
      console.log(`  Name:   ${opts.name}`);
      console.log(`  Status: ${opts.status.toUpperCase()}`);
    });

  program
    .command("update-adset")
    .description("Update an existing ad set")
    .requiredOption("--adset-id <id>", "Ad set ID")
    .option("--status <status>", "New status (ACTIVE, PAUSED, ARCHIVED)")
    .option("--daily-budget <amount>", "New daily budget in cents")
    .option("--lifetime-budget <amount>", "New lifetime budget in cents")
    .option("--targeting <json>", "New targeting spec as JSON string")
    .option("--bid-amount <amount>", "New bid amount in cents")
    .option("--bid-strategy <strategy>", "New bid strategy")
    .option("--optimization-goal <goal>", "New optimization goal")
    .action(async (opts: {
      adsetId: string;
      status?: string;
      dailyBudget?: string;
      lifetimeBudget?: string;
      targeting?: string;
      bidAmount?: string;
      bidStrategy?: string;
      optimizationGoal?: string;
    }) => {
      const params: Record<string, unknown> = {};
      if (opts.status) params.status = opts.status.toUpperCase();
      if (opts.dailyBudget) params.daily_budget = opts.dailyBudget;
      if (opts.lifetimeBudget) params.lifetime_budget = opts.lifetimeBudget;
      if (opts.targeting) params.targeting = opts.targeting;
      if (opts.bidAmount) params.bid_amount = opts.bidAmount;
      if (opts.bidStrategy) params.bid_strategy = opts.bidStrategy.toUpperCase();
      if (opts.optimizationGoal) params.optimization_goal = opts.optimizationGoal.toUpperCase();

      if (Object.keys(params).length === 0) {
        console.error("No update fields provided.");
        process.exit(1);
      }

      const token = getAccessToken();
      const res = await makeApiRequest(opts.adsetId, token, params, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Ad set ${opts.adsetId} updated.`);
      for (const [key, value] of Object.entries(params)) {
        console.log(`  ${key}: ${value}`);
      }
    });
}
