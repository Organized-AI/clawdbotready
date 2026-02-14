import { Command } from "commander";

const GUIDE = `
Google Ads CLI v2 — User Guide
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your AI assistant (Hermes) can manage your Google Ads accounts
directly through Telegram. Just ask in plain English.

YOUR ACCOUNTS
━━━━━━━━━━━━━
  Blade (default)                  1741833734
  Advanced Muscle Mechanics        7375860000
  Amour de Moi Skin                6347162444
  BiOptimizers - Gallant Seto      7994854565
  Civics Unplugged                 9134716978
  Dirty Saint                      4066741641
  Essence                          6193843225
  Heather Rae Essentials           4925579831
  Myosin - Foundation Law          6111060860
  Myosin - MVA Funnel              1729599101
  Myosin - Mass Tort Law           6650090207
  Myosin Wonder Video Temp         5059244248
  RTT (Marisa Peer)                2290369257
  Teleios Health                   6890103064

If you don't specify an account, Blade is used by default.

WHAT YOU CAN DO
━━━━━━━━━━━━━━━

1. LIST CAMPAIGNS
   "Show me all Blade campaigns"
   "List active campaigns for Teleios Health"
   "Show PMAX campaigns"

   Use --active-only to hide paused campaigns.
   Use --json for machine-readable output.

2. GET CPA METRICS
   "What's the CPA for Blade today?"
   "Blade CPA last 7 days"
   "Teleios Health CPA last 30 days"

   Date options: TODAY, YESTERDAY, LAST_7_DAYS, LAST_30_DAYS

3. PERFORMANCE REPORT
   "Weekly report for Blade"
   "Performance report for Teleios Health last 30 days"

4. UPDATE BUDGET
   "Set the PMAX USA budget to $500 per day"
   "Change airport transfers budget to $300"

   Amounts are in dollars. Use --dry-run to preview first.

5. PAUSE / ENABLE CAMPAIGNS
   "Pause the BLADE_PMAX_HPN campaign"
   "Enable the BLADEone Performance Max campaign"
   "Turn off the airport transfers campaign"

   You need the campaign ID — run "list campaigns" first.

TIPS
━━━━
- Just ask naturally. Hermes understands context.
- Name the account if it's not Blade (e.g. "for Teleios Health").
- Use "active only" or "active campaigns" to filter out paused ones.
- Always preview budget changes with --dry-run first.
- Campaign IDs are the long numbers shown in the campaigns list.

QUICK REFERENCE
━━━━━━━━━━━━━━━
  See campaigns        "List Blade campaigns"
  Active only          "Show active Blade campaigns"
  Today's CPA          "Blade CPA today"
  Weekly CPA           "CPA last 7 days"
  Report               "Weekly report for Blade"
  Change budget        "Set PMAX USA budget to $500"
  Pause campaign       "Pause the HPN campaign"
  Enable campaign      "Turn on the HPN campaign"
  JSON output          "List campaigns as JSON"
`;

export function registerGuideCommand(program: Command): void {
  program
    .command("guide")
    .description("Show the user guide for Google Ads CLI")
    .action(() => {
      console.log(GUIDE.trim());
    });
}
