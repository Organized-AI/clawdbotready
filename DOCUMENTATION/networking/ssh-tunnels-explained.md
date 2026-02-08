# SSH Tunnels - A Visual Guide

## TL;DR (What Is It?)

An SSH tunnel is an **encrypted pipe** between two computers that lets you securely access services running on a remote machine as if they were running locally. Think of it like a secret underground passage that only you can use.

---

## The Core Concept

```
WITHOUT TUNNEL (Exposed):
┌──────────────┐                         ┌──────────────┐
│  Your Laptop │ ──── INTERNET ────────▶ │ Remote Server│
│              │     (Anyone can see)    │  :18789      │
└──────────────┘                         └──────────────┘
       ⚠️ Traffic visible to everyone on the network


WITH SSH TUNNEL (Protected):
┌──────────────┐                         ┌──────────────┐
│  Your Laptop │                         │ Remote Server│
│  localhost   │                         │  :18789      │
│    :18789    │                         │              │
└──────┬───────┘                         └──────┬───────┘
       │                                        │
       │    ╔══════════════════════════════╗    │
       └────║  🔒 ENCRYPTED SSH TUNNEL     ║────┘
            ║    (Only you can see)        ║
            ╚══════════════════════════════╝
```

The tunnel creates a secure connection where:
- **Your laptop** thinks the service is running locally on `localhost:18789`
- **The remote server** receives your traffic through the encrypted tunnel
- **Everyone else** sees only encrypted gibberish

---

## How Data Flows Through the Tunnel

```
┌─────────────────────────────────────────────────────────────────────┐
│                          YOUR LAPTOP                                │
│  ┌───────────────┐      ┌───────────────┐                          │
│  │  Browser      │ ───▶ │  SSH Client   │                          │
│  │  localhost    │      │  (encrypts)   │                          │
│  │  :18789       │      │               │                          │
│  └───────────────┘      └───────┬───────┘                          │
└─────────────────────────────────┼───────────────────────────────────┘
                                  │
                    ══════════════╪══════════════
                    ║  INTERNET (encrypted)     ║
                    ══════════════╪══════════════
                                  │
┌─────────────────────────────────┼───────────────────────────────────┐
│                          REMOTE SERVER                              │
│                         ┌───────▼───────┐      ┌───────────────┐   │
│                         │  SSH Server   │ ───▶ │  Clawdbot     │   │
│                         │  (decrypts)   │      │  :18789       │   │
│                         │               │      │               │   │
│                         └───────────────┘      └───────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

**Step-by-step:**
1. Browser requests `localhost:18789`
2. SSH client catches the request and encrypts it
3. Encrypted data travels through the internet
4. SSH server decrypts the data
5. Decrypted request goes to Clawdbot on `:18789`
6. Response travels back through the same encrypted tunnel

---

## The Command Explained

```bash
ssh -L local_port:remote_host:remote_port user@server
```

```
ssh -L 18789:127.0.0.1:18789 jordan@mac-mini.local
     │  │     │         │     │      │
     │  │     │         │     │      └── Server to connect to
     │  │     │         │     └── Username on remote
     │  │     │         └── Remote port where service runs
     │  │     └── Remote host (127.0.0.1 = same server)
     │  └── Local port on YOUR machine
     └── "-L" means Local tunnel (forward traffic TO remote)
```

**After running this command:**
- Open `http://localhost:18789` on your laptop
- Traffic magically appears at `mac-mini:18789`
- Everything is encrypted end-to-end

---

## Real-World Scenario: Clawdbot Remote Access

**The Setup:**
- Your Clawdbot runs on M4 Mac Mini at the office
- You're at a coffee shop with your M1 MacBook
- You need to access the Clawdbot dashboard

```
┌────────────────────────────────────────────────────────────────┐
│                       ☕ COFFEE SHOP                           │
│  ┌──────────────────┐                                         │
│  │  M1 MacBook Pro  │                                         │
│  │                  │                                         │
│  │  Browser ───▶ localhost:18789                              │
│  │                  │                                         │
│  │  SSH Client ─────┼──────────┐                              │
│  └──────────────────┘          │                              │
└────────────────────────────────┼───────────────────────────────┘
                                 │
                    ═════════════╪═════════════
                    ║ 🔒 ENCRYPTED TUNNEL     ║
                    ═════════════╪═════════════
                                 │
┌────────────────────────────────┼───────────────────────────────┐
│                       🏢 OFFICE                                │
│                                │                               │
│  ┌──────────────────┐   ┌──────▼──────┐                       │
│  │  M4 Mac Mini     │   │  SSH Server │                       │
│  │                  │   │             │                       │
│  │  Clawdbot ◀──────┼───│  decrypts   │                       │
│  │  :18789          │   │  traffic    │                       │
│  └──────────────────┘   └─────────────┘                       │
└────────────────────────────────────────────────────────────────┘
```

**Commands to run:**

```bash
# On your M1 MacBook at the coffee shop:
ssh -L 18789:127.0.0.1:18789 jordan@mac-mini.local

# Then open browser to:
http://localhost:18789
```

---

## Three Types of SSH Tunnels

```
┌─────────────────────────────────────────────────────────────────────┐
│  LOCAL TUNNEL (-L)                                                  │
│  "Bring remote service to my machine"                               │
│                                                                     │
│     [You] ◀════════════════════════════ [Remote Service]            │
│     localhost:8080                       server:8080                │
│                                                                     │
│  Use case: Access dashboard/DB on remote server                     │
│  Command:  ssh -L 8080:localhost:8080 user@server                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  REMOTE TUNNEL (-R)                                                 │
│  "Expose my local service to remote machine"                        │
│                                                                     │
│     [You] ════════════════════════════▶ [Remote Server]             │
│     localhost:3000                       server:3000                │
│                                                                     │
│  Use case: Let teammate access your local dev server                │
│  Command:  ssh -R 3000:localhost:3000 user@server                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  DYNAMIC TUNNEL (-D)                                                │
│  "Route ALL traffic through remote server"                          │
│                                                                     │
│     [You] ════════════════════════════▶ [Proxy Server]              │
│     SOCKS5 :1080                         (internet via server)      │
│                                                                     │
│  Use case: Browse internet as if you're on remote network           │
│  Command:  ssh -D 1080 user@server                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Pros and Cons

```
┌──────────────────────────────────────────────────────────────────┐
│                         SSH TUNNELS                               │
├──────────────────────────────────────────────────────────────────┤
│  ✅ PROS                      │  ⚠️  CONS                        │
├───────────────────────────────┼──────────────────────────────────┤
│  No software to install       │  Connection can drop             │
│  (SSH is everywhere)          │  (need autossh for persistence)  │
├───────────────────────────────┼──────────────────────────────────┤
│  Extremely secure             │  Manual setup each time          │
│  (battle-tested encryption)   │  (unless you script it)          │
├───────────────────────────────┼──────────────────────────────────┤
│  Works through most firewalls │  Breaks when network changes     │
│  (only needs port 22)         │  (WiFi → cellular = reconnect)   │
├───────────────────────────────┼──────────────────────────────────┤
│  Free - no subscription       │  Point-to-point only             │
│                               │  (one laptop ↔ one server)       │
├───────────────────────────────┼──────────────────────────────────┤
│  Fine-grained control         │  Requires SSH access             │
│  (exactly which ports)        │  (need credentials/keys)         │
└───────────────────────────────┴──────────────────────────────────┘
```

---

## Quick Reference

```bash
# Basic local tunnel
ssh -L LOCAL_PORT:REMOTE_HOST:REMOTE_PORT user@server

# Clawdbot dashboard access
ssh -L 18789:127.0.0.1:18789 user@your-server

# Keep tunnel alive (reconnects on drop)
autossh -M 0 -o "ServerAliveInterval 30" -L 18789:127.0.0.1:18789 user@server

# Run in background
ssh -fN -L 18789:127.0.0.1:18789 user@server
#  -f  Fork to background
#  -N  Don't execute remote command (just tunnel)

# Multiple ports at once
ssh -L 18789:127.0.0.1:18789 -L 5432:127.0.0.1:5432 user@server

# Check if tunnel is working
curl http://localhost:18789/health
```

---

## When to Use SSH Tunnels vs Alternatives

```
┌────────────────────────────────────────────────────────────────────┐
│  SITUATION                              │  RECOMMENDATION          │
├─────────────────────────────────────────┼──────────────────────────┤
│  Quick one-time access                  │  ✅ SSH Tunnel           │
│  Stable network (office/home)           │  ✅ SSH Tunnel           │
│  Maximum security paranoia              │  ✅ SSH Tunnel           │
│  Can't install software on machine      │  ✅ SSH Tunnel           │
├─────────────────────────────────────────┼──────────────────────────┤
│  Always-on access to multiple services  │  ⚠️  Consider Tailscale  │
│  Need to access from phone too          │  ⚠️  Consider Tailscale  │
│  Frequently change networks             │  ⚠️  Consider Tailscale  │
│  Multiple team members need access      │  ⚠️  Consider Tailscale  │
└─────────────────────────────────────────┴──────────────────────────┘
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Is SSH server running? `sudo systemctl status sshd` |
| "Permission denied" | Check SSH keys or password |
| "Address already in use" | Local port taken - choose different one or `kill $(lsof -t -i:18789)` |
| Tunnel drops frequently | Use `autossh` or add `ServerAliveInterval 30` |
| Can't reach service through tunnel | Verify service is running on remote: `curl localhost:18789` |

---

*Created with the Explainer Docs skill for learning while building.*
