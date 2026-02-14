#!/usr/bin/env node
import { Command } from "commander";
import { readFileSync } from "fs";
import { join } from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";
import { listCampaigns } from "./commands/list-campaigns.js";
import { getCpaMetrics } from "./commands/get-cpa-metrics.js";
import { updateBudget } from "./commands/update-budget.js";
import { generateReport } from "./commands/generate-report.js";
import { manageCampaign } from "./commands/manage-campaign.js";
import { registerGuideCommand } from "./commands/help-cmd.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const packageJson = JSON.parse(
  readFileSync(join(__dirname, "../", "package.json"), "utf-8")
);

const program = new Command();

program
  .name("google-ads-cli")
  .description("Lightweight CLI for Google Ads API access")
  .version(packageJson.version);

// Global options
program.option("--customer-id <id>", "Google Ads customer ID");
program.option("--verbose", "Enable verbose logging");
program.option("--json", "Output machine-readable JSON");
program.option("--active-only", "Show only ENABLED campaigns");

// List campaigns command
program
  .command("list-campaigns")
  .alias("campaigns")
  .description("List campaigns with optional filter")
  .option("--filter <name>", "Filter campaigns by name")
  .action(async (options) => {
    try {
      const opts = program.opts();
      await listCampaigns({
        customerId: opts.customerId,
        filter: options.filter,
        verbose: opts.verbose,
        json: opts.json,
        activeOnly: opts.activeOnly,
      });
    } catch (error) {
      console.error(
        "Error:",
        error instanceof Error ? error.message : "Unknown error"
      );
      process.exit(1);
    }
  });

// Get CPA metrics command
program
  .command("get-cpa-metrics")
  .alias("cpa")
  .description("Fetch CPA metrics from Google Ads API")
  .option(
    "--date <range>",
    "Date range (TODAY, YESTERDAY, LAST_7_DAYS, LAST_30_DAYS)",
    "TODAY"
  )
  .option("--filter <name>", "Filter campaigns by name")
  .action(async (options) => {
    try {
      const opts = program.opts();
      await getCpaMetrics({
        customerId: opts.customerId,
        dateRange: options.date,
        filter: options.filter,
        verbose: opts.verbose,
        json: opts.json,
        activeOnly: opts.activeOnly,
      });
    } catch (error) {
      console.error(
        "Error:",
        error instanceof Error ? error.message : "Unknown error"
      );
      process.exit(1);
    }
  });

// Update budget command
program
  .command("update-budget")
  .alias("budget")
  .description("Update campaign daily budget (amount in dollars)")
  .requiredOption("--campaign-id <id>", "Campaign ID to update")
  .requiredOption("--amount <dollars>", "Daily budget in dollars (e.g. 500)")
  .option("--dry-run", "Preview changes without applying")
  .action(async (options) => {
    try {
      const opts = program.opts();
      await updateBudget({
        customerId: opts.customerId,
        campaignId: options.campaignId,
        amount: options.amount,
        dryRun: options.dryRun,
        verbose: opts.verbose,
        json: opts.json,
      });
    } catch (error) {
      console.error(
        "Error:",
        error instanceof Error ? error.message : "Unknown error"
      );
      process.exit(1);
    }
  });

// Generate report command
program
  .command("generate-report")
  .alias("report")
  .description("Generate formatted performance report")
  .option(
    "--date <range>",
    "Date range (TODAY, YESTERDAY, LAST_7_DAYS, LAST_30_DAYS)",
    "LAST_7_DAYS"
  )
  .option("--metrics <metrics>", "Comma-separated metrics to include")
  .action(async (options) => {
    try {
      const opts = program.opts();
      await generateReport({
        customerId: opts.customerId,
        dateRange: options.date,
        metrics: options.metrics?.split(","),
        verbose: opts.verbose,
        json: opts.json,
        activeOnly: opts.activeOnly,
      });
    } catch (error) {
      console.error(
        "Error:",
        error instanceof Error ? error.message : "Unknown error"
      );
      process.exit(1);
    }
  });

// Manage campaign command
program
  .command("manage-campaign <action>")
  .alias("manage")
  .description("Manage campaign lifecycle (pause, enable)")
  .option("--campaign-id <id>", "Campaign ID (required for pause/enable)")
  .action(async (action, options) => {
    try {
      const opts = program.opts();
      await manageCampaign({
        customerId: opts.customerId,
        action,
        campaignId: options.campaignId,
        verbose: opts.verbose,
        json: opts.json,
      });
    } catch (error) {
      console.error(
        "Error:",
        error instanceof Error ? error.message : "Unknown error"
      );
      process.exit(1);
    }
  });

// Guide command (user-facing help)
registerGuideCommand(program);

program.parse();
