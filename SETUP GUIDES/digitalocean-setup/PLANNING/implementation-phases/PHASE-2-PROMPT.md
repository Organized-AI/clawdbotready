# Phase 2: Configure LLM Provider

## Objective
Complete the interactive configuration to connect OpenClaw to your LLM provider and verify the web dashboard.

## Steps

### 1. Run Interactive Setup

On first SSH login, OpenClaw presents an interactive configuration prompt:

1. **Select LLM provider**: Choose Anthropic, OpenAI, or Gradient
2. **Paste API key**: Enter your provider's API key
3. The service restarts automatically with the new configuration

If you missed the interactive setup or need to reconfigure:

```bash
nano /opt/openclaw.env
# Set LLM_PROVIDER and the corresponding API key
systemctl restart openclaw
```

### 2. Verify the Service

```bash
systemctl status openclaw
```

Expected: `active (running)`

### 3. Check Gateway Health

```bash
curl -s http://127.0.0.1:18789/health
```

Expected: A JSON response confirming the gateway is healthy.

### 4. Access the Web Dashboard

The dashboard URL is shown in the SSH welcome message. Open it in your browser:

```
http://YOUR_DROPLET_IP:18789/
```

The dashboard provides:
- Live agent logs
- Configuration editor
- Channel management
- Device pairing controls

### 5. Note the Gateway Token

The gateway token was auto-generated during provisioning:

```bash
grep GATEWAY_TOKEN /opt/openclaw.env
```

Save this token — you'll need it for client connections.

### 6. Open the TUI (Optional)

For a terminal-based dashboard:

```bash
/opt/openclaw-tui.sh
```

## Verification
- [ ] `systemctl status openclaw` shows active
- [ ] Gateway health check returns OK
- [ ] Web dashboard accessible in browser
- [ ] Gateway token saved locally

## Next Phase
Proceed to [Phase 3: Set Up Messaging Channels](PHASE-3-PROMPT.md)
