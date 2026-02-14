#!/usr/bin/env node

import { Command } from "commander";
import { registerAuthCommands } from "./commands/auth-cmd.js";
import { registerAccountCommands } from "./commands/accounts.js";
import { registerCampaignCommands } from "./commands/campaigns.js";
import { registerAdsetCommands } from "./commands/adsets.js";
import { registerAdCommands } from "./commands/ads.js";
import { registerInsightCommands } from "./commands/insights.js";
import { registerTargetingCommands } from "./commands/targeting.js";
import { MetaApiError } from "./lib/client.js";

const program = new Command();

program
  .name("meta-ads-cli")
  .description("CLI for Meta/Facebook Marketing API")
  .version("1.0.0")
  .option("--verbose", "Show detailed output including API requests")
  .option("--json", "Output raw JSON instead of formatted tables");

// Register all command groups
registerAuthCommands(program);
registerAccountCommands(program);
registerCampaignCommands(program);
registerAdsetCommands(program);
registerAdCommands(program);
registerInsightCommands(program);
registerTargetingCommands(program);

// Global error handling
program.hook("postAction", () => {});

async function main() {
  try {
    await program.parseAsync(process.argv);
  } catch (err) {
    if (err instanceof MetaApiError) {
      console.error(`\nError: ${err.toUserMessage()}`);
      if (program.opts().verbose) {
        console.error(`  Code: ${err.code}, Type: ${err.type}`);
        if (err.fbtraceId) console.error(`  Trace: ${err.fbtraceId}`);
      }
    } else if (err instanceof Error) {
      console.error(`\nError: ${err.message}`);
    }
    process.exit(1);
  }
}

main();
