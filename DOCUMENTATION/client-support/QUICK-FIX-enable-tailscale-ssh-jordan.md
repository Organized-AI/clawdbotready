# Quick Fix: Enable Tailscale SSH on Mac Mini

**For**: jordan (machine owner at 100.66.145.48)
**Time Required**: 30 seconds
**Purpose**: Allow remote troubleshooting of OpenClaw Gateway

---

## Steps (Super Simple)

### On the Mac Mini:

1. **Click the Tailscale icon** in your menu bar (top-right corner)

2. **Click "Preferences..."** (or "Settings...")

3. **Find "Allow SSH connections"** checkbox
   - Might be under "General" or "SSH" tab
   - Toggle it **ON** (should turn blue/green)

4. **Click "Save"** or just close the window (it saves automatically)

That's it! ✅

---

## What This Does

- Allows trusted Tailscale users to connect remotely
- Uses Tailscale's built-in authentication (no SSH keys needed)
- More secure than traditional SSH
- You can disable it anytime by unchecking the same box

---

## After Enabling

**The tech support person can now:**
- Check the OpenClaw Gateway status
- Fix any configuration issues
- View logs and diagnose problems
- Restart services if needed

**You'll be notified when:**
- Someone connects (you can see in Terminal if it's open)
- You can watch what they're doing in real-time
- You can disconnect them anytime by turning off SSH in Tailscale

---

## Security Note

This is **more secure** than regular SSH because:
- ✅ No passwords
- ✅ No SSH keys to manage
- ✅ Tailscale handles all authentication
- ✅ Zero exposure to internet (only Tailscale network)
- ✅ Can revoke access instantly from Tailscale admin panel

---

**Alternative**: If you're not comfortable enabling SSH, we can:
1. Schedule a screen-sharing session instead
2. Walk through fixes together over video call
3. Provide step-by-step commands for you to run

---

*Created: 2026-02-08*
*Issue: Cannot access gateway at 100.66.145.48 for troubleshooting*
