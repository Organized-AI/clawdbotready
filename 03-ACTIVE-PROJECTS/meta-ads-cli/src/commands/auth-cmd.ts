import type { Command } from "commander";
import { loadConfig, saveConfig, getTokenStatus, runOAuthFlow } from "../lib/auth.js";
import { makeApiRequest } from "../lib/client.js";

export function registerAuthCommands(program: Command): void {
  program
    .command("login")
    .description("Authenticate with Facebook via OAuth")
    .option("--app-id <id>", "Facebook App ID")
    .option("--app-secret <secret>", "Facebook App Secret")
    .action(async (opts: { appId?: string; appSecret?: string }) => {
      const config = loadConfig();
      const appId = opts.appId ?? config.app_id;
      const appSecret = opts.appSecret ?? config.app_secret;

      if (!appId) {
        console.error(
          "Error: No App ID provided.\n" +
          "  Use --app-id <id> or set app_id in ~/.meta-ads-cli/config.json"
        );
        process.exit(1);
      }

      // Save to config for future use
      if (opts.appId || opts.appSecret) {
        saveConfig({
          ...config,
          ...(opts.appId ? { app_id: opts.appId } : {}),
          ...(opts.appSecret ? { app_secret: opts.appSecret } : {}),
        });
      }

      try {
        const token = await runOAuthFlow(appId, appSecret);
        console.log("\nAuthentication successful!");
        console.log(`Token saved to ~/.meta-ads-cli/token_cache.json`);

        // Validate by fetching user info
        try {
          const me = await makeApiRequest("me", token, { fields: "id,name" });
          console.log(`Authenticated as: ${me.name} (${me.id})`);
        } catch {
          console.log("Token saved but could not verify identity.");
        }
      } catch (err) {
        console.error(`Login failed: ${err instanceof Error ? err.message : String(err)}`);
        process.exit(1);
      }
    });

  program
    .command("token-status")
    .description("Check current access token status")
    .action(async () => {
      const status = getTokenStatus();

      if (!status.hasToken) {
        console.log("Status: No token configured");
        console.log("\nRun: meta-ads-cli login");
        process.exit(1);
      }

      console.log(`Status:  Active`);
      console.log(`Source:  ${status.source}`);
      if (status.expiresAt) {
        const expires = new Date(status.expiresAt);
        const now = new Date();
        const daysLeft = Math.ceil((expires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        console.log(`Expires: ${expires.toLocaleDateString()} (${daysLeft} days)`);
      }

      // Validate the token with a real API call
      try {
        const { getAccessToken } = await import("../lib/auth.js");
        const token = getAccessToken();
        const me = await makeApiRequest("me", token, { fields: "id,name" });
        console.log(`User:    ${me.name} (${me.id})`);
        console.log("\nToken is valid and working.");
      } catch (err) {
        console.log(`\nWarning: Token may be expired or invalid.`);
        console.log(`  ${err instanceof Error ? err.message : String(err)}`);
      }
    });
}
