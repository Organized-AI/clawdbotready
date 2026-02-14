import type { Command } from "commander";
import { getAccessToken } from "../lib/auth.js";
import { makeApiRequest, ensureActPrefix } from "../lib/client.js";
import * as fmt from "../lib/format.js";

const ACCOUNT_FIELDS = "id,name,account_id,account_status,amount_spent,balance,currency,age,business_city,business_country_code";

const ACCOUNT_STATUS_MAP: Record<number, string> = {
  1: "ACTIVE",
  2: "DISABLED",
  3: "UNSETTLED",
  7: "PENDING_RISK_REVIEW",
  8: "PENDING_SETTLEMENT",
  9: "IN_GRACE_PERIOD",
  100: "PENDING_CLOSURE",
  101: "CLOSED",
  201: "ANY_ACTIVE",
  202: "ANY_CLOSED",
};

export function registerAccountCommands(program: Command): void {
  program
    .command("accounts")
    .description("List ad accounts for the authenticated user")
    .option("--limit <n>", "Max accounts to return", "200")
    .action(async (opts: { limit: string }) => {
      const token = getAccessToken();
      const res = await makeApiRequest("me/adaccounts", token, {
        fields: ACCOUNT_FIELDS,
        limit: opts.limit,
      });

      const accounts = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(accounts));
        return;
      }

      if (accounts.length === 0) {
        console.log("No ad accounts found.");
        return;
      }

      console.log(fmt.header("META AD ACCOUNTS"));
      console.log();

      const rows = accounts.map((a) => [
        String(a.account_id ?? ""),
        String(a.name ?? ""),
        ACCOUNT_STATUS_MAP[a.account_status as number] ?? String(a.account_status),
        String(a.currency ?? ""),
        a.amount_spent ? fmt.currency(a.amount_spent as string) : "—",
      ]);

      console.log(
        fmt.table(["Account ID", "Name", "Status", "Currency", "Total Spent"], rows)
      );
      console.log();
      console.log(`${accounts.length} account(s) found.`);
    });

  program
    .command("account-info")
    .description("Get detailed info for a specific ad account")
    .requiredOption("--account-id <id>", "Ad account ID")
    .action(async (opts: { accountId: string }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);
      const res = await makeApiRequest(actId, token, {
        fields: ACCOUNT_FIELDS + ",timezone_name,timezone_offset_hours_utc,spend_cap,funding_source_details",
      });

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(fmt.header(`ACCOUNT: ${res.name ?? actId}`));
      console.log();
      console.log(
        fmt.kv([
          ["Account ID", String(res.account_id ?? "")],
          ["Name", String(res.name ?? "")],
          ["Status", ACCOUNT_STATUS_MAP[res.account_status as number] ?? String(res.account_status)],
          ["Currency", String(res.currency ?? "")],
          ["Timezone", String(res.timezone_name ?? "")],
          ["Total Spent", res.amount_spent ? fmt.currency(res.amount_spent as string) : "—"],
          ["Balance", res.balance ? fmt.currency(res.balance as string) : "—"],
          ["Spend Cap", res.spend_cap ? fmt.currency(res.spend_cap as string) : "No cap"],
          ["Age (days)", String(res.age ?? "")],
          ["Location", [res.business_city, res.business_country_code].filter(Boolean).join(", ") || "—"],
        ])
      );
    });

  program
    .command("account-pages")
    .description("List pages associated with an ad account")
    .requiredOption("--account-id <id>", "Ad account ID")
    .action(async (opts: { accountId: string }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);
      const res = await makeApiRequest(`${actId}/promote_pages`, token, {
        fields: "id,name,category,fan_count",
      });

      const pages = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(pages));
        return;
      }

      if (pages.length === 0) {
        console.log("No pages found for this account.");
        return;
      }

      const rows = pages.map((p) => [
        String(p.id ?? ""),
        String(p.name ?? ""),
        String(p.category ?? ""),
        p.fan_count ? fmt.num(p.fan_count as number) : "—",
      ]);

      console.log(fmt.table(["Page ID", "Name", "Category", "Followers"], rows));
    });
}
