# Telegram Bot Setup Guide with OpenRouter

**Created**: 2026-02-02
**Status**: ✅ Tested and Working
**OpenClaw Version**: 2026.2.1+

---

## Overview

This guide shows you how to set up a Telegram bot using OpenClaw Gateway with OpenRouter API (supporting models like Kimi K2.5, DeepSeek, Claude, etc.).

## Prerequisites

- OpenClaw Gateway installed (v2026.2.1 or later)
- Telegram bot token from [@BotFather](https://t.me/BotFather)
- OpenRouter API key from [openrouter.ai](https://openrouter.ai)

---

## Quick Setup (5 Minutes)

### Step 1: Get Your Telegram Bot Token

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Follow prompts to name your bot
4. Copy the token (format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Step 2: Get Your OpenRouter API Key

1. Sign up at [openrouter.ai](https://openrouter.ai)
2. Go to API Keys page
3. Create a new key
4. Copy the key (format: `sk-or-v1-...`)

### Step 3: Configure OpenClaw

```bash
# Add Telegram channel
openclaw channels add --channel telegram \
  --token "YOUR_TELEGRAM_BOT_TOKEN" \
  --name "My Telegram Bot"

# Enable Telegram plugin
openclaw plugins enable telegram

# Add OpenRouter API key to environment (CRITICAL: Must persist to LaunchAgent)
launchctl bootout gui/$(id -u)/ai.openclaw.gateway 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OPENROUTER_API_KEY string YOUR_OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:OPENROUTER_API_KEY YOUR_OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Set model using CORRECT OpenRouter format
openclaw models set openrouter/moonshotai/kimi-k2.5

# Restart Gateway to apply changes
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

### Step 4: Pair Your Telegram Account

1. Send a message to your bot on Telegram
2. Bot will respond with a pairing code (e.g., `6MZL3G56`)
3. Approve the pairing:
   ```bash
   openclaw pairing approve telegram YOUR_PAIRING_CODE
   ```

### Step 5: Test!

Send any message to your bot. It should respond using Kimi K2.5!

---

## Critical Configuration Notes

### ⚠️ OpenRouter Model Naming Convention

**MUST USE** this exact format: `openrouter/<author>/<slug>`

✅ **Correct Examples:**
- Kimi K2.5: `openrouter/moonshotai/kimi-k2.5`
- DeepSeek: `openrouter/deepseek/deepseek-chat`
- Claude Sonnet: `openrouter/anthropic/claude-sonnet-4.5`
- Auto-router: `openrouter/openrouter/auto`

❌ **Wrong Formats (These will NOT work):**
- `moonshotai/kimi-k2.5` (missing `openrouter/` prefix)
- `moonshot/kimi-k2.5` (wrong author name)
- `kimi-k2.5` (missing both prefix and author)

**Source**: [OpenRouter Official Integration Guide](https://openrouter.ai/docs/guides/guides/openclaw-integration)

### ⚠️ Environment Variable Must Persist to LaunchAgent

The `OPENROUTER_API_KEY` environment variable must be added to the LaunchAgent plist file, not just your shell profile. This is because:

1. LaunchAgent services don't load `.zprofile` or `.zshrc`
2. The Gateway runs as a background service via LaunchAgent
3. Shell environment variables are not inherited by LaunchAgent processes

**Correct Method:**
```bash
# Add to LaunchAgent plist
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OPENROUTER_API_KEY string YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Or update existing key
/usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:OPENROUTER_API_KEY YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Verify it's there:**
```bash
/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

### ⚠️ OpenClaw Version Requirements

- **Minimum Version**: 2026.2.1
- **Reason**: Earlier versions (2026.1.30) have incomplete OpenRouter support
- **Check version**: `openclaw --version`
- **Update if needed**: `pnpm add -g openclaw@latest`

---

## Verification Checklist

Use this checklist to ensure everything is configured correctly:

```bash
# 1. Check OpenClaw version (must be 2026.2.1+)
openclaw --version

# 2. Check Gateway is running
openclaw gateway status
# Should show: "Runtime: running"

# 3. Check Telegram channel status
openclaw channels status
# Should show: "Telegram default: enabled, configured, running"

# 4. Check model configuration
openclaw models status
# Should show:
# - Default: openrouter/moonshotai/kimi-k2.5
# - openrouter effective=env:sk-or-v1...

# 5. Check API key is in LaunchAgent
/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
# Should output your API key (starts with sk-or-v1-)

# 6. Check pairing status
openclaw pairing list
# Should show your Telegram user ID if paired

# 7. Test the bot
# Send a message to your bot on Telegram - it should respond!
```

---

## Troubleshooting

### Error: "Unknown model: moonshotai/kimi-k2.5"

**Cause**: Missing `openrouter/` prefix in model name

**Solution**:
```bash
openclaw models set openrouter/moonshotai/kimi-k2.5
openclaw gateway restart
```

### Error: "No API key found for provider 'anthropic'"

**Cause**: Model name format is wrong, or API key not in LaunchAgent environment

**Solution 1 - Fix Model Name**:
```bash
openclaw models set openrouter/moonshotai/kimi-k2.5
```

**Solution 2 - Add API Key to LaunchAgent**:
```bash
launchctl bootout gui/$(id -u)/ai.openclaw.gateway
/usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:OPENROUTER_API_KEY YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

### Bot Not Responding After Everything Looks Correct

**Check logs for actual error**:
```bash
tail -50 ~/.openclaw/logs/gateway.log
# Or
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | grep -i error
```

**Common Issues**:
1. Pairing not approved - Run `openclaw pairing approve telegram CODE`
2. Gateway not running - Run `openclaw gateway status`
3. Wrong OpenClaw version - Run `openclaw --version` (need 2026.2.1+)

### Gateway Service Won't Start After Update

**Reinstall the LaunchAgent**:
```bash
openclaw gateway uninstall
openclaw gateway install --port 18789
# Re-add API key to new plist
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OPENROUTER_API_KEY string YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
openclaw gateway restart
```

---

## Available Models on OpenRouter

Here are some popular models you can use:

### Kimi/Moonshot Models
- `openrouter/moonshotai/kimi-k2.5` - Latest Kimi model (recommended)
- `openrouter/moonshotai/kimi-k2-thinking` - Reasoning model
- `openrouter/moonshotai/kimi-k2-0905` - Specific version

### Other Models
- `openrouter/deepseek/deepseek-chat` - DeepSeek Chat
- `openrouter/anthropic/claude-sonnet-4.5` - Claude Sonnet 4.5
- `openrouter/google/gemini-pro-1.5` - Gemini Pro 1.5
- `openrouter/openrouter/auto` - Auto-select best model

**Find all models**: Visit [openrouter.ai/models](https://openrouter.ai/models)

**Get model list via API**:
```bash
curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  | jq -r '.data[].id' | grep kimi
```

---

## Complete Setup Script

Here's a complete script that does everything:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
OPENROUTER_API_KEY="YOUR_OPENROUTER_API_KEY"
MODEL="openrouter/moonshotai/kimi-k2.5"

# Add Telegram channel
openclaw channels add --channel telegram \
  --token "$TELEGRAM_BOT_TOKEN" \
  --name "My Telegram Bot"

# Enable plugin
openclaw plugins enable telegram

# Stop Gateway
openclaw gateway stop 2>/dev/null || true

# Add API key to LaunchAgent plist
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OPENROUTER_API_KEY string $OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:OPENROUTER_API_KEY $OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Set model
openclaw models set "$MODEL"

# Start Gateway
openclaw gateway start

# Wait for startup
sleep 5

# Show status
echo "Setup complete!"
openclaw gateway status
openclaw channels status
openclaw models status

echo ""
echo "Next steps:"
echo "1. Send a message to your bot on Telegram"
echo "2. Copy the pairing code from the bot's response"
echo "3. Run: openclaw pairing approve telegram YOUR_CODE"
```

---

## Key Takeaways

1. ✅ **Always use OpenRouter format**: `openrouter/<author>/<slug>`
2. ✅ **API key must be in LaunchAgent plist**, not just shell profile
3. ✅ **Use OpenClaw v2026.2.1 or later** for full OpenRouter support
4. ✅ **Approve pairing** after first message from Telegram
5. ✅ **Verify with `openclaw models status`** to see if API key is detected

---

## Related Documentation

- [OpenRouter OpenClaw Integration Guide](https://openrouter.ai/docs/guides/guides/openclaw-integration)
- [OpenClaw Models Documentation](https://docs.openclaw.ai/cli/models)
- [Telegram Bot Setup](https://core.telegram.org/bots#how-do-i-create-a-bot)

---

**Version**: 1.0
**Last Updated**: 2026-02-02
**Tested With**: OpenClaw 2026.2.1, OpenRouter API, Kimi K2.5
