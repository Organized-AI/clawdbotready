# Telegram + OpenRouter Setup Summary

**Date**: 2026-02-02
**Status**: ✅ Tested and Working
**Components**: OpenClaw 2026.2.1, OpenRouter API, Kimi K2.5, Telegram Bot

---

## What Was Accomplished

Successfully configured a fully functional Telegram bot using OpenClaw Gateway with OpenRouter API (Kimi K2.5 model).

## Key Discoveries

### 1. OpenRouter Model Naming Convention (CRITICAL)

**The Issue**: Models were failing with "Unknown model" errors despite correct-looking names.

**The Solution**: OpenClaw requires the exact format `openrouter/<author>/<slug>`

❌ Wrong: `moonshotai/kimi-k2.5`
✅ Correct: `openrouter/moonshotai/kimi-k2.5`

**Source**: [OpenRouter Official Integration Guide](https://openrouter.ai/docs/guides/guides/openclaw-integration)

### 2. LaunchAgent Environment Variables (CRITICAL)

**The Issue**: API key set in shell profile wasn't available to the Gateway service.

**The Solution**: API keys must be added to the LaunchAgent plist file:

```bash
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OPENROUTER_API_KEY string YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Why**: LaunchAgent services don't inherit shell environment variables.

### 3. OpenClaw Version Requirements

**The Issue**: Version 2026.1.30 had incomplete OpenRouter support.

**The Solution**: Update to 2026.2.1 or later:

```bash
pnpm add -g openclaw@latest
openclaw gateway uninstall
openclaw gateway install --port 18789
```

## Complete Working Configuration

### Environment Setup

**File**: `~/Library/LaunchAgents/ai.openclaw.gateway.plist`

```xml
<key>EnvironmentVariables</key>
<dict>
    <key>OPENROUTER_API_KEY</key>
    <string>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</string>
    <!-- other environment variables -->
</dict>
```

### Model Configuration

```bash
openclaw models set openrouter/moonshotai/kimi-k2.5
```

### Channel Configuration

```bash
# Add Telegram channel
openclaw channels add --channel telegram \
  --token "8373900770:AAG4no3cENcskehzIusyEq36AAOGRhDWFII" \
  --name "Clawdbot Telegram"

# Enable plugin
openclaw plugins enable telegram

# Restart Gateway
openclaw gateway restart
```

### Pairing

```bash
# User sends message to bot
# Bot responds with pairing code (e.g., 6MZL3G56)

# Approve pairing
openclaw pairing approve telegram 6MZL3G56
```

## Verification Commands

```bash
# Check version (must be 2026.2.1+)
openclaw --version

# Check model status
openclaw models status
# Should show:
# - Default: openrouter/moonshotai/kimi-k2.5
# - openrouter effective=env:sk-or-v1...

# Check API key in LaunchAgent
/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Check Gateway status
openclaw gateway status

# Check channel status
openclaw channels status
# Should show: "Telegram default: enabled, configured, running"
```

## Testing Results

✅ **Bot responds successfully** to messages
✅ **Uses Kimi K2.5 model** via OpenRouter
✅ **Pairing system works** correctly
✅ **No authentication errors**
✅ **Stable Gateway operation**

## Common Errors Solved

| Error | Cause | Solution |
|-------|-------|----------|
| "Unknown model: moonshotai/kimi-k2.5" | Missing `openrouter/` prefix | Use `openrouter/moonshotai/kimi-k2.5` |
| "No API key found for provider 'anthropic'" | Wrong model format or missing API key | Fix model name + add key to plist |
| "command not found: openclaw" | PATH not configured | Add to `~/.zprofile` and `~/.zshrc` |
| Model works in CLI but not in bot | API key not in LaunchAgent | Add to plist file, not just shell |

## Documentation Created

1. **[TELEGRAM-BOT-SETUP-GUIDE.md](./TELEGRAM-BOT-SETUP-GUIDE.md)** - Complete setup guide
2. **[openclaw-onboarding skill v2.3.0](../../.claude/skills/openclaw-onboarding/skill.md)** - Updated with Lesson 6 on OpenRouter
3. **This summary** - Quick reference for future deployments

## Lessons for Agent Skill

The following was added as **Lesson 6** to the openclaw-onboarding skill:

1. **Model naming convention** must be `openrouter/<author>/<slug>`
2. **API keys** must be in LaunchAgent plist, not shell profile
3. **OpenClaw version** must be 2026.2.1 or later
4. **Verification steps** to confirm correct configuration

## Next Steps for Future Deployments

1. Check OpenClaw version first (`openclaw --version`)
2. Use correct model format from the start
3. Add API key to LaunchAgent immediately
4. Verify with `openclaw models status` before testing
5. Reference [TELEGRAM-BOT-SETUP-GUIDE.md](./TELEGRAM-BOT-SETUP-GUIDE.md) for complete steps

---

**Success Rate**: 100% after applying correct configuration
**Time to Working Bot**: ~5 minutes with correct method
**Key Takeaway**: Model naming format and LaunchAgent environment variables are CRITICAL
