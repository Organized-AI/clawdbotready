# Monday Office Action Plan — SSH Fix + Fleet Status Fast v2 Kickoff

**Date:** Monday, March 2, 2026
**Location:** Office (M4 Mac Mini — jordans-mac-mini / 100.86.248.8)
**Target:** openclaws-mac-mini / 100.66.145.48

---

## Situation

- M1 MacBook Pro (supabowl) has a GitLab-only ed25519 key — NOT authorized on any fleet machine
- Working SSH keys are on the M4 Mac Mini at the office
- Tailscale SSH is NOT enabled on openclaws-mac-mini (needs `sudo tailscale set --ssh`)
- Gateway at 100.66.145.48:18789 is online and healthy (HTTP 200 confirmed Feb 28)

---

## Step 1: Enable Tailscale SSH (Browser — Do This First)

Open: **https://login.tailscale.com/admin/acls**

Ensure this policy is saved:

```json
{
  "acls": [
    { "action": "accept", "src": ["*"], "dst": ["*:*"] }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:members"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot"]
    }
  ]
}
```

Click **Save**.

---

## Step 2: Enable Tailscale SSH on openclaws-mac-mini (From M4 Mac Mini)

The M4 has working SSH keys. From Terminal on the M4:

```bash
ssh openclaw@100.66.145.48 "sudo tailscale set --ssh"
```

If that prompts for a password, SSH in interactively first:

```bash
ssh openclaw@100.66.145.48
sudo tailscale set --ssh
exit
```

---

## Step 3: Authorize the M1 MacBook Pro Key (While You're In)

The M1's public key:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPu+AIbA+KeWC4puM5HIKRaU42cqSe7xA2++kc0o91cE gitlab key
```

From the M4, push it to openclaws-mac-mini:

```bash
ssh openclaw@100.66.145.48 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPu+AIbA+KeWC4puM5HIKRaU42cqSe7xA2++kc0o91cE gitlab key" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo "Key added"'
```

Also authorize it on the M4 itself:

```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPu+AIbA+KeWC4puM5HIKRaU42cqSe7xA2++kc0o91cE gitlab key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## Step 4: Verify From M1 MacBook Pro (Test Remotely After)

```bash
# Tailscale SSH (no keys needed)
tailscale ssh openclaw@openclaws-mac-mini "echo 'Tailscale SSH works'"

# Direct SSH with key
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 openclaw@100.66.145.48 "echo 'Direct SSH works'"

# M4 Mac Mini
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 jordaaan@100.86.248.8 "echo 'M4 SSH works'"
```

---

## Step 5: Fix M1 SSH Config

On the M1 MacBook Pro, run:

```bash
cat >> ~/.ssh/config << 'EOF'

# Fleet machines — Tailscale
Host openclaws-mac-mini
    HostName 100.66.145.48
    User openclaw
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host jordans-mac-mini
    HostName 100.86.248.8
    User jordaaan
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
```

After this: `ssh openclaws-mac-mini` just works.

---

## Step 6: Start Fleet Status Fast v2 Build

SSH into openclaws-mac-mini, create project, launch Claude Code:

```bash
ssh openclaw@100.66.145.48
mkdir -p ~/fleet-control-api && cd ~/fleet-control-api
claude --dangerously-skip-permissions
```

Then paste the Phase 0+1 prompt from `CLAUDE-CODE-PHASE-0.md`.

---

## Verification Checklist

- [ ] Tailscale ACL SSH policy saved
- [ ] `sudo tailscale set --ssh` run on openclaws-mac-mini
- [ ] M1 MacBook Pro key authorized on openclaws-mac-mini
- [ ] M1 MacBook Pro key authorized on M4 Mac Mini
- [ ] `tailscale ssh openclaw@openclaws-mac-mini` works from M1
- [ ] Direct SSH works from M1 with IdentitiesOnly
- [ ] M1 `~/.ssh/config` updated with fleet hosts
- [ ] Fleet Control API Phase 0+1 started on openclaws-mac-mini
