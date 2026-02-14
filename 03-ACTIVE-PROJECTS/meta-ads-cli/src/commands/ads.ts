import type { Command } from "commander";
import { getAccessToken } from "../lib/auth.js";
import { makeApiRequest, uploadFile, ensureActPrefix } from "../lib/client.js";
import * as fmt from "../lib/format.js";

const AD_FIELDS = "id,name,status,effective_status,campaign_id,adset_id,creative{id,name,title,body,image_url,thumbnail_url,link_url},created_time,updated_time";
const CREATIVE_FIELDS = "id,name,title,body,image_url,thumbnail_url,link_url,object_story_spec,effective_object_story_id,asset_feed_spec";

export function registerAdCommands(program: Command): void {
  program
    .command("ads")
    .description("List ads for an account, campaign, or ad set")
    .requiredOption("--account-id <id>", "Ad account ID")
    .option("--campaign-id <id>", "Filter by campaign ID")
    .option("--adset-id <id>", "Filter by ad set ID")
    .option("--limit <n>", "Max ads to return", "25")
    .action(async (opts: { accountId: string; campaignId?: string; adsetId?: string; limit: string }) => {
      const token = getAccessToken();

      let endpoint: string;
      if (opts.adsetId) {
        endpoint = `${opts.adsetId}/ads`;
      } else if (opts.campaignId) {
        endpoint = `${opts.campaignId}/ads`;
      } else {
        endpoint = `${ensureActPrefix(opts.accountId)}/ads`;
      }

      const res = await makeApiRequest(endpoint, token, {
        fields: AD_FIELDS,
        limit: opts.limit,
      });

      const ads = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(ads));
        return;
      }

      if (ads.length === 0) {
        console.log("No ads found.");
        return;
      }

      console.log(fmt.header("ADS"));
      console.log();

      const rows = ads.map((a) => {
        const creative = a.creative as Record<string, unknown> | undefined;
        return [
          String(a.id ?? ""),
          String(a.name ?? "").slice(0, 35),
          String(a.effective_status ?? a.status ?? ""),
          String(a.adset_id ?? ""),
          creative?.name ? String(creative.name).slice(0, 25) : "—",
        ];
      });

      console.log(
        fmt.table(["Ad ID", "Name", "Status", "Ad Set ID", "Creative"], rows)
      );
      console.log();
      console.log(`${ads.length} ad(s) found.`);
    });

  program
    .command("ad-details")
    .description("Get details for a specific ad")
    .requiredOption("--ad-id <id>", "Ad ID")
    .action(async (opts: { adId: string }) => {
      const token = getAccessToken();
      const res = await makeApiRequest(opts.adId, token, {
        fields: AD_FIELDS + ",tracking_specs,conversion_specs",
      });

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      const creative = res.creative as Record<string, unknown> | undefined;

      console.log(fmt.header(`AD: ${res.name ?? opts.adId}`));
      console.log();
      console.log(
        fmt.kv([
          ["Ad ID", String(res.id ?? "")],
          ["Name", String(res.name ?? "")],
          ["Status", String(res.effective_status ?? res.status ?? "")],
          ["Campaign ID", String(res.campaign_id ?? "")],
          ["Ad Set ID", String(res.adset_id ?? "")],
          ["Creative ID", creative ? String(creative.id ?? "") : "—"],
          ["Creative Name", creative ? String(creative.name ?? "") : "—"],
          ["Link URL", creative?.link_url ? String(creative.link_url) : "—"],
          ["Created", String(res.created_time ?? "")],
          ["Updated", String(res.updated_time ?? "")],
        ])
      );
    });

  program
    .command("creatives")
    .description("Get creative details for an ad")
    .requiredOption("--ad-id <id>", "Ad ID")
    .action(async (opts: { adId: string }) => {
      const token = getAccessToken();
      const res = await makeApiRequest(`${opts.adId}/adcreatives`, token, {
        fields: CREATIVE_FIELDS,
      });

      const creatives = (res.data ?? []) as Record<string, unknown>[];

      if (program.opts().json) {
        console.log(fmt.json(creatives));
        return;
      }

      if (creatives.length === 0) {
        console.log("No creatives found for this ad.");
        return;
      }

      for (const c of creatives) {
        console.log(fmt.header(`CREATIVE: ${c.name ?? c.id}`));
        console.log();
        console.log(
          fmt.kv([
            ["Creative ID", String(c.id ?? "")],
            ["Name", String(c.name ?? "")],
            ["Title", String(c.title ?? "—")],
            ["Body", String(c.body ?? "—")],
            ["Image URL", String(c.image_url ?? "—")],
            ["Link URL", String(c.link_url ?? "—")],
          ])
        );
        console.log();
      }
    });

  // --- Write operations ---

  program
    .command("create-ad")
    .description("Create a new ad (defaults to PAUSED)")
    .requiredOption("--account-id <id>", "Ad account ID")
    .requiredOption("--name <name>", "Ad name")
    .requiredOption("--adset-id <id>", "Ad set ID")
    .requiredOption("--creative-id <id>", "Creative ID")
    .option("--status <status>", "Initial status", "PAUSED")
    .action(async (opts: {
      accountId: string;
      name: string;
      adsetId: string;
      creativeId: string;
      status: string;
    }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const res = await makeApiRequest(`${actId}/ads`, token, {
        name: opts.name,
        adset_id: opts.adsetId,
        creative: JSON.stringify({ creative_id: opts.creativeId }),
        status: opts.status.toUpperCase(),
      }, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Ad created successfully.`);
      console.log(`  ID:     ${res.id}`);
      console.log(`  Name:   ${opts.name}`);
      console.log(`  Status: ${opts.status.toUpperCase()}`);
    });

  program
    .command("update-ad")
    .description("Update an existing ad")
    .requiredOption("--ad-id <id>", "Ad ID")
    .option("--status <status>", "New status (ACTIVE, PAUSED, ARCHIVED)")
    .option("--name <name>", "New ad name")
    .action(async (opts: { adId: string; status?: string; name?: string }) => {
      const params: Record<string, unknown> = {};
      if (opts.status) params.status = opts.status.toUpperCase();
      if (opts.name) params.name = opts.name;

      if (Object.keys(params).length === 0) {
        console.error("No update fields provided. Use --status or --name.");
        process.exit(1);
      }

      const token = getAccessToken();
      const res = await makeApiRequest(opts.adId, token, params, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Ad ${opts.adId} updated.`);
      for (const [key, value] of Object.entries(params)) {
        console.log(`  ${key}: ${value}`);
      }
    });

  program
    .command("create-creative")
    .description("Create a new ad creative")
    .requiredOption("--account-id <id>", "Ad account ID")
    .requiredOption("--name <name>", "Creative name")
    .requiredOption("--image-hash <hash>", "Image hash (from upload-image)")
    .requiredOption("--page-id <id>", "Facebook Page ID")
    .requiredOption("--link-url <url>", "Destination URL")
    .requiredOption("--message <msg>", "Post message/body text")
    .option("--headline <text>", "Ad headline")
    .option("--description <text>", "Ad description")
    .option("--cta-type <type>", "Call to action: LEARN_MORE, SHOP_NOW, SIGN_UP, BOOK_TRAVEL, CONTACT_US, etc.")
    .option("--instagram-actor-id <id>", "Instagram account ID")
    .action(async (opts: {
      accountId: string;
      name: string;
      imageHash: string;
      pageId: string;
      linkUrl: string;
      message: string;
      headline?: string;
      description?: string;
      ctaType?: string;
      instagramActorId?: string;
    }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const linkData: Record<string, unknown> = {
        image_hash: opts.imageHash,
        link: opts.linkUrl,
        message: opts.message,
      };
      if (opts.headline) linkData.name = opts.headline;
      if (opts.description) linkData.description = opts.description;
      if (opts.ctaType) {
        linkData.call_to_action = { type: opts.ctaType.toUpperCase() };
      }

      const objectStorySpec: Record<string, unknown> = {
        page_id: opts.pageId,
        link_data: linkData,
      };
      if (opts.instagramActorId) {
        objectStorySpec.instagram_actor_id = opts.instagramActorId;
      }

      const res = await makeApiRequest(`${actId}/adcreatives`, token, {
        name: opts.name,
        object_story_spec: JSON.stringify(objectStorySpec),
      }, "POST");

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      console.log(`Creative created successfully.`);
      console.log(`  ID:   ${res.id}`);
      console.log(`  Name: ${opts.name}`);
    });

  program
    .command("upload-image")
    .description("Upload an image to an ad account")
    .requiredOption("--account-id <id>", "Ad account ID")
    .requiredOption("--image-path <path>", "Path to image file")
    .option("--name <name>", "Image name")
    .action(async (opts: { accountId: string; imagePath: string; name?: string }) => {
      const token = getAccessToken();
      const actId = ensureActPrefix(opts.accountId);

      const extraParams: Record<string, string> = {};
      if (opts.name) extraParams.name = opts.name;

      const res = await uploadFile(
        `${actId}/adimages`,
        token,
        opts.imagePath,
        "filename",
        extraParams
      );

      if (program.opts().json) {
        console.log(fmt.json(res));
        return;
      }

      // Response has images.{filename}.hash
      const images = res.images as Record<string, Record<string, unknown>> | undefined;
      if (images) {
        const first = Object.values(images)[0];
        console.log(`Image uploaded successfully.`);
        console.log(`  Hash: ${first?.hash ?? "unknown"}`);
        console.log(`  URL:  ${first?.url ?? "—"}`);
      } else {
        console.log("Image uploaded. Response:");
        console.log(fmt.json(res));
      }
    });
}
