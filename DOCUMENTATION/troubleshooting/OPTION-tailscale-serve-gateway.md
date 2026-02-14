# Option: Expose Gateway via Tailscale Serve

**Best of Both Worlds**: Keep gateway on localhost, but make it accessible via Tailscale without SSH tunnels.

**Time Required**: 1 minute (client runs one command)
**Security**: Good - only accessible to Tailscale network
**Reversible**: Yes - easy to disable

---

## Setup (Client Runs on Mac Mini)

### Quick Start - One Command:

```bash
# Expose local gateway through Tailscale
tailscale serve --bg --set-path=/dashboard 18789
```

This makes the gateway accessible at:
```
https://openclaws-mac-mini.tailb35295.ts.net/dashboard
```

### Verify It's Working:

```bash
# Check Tailscale serve status
tailscale serve status

# Should show something like:
# https://openclaws-mac-mini.tailb35295.ts.net/dashboard (proxy http://127.0.0.1:18789)
```

---

## From Your Support Machine

Now you can access the gateway directly via Tailscale HTTPS:

```bash
# Get the gateway token
# (client sends you this or you retrieve via Tailscale file transfer)
TOKEN="their-gateway-token-here"

# Access dashboard
open "https://openclaws-mac-mini.tailb35295.ts.net/dashboard?token=$TOKEN"
```

No SSH tunnel needed! ✅

---

## How It Works

1. **Gateway still listens on localhost** (secure)
2. **Tailscale Serve acts as a proxy** from Tailscale network → localhost
3. **HTTPS by default** (Tailscale provides TLS certificates automatically)
4. **Only accessible to your Tailscale network** (not public internet)

---

## Benefits Over Direct Binding

| Feature | Direct Binding (0.0.0.0) | Tailscale Serve |
|---------|-------------------------|-----------------|
| Gateway Config Changes | Required ❌ | None ✅ |
| HTTPS/TLS | Manual setup ❌ | Automatic ✅ |
| Revoke Access | Restart gateway ❌ | One command ✅ |
| Security | Medium ⚠️ | Good ✅ |
| Setup Complexity | Medium | Easy ✅ |

---

## Disable Tailscale Serve (If Needed)

```bash
# Stop serving
tailscale serve off

# Gateway remains on localhost, just not exposed via Tailscale
```

---

## Alternative: Serve Multiple Ports

If you have multiple services to expose:

```bash
# Serve gateway on /gateway path
tailscale serve --bg --set-path=/gateway 18789

# Serve another service on /api path
tailscale serve --bg --set-path=/api 3000

# Check status
tailscale serve status
```

---

## Troubleshooting

### "tailscale serve: command not found"

Your Tailscale version might be outdated. Update:

```bash
# Download latest Tailscale
open https://tailscale.com/download/mac

# Or via Homebrew
brew upgrade tailscale
```

### "serve requires Tailscale version X.X or higher"

Same solution - update Tailscale to latest version.

### Gateway still not accessible

1. Check if serve is active:
   ```bash
   tailscale serve status
   ```

2. Verify gateway is running locally:
   ```bash
   curl http://localhost:18789/
   # Should return HTTP 200
   ```

3. Check Tailscale connection:
   ```bash
   tailscale status
   # Should show "online"
   ```

---

## Security Considerations

**Who Can Access:**
- ✅ Anyone on your Tailscale network
- ❌ Public internet (blocked by default)
- ❌ People outside your Tailscale network

**Access Control:**
- Gateway token still required (authentication layer)
- Tailscale ACLs can further restrict access
- HTTPS encrypted by default
- Can revoke access via Tailscale admin panel

**Recommended:**
- Rotate gateway token periodically
- Use Tailscale ACLs to limit access to specific IPs
- Monitor gateway logs for unusual activity
- Disable serve when not needed for maintenance

---

## Summary: Why This is Better Than SSH Tunnels

**With SSH Tunnels:**
```bash
# Support person creates tunnel every time
ssh -L 18790:127.0.0.1:18789 user@machine
open http://localhost:18790/?token=...
```

**With Tailscale Serve:**
```bash
# Client sets up once (1 command)
# Support person accesses directly anytime
open https://openclaws-mac-mini.tailb35295.ts.net/dashboard?token=...
```

**Result:**
- ✅ No SSH setup needed
- ✅ No SSH key management
- ✅ No tunnel management
- ✅ Always accessible when needed
- ✅ HTTPS by default
- ✅ Easy to enable/disable

---

*Created: 2026-02-08*
*Recommended approach for Tailscale-native gateway access*
