# Client Setup Guide: Tailscale SSH on M1 Mac Mini

**For**: Non-technical users setting up remote access
**Time Required**: 10-15 minutes
**What You'll Enable**: Secure remote access to your Mac from anywhere

---

## What This Does

This guide helps you set up **Tailscale SSH**, which allows trusted people to securely access your Mac Mini remotely to help with setup and troubleshooting. Think of it like giving a friend a key to your house - but digital, temporary, and you can take it back anytime.

**Key Benefits:**
- ✅ No complicated router or firewall configuration
- ✅ Works from anywhere (coffee shop, home, etc.)
- ✅ Secure by default - only approved people can connect
- ✅ You control who has access and for how long

---

## Part 1: Install Tailscale (5 minutes)

### Step 1: Download Tailscale
1. Open Safari and go to: **https://tailscale.com/download/mac**
2. Click the blue **"Download"** button
3. Wait for the download to complete (the file will be named `Tailscale-xxx.zip`)

### Step 2: Install Tailscale
1. Open your **Downloads** folder
2. Double-click the `Tailscale-xxx.zip` file to unzip it
3. Drag the **Tailscale** app to your **Applications** folder
4. Open **Applications** folder and double-click **Tailscale**
5. If you see "Tailscale can't be opened because it's from an unidentified developer":
   - Click **OK**
   - Open **System Settings** → **Privacy & Security**
   - Scroll down and click **Open Anyway** next to the Tailscale message
   - Click **Open** in the confirmation dialog

### Step 3: Sign In to Tailscale
1. Tailscale will open in your menu bar (top-right corner, look for a small icon)
2. Click the Tailscale icon
3. Click **Log in**
4. A browser window will open
5. Choose your login method:
   - **Google** (recommended if you have Gmail)
   - **Microsoft**
   - **Apple**
   - **Email** (you'll get a magic link)
6. Complete the sign-in process
7. When you see "Success!", you can close the browser

### Step 4: Verify Connection
1. Click the Tailscale icon in your menu bar
2. You should see:
   - ✅ Your Mac's name
   - ✅ An IP address that starts with `100.`
   - ✅ Status: "Connected"

**Write down this IP address - you'll need it later:**
```
My Tailscale IP: 100.___.___.___
```

---

## Part 2: Enable SSH Access (5 minutes)

SSH is how tech support will securely connect to your Mac. Don't worry - it's already built into macOS, you just need to turn it on.

### Step 5: Open System Settings
1. Click the **Apple menu**  (top-left corner)
2. Click **System Settings**

### Step 6: Enable Remote Login
1. In System Settings, click **General** in the left sidebar
2. Click **Sharing** on the right side
3. Find **Remote Login** in the list
4. Toggle it **ON** (the switch should turn blue)
5. You'll see a message like: `Remote Login: On`

### Step 7: Allow All Users (Simplest Option)
Under "Allow access for:", select:
- **All users** (recommended for initial setup)

> **Note:** Later, after setup is complete, you can change this to specific users only for better security.

### Step 8: Verify SSH is Working
1. Open **Terminal** (you can find it by pressing `⌘ + Space` and typing "Terminal")
2. Type this command and press Enter:
   ```bash
   sudo systemsetup -getremotelogin
   ```
3. You'll be asked for your Mac password - type it and press Enter
   - *Note: Your password won't appear as you type - this is normal*
4. You should see: **"Remote Login: On"**

---

## Part 3: Share Access Information (2 minutes)

### Step 9: Gather Your Access Information
You need to share three pieces of information with your tech support person:

#### 1. Your Tailscale Email
The email you used to sign in to Tailscale (Step 3)
```
My Tailscale Email: _____________________
```

#### 2. Your Mac's Tailscale IP
From Step 4 above:
```
My Tailscale IP: 100.___.___.___
```

#### 3. Your Mac Username
1. Open **Terminal** (⌘ + Space, type "Terminal")
2. Type this and press Enter:
   ```bash
   whoami
   ```
3. Write down what it shows:
   ```
   My Username: _____________________
   ```

### Step 10: Send Information Securely
**Option A: Via Secure Message** (Recommended)
1. Use Signal, WhatsApp, or iMessage to send:
   ```
   Tailscale Email: [your email]
   Tailscale IP: 100.x.y.z
   Mac Username: [your username]
   ```

**Option B: Via Email**
1. Send an email with the subject "Mac Remote Access Info"
2. Include the three pieces of information above
3. Do NOT include your Mac password

---

## Part 4: Grant Access to Tech Support (5 minutes)

Your tech support person needs to be added to your Tailscale network.

### Step 11: Add Tech Support to Your Network
1. Go to **https://login.tailscale.com/admin/machines**
2. Sign in with the same account you used in Step 3
3. Click **Settings** in the left sidebar
4. Click **Users**
5. Click **Invite users** button
6. Enter the tech support person's email address
7. Click **Send invite**

They'll receive an email and need to:
1. Click the link in the email
2. Sign in to Tailscale with their own account
3. Accept the invitation

### Step 12: Confirm They Can Connect
Ask your tech support person to try connecting:
```bash
ssh [your-username]@100.x.y.z
```

They should be able to see your Mac's terminal.

---

## Part 5: Security Best Practices

### During Setup
While tech support is actively working on your Mac:
- ✅ Keep Remote Login ON
- ✅ Keep Tailscale running (connected)
- ✅ You can watch what they're doing by looking at Terminal

### After Setup is Complete
Once your Mac is fully configured and working:

#### Option A: Disable Remote Login (Most Secure)
1. Go back to **System Settings** → **General** → **Sharing**
2. Toggle **Remote Login** to **OFF**
3. You can always turn it back on if you need help again

#### Option B: Keep Remote Login ON (More Convenient)
1. In **System Settings** → **General** → **Sharing** → **Remote Login**
2. Change "Allow access for:" to **Only these users**
3. Click the **+** button and add only your account
4. Remove any other users

#### Remove Tech Support Access (Optional)
If you want to completely revoke access:
1. Go to **https://login.tailscale.com/admin/machines**
2. Find the tech support person's device
3. Click **⋯** (three dots)
4. Click **Remove machine**

---

## Troubleshooting

### "I can't find the Tailscale icon in my menu bar"
1. Open **Finder**
2. Go to **Applications**
3. Double-click **Tailscale**
4. It should appear in your menu bar (top-right)

### "Remote Login won't turn on"
1. Make sure you're using an admin account
2. Try restarting your Mac
3. After restart, try enabling Remote Login again

### "Tech support can't connect"
Check these things:
1. Is Tailscale showing "Connected" in your menu bar?
   - Click the Tailscale icon to check
   - If not, click **Connect**

2. Is Remote Login still ON?
   - **System Settings** → **General** → **Sharing** → **Remote Login**
   - Should be toggled ON (blue)

3. Did you send the correct information?
   - Verify your Tailscale IP: Click Tailscale icon in menu bar
   - Verify your username: Open Terminal and type `whoami`

4. Is your Mac asleep?
   - Keep it awake during setup
   - **System Settings** → **Lock Screen** → Set "Turn display off" to "Never" temporarily

### "I forgot my Tailscale IP address"
1. Click the **Tailscale icon** in your menu bar
2. Your IP address is shown (starts with `100.`)

---

## Quick Reference Card

**Print this and keep it handy:**

```
┌─────────────────────────────────────────────┐
│     MY TAILSCALE SSH ACCESS INFO            │
├─────────────────────────────────────────────┤
│ Tailscale Email: ___________________        │
│                                             │
│ Tailscale IP: 100.___.___.___              │
│                                             │
│ Mac Username: ___________________           │
│                                             │
│ Remote Login Status: _________________      │
│                                             │
│ Last Updated: ___________________           │
└─────────────────────────────────────────────┘

TO ENABLE SSH:
1. System Settings → General → Sharing
2. Toggle "Remote Login" ON

TO DISABLE SSH:
1. System Settings → General → Sharing
2. Toggle "Remote Login" OFF

TO CHECK TAILSCALE:
1. Click Tailscale icon in menu bar
2. Should say "Connected"
```

---

## What Happens Next?

After completing this guide:
1. ✅ Your Mac is connected to Tailscale
2. ✅ SSH access is enabled
3. ✅ Tech support can securely connect remotely
4. ✅ You're ready for the OpenClaw Gateway installation

Your tech support person will now be able to:
- Help install OpenClaw Gateway
- Configure the AI agent system
- Troubleshoot any issues
- Run tests to make sure everything works

**You will be notified** before they connect, and you can watch what they're doing in real-time if you open Terminal.

---

## FAQ

**Q: Is this secure?**
A: Yes! Tailscale uses the same encryption as Signal messenger. Only people you explicitly invite can connect.

**Q: Can they access my files?**
A: They can only access files your Mac user account can access. They cannot access:
- Your iCloud files (unless synced locally)
- Other user accounts on your Mac
- Encrypted data they don't have passwords for

**Q: Will this slow down my Mac?**
A: No. Tailscale uses very little resources (about 20-50MB of RAM).

**Q: What if I want to revoke access immediately?**
A: Simply turn off Remote Login in System Settings, or quit Tailscale from the menu bar.

**Q: Do I need to leave my Mac on?**
A: Yes, during setup sessions. Your Mac needs to be powered on and awake for remote connections.

**Q: Can I use my Mac while they're connected?**
A: Yes! You can continue using your Mac normally. Their terminal session is separate.

**Q: How do I know when they connect?**
A: Check the Terminal app - if it's open, you'll see commands being run in real-time.

---

## After Setup is Complete

Once your OpenClaw Gateway is fully installed and working:

### Recommended: Disable SSH
```
System Settings → General → Sharing → Remote Login → OFF
```

### Keep Tailscale Running
Leave Tailscale connected - it's useful for:
- Future troubleshooting
- Remote monitoring
- Quick support sessions

### Create a Reminder
Set a calendar reminder to review access permissions every 30 days:
1. **https://login.tailscale.com/admin/machines**
2. Remove any devices you don't recognize
3. Check that only trusted people have access

---

## Need Help?

If you get stuck during this setup:

1. **Take a screenshot** of any error messages (⌘ + Shift + 4)
2. **Note where you got stuck** (which step number)
3. **Contact your tech support** with:
   - The step number
   - The screenshot
   - What you tried

**Emergency: Need to Disable Everything?**
1. Click **Tailscale icon** in menu bar → **Quit Tailscale**
2. **System Settings** → **General** → **Sharing** → **Remote Login OFF**

---

*Guide created: 2026-02-02*
*Target: Non-technical M1 Mac Mini users*
*Context: OpenClaw Gateway remote deployment*
