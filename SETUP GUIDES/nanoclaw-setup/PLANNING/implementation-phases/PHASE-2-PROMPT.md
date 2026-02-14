# Phase 2: Claude Authentication

## Objective
Configure Claude authentication so containers can invoke Claude Agent SDK.

## Background
NanoClaw runs Claude Agent SDK inside containers. The container needs authentication credentials, which are passed via a mounted env file at `data/env/env`. Only whitelisted environment variables (`CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY`) are exposed.

## Steps

### Option A: Claude Subscription (OAuth Token)

1. **Authenticate Claude Code**
   ```bash
   claude setup-token
   # Follow the interactive prompts
   ```

2. **Extract the OAuth token**
   ```bash
   # The setup skill does this automatically, but manually:
   mkdir -p data/env
   echo "CLAUDE_CODE_OAUTH_TOKEN=$(claude auth token 2>/dev/null)" > data/env/env
   ```

### Option B: Anthropic API Key

1. **Get API key from** [console.anthropic.com](https://console.anthropic.com)

2. **Create env file**
   ```bash
   mkdir -p data/env
   echo "ANTHROPIC_API_KEY=sk-ant-your-key-here" > data/env/env
   ```

## Verification

```bash
# Verify env file exists and has content
cat data/env/env
# Should show either CLAUDE_CODE_OAUTH_TOKEN=... or ANTHROPIC_API_KEY=...

# Verify the file is not empty
test -s data/env/env && echo "OK" || echo "EMPTY"
```

## Security Notes
- `data/env/env` is mounted read-only into containers
- Only auth-related vars are included (no other env vars leak)
- The env file is gitignored (never committed)
- Known limitation: agents inside the container can read these credentials via bash. See NanoClaw's SECURITY.md for details.

## Success Criteria
- [ ] `data/env/env` exists with valid authentication credential
- [ ] Credential format is correct (starts with expected prefix)
- [ ] File is not committed to git (in `.gitignore`)
