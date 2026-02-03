# Dashboard Troubleshoot Skill

Expert troubleshooting assistant for OpenClaw Gateway dashboard connection issues.

## Quick Start

Use this skill when dashboard shows:
```
Disconnected (1008): unauthorized: gateway token missing
```

The skill will:
1. Check if Gateway is running
2. Retrieve the Gateway token
3. Create SSH tunnel (if accessing remote Gateway)
4. Provide tokenized dashboard URL

## Usage

```bash
# In Claude Code CLI
/dashboard-troubleshoot

# Or just mention the issue
"My dashboard won't connect - shows unauthorized error"
```

## What It Fixes

- ❌ Dashboard disconnected (1008 error)
- ❌ "Unauthorized: gateway token missing"
- ❌ Can't access remote Gateway dashboard
- ❌ Multiple Gateways causing confusion
- ❌ SSH tunnel not working

## Example Output

```
✓ Mac Mini Gateway: Running (PID 13847)
✓ SSH Tunnel: Active on port 18790
✓ Token Retrieved

Access your dashboard:
http://localhost:18790/?token=96e234ec9a175f394df0b5b4345b652a4617b992ce1bd41db5dea36eb572fed9
```

## Common Scenarios

### Local Gateway
```bash
# Opens local dashboard with token
http://localhost:18789/?token=<YOUR_TOKEN>
```

### Remote Gateway (via SSH)
```bash
# Creates tunnel on port 18790
ssh -f -N -L 18790:127.0.0.1:18789 openclaw@100.66.145.48

# Opens remote dashboard
http://localhost:18790/?token=<REMOTE_TOKEN>
```

### Multiple Gateways
- Local: `http://localhost:18789/?token=<LOCAL_TOKEN>`
- Remote: `http://localhost:18790/?token=<REMOTE_TOKEN>`

## Related Documentation

- [Dashboard Troubleshooting Guide](../../../DOCUMENTATION/dashboard-troubleshooting.md)
- [Remote Support Guide](../../../REMOTE-SUPPORT-GUIDE.md)

## Version

1.0.0 - Initial release (2026-02-03)
