# VM Terminal Setup Guide

## Issue: "command not found" in VM Terminal

When you SSH into the VM, you need to load the environment variables for Homebrew and pnpm.

## Quick Fix

In your VM terminal (the one showing "clawusers-Virtual-Machine"), run:

```bash
source ~/.zprofile
```

Then verify:
```bash
openclaw --version
```

You should see: `2026.1.30`

## Permanent Fix

The `.zprofile` file has been configured, but it only loads automatically for **login shells**.

### Make it automatic for all shells:

```bash
# Inside the VM
echo 'source ~/.zprofile' >> ~/.zshrc
```

Now every time you connect, the paths will be available.

## Verify Everything Works

Run these commands in the VM to verify the setup:

```bash
# 1. Check Node.js
node --version
# Expected: v25.5.0

# 2. Check pnpm
pnpm --version
# Expected: 10.28.2

# 3. Check OpenClaw
openclaw --version
# Expected: 2026.1.30

# 4. Check Gateway status
openclaw gateway status
# Expected: "Runtime: running" and "RPC probe: ok"
```

## If Commands Still Not Found

Run this comprehensive setup command:

```bash
# Load all paths
eval "$(/opt/homebrew/bin/brew shellenv)"
export PNPM_HOME="/Users/clawuser/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Test
openclaw --version
```

## Current Setup Summary

✅ **Homebrew**: Installed at `/opt/homebrew`
✅ **Node.js**: v25.5.0 via Homebrew
✅ **pnpm**: 10.28.2 via Homebrew
✅ **OpenClaw**: 2026.1.30 installed globally
✅ **Gateway**: Running with PID 18797
✅ **Auth Token**: Configured and secure

## Connecting to VM from Host

From your host Mac:
```bash
ssh -i ~/.ssh/openclaw_vm_ed25519 clawuser@192.168.64.5
```

## Troubleshooting

### Q: Why does this happen?
A: macOS zsh doesn't automatically load `.zprofile` for non-login shells. When you SSH in, it starts a login shell, but if you run `zsh` again inside, it's not a login shell.

### Q: Can I use bash instead?
A: Yes, but you'd need to create a `.bash_profile` with the same content.

### Q: How do I check if paths are loaded?
```bash
echo $PATH | grep -o "homebrew\|pnpm"
```

Should show both `homebrew` and `pnpm`.

---

**Next Steps After Setup:**
1. Verify Gateway: `openclaw gateway status`
2. Connect a channel: `openclaw channels login`
3. Test messaging integration
