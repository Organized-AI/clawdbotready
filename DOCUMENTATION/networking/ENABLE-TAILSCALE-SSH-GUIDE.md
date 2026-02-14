# Enable Tailscale SSH — Client Guide

**For**: The person who owns the Tailscale network (the client)
**Time Required**: 5 minutes
**What This Does**: Allows your tech support person to SSH into your Mac using Tailscale — no passwords, no keys to manage, no router configuration

---

## Why Tailscale SSH?

Regular SSH requires managing keys, passwords, and firewall rules. Tailscale SSH replaces all of that — it handles authentication through your Tailscale account, so only people on your network can connect. It's simpler and more secure.

---

## What You Need Before Starting

- You are the **owner** (or admin) of your Tailscale network
- Your tech support person is already a member of your Tailscale network
- Both machines have Tailscale installed and connected

If you haven't done these steps yet, follow the [Client Tailscale Setup Guide](client-tailscale-ssh-setup.md) first.

---

## Step 1: Open the Tailscale Admin Console

1. Open your browser and go to: **https://login.tailscale.com/admin**
2. Sign in with the same account you used when you set up Tailscale

You should see a list of your machines (your Mac Mini should be listed here).

---

## Step 2: Go to the Access Controls Page

1. In the left sidebar, click **Access controls**
2. You'll see a code editor with your network's policy file (it looks like JSON)

If you've never edited this before, it will contain default rules that look something like this:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ]
}
```

---

## Step 3: Add the SSH Rules

You need to add an `"ssh"` section to enable Tailscale SSH. Copy the block below and paste it into your policy file **after the `"acls"` section** (make sure there's a comma between them).

### Option A: Allow Your Tech Support to SSH as Any User

This is the simplest option. It lets anyone on your Tailscale network SSH into any machine as any user.

Your full policy file should look like this:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
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

### Option B: Only Allow a Specific Person (More Restrictive)

If you want to limit SSH access to just your tech support person's Tailscale email:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["jordaaan@github"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot"]
    }
  ]
}
```

Replace `jordaaan@github` with the actual Tailscale identity of your tech support person. Ask them for this — it's the email or identity shown in the Tailscale admin under **Users**.

---

## Step 4: Save the Policy

1. After pasting in the SSH rules, click the **Save** button at the bottom of the page
2. You should see a green confirmation that the policy was saved

If you see a red error message, double-check that:
- All commas are in the right places
- All brackets `[ ]` and braces `{ }` are properly matched
- You didn't accidentally delete any existing content

---

## Step 5: Enable Tailscale SSH on Your Mac Mini

On the Mac Mini itself, Tailscale SSH needs to be turned on. Your tech support person may have already done this, but if not:

1. Open **Terminal** on the Mac Mini (press `Cmd + Space`, type "Terminal", press Enter)
2. Run this command:
   ```bash
   sudo tailscale set --ssh
   ```
3. Enter your Mac password when prompted (it won't show as you type — that's normal)
4. You should see no output, which means it worked

### Verify It's On

Run this command:
```bash
tailscale status
```

You should see your machine listed, and it should show SSH capability.

---

## Step 6: Test the Connection

Ask your tech support person to try connecting:

```bash
ssh openclaw@your-machine-name
```

They can use either:
- The **machine name** shown in Tailscale (e.g., `ssh openclaw@mac-mini`)
- The **Tailscale IP** address (e.g., `ssh openclaw@100.66.145.48`)

If it works, they'll see a terminal prompt without being asked for a password — Tailscale handles the authentication.

---

## How to Revoke Access Later

### Remove SSH Access But Keep Network Access

1. Go to **https://login.tailscale.com/admin/acls**
2. Delete the `"ssh"` section from your policy
3. Click **Save**

### Remove Someone From Your Network Entirely

1. Go to **https://login.tailscale.com/admin/machines**
2. Find their device
3. Click the **...** menu next to it
4. Click **Remove**

### Disable Tailscale SSH on the Mac Mini

On the Mac Mini, run:
```bash
sudo tailscale set --ssh=false
```

---

## Troubleshooting

### "Permission denied" when they try to connect

- **Check the ACL policy** — make sure the `"ssh"` section is saved and the `src` matches their identity
- **Check that SSH is enabled** on the Mac Mini: `tailscale status` should show the machine
- **Make sure they're connected** — ask them to run `tailscale status` on their end too

### "Connection refused"

- Tailscale SSH may not be enabled on the Mac Mini — run `sudo tailscale set --ssh` on it
- The Mac Mini may be asleep or Tailscale may be disconnected — check the Tailscale icon in the menu bar

### Policy won't save (red error)

- JSON syntax error — the most common mistake is a missing or extra comma
- Try pasting your policy into **https://jsonlint.com** to find the error
- Or just replace the entire contents with one of the complete examples from Step 3

### They can connect with regular SSH but not Tailscale SSH

- Regular SSH (port 22) and Tailscale SSH are different things
- Tailscale SSH uses Tailscale's authentication instead of keys/passwords
- Make sure `sudo tailscale set --ssh` was run on the Mac Mini

---

## Quick Reference

| What | Where |
|------|-------|
| Admin console | https://login.tailscale.com/admin |
| ACL / SSH policy | https://login.tailscale.com/admin/acls |
| Manage machines | https://login.tailscale.com/admin/machines |
| Manage users | https://login.tailscale.com/admin/users |
| Enable SSH on Mac | `sudo tailscale set --ssh` |
| Disable SSH on Mac | `sudo tailscale set --ssh=false` |
| Check Tailscale status | `tailscale status` |

---

## What This Looks Like When It's Working

Once everything is set up:

1. Your tech support person runs `ssh openclaw@100.66.145.48` from their computer
2. Tailscale checks that they're on your network and authorized in the ACL policy
3. They get a terminal on your Mac Mini — no password needed
4. You can revoke access anytime by editing the policy or removing them from your network

---

*Guide created: 2026-02-09*
*For use with: Tailscale on macOS (Apple Silicon)*
