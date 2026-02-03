# Dashboard Troubleshoot Skill

**Skill Name:** `dashboard-troubleshoot`
**Version:** 1.0.0
**Category:** OpenClaw Operations
**Author:** Jordan (Clawdbot Ready)

## Description

Expert troubleshooting assistant for OpenClaw Gateway dashboard connection issues. Diagnoses and resolves common dashboard problems including authentication errors, SSH tunnel failures, token retrieval, and multi-Gateway configurations.

## When to Use This Skill

Use this skill when:
- User reports dashboard showing "disconnected (1008): unauthorized: gateway token missing"
- Dashboard won't load or connect to Gateway
- User needs to access multiple Gateway dashboards simultaneously
- SSH tunnel to remote Gateway isn't working
- Token authentication fails or token is missing
- User asks "why won't my dashboard connect?" or "dashboard shows unauthorized"
- Setting up dashboard access for the first time
- Switching between local and remote Gateway dashboards

## Triggers

Activate when user mentions:
- "dashboard disconnected"
- "unauthorized gateway token"
- "1008 error"
- "can't connect to dashboard"
- "dashboard won't load"
- "need dashboard token"
- "how to access dashboard"
- "multiple dashboards"
- "tunnel to dashboard"

## What This Skill Does

1. **Diagnoses Dashboard Connection Issues**
   - Checks if Gateway is running
   - Verifies SSH tunnels (for remote access)
   - Tests dashboard connectivity
   - Reviews Gateway logs for errors

2. **Retrieves Gateway Tokens**
   - Extracts token from `~/.openclaw/openclaw.json`
   - Handles both local and remote (SSH) token retrieval
   - Generates new tokens if missing

3. **Creates Tokenized Dashboard URLs**
   - Builds `http://localhost:PORT/?token=...` URLs
   - Handles multiple Gateways on different ports
   - Provides clickable links for instant access

4. **Manages SSH Tunnels**
   - Creates SSH tunnels to remote Gateways
   - Uses alternate ports to avoid conflicts
   - Verifies tunnel connectivity
   - Provides tunnel management commands

5. **Resolves Multi-Gateway Scenarios**
   - Identifies port conflicts
   - Assigns unique ports for each Gateway
   - Creates separate tokenized URLs for each

## Core Workflow

### Phase 1: Diagnosis

```bash
# Check if Gateway is running locally
ps aux | grep openclaw-gateway | grep -v grep

# Check port status
lsof -i :18789

# Test local connectivity
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:18789/
```

**For Remote Gateway (via SSH):**

```bash
# Verify SSH connectivity
ssh openclaw@<TAILSCALE_IP> "echo 'SSH OK'"

# Check if remote Gateway is running
ssh openclaw@<TAILSCALE_IP> "ps aux | grep openclaw-gateway | grep -v grep"

# Check remote Gateway logs
ssh openclaw@<TAILSCALE_IP> "tail -30 ~/.openclaw/logs/gateway.log"
```

### Phase 2: Token Retrieval

**Local Token:**

```bash
cat ~/.openclaw/openclaw.json | grep -A 5 '"gateway"' | grep -A 3 '"auth"'
```

**Remote Token (SSH):**

```bash
ssh openclaw@<TAILSCALE_IP> "cat ~/.openclaw/openclaw.json | grep -A 5 '\"gateway\"' | grep -A 3 '\"auth\"'"
```

**Extract Token Value:**

```bash
# Local
LOCAL_TOKEN=$(cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"' | grep '"token"' | cut -d'"' -f4)

# Remote
REMOTE_TOKEN=$(ssh openclaw@<TAILSCALE_IP> "cat ~/.openclaw/openclaw.json | grep -A 3 '\"auth\"' | grep '\"token\"' | cut -d'\"' -f4")
```

### Phase 3: SSH Tunnel (for Remote Access)

**Create Tunnel:**

```bash
# Use alternate port to avoid conflict with local Gateway
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@<TAILSCALE_IP>
```

Flags:
- `-f` - Background after authentication
- `-N` - No remote command execution (tunnel only)
- `-L 18790:127.0.0.1:18789` - Forward local port 18790 to remote 127.0.0.1:18789

**Verify Tunnel:**

```bash
# Check tunnel process
ps aux | grep "ssh.*18790" | grep -v grep

# Test connectivity
curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:18790/
```

### Phase 4: Provide Tokenized URLs

**Format:**

```
http://localhost:<PORT>/?token=<GATEWAY_TOKEN>
```

**Examples:**

Local Gateway (default port 18789):
```
http://localhost:18789/?token=6ab72a8937d83589a29fea9cf7c4dd1901226fa28c6cbc4bedccc6ea105d2f55
```

Remote Gateway (tunneled to port 18790):
```
http://localhost:18790/?token=96e234ec9a175f394df0b5b4345b652a4617b992ce1bd41db5dea36eb572fed9
```

## Common Scenarios

### Scenario 1: Single Local Gateway

**User Issue:** "Dashboard shows disconnected (1008)"

**Solution:**

1. Retrieve token:
```bash
cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"' | grep '"token"' | cut -d'"' -f4
```

2. Provide tokenized URL:
```
http://localhost:18789/?token=<TOKEN>
```

### Scenario 2: Remote Gateway via SSH

**User Issue:** "Can't access Mac Mini dashboard"

**Solution:**

1. Test SSH connectivity:
```bash
ssh openclaw@100.66.145.48 "echo 'Connection OK'"
```

2. Get remote token:
```bash
ssh openclaw@100.66.145.48 "cat ~/.openclaw/openclaw.json | grep -A 3 '\"auth\"' | grep '\"token\"' | cut -d'\"' -f4"
```

3. Create SSH tunnel:
```bash
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48
```

4. Provide tokenized URL:
```
http://localhost:18790/?token=<REMOTE_TOKEN>
```

### Scenario 3: Multiple Gateways (Local + Remote)

**User Issue:** "I have two Gateways running and I'm confused which dashboard is which"

**Solution:**

1. Identify local Gateway:
```bash
lsof -i :18789  # Should show local node process
```

2. Create tunnel for remote Gateway on alternate port:
```bash
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@<REMOTE_IP>
```

3. Get both tokens:
```bash
LOCAL_TOKEN=$(cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"' | grep '"token"' | cut -d'"' -f4)
REMOTE_TOKEN=$(ssh openclaw@<REMOTE_IP> "cat ~/.openclaw/openclaw.json | grep -A 3 '\"auth\"' | grep '\"token\"' | cut -d'\"' -f4")
```

4. Provide both URLs with clear labels:
```
Local Dashboard: http://localhost:18789/?token=${LOCAL_TOKEN}
Remote Dashboard: http://localhost:18790/?token=${REMOTE_TOKEN}
```

## Troubleshooting Decision Tree

```
Dashboard won't connect?
├─ Is Gateway running locally?
│  ├─ NO → Start Gateway: openclaw gateway start --port 18789
│  └─ YES → Continue
│
├─ Is this a REMOTE Gateway?
│  ├─ YES → Is SSH tunnel active?
│  │  ├─ NO → Create tunnel: ssh -f -N -L 18790:127.0.0.1:18789 user@host
│  │  └─ YES → Test tunnel: curl localhost:18790
│  └─ NO → Continue
│
├─ Can you reach Gateway HTTP?
│  ├─ NO → Check logs: tail ~/.openclaw/logs/gateway.log
│  └─ YES → Continue
│
├─ Do you have the token?
│  ├─ NO → Retrieve from config (see Phase 2)
│  └─ YES → Continue
│
└─ Provide tokenized URL:
   http://localhost:<PORT>/?token=<TOKEN>
```

## Token Generation (if missing)

If token doesn't exist in config:

```bash
# Generate new token
NEW_TOKEN=$(openssl rand -hex 32)

# Set in config
openclaw config set gateway.auth.token "$NEW_TOKEN"

# Or manually edit ~/.openclaw/openclaw.json:
{
  "gateway": {
    "auth": {
      "token": "YOUR_GENERATED_TOKEN_HERE",
      "mode": "token"
    }
  }
}

# Restart Gateway
launchctl stop com.openclaw.gateway && sleep 2 && launchctl start com.openclaw.gateway
```

## SSH Tunnel Management

### Create Tunnel
```bash
ssh -f -N -L <LOCAL_PORT>:127.0.0.1:18789 user@<REMOTE_HOST>
```

### Kill Tunnel
```bash
# Kill specific tunnel
pkill -f "ssh.*<LOCAL_PORT>.*<REMOTE_HOST>"

# Kill all tunnels to a host
pkill -f "ssh.*<REMOTE_HOST>"
```

### Check Tunnel Status
```bash
# List active tunnels
ps aux | grep "ssh.*-L" | grep -v grep

# Check if port is listening
lsof -i :<LOCAL_PORT>
```

## Expected Outputs

### Successful Connection

**Browser Console:**
```
WebSocket connection established
Connected to OpenClaw Gateway
```

**Dashboard UI:**
- Shows "Connected" status (green indicator)
- Displays channels (Telegram, iMessage, etc.)
- Agent configurations visible
- No "unauthorized" errors

### Failed Connection (Before Fix)

**Dashboard UI:**
```
Disconnected (1008): unauthorized: gateway token missing
(open a tokenized dashboard URL or paste token in Control UI settings)
```

**Browser Console:**
```
WebSocket connection failed: 1008
Unauthorized: gateway token missing
```

## Output Format

When helping a user, provide:

1. **Diagnosis Summary:**
   - Gateway status (running/not running)
   - Connection type (local/remote)
   - Any errors found

2. **Token Information:**
   ```
   Gateway Token: <TOKEN_VALUE>
   ```

3. **Tokenized URLs (clickable):**
   ```
   Local Dashboard: http://localhost:18789/?token=<TOKEN>
   Remote Dashboard: http://localhost:18790/?token=<TOKEN>
   ```

4. **Tunnel Commands (if applicable):**
   ```bash
   # Create tunnel
   ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48

   # Verify tunnel
   curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:18790/
   ```

5. **Next Steps:**
   - Click the tokenized URL to open dashboard
   - Or manually paste token in Control UI settings
   - Verify connection status shows "Connected"

## Tool Usage Pattern

```bash
# Always run diagnostics first
ps aux | grep openclaw-gateway | grep -v grep  # Is it running?
lsof -i :18789                                 # What's on the port?

# For remote access
ssh user@host "ps aux | grep openclaw-gateway"  # Remote status
ssh -f -N -L 18790:127.0.0.1:18789 user@host   # Create tunnel
curl localhost:18790                            # Test tunnel

# Get tokens
cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"'              # Local
ssh user@host "cat ~/.openclaw/openclaw.json | grep -A 3 '\"auth\"'"  # Remote

# Build and provide URLs
http://localhost:18789/?token=<LOCAL_TOKEN>
http://localhost:18790/?token=<REMOTE_TOKEN>
```

## Files Referenced

- `~/.openclaw/openclaw.json` - Main config with Gateway auth token
- `~/.openclaw/logs/gateway.log` - Gateway activity log
- `~/.openclaw/logs/gateway.err.log` - Error log
- `~/.openclaw/.gateway-token` - Alternative token storage (if exists)

## Related Skills

- `ssh-troubleshoot` - SSH connectivity issues
- `openclaw-onboarding` - Initial OpenClaw setup
- `session:start` - Session initialization (Boris methodology)

## Related Documentation

- [Dashboard Troubleshooting Guide](../../DOCUMENTATION/dashboard-troubleshooting.md) - Comprehensive troubleshooting reference
- [Remote Support Guide](../../REMOTE-SUPPORT-GUIDE.md) - SSH access and remote operations
- [Tailscale Explained](../../DOCUMENTATION/tailscale-explained.md) - Network connectivity

## Success Criteria

User successfully:
- [ ] Accesses dashboard without "unauthorized" error
- [ ] Sees "Connected" status in dashboard
- [ ] Can view and interact with channels/agents
- [ ] Understands difference between local and remote dashboards (if applicable)
- [ ] Can reconnect to dashboard after closing browser

## Notes

- **Security:** Never commit tokens to git or share them publicly
- **Port Conflicts:** Always use alternate ports (18790, 18791, etc.) for tunnels to avoid conflicts with local Gateway
- **Tunnel Persistence:** SSH tunnels created with `-f` flag persist until killed or system reboot
- **Token Rotation:** Tokens can be regenerated; just update config and restart Gateway
- **Browser Cache:** Sometimes requires hard refresh (Cmd+Shift+R) after fixing token issues

---

*Created: 2026-02-03*
*Last Updated: 2026-02-03*
*Tested With: OpenClaw 2026.2.1+*
