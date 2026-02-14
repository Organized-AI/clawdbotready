# Option: Make Gateway Accessible via Tailscale (No SSH Tunnel Needed)

**⚠️ Security Trade-off**: This makes the gateway accessible to anyone on your Tailscale network, not just localhost.

**Recommended**: Only do this if you trust everyone on your Tailscale network.

---

## Steps (Client Runs on Mac Mini)

### 1. Find the OpenClaw Gateway Start Command

```bash
# Check current LaunchAgent configuration
cat ~/Library/LaunchAgents/com.openclaw.gateway.plist
```

Look for the command that starts the gateway. It probably includes `--port 18789` or similar.

### 2. Modify to Listen on Tailscale Interface

Edit the plist or the gateway start command to bind to `0.0.0.0` (all interfaces) or specifically to the Tailscale IP `100.66.145.48`.

**Option A: Listen on all interfaces**
```bash
# Edit the LaunchAgent plist
nano ~/Library/LaunchAgents/com.openclaw.gateway.plist

# Find the gateway start command and add:
--bind 0.0.0.0
# or
--host 0.0.0.0
```

**Option B: Listen only on Tailscale interface** (more secure)
```bash
# Bind to Tailscale IP only
--bind 100.66.145.48
# or
--host 100.66.145.48
```

### 3. Reload and Restart Gateway

```bash
# Unload the old configuration
launchctl unload ~/Library/LaunchAgents/com.openclaw.gateway.plist

# Load the new configuration
launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist

# Start the gateway
launchctl start com.openclaw.gateway
```

### 4. Test Remote Access

From your support machine:
```bash
# Should now work!
curl http://100.66.145.48:18789/

# Access dashboard with token
open "http://100.66.145.48:18789/?token=YOUR_GATEWAY_TOKEN"
```

---

## Security Implications

**Before this change:**
- ✅ Gateway only accessible from localhost
- ✅ Requires SSH tunnel for remote access
- ✅ Extra layer of security

**After this change:**
- ⚠️ Gateway accessible to entire Tailscale network
- ⚠️ Anyone with Tailscale access + gateway token can connect
- ⚠️ No SSH authentication layer

**Mitigation:**
- Only invite trusted users to Tailscale network
- Rotate gateway token regularly
- Use Tailscale ACLs to restrict access to specific IPs
- Monitor gateway logs for unauthorized access attempts

---

## Alternative: Use Tailscale Funnel (If Available)

If the client has Tailscale Funnel enabled, they can expose the gateway securely:

```bash
tailscale serve --bg 18789
```

This creates a secure proxy through Tailscale without changing the gateway config.

---

*Created: 2026-02-08*
*Use Case: Direct Tailscale access to OpenClaw Gateway without SSH tunnels*
