# iMessage Bot Interaction Guide

**Created**: 2026-02-02
**Status**: ✅ Ready to Use
**Channel**: iMessage (native macOS)

---

## Overview

Your OpenClaw Gateway is now connected to iMessage and ready to receive messages. This guide shows you how to interact with your AI bot using iMessage on any Apple device.

## Quick Start

### ✅ What's Already Set Up

- **Gateway**: Running on port 18789 in your VM
- **iMessage Channel**: Enabled and active
- **Authentication**: Automatic (uses macOS iMessage)
- **No QR Codes**: No scanning required
- **No Tokens**: Works out of the box

### How It Works

```
Your iPhone/Mac → iMessage → OpenClaw Gateway → AI Agent → Response → iMessage → You
```

---

## Using the Bot

### Method 1: Send a Message from iPhone

1. Open **Messages** app on your iPhone
2. Start a new conversation or use an existing one
3. Send a message to the phone number or Apple ID associated with the VM's iMessage
4. The bot will process your message and respond

### Method 2: Send a Message from Mac

1. Open **Messages** app on your Mac (host machine, not VM)
2. Start a new conversation
3. Send a message to yourself or the VM's iMessage account
4. The bot will intercept and respond

### Method 3: Group Conversations

The bot can participate in group conversations:
1. Add the bot's iMessage account to a group
2. Message the group
3. The bot will respond to messages in the group

---

## Testing Your Bot

### Simple Test Message

Send this to test basic functionality:
```
Hello bot!
```

Expected response:
```
[Bot introduces itself and confirms it's working]
```

### Ask a Question

```
What can you help me with?
```

### Request Information

```
Tell me about the weather
```

### Complex Task

```
Can you help me draft an email?
```

---

## Bot Capabilities

Your bot can:

- **Answer Questions**: General knowledge, technical help, explanations
- **Have Conversations**: Natural back-and-forth dialogue
- **Execute Tasks**: Depends on your AI agent configuration
- **Remember Context**: Maintains conversation history
- **Handle Multiple Users**: If configured for group chats

---

## Important Configuration Notes

### Full Disk Access Required

iMessage integration requires Full Disk Access permission:

**To Grant Permission:**
1. Open **System Settings** on the VM
2. Go to **Privacy & Security** > **Full Disk Access**
3. Click the lock icon and authenticate
4. Find the process running OpenClaw (likely `node` or `openclaw`)
5. Enable the toggle

**Why This is Needed:**
iMessage stores conversations in a protected database at `~/Library/Messages/chat.db`. OpenClaw needs read access to monitor incoming messages.

### VM Must Be Running

The bot only works when:
- ✅ VM is powered on
- ✅ Gateway is running (`openclaw gateway status` shows "running")
- ✅ iMessage is signed in on the VM

### iMessage Account on VM

The VM needs its own iMessage account:

**Option 1: Use Your Existing Apple ID**
- Sign in with your main Apple ID
- Messages sent to you will be intercepted by the bot

**Option 2: Create a Separate Apple ID (Recommended)**
- Create a new Apple ID specifically for the bot
- Give it a unique name (e.g., "AI Assistant")
- People message this account to talk to the bot

---

## Checking Bot Status

### From Host Mac

```bash
# SSH into VM
ssh -i ~/.ssh/openclaw_vm_ed25519 clawuser@192.168.64.5

# Check channel status
openclaw channels status

# Should show:
# - iMessage default (ClawBot iMessage): enabled, configured, running
```

### Gateway Status

```bash
# Inside VM
openclaw gateway status

# Should show:
# Runtime: running
# RPC probe: ok
```

### View Logs

```bash
# Inside VM
tail -f ~/.openclaw/logs/gateway.log
```

This shows real-time activity including incoming iMessages and bot responses.

---

## Troubleshooting

### Issue: Bot Not Responding

**Symptoms:**
- Messages sent but no response
- Bot seems offline

**Solutions:**

1. **Check Gateway Status**
   ```bash
   ssh -i ~/.ssh/openclaw_vm_ed25519 clawuser@192.168.64.5
   openclaw gateway status
   ```
   Should show "Runtime: running"

2. **Check iMessage Channel**
   ```bash
   openclaw channels status
   ```
   iMessage should show "running"

3. **Verify Full Disk Access**
   - System Settings > Privacy & Security > Full Disk Access
   - Ensure OpenClaw process has permission

4. **Restart Gateway**
   ```bash
   openclaw gateway restart
   ```

### Issue: Permission Denied Errors

**Symptoms:**
- Logs show permission errors
- Can't read iMessage database

**Solution:**
Grant Full Disk Access (see "Full Disk Access Required" section above)

### Issue: Messages Not Being Intercepted

**Symptoms:**
- iMessage works normally
- Bot doesn't see the messages

**Solutions:**

1. **Verify iMessage is signed in on VM**
   - Open Messages app on VM
   - Check that you're signed in

2. **Check Database Path**
   ```bash
   openclaw channels list
   # Verify db-path is: ~/Library/Messages/chat.db
   ```

3. **Restart iMessage on VM**
   ```bash
   # Force quit Messages app
   killall Messages

   # Reopen Messages app
   open -a Messages
   ```

### Issue: Delayed Responses

**Symptoms:**
- Bot responds but takes a long time

**Causes:**
- AI model processing time
- Network latency
- VM resource constraints

**Solutions:**
- Ensure VM has adequate resources (8GB RAM recommended)
- Check Gateway logs for performance issues
- Consider upgrading VM specs

---

## Advanced Configuration

### Customizing Bot Behavior

Edit the bot's personality and capabilities:

```bash
# Inside VM
openclaw config edit
```

### Filtering Messages

Configure which messages the bot responds to:

```bash
# Example: Only respond to messages containing certain keywords
# This requires custom configuration in your OpenClaw setup
```

### Multiple Bots

You can run multiple iMessage bots:

```bash
# Add another iMessage account
openclaw channels add --channel imessage \
  --db-path "~/Library/Messages/chat.db" \
  --account "bot2" \
  --name "Second Bot"
```

### Group Chat Settings

Configure how the bot behaves in group chats:

```bash
# Set acknowledgment scope
openclaw config set messages.ackReactionScope "group-mentions"
```

Options:
- `all`: Respond to all messages
- `group-mentions`: Only when mentioned
- `none`: Don't respond in groups

---

## Privacy & Security

### What the Bot Can See

The bot has access to:
- ✅ Messages sent to the VM's iMessage account
- ✅ Group conversations where it's a participant
- ❌ Messages from other iMessage accounts (unless shared VM)

### Data Storage

- **Messages**: Stored in OpenClaw's database for context
- **Logs**: Recorded in `~/.openclaw/logs/`
- **Transcripts**: Conversation history in `~/.openclaw/agents/main/sessions/`

### Securing Your Bot

1. **Use a Dedicated Apple ID**
   - Don't use your personal Apple ID
   - Create a bot-specific account

2. **Limit VM Access**
   - Keep SSH keys secure
   - Use strong passwords
   - Don't expose VM to internet

3. **Monitor Activity**
   - Regularly check logs
   - Review conversation transcripts
   - Set up alerts for suspicious activity

---

## Next Steps

### Add More Channels

You can add other messaging platforms alongside iMessage:

**Telegram** (Requires bot token):
```bash
openclaw channels add --channel telegram \
  --token "YOUR_BOT_TOKEN" \
  --name "Telegram Bot"
```

**Slack** (Requires bot + app tokens):
```bash
openclaw channels add --channel slack \
  --bot-token "xoxb-..." \
  --app-token "xapp-..." \
  --name "Slack Bot"
```

### Configure AI Model

Customize which AI model powers your bot:

```bash
# Example: Use different model
openclaw config set agents.defaults.model "claude-3-sonnet"
```

### Set Up Monitoring (Phase 5)

Enable monitoring to track bot health and performance:

```bash
# Inside VM
cd "SETUP GUIDES/openclaw-vm-setup"
./setup.sh 5  # Run Phase 5: Monitoring Setup
```

### Configure Backups (Phase 6)

Protect your bot configuration with automated backups:

```bash
# Inside VM
cd "SETUP GUIDES/openclaw-vm-setup"
./setup.sh 6  # Run Phase 6: Backup Automation
```

---

## Example Conversations

### Basic Interaction

**You:**
```
Hey, can you help me with something?
```

**Bot:**
```
Of course! I'm here to help. What do you need assistance with?
```

### Information Request

**You:**
```
What's the capital of France?
```

**Bot:**
```
The capital of France is Paris. It's the largest city in France and serves as the country's political, economic, and cultural center. Is there anything else you'd like to know about Paris or France?
```

### Task Execution

**You:**
```
Can you draft a professional email declining a meeting?
```

**Bot:**
```
I'd be happy to help! To draft an appropriate email, I need a few details:
1. Who is the meeting with?
2. What is the reason you're declining?
3. Would you like to suggest an alternative time?

Please provide these details and I'll draft the email for you.
```

---

## Support & Resources

### Documentation

- **OpenClaw Docs**: https://docs.openclaw.ai
- **iMessage Integration**: https://docs.openclaw.ai/channels/imessage
- **Troubleshooting**: See `DEPLOYMENT-LESSONS-LEARNED.md`

### Getting Help

1. **Check Logs First**
   ```bash
   tail -100 ~/.openclaw/logs/gateway.log
   ```

2. **Run Diagnostics**
   ```bash
   openclaw doctor
   ```

3. **Review Channel Status**
   ```bash
   openclaw channels status
   ```

### Common Commands Reference

```bash
# Check Gateway status
openclaw gateway status

# List all channels
openclaw channels list

# View channel logs
openclaw channels logs

# Restart Gateway
openclaw gateway restart

# Full system check
openclaw doctor

# View configuration
openclaw config get
```

---

## Conclusion

Your iMessage bot is now ready to use! Simply send a message from any Apple device to the VM's iMessage account, and the bot will respond.

**Key Takeaways:**
- ✅ No QR codes or tokens needed
- ✅ Works with existing iMessage
- ✅ Responds automatically to messages
- ✅ Easy to test and use
- ✅ Secure by default

**Happy chatting with your AI bot!** 🤖

---

**Version**: 1.0
**Last Updated**: 2026-02-02
**Part of**: Clawdbot Ready - OpenClaw Gateway Deployment
