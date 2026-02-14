# CLAUDE TASK: OpenClaw QMD Memory Enablement

**Status**: Ready to Execute
**Created**: 2026-02-09
**Estimated Time**: ~1.25 hours
**Priority**: High (agent intelligence upgrade)

---

## Quick Context
**Problem**: OpenClaw agent has no memory of past conversations. Session JSONL files exist but aren't searchable. Workspace docs like TOOLS.md aren't indexed for semantic retrieval.

**Solution**: Enable QMD semantic search backend with dual embedding providers (OpenAI + local GGUF fallback), session indexing, and custom document collections.

**Plan Location**: `03-ACTIVE-PROJECTS/openclaw-qmd-memory/`

---

## Prerequisites
- [x] Mac Mini accessible via SSH (openclaw@100.66.145.48)
- [x] OpenClaw Gateway running (v2026.2.1)
- [x] OpenAI API key active (updated 2026-02-09)
- [x] Session JSONL files present (~/.openclaw/agents/main/sessions/)
- [x] TOOLS.md and memory files in workspace
- [ ] Bun runtime installed (check first)
- [ ] QMD CLI available (install in Phase 2)

---

## Execution Checklist

### Phase 1: Prerequisites Check (10 min)

```bash
# Verify SSH access
ssh openclaw@100.66.145.48 'echo "Connected: $(hostname)"'

# Check gateway version
ssh openclaw@100.66.145.48 'openclaw --version'

# Check if Bun is installed
ssh openclaw@100.66.145.48 'which bun && bun --version || echo "Bun NOT installed"'

# Check current memory config
ssh openclaw@100.66.145.48 'cat ~/.openclaw/openclaw.json | python3 -m json.tool 2>/dev/null || echo "No config or invalid JSON"'

# Snapshot FD count
ssh openclaw@100.66.145.48 'lsof -p $(pgrep -f openclaw | head -1) 2>/dev/null | wc -l || echo "Cannot count FDs"'

# Count existing sessions
ssh openclaw@100.66.145.48 'ls ~/.openclaw/agents/main/sessions/*.jsonl 2>/dev/null | wc -l'

# Check workspace files
ssh openclaw@100.66.145.48 'ls ~/.openclaw/workspace/TOOLS.md ~/.openclaw/workspace/MEMORY.md 2>/dev/null'
```

- [ ] SSH access works
- [ ] Gateway version confirmed (v2026.2.1)
- [ ] Bun status checked
- [ ] Current config inspected
- [ ] FD count baselined
- [ ] Session files counted
- [ ] Workspace files verified

---

### Phase 2: Install QMD CLI (15 min)

```bash
# Install Bun (if not present)
ssh openclaw@100.66.145.48 'curl -fsSL https://bun.sh/install | bash'

# Reload shell profile
ssh openclaw@100.66.145.48 'source ~/.zprofile 2>/dev/null; source ~/.bashrc 2>/dev/null; bun --version'

# Install QMD globally
ssh openclaw@100.66.145.48 'bun install -g https://github.com/tobi/qmd'

# Verify QMD installed
ssh openclaw@100.66.145.48 'qmd --version'

# Ensure QMD is on PATH for non-interactive shells
# Check if .zprofile has bun PATH
ssh openclaw@100.66.145.48 'grep -q "bun" ~/.zprofile && echo "Bun PATH in zprofile" || echo "Need to add Bun PATH"'

# If needed, add to .zprofile:
# ssh openclaw@100.66.145.48 'echo "export PATH=\"\$HOME/.bun/bin:\$PATH\"" >> ~/.zprofile'

# Verify non-interactive PATH works
ssh openclaw@100.66.145.48 'which qmd'
```

- [ ] Bun installed
- [ ] QMD installed globally
- [ ] `qmd --version` works
- [ ] QMD on PATH for non-interactive shells

---

### Phase 3: Configure Memory Backend (15 min)

```bash
# Back up existing config
ssh openclaw@100.66.145.48 'cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d)'

# Verify backup
ssh openclaw@100.66.145.48 'ls -la ~/.openclaw/openclaw.json.bak-*'
```

**Edit `~/.openclaw/openclaw.json`** — add/merge these keys:

```json5
{
  "memory": {
    "backend": "qmd",
    "citations": "auto",
    "qmd": {
      "command": "qmd",
      "includeDefaultMemory": true,
      "paths": [
        {
          "name": "workspace-tools",
          "path": "~/.openclaw/workspace",
          "pattern": "**/*.md"
        }
      ],
      "sessions": {
        "enabled": true,
        "retentionDays": 30
      },
      "update": {
        "interval": "5m",
        "debounceMs": 15000,
        "onBoot": true,
        "waitForBootSync": false,
        "embedInterval": "5m",
        "commandTimeoutMs": 30000,
        "updateTimeoutMs": 60000,
        "embedTimeoutMs": 300000
      },
      "limits": {
        "maxResults": 6,
        "maxSnippetChars": 700,
        "maxInjectedChars": 4000,
        "timeoutMs": 4000
      },
      "scope": {
        "default": "deny",
        "rules": [
          { "action": "allow", "match": { "chatType": "direct" } }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "openai",
        "model": "text-embedding-3-small",
        "enabled": true,
        "sources": ["memory", "sessions"],
        "fallback": "local",
        "local": {
          "modelPath": "hf:ggml-org/embeddinggemma-300M-GGUF/embeddinggemma-300M-Q8_0.gguf"
        },
        "query": {
          "hybrid": {
            "enabled": true,
            "vectorWeight": 0.7,
            "textWeight": 0.3
          }
        },
        "cache": {
          "enabled": true,
          "maxEntries": 50000
        }
      }
    }
  }
}
```

```bash
# Validate JSON after editing
ssh openclaw@100.66.145.48 'cat ~/.openclaw/openclaw.json | python3 -m json.tool > /dev/null && echo "Valid JSON" || echo "INVALID JSON"'

# Show diff from backup
ssh openclaw@100.66.145.48 'diff ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d) ~/.openclaw/openclaw.json || true'
```

- [ ] Config backed up
- [ ] Memory backend set to "qmd"
- [ ] QMD settings configured (sessions, collections, scope, intervals)
- [ ] Dual embedding providers configured (OpenAI + local fallback)
- [ ] JSON validated

---

### Phase 4: Pre-warm Index (10 min)

```bash
# Create QMD directories
ssh openclaw@100.66.145.48 'mkdir -p ~/.openclaw/agents/main/qmd/{xdg-config,xdg-cache,sessions}'

# Set environment and run QMD commands
ssh openclaw@100.66.145.48 'export XDG_CONFIG_HOME=~/.openclaw/agents/main/qmd/xdg-config && export XDG_CACHE_HOME=~/.openclaw/agents/main/qmd/xdg-cache && qmd update'

# Generate embeddings (this may download the GGUF model on first run, ~600MB)
ssh openclaw@100.66.145.48 'export XDG_CONFIG_HOME=~/.openclaw/agents/main/qmd/xdg-config && export XDG_CACHE_HOME=~/.openclaw/agents/main/qmd/xdg-cache && qmd embed'

# Test search
ssh openclaw@100.66.145.48 'export XDG_CONFIG_HOME=~/.openclaw/agents/main/qmd/xdg-config && export XDG_CACHE_HOME=~/.openclaw/agents/main/qmd/xdg-cache && qmd query "Google Ads" --json -n 3'

# List collections
ssh openclaw@100.66.145.48 'export XDG_CONFIG_HOME=~/.openclaw/agents/main/qmd/xdg-config && export XDG_CACHE_HOME=~/.openclaw/agents/main/qmd/xdg-cache && qmd collection list --json'
```

- [ ] QMD directories created
- [ ] `qmd update` ran successfully
- [ ] `qmd embed` ran (model downloaded if needed)
- [ ] Test search returns results
- [ ] Collections listed

---

### Phase 5: Restart & Verify (15 min)

```bash
# Restart the gateway (method depends on how it's running)
# If using launchctl:
ssh openclaw@100.66.145.48 'launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway'

# Or if manual:
# ssh openclaw@100.66.145.48 'pkill -f "openclaw gateway" && sleep 2 && openclaw gateway --port 18789 --verbose &'

# Wait for startup
sleep 10

# Check gateway is running
ssh openclaw@100.66.145.48 'pgrep -f openclaw > /dev/null && echo "Gateway running" || echo "Gateway NOT running"'

# Check FD count (should be ~64, not spiking)
ssh openclaw@100.66.145.48 'lsof -p $(pgrep -f openclaw | head -1) 2>/dev/null | wc -l'

# Check logs for QMD initialization
ssh openclaw@100.66.145.48 'tail -50 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null | grep -i "qmd\|memory\|backend" || echo "Check gateway.log instead"'

# Check for errors
ssh openclaw@100.66.145.48 'tail -20 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null | grep -i "error\|fail\|fallback" || echo "No errors found"'
```

**Manual Telegram Test:**
1. Send a message to @SAMyosin_bot referencing a past conversation topic
2. Check if agent recalls context from previous sessions
3. Ask about something only documented in TOOLS.md
4. Verify agent cites the source

- [ ] Gateway restarted
- [ ] Gateway is running
- [ ] FD count stable (~64)
- [ ] Logs show QMD initialized (no fallback to builtin)
- [ ] Telegram memory search works
- [ ] Custom doc search works (TOOLS.md content)
- [ ] No EMFILE or memory errors

---

### Phase 6: Documentation & Wrap-up (10 min)

- [ ] Update MEMORY.md with QMD config details
- [ ] Update STATE.md to mark project complete
- [ ] Verify fallback: temporarily break QMD path → confirm builtin takes over → restore
- [ ] Note any config adjustments needed

---

## Rollback Commands

If anything goes wrong:

```bash
# Restore original config
ssh openclaw@100.66.145.48 'cp ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d) ~/.openclaw/openclaw.json'

# Restart gateway
ssh openclaw@100.66.145.48 'launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway'

# Verify recovery
ssh openclaw@100.66.145.48 'pgrep -f openclaw > /dev/null && echo "Gateway recovered" || echo "PROBLEM: Gateway not running"'
```

---

## Troubleshooting

### QMD binary not found
```bash
# Check bun global bin location
ssh openclaw@100.66.145.48 'bun pm bin -g'
# Add that path to ~/.zprofile if missing
```

### GGUF model download fails
```bash
# Manual download fallback
ssh openclaw@100.66.145.48 'curl -L -o ~/.openclaw/agents/main/qmd/xdg-cache/embeddinggemma-300M-Q8_0.gguf "https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/main/embeddinggemma-300M-Q8_0.gguf"'
```

### FD count spiking
```bash
# Check what's opening files
ssh openclaw@100.66.145.48 'lsof -p $(pgrep -f openclaw | head -1) | sort -k9 | tail -30'
# If QMD causes spike, disable and fall back to builtin
```

### JSON config syntax error
```bash
# Restore backup and try again
ssh openclaw@100.66.145.48 'cp ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d) ~/.openclaw/openclaw.json'
# Use python3 to validate after each edit:
ssh openclaw@100.66.145.48 'python3 -c "import json; json.load(open(\"$HOME/.openclaw/openclaw.json\"))" && echo OK'
```
