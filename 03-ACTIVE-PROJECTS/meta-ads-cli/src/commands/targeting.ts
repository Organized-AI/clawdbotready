import type { Command } from "commander";
import { getAccessToken } from "../lib/auth.js";
import { makeApiRequest, ensureActPrefix } from "../lib/client.js";
import * as fmt from "../lib/format.js";

export function registerTargetingCommands(program: Command): void {
  program
    .command("search-interests")
    .description("Search for interest targeting options")
    .requiredOption("--query <q>", "Search query")
    .option("--limit <n>", "Max results", "25")
    .action(async (opts: { query: string; limit: string }) => {
      const token = getAccessToken();
      const res = await makeApiRequest("search", token, {
        type: "adinterest",
        q: opts.query,
        limit: opts.limit,
      });

      const interests = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(interests));
        return;
      }

      if (interests.length === 0) {
        console.log(`No interests found for "${opts.query}".`);
        return;
      }

      console.log(fmt.header(`INTERESTS — "${opts.query}"`));
      console.log();

      const rows = interests.map((i) => [
        String(i.id ?? ""),
        String(i.name ?? ""),
        i.audience_size_lower_bound && i.audience_size_upper_bound
          ? `${fmt.num(i.audience_size_lower_bound as number)}–${fmt.num(i.audience_size_upper_bound as number)}`
          : "—",
        String(i.topic ?? "—"),
      ]);

      console.log(fmt.table(["ID", "Interest", "Audience Size", "Topic"], rows));
      console.log();
      console.log(`${interests.length} result(s).`);
    });

  program
    .command("interest-suggestions")
    .description("Get suggested interests related to given interests")
    .requiredOption("--interests <list>", "Comma-separated interest names")
    .option("--limit <n>", "Max results", "25")
    .action(async (opts: { interests: string; limit: string }) => {
      const token = getAccessToken();
      const interestList = opts.interests.split(",").map((s) => s.trim());

      const res = await makeApiRequest("search", token, {
        type: "adinterestsuggestion",
        interest_list: interestList,
        limit: opts.limit,
      });

      const suggestions = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(suggestions));
        return;
      }

      if (suggestions.length === 0) {
        console.log("No suggestions found.");
        return;
      }

      console.log(fmt.header("INTEREST SUGGESTIONS"));
      console.log();

      const rows = suggestions.map((s) => [
        String(s.id ?? ""),
        String(s.name ?? ""),
        s.audience_size_lower_bound && s.audience_size_upper_bound
          ? `${fmt.num(s.audience_size_lower_bound as number)}–${fmt.num(s.audience_size_upper_bound as number)}`
          : "—",
      ]);

      console.log(fmt.table(["ID", "Interest", "Audience Size"], rows));
    });

  program
    .command("audience-size")
    .description("Estimate audience size for targeting spec")
    .requiredOption("--account-id <id>", "Ad account ID")
    .option("--targeting <json>", "Full targeting spec as JSON")
    .option("--interests <list>", "Comma-separated interest names (shorthand)")
    .option("--countries <list>", "Comma-separated country codes (e.g., US,GB)")
    .option("--age-min <n>", "Minimum age")
    .option("--age-max <n>", "Maximum age")
    .action(async (opts: {
      accountId: string;
      targeting?: string;
      interests?: string;
      countries?: string;
      ageMin?: string;
      ageMax?: string;
    }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      let targetingSpec: Record<string, unknown>;

      if (opts.targeting) {
        targetingSpec = JSON.parse(opts.targeting);
      } else {
        // Build from shorthand options
        targetingSpec = {} as Record<string, unknown>;
        if (opts.interests) {
          const names = opts.interests.split(",").map((s) => s.trim());
          // Look up interest IDs
          const interests: { id: string; name: string }[] = [];
          for (const name of names) {
            const searchRes = await makeApiRequest("search", token, {
              type: "adinterest",
              q: name,
              limit: "1",
            });
            const found = (searchRes.data ?? []) as Record<string, unknown>[];
            if (found.length > 0) {
              interests.push({ id: String(found[0].id), name: String(found[0].name) });
            }
          }
          if (interests.length > 0) {
            targetingSpec.flexible_spec = [{ interests }];
          }
        }
        if (opts.countries) {
          targetingSpec.geo_locations = {
            countries: opts.countries.split(",").map((s) => s.trim().toUpperCase()),
          };
        }
        if (opts.ageMin) targetingSpec.age_min = parseInt(opts.ageMin, 10);
        if (opts.ageMax) targetingSpec.age_max = parseInt(opts.ageMax, 10);
      }

      const res = await makeApiRequest(`${actId}/reachestimate`, token, {
        targeting_spec: targetingSpec,
        optimization_goal: "REACH",
      });

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      const data = res.data as Record<string, unknown> | undefined;
      const users = (data?.users ?? res.users ?? 0) as number;
      const usersLower = (data?.users_lower_bound ?? res.users_lower_bound ?? 0) as number;
      const usersUpper = (data?.users_upper_bound ?? res.users_upper_bound ?? 0) as number;

      console.log(fmt.header("AUDIENCE SIZE ESTIMATE"));
      console.log();
      console.log(
        fmt.kv([
          ["Estimated Audience", fmt.num(users)],
          ["Lower Bound", fmt.num(usersLower)],
          ["Upper Bound", fmt.num(usersUpper)],
        ])
      );
      console.log();
      console.log("Targeting spec:");
      console.log(JSON.stringify(targetingSpec, null, 2));
    });

  program
    .command("search-locations")
    .description("Search for geographic targeting locations")
    .requiredOption("--query <q>", "Search query (e.g., city, state, country name)")
    .option("--type <type>", "Location type: city, region, country, zip, geo_market, electoral_district")
    .option("--limit <n>", "Max results", "25")
    .action(async (opts: { query: string; type?: string; limit: string }) => {
      const token = getAccessToken();

      const params: Record<string, unknown> = {
        type: "adgeolocation",
        q: opts.query,
        limit: opts.limit,
      };

      if (opts.type) {
        params.location_types = JSON.stringify([opts.type]);
      }

      const res = await makeApiRequest("search", token, params);
      const locations = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(locations));
        return;
      }

      if (locations.length === 0) {
        console.log(`No locations found for "${opts.query}".`);
        return;
      }

      console.log(fmt.header(`LOCATIONS — "${opts.query}"`));
      console.log();

      const rows = locations.map((l) => [
        String(l.key ?? ""),
        String(l.name ?? ""),
        String(l.type ?? ""),
        String(l.country_code ?? ""),
        String(l.region ?? "—"),
      ]);

      console.log(fmt.table(["Key", "Name", "Type", "Country", "Region"], rows));
    });
}
