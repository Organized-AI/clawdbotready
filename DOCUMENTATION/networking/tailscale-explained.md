# Tailscale - A Visual Guide

## TL;DR (What Is It?)

Tailscale is a **mesh VPN** that makes all your devices appear on the same private network, no matter where they are. Each device gets a unique IP address (like `100.64.0.1`) and can talk directly to any other device - even through firewalls and NATs - without any port forwarding or complex setup.

---

## The Core Concept

```
TRADITIONAL VPN (Hub-and-Spoke):
                    ┌─────────────────┐
        ┌──────────▶│   VPN Server    │◀──────────┐
        │           │  (bottleneck)   │           │
        │           └─────────────────┘           │
        │                   ▲                     │
        │                   │                     │
   ┌────┴────┐         ┌────┴────┐          ┌────┴────┐
   │ Phone   │         │ Laptop  │          │ Server  │
   └─────────┘         └─────────┘          └─────────┘
   
   All traffic goes through central server (slow, expensive)


TAILSCALE (Mesh Network):
   ┌─────────┐                              ┌─────────┐
   │ Phone   │◀═══════════════════════════▶│ Server  │
   │100.64.0.1                              │100.64.0.3
   └────┬────┘                              └────┬────┘
        │                                        │
        │          ┌─────────┐                   │
        └─────────▶│ Laptop  │◀──────────────────┘
                   │100.64.0.2
                   └─────────┘
   
   Direct peer-to-peer connections (fast, free)
```

**Key insight:** Tailscale devices talk directly to each other. There's no central server bottleneck - just encrypted tunnels between each pair of devices that need to communicate.

---

## How Tailscale Actually Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TAILSCALE ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│                    ☁️  CONTROL PLANE                                │
│                    (Tailscale's servers)                            │
│               ┌─────────────────────────┐                           │
│               │  • Authentication       │                           │
│               │  • Key exchange         │                           │
│               │  • Device discovery     │                           │
│               │  • Access control (ACLs)│                           │
│               └───────────┬─────────────┘                           │
│                           │                                         │
│         ┌─────────────────┼─────────────────┐                       │
│         │ metadata only   │   metadata only │                       │
│         ▼                 ▼                 ▼                       │
│    ┌─────────┐       ┌─────────┐       ┌─────────┐                  │
│    │ Phone   │       │ Laptop  │       │ Server  │                  │
│    └────┬────┘       └────┬────┘       └────┬────┘                  │
│         │                 │                 │                       │
│         │    🔒 DATA PLANE (WireGuard)      │                       │
│         │    Direct encrypted connections   │                       │
│         │◀═══════════════▶│◀═══════════════▶│                       │
│         │                 │                 │                       │
│    Your data NEVER touches Tailscale servers!                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Two separate planes:**
1. **Control Plane** - Tailscale's servers handle coordination (who can talk to whom, key exchange)
2. **Data Plane** - Your actual traffic flows directly between devices via WireGuard encryption

---

## NAT Traversal: The Magic Explained

The hardest problem Tailscale solves is connecting devices behind NATs and firewalls.

```
BEFORE TAILSCALE (NAT blocks incoming connections):

┌─────────────────────────────────────────────────────────────────────┐
│  HOME NETWORK                                                       │
│  ┌─────────────┐                                                   │
│  │   Router    │ ◀───── ❌ BLOCKED ───── Incoming connection       │
│  │   (NAT)     │        from internet                              │
│  └──────┬──────┘                                                   │
│         │                                                          │
│    ┌────▼────┐                                                     │
│    │ Laptop  │   192.168.1.50 (private IP, unreachable)            │
│    └─────────┘                                                     │
└─────────────────────────────────────────────────────────────────────┘


TAILSCALE NAT TRAVERSAL (UDP hole punching):

Step 1: Both devices register with Tailscale
        ┌───────────────────────────┐
        │   Tailscale Coordination  │
        │   Server                  │
        └─────────┬─────────────────┘
         "Phone is at 73.45.2.100:54321"
         "Laptop is at 98.76.5.200:12345"
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼

Step 2: Devices send packets simultaneously (hole punching)
┌─────────────┐             ┌─────────────┐
│   Phone     │ ──────────▶ │   Laptop    │
│ 73.45.2.100 │ ◀────────── │ 98.76.5.200 │
└─────────────┘             └─────────────┘
   Both NATs allow the traffic because both sides initiated!

Step 3: Direct encrypted tunnel established
┌─────────────┐    🔒      ┌─────────────┐
│   Phone     │◀══════════▶│   Laptop    │
│ 100.64.0.1  │ WireGuard  │ 100.64.0.2  │
└─────────────┘            └─────────────┘
```

---

## Tailscale IP Addresses

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TAILSCALE IP SCHEME                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Range: 100.64.0.0/10 (CGNAT range - won't conflict with your LAN) │
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  M4 Mac Mini    │  │  M1 MacBook     │  │  iPhone         │     │
│  │  100.64.0.1     │  │  100.64.0.2     │  │  100.64.0.3     │     │
│  │  mac-mini       │  │  macbook-pro    │  │  iphone         │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
│                                                                     │
│  Access methods:                                                    │
│    • By IP:       curl http://100.64.0.1:18789                     │
│    • By hostname: curl http://mac-mini:18789    (MagicDNS)         │
│    • By FQDN:     curl http://mac-mini.tailnet-name.ts.net:18789   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**MagicDNS** - Tailscale automatically provides DNS names for your devices, so you don't have to remember IP addresses.

---

## Real-World Scenario: Clawdbot from Anywhere

```
┌─────────────────────────────────────────────────────────────────────┐
│                    YOUR TAILSCALE NETWORK                           │
│                     (tailnet: jordan-ai)                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   🏢 OFFICE                    ☕ COFFEE SHOP                        │
│   ┌─────────────────┐         ┌─────────────────┐                  │
│   │  M4 Mac Mini    │◀═══════▶│  M1 MacBook     │                  │
│   │  100.64.0.1     │         │  100.64.0.2     │                  │
│   │                 │         │                 │                  │
│   │  ┌───────────┐  │         │  Browser:       │                  │
│   │  │ Clawdbot  │  │         │  http://mac-mini:18789             │
│   │  │ :18789    │  │         │                 │                  │
│   │  └───────────┘  │         └─────────────────┘                  │
│   └─────────────────┘                  ▲                           │
│            ▲                           │                           │
│            │                           │                           │
│            │     🚗 IN THE CAR          │                           │
│            │     ┌─────────────────┐   │                           │
│            └════▶│  iPhone         │◀══┘                           │
│                  │  100.64.0.3     │                               │
│                  │                 │                               │
│                  │  Clawdbot app:  │                               │
│                  │  http://mac-mini:18789                          │
│                  └─────────────────┘                               │
│                                                                     │
│   🌍 CLOUD VPS (Fly.io)                                            │
│   ┌─────────────────┐                                              │
│   │  clawdbot-prod  │◀══════════════════════════════════════════╗  │
│   │  100.64.0.4     │   Can access Mac Mini securely!           ║  │
│   └─────────────────┘                                            ║  │
│            ║                                                      ║  │
│            ╚══════════════════════════════════════════════════════╝  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Access Clawdbot from anywhere:**
```bash
# Any device on your tailnet can simply do:
curl http://mac-mini:18789
# or
curl http://100.64.0.1:18789
```

No port forwarding. No VPN clients to configure. Just works.

---

## DERP Relay: The Fallback

Sometimes direct connections fail (very strict firewalls). Tailscale has fallback relay servers.

```
NORMAL (Direct Connection):
┌─────────┐         ┌─────────┐
│ Phone   │◀═══════▶│ Laptop  │     ~5ms latency
└─────────┘ direct  └─────────┘


FALLBACK (DERP Relay - still encrypted!):
┌─────────┐         ┌─────────┐         ┌─────────┐
│ Phone   │════════▶│  DERP   │════════▶│ Laptop  │
└─────────┘         │ Relay   │         └─────────┘
                    └─────────┘
                    ~50ms latency (still end-to-end encrypted!)
                    
Tailscale CANNOT see your data - only encrypted packets pass through.
```

---

## macOS Installation Variants

Tailscale offers three distinct installation methods for macOS 12.0+, each with different characteristics and use cases.

```
┌─────────────────────────────────────────────────────────────────────┐
│               TAILSCALE macOS INSTALLATION OPTIONS                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1️⃣  STANDALONE (Recommended for most users)                        │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Download:  https://tailscale.com/download/mac                │ │
│  │  Type:      System Extension                                  │ │
│  │  Requires:  No Apple ID                                       │ │
│  │  Updates:   Direct from Tailscale (faster security patches)   │ │
│  │  Features:  Full feature set (Funnel, SSH server, Taildrop)   │ │
│  │  Pros:      Best compatibility, fastest updates, most stable  │ │
│  │  Cons:      Manual installation (.pkg file)                   │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  2️⃣  MAC APP STORE (Easiest for beginners)                          │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Download:  Mac App Store (search "Tailscale")                │ │
│  │  Type:      Network Extension (sandboxed)                     │ │
│  │  Requires:  Apple ID                                          │ │
│  │  Updates:   Through App Store (slower, subject to review)     │ │
│  │  Features:  Limited - NO Funnel, NO SSH server                │ │
│  │  Pros:      One-click install, familiar update process        │ │
│  │  Cons:      Feature limitations, Screen Time conflicts        │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  3️⃣  CLI ONLY (Advanced users & automation)                         │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Download:  brew install tailscale (or compile from source)   │ │
│  │  Type:      Kernel utun interface                             │ │
│  │  Requires:  Command-line familiarity                          │ │
│  │  Updates:   Manual (Homebrew or build from source)            │ │
│  │  Features:  No GUI, incomplete Taildrop support               │ │
│  │  Pros:      Maximum control, scriptable, open source          │ │
│  │  Cons:      No graphical interface, manual configuration      │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Feature Comparison Matrix

```
┌──────────────────────┬─────────────┬─────────────┬─────────────┐
│  FEATURE             │  STANDALONE │  APP STORE  │  CLI ONLY   │
├──────────────────────┼─────────────┼─────────────┼─────────────┤
│  System Extension    │      ✅     │      ❌     │      ❌     │
│  Network Extension   │      ❌     │      ✅     │      ❌     │
│  GUI Management      │      ✅     │      ✅     │      ❌     │
│  MagicDNS            │      ✅     │      ✅     │      ✅     │
│  Auto-updates        │      ✅     │      ✅     │      ❌     │
│  Tailscale Funnel    │      ✅     │      ❌     │      ✅     │
│  SSH Server          │      ✅     │      ❌     │      ✅     │
│  Taildrop (file)     │      ✅     │      ✅     │     ⚠️*     │
│  Apple ID required   │      ❌     │      ✅     │      ❌     │
│  Conflict detection  │      ✅     │      ❌     │      ❌     │
└──────────────────────┴─────────────┴─────────────┴─────────────┘
* CLI variant has incomplete Taildrop support
```

### ⚠️ Important Installation Notes

**DO NOT install multiple variants simultaneously!**

```
❌ WRONG:
   Standalone + App Store on same Mac = Extension won't launch

✅ CORRECT:
   1. Uninstall existing variant completely
   2. Empty Trash
   3. Reboot Mac
   4. Install new variant
```

### Which Variant Should You Choose?

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DECISION GUIDE                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Choose STANDALONE if:                                              │
│    • You want the most stable, feature-complete experience          │
│    • You need Tailscale Funnel (expose services to internet)        │
│    • You want to run Tailscale SSH server                           │
│    • You need fastest security updates                              │
│    • You're deploying for production use (Clawdbot!)                │
│                                                                     │
│  Choose APP STORE if:                                               │
│    • You're just trying Tailscale for the first time                │
│    • You want one-click installation                                │
│    • You only need basic VPN connectivity                           │
│    • You don't need advanced features                               │
│                                                                     │
│  Choose CLI ONLY if:                                                │
│    • You're automating deployments (scripting)                      │
│    • You prefer command-line tools                                  │
│    • You don't need GUI management                                  │
│    • You're building custom integrations                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### For Clawdbot Deployments: Use Standalone

```
🎯 RECOMMENDATION:
   For OpenClaw Gateway / Clawdbot deployments, use the STANDALONE variant:

   • Full feature compatibility
   • Best stability for production services
   • Faster security patches (no App Store review delays)
   • Can detect conflicts with other VPN/network tools
   • Supports Funnel if you want to expose Gateway to internet later
```

---

## Setup Commands

```bash
# Install - STANDALONE (Recommended for Clawdbot)
# Download from: https://tailscale.com/download/mac
# Run the .pkg installer

# Install - CLI ONLY (via Homebrew)
brew install tailscale

# Start the service
sudo tailscaled &

# Login (opens browser for auth)
tailscale up

# Check status
tailscale status
# Output:
# 100.64.0.1    mac-mini      jordanai@    macOS   -
# 100.64.0.2    macbook-pro   jordanai@    macOS   active; direct 192.168.1.50:41641

# See your Tailscale IP
tailscale ip -4
# 100.64.0.2

# Ping another device
tailscale ping mac-mini
# pong from mac-mini (100.64.0.1) via 192.168.1.100:41641 in 2ms

# Access Clawdbot on Mac Mini from anywhere
curl http://mac-mini:18789/health
```

---

## Pros and Cons

```
┌──────────────────────────────────────────────────────────────────┐
│                          TAILSCALE                                │
├──────────────────────────────────────────────────────────────────┤
│  ✅ PROS                      │  ⚠️  CONS                        │
├───────────────────────────────┼──────────────────────────────────┤
│  Zero configuration           │  Requires software installation  │
│  (just install and login)     │  (not everywhere allows this)    │
├───────────────────────────────┼──────────────────────────────────┤
│  Works through any NAT        │  Dependency on Tailscale service │
│  (even double NAT, CGNAT)     │  (coordination servers)          │
├───────────────────────────────┼──────────────────────────────────┤
│  Automatic reconnection       │  Learning curve for ACLs         │
│  (seamless WiFi→cellular)     │  (if you need complex policies)  │
├───────────────────────────────┼──────────────────────────────────┤
│  MagicDNS hostnames           │  Free tier has device limits     │
│  (http://mac-mini not IPs)    │  (100 devices, 3 users)          │
├───────────────────────────────┼──────────────────────────────────┤
│  Multi-device mesh            │  Small latency vs no VPN         │
│  (all devices can talk)       │  (usually <5ms, barely noticeable│
├───────────────────────────────┼──────────────────────────────────┤
│  WireGuard encryption         │                                  │
│  (state-of-the-art security)  │                                  │
└───────────────────────────────┴──────────────────────────────────┘
```

---

## SSH Tunnel vs Tailscale

```
┌───────────────────┬────────────────────────┬────────────────────────┐
│  FEATURE          │  SSH TUNNEL            │  TAILSCALE             │
├───────────────────┼────────────────────────┼────────────────────────┤
│  Setup            │  Manual each time      │  One-time install      │
│  Network changes  │  Breaks (reconnect)    │  Seamless transition   │
│  Multiple devices │  Tunnel per device     │  All devices in mesh   │
│  Mobile access    │  Awkward               │  Native apps           │
│  Port forwarding  │  Per-port tunnel       │  Full network access   │
│  Dependencies     │  SSH (everywhere)      │  Tailscale software    │
│  Cost             │  Free                  │  Free (up to limits)   │
│  Latency          │  ~same                 │  ~same                 │
│  Security         │  SSH encryption        │  WireGuard encryption  │
└───────────────────┴────────────────────────┴────────────────────────┘

RECOMMENDATIONS:

Use SSH Tunnel when:
  • Quick/temporary access needed
  • Can't install software on target machine  
  • Single port, single machine
  • Network is stable

Use Tailscale when:
  • Always-on access needed
  • Multiple devices or team members
  • Mobile access required
  • Frequently change networks (laptop user)
  • "It just works" is priority
```

---

## Tailscale for Teams

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TEAM TAILSCALE SETUP                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Admin Console (admin.tailscale.com)                               │
│  ┌─────────────────────────────────────┐                           │
│  │  Users:                             │                           │
│  │    • jordan@company.com  (admin)    │                           │
│  │    • dev1@company.com    (member)   │                           │
│  │    • dev2@company.com    (member)   │                           │
│  │                                     │                           │
│  │  Devices:                           │                           │
│  │    • mac-mini (jordan) - 100.64.0.1 │                           │
│  │    • laptop-1 (dev1)   - 100.64.0.2 │                           │
│  │    • laptop-2 (dev2)   - 100.64.0.3 │                           │
│  │                                     │                           │
│  │  ACLs (Access Control):             │                           │
│  │    • All users can access mac-mini  │                           │
│  │    • Only jordan can SSH to servers │                           │
│  └─────────────────────────────────────┘                           │
│                                                                     │
│  All team members can now access:                                   │
│    http://mac-mini:18789  (Clawdbot dashboard)                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

```bash
# Install
brew install tailscale         # macOS
curl -fsSL https://tailscale.com/install.sh | sh  # Linux

# Basic operations
tailscale up                   # Connect to tailnet
tailscale down                 # Disconnect
tailscale status               # Show connected devices
tailscale ip -4                # Show your Tailscale IP

# Diagnostics
tailscale ping <hostname>      # Test connectivity
tailscale netcheck             # Check NAT type, connectivity
tailscale debug derp           # Check DERP relay status

# Share a machine (let others access without adding to tailnet)
tailscale serve 18789          # Expose port via Tailscale Funnel

# Access from any tailnet device
curl http://<hostname>:18789   # By MagicDNS name
curl http://100.64.0.x:18789   # By Tailscale IP
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Tailscale is stopped" | Run `tailscale up` to connect |
| Can't reach device | Check `tailscale status` - is it online? |
| High latency | Check `tailscale ping` - using DERP relay? Check firewall |
| MagicDNS not working | Enable in admin console, or use IP directly |
| Connection timeout | Verify both devices logged into same tailnet |

---

*Created with the Explainer Docs skill for learning while building.*
