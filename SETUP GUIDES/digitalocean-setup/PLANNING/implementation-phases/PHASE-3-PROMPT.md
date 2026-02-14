# Phase 3: Set Up Messaging Channels

## Objective
Connect at least one messaging platform (Telegram, WhatsApp, Discord, Slack, or Signal) to the OpenClaw instance.

## Steps

### Option A: Telegram (Recommended — Fastest)

1. **Create a bot via @BotFather** on Telegram:
   - Open Telegram, search for `@BotFather`
   - Send `/newbot`
   - Choose a display name (e.g., "My OpenClaw Agent")
   - Choose a username (must end in `bot`, e.g., `myopenclaw_bot`)
   - Copy the bot token

2. **Add the bot to OpenClaw**:
   ```bash
   ssh root@YOUR_DROPLET_IP
   /opt/openclaw-cli.sh channels add
   # Select "Telegram"
   # Paste the bot token when prompted
   ```

3. **Configure the allowlist**:
   - Open the web dashboard
   - Add your Telegram user ID to the allowlist
   - To find your ID: send a message to `@userinfobot` on Telegram

4. **Test it**: Send a message to your bot on Telegram.

### Option B: WhatsApp

1. **Run channel setup**:
   ```bash
   ssh root@YOUR_DROPLET_IP
   /opt/openclaw-cli.sh channels add
   # Select "WhatsApp"
   ```

2. **Scan QR code**: The CLI displays a QR code. Scan it with WhatsApp on your phone (Linked Devices).

3. **Test it**: Send a message from your phone.

### Option C: Discord

1. **Create a Discord bot**:
   - Go to [discord.com/developers/applications](https://discord.com/developers/applications)
   - New Application → Bot → Copy token
   - Enable Message Content Intent under Privileged Gateway Intents

2. **Add to OpenClaw**:
   ```bash
   /opt/openclaw-cli.sh channels add
   # Select "Discord"
   # Paste bot token
   ```

3. **Invite bot to server** using the OAuth2 URL from the developer portal.

### Option D: Slack

1. **Create a Slack app** at [api.slack.com/apps](https://api.slack.com/apps)
2. Enable Socket Mode and get both Bot Token and App Token
3. Add to OpenClaw:
   ```bash
   /opt/openclaw-cli.sh channels add
   # Select "Slack"
   # Paste both tokens
   ```

## Verification
- [ ] At least one channel is connected
- [ ] Send a test message and receive a response from the agent
- [ ] Device pairing confirmed in the dashboard
- [ ] Allowlist configured (for Telegram/WhatsApp)

## Next Phase
Proceed to [Phase 4: Verify & Harden](PHASE-4-PROMPT.md)
