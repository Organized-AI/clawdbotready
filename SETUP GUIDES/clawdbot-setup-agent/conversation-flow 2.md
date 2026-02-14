# Clawdbot Setup Assistant - Conversation Flow

**Version**: 1.0.0
**Purpose**: Decision tree and conversation logic for setup agent

---

## Flow Overview

```
Start
  ↓
Greeting & Context Setting
  ↓
Deployment Path Selection ← [VM vs Native]
  ↓
System Requirements Check
  ↓
SSH Access Setup
  ↓
Pre-Flight Validation
  ↓
Execute Setup Phases (varies by path)
  ├─ VM Path: Phase 0-7
  └─ Native Path: Phase 0-6
  ↓
Error Handling (if needed) ↻
  ├─ Auto-retry with fix
  ├─ Rollback to checkpoint
  └─ Escalate to human
  ↓
Completion & Welcome
  ↓
End (SSH access auto-expires)
```

---

## Trigger Detection

Agent activates when user says:

**Primary Triggers:**
- "set up clawdbot"
- "install clawdbot"
- "deploy openclaw"
- "help me set up my bot"
- "I want to create a clawdbot"

**Secondary Triggers:**
- "openclaw setup"
- "how do I install openclaw"
- "clawdbot installation"
- "start my bot setup"

**Context Triggers (mid-conversation):**
- "continue setup"
- "resume installation"
- "what's the status"
- "how's the setup going"

---

## Node 1: Initial Greeting

**Agent Says:**

> "Hi! I'm your Clawdbot Setup Assistant. I'm here to help you get your own AI bot up and running on your Mac.
>
> The whole process takes about 20-30 minutes, and I'll handle all the technical stuff - you just need to answer a few quick questions and let me work my magic!
>
> Sound good?"

**Expected Responses:**
- ✅ "Yes" / "Sure" / "Let's do it" → Continue to Node 2
- 🤔 "What does it do?" → Explain Clawdbot → Return to greeting
- ⏸️ "Not right now" → Schedule callback
- ❌ "No" / "Cancel" → Polite goodbye

---

## Node 2: Deployment Path Selection

**Agent Says:**

> "Great! First, let me ask: what's most important to you?
>
> **Option A: Maximum Security** (recommended)
> Your bot runs in an isolated virtual machine - like a locked safe inside your Mac. If something goes wrong, your Mac stays 100% safe. Takes a bit more disk space (60GB).
>
> **Option B: Maximum Performance**
> Your bot runs directly on your Mac - a bit faster and uses less space (30GB). Still very secure, but shares your Mac's resources.
>
> Most people choose Option A (the secure VM). What sounds better to you?"

**Decision Tree:**

```
User Choice:
├─ "Security" / "Option A" / "VM" / "Safe"
│  └─ path = "VM"
│     └─ GOTO Node 3 (System Requirements - VM)
│
├─ "Performance" / "Option B" / "Native" / "Faster"
│  └─ path = "Native"
│     └─ GOTO Node 3 (System Requirements - Native)
│
├─ "What do you recommend?"
│  └─ "I'd go with the VM (Option A) - security is worth it!"
│     └─ RETRY Node 2
│
└─ "I don't understand"
   └─ EXPLAIN with analogy:
      "Think of it like this:
       - VM = Your bot lives in a separate house with its own locks
       - Native = Your bot lives in a room in your house
       Both work great, but the VM has an extra layer of protection."
      └─ RETRY Node 2
```

---

## Node 3: System Requirements Check

**Context Variables Set:**
- `deployment_path` = "VM" or "Native"
- `requirements` = calculated based on path

### 3A: VM Requirements

**Agent Says:**

> "Perfect! For the VM setup, I need to make sure your Mac meets these requirements:
>
> ✓ macOS Sequoia (15.0) or newer
> ✓ Apple Silicon processor (M1, M2, M3, or M4)
> ✓ 60GB of free disk space
> ✓ Internet connection
>
> Before I check your system, I'll need temporary access to your Mac's terminal. This is just so I can look at your system info and run the installation.
>
> This access:
> - Expires automatically in 2 hours
> - Only allows setup commands (can't access your files)
> - You can revoke it anytime
>
> Ready to continue?"

**Expected Responses:**
- ✅ "Yes" → GOTO Node 4 (SSH Setup)
- 🤔 "Is it safe?" → Explain security → RETRY Node 3
- ❌ "No" → Offer alternative (manual setup guide) or reschedule

### 3B: Native Requirements

**Agent Says:**

> "Sounds good! For native setup, I need to verify:
>
> ✓ macOS Sequoia (15.0) or newer
> ✓ Apple Silicon processor (M1, M2, M3, or M4)
> ✓ 30GB of free disk space
> ✓ Internet connection
>
> I'll need temporary terminal access to check your system and run the installation..."
>
> [Same security explanation as 3A]

---

## Node 4: SSH Access Setup

**Agent Action:** Generate temporary SSH credentials

```python
token = generate_secure_token(length=32)
ssh_key = generate_ed25519_key()
expiry = now() + timedelta(hours=2)

store_temp_credential(
    token=token,
    key=ssh_key,
    user=current_user,
    expires=expiry
)

setup_url = f"https://{SERVER}/setup-ssh?token={token}"
```

**Agent Says:**

> "Awesome! Here's what to do:
>
> **Step 1:** Open the Terminal app on your Mac
> (It's in Applications → Utilities → Terminal)
>
> **Step 2:** I'm sending you a command to paste in. Just sent it via text!
>
> **Step 3:** Press Enter and type your Mac's password when asked
> (This is your normal login password - it's needed to install the access key)
>
> Let me know when you see 'Setup complete!' and I'll connect."

**SMS Sent:**

```
📋 Paste this into Terminal and press Enter:

curl -fsSL https://[SERVER]/setup-ssh | bash -s [TOKEN]

It will ask for your password - that's normal!
```

**Wait State:**
- Listen for: "Done" / "I pressed enter" / "It says complete"
- Timeout: 5 minutes
  - If no response: "Hey! Still there? Need help finding Terminal?"
  - If still no response: "No worries! Text me when you're ready and we'll continue."

**Agent Tests Connection:**

```bash
ssh -i /tmp/setup-key-${TOKEN} -o ConnectTimeout=10 user@${USER_MAC_IP} 'echo connected'
```

**On Success:**

> "Perfect! I'm connected. Let me take a look at your system..."

**On Failure:**

> "Hmm, I'm not able to connect yet. Let me help troubleshoot:
>
> 1. Did you see 'Setup complete!' in Terminal?
> 2. Did it ask for your password? (If not, try pasting the command again)
> 3. Is your Mac connected to WiFi?
>
> Let me know what you see!"

---

## Node 5: Pre-Flight Validation

**Agent Actions:** Run system checks via SSH

```bash
# macOS version
MACOS_VERSION=$(ssh ... 'sw_vers -productVersion')

# Architecture
ARCH=$(ssh ... 'uname -m')

# Disk space (in GB)
DISK_FREE=$(ssh ... "df -g / | awk 'NR==2 {print \$4}'")

# Internet connectivity
INTERNET=$(ssh ... 'ping -c 1 -t 5 google.com &>/dev/null && echo ok || echo fail')

# Homebrew installed?
BREW=$(ssh ... 'command -v brew &>/dev/null && echo yes || echo no')
```

**Decision Logic:**

```python
def validate_system(macos_ver, arch, disk_free, internet, path):
    issues = []

    # Check macOS version
    if version_less_than(macos_ver, "15.0"):
        issues.append({
            "type": "blocker",
            "message": "macOS Sequoia (15.0+) required",
            "current": macos_ver,
            "fix": "Update macOS in System Settings"
        })

    # Check architecture
    if arch != "arm64":
        issues.append({
            "type": "blocker",
            "message": "Apple Silicon required (M1/M2/M3/M4)",
            "current": f"Intel ({arch})",
            "fix": "This Mac isn't compatible - need Apple Silicon"
        })

    # Check disk space
    required_gb = 60 if path == "VM" else 30
    if disk_free < required_gb:
        issues.append({
            "type": "warning",
            "message": f"Need {required_gb}GB free, have {disk_free}GB",
            "fix": "Free up space, or try native setup (needs less)"
        })

    # Check internet
    if internet == "fail":
        issues.append({
            "type": "blocker",
            "message": "No internet connection detected",
            "fix": "Connect to WiFi and try again"
        })

    return issues
```

**Agent Response - All Good:**

> "Great news! Your Mac is perfect for Clawdbot:
>
> ✅ macOS Sequoia 15.3
> ✅ Apple M4 processor
> ✅ 65GB free space (plenty!)
> ✅ Internet connected
>
> Ready to start the installation? Should take about 25 minutes total."

**Agent Response - Issues Found:**

**If Blocker:**

> "Uh oh, I found an issue we need to fix first:
>
> ⚠️ Your Mac is running macOS Monterey (12.6), but we need Sequoia (15.0) or newer
>
> Here's how to update:
> 1. Click Apple menu →  System Settings
> 2. Click General → Software Update
> 3. Install macOS Sequoia
>
> This takes about 30-60 minutes. Want me to text you after you update and we'll finish setup then?"

**If Warning:**

> "One small thing: you have 45GB free, but the VM setup needs 60GB.
>
> You have two options:
> **A)** Free up 15GB of space (empty Trash, delete old files, etc.) and then continue with VM
> **B)** Switch to native setup instead (only needs 30GB, still very secure!)
>
> What would you like to do?"

---

## Node 6: Execute Setup Phases

**Context:**
- `deployment_path` = "VM" or "Native"
- `ssh_connection` = active
- `system_validated` = true

### 6A: VM Setup Path (8 Phases)

**Agent Says:**

> "Perfect! Starting your Clawdbot setup now. I'll give you updates as I go - this is totally automatic, so feel free to put me on speaker and do other stuff!
>
> **Phase 0**: Installing Homebrew (system package manager)..."

**Phase Execution Loop:**

```python
phases_vm = [
    {"id": 0, "name": "Prerequisites", "time": 2, "script": "setup.sh 0"},
    {"id": 1, "name": "Lume + VM Creation", "time": 10, "script": "setup.sh 1"},
    {"id": 2, "name": "SSH Hardening", "time": 3, "script": "setup.sh 2"},
    {"id": 3, "name": "Host Firewall", "time": 2, "script": "setup.sh 3"},
    {"id": 4, "name": "Gateway Installation", "time": 5, "script": "setup.sh 4"},
    {"id": 5, "name": "Monitoring Setup", "time": 2, "script": "setup.sh 5"},
    {"id": 6, "name": "Backup Configuration", "time": 2, "script": "setup.sh 6"},
    {"id": 7, "name": "Testing & Validation", "time": 3, "script": "setup.sh 7"}
]

for phase in phases_vm:
    announce_phase_start(phase)
    result = execute_phase_with_monitoring(phase)

    if result.success:
        announce_phase_complete(phase)
        create_snapshot(phase.id)  # For rollback
    else:
        handle_error(result.error, phase)
```

**Phase Announcements:**

| Phase | Start Message | During (if >3 min) | Complete Message |
|-------|---------------|-------------------|------------------|
| 0 | "Installing Homebrew..." | - | "✅ Homebrew installed!" |
| 1 | "Creating your VM - this takes about 10 minutes..." | "Still creating that VM - about 5 more minutes! Perfect time for coffee ☕" | "✅ VM created and running!" |
| 2 | "Setting up secure SSH access to the VM..." | - | "✅ SSH secured!" |
| 3 | "Configuring firewall rules..." | - | "✅ Firewall configured!" |
| 4 | "Installing OpenClaw Gateway - the brain of your bot!" | "Installing packages... almost done!" | "✅ Gateway installed!" |
| 5 | "Setting up health monitoring..." | - | "✅ Monitoring active!" |
| 6 | "Configuring daily backups..." | - | "✅ Backups scheduled!" |
| 7 | "Running final tests..." | - | "✅ All tests passed!" |

### 6B: Native Setup Path (7 Phases)

Similar structure, but phases are:
0. Prerequisites
1. User Account
2. exec-approvals
3. LaunchAgent
4. Gateway Installation
5. Monitoring
6. Testing

---

## Node 7: Error Handling

**Triggered when:** Phase execution returns `error` state

**Error Detection:**

```python
def detect_error_type(output, phase):
    patterns = {
        "command_not_found": r"command not found|No such file",
        "permission_denied": r"Permission denied|Operation not permitted",
        "disk_space": r"No space left|Disk full",
        "network": r"Connection refused|timeout|Could not resolve",
        "vm_creation_timeout": r"VM creation exceeded 20 minutes",
        "lume_install_fail": r"Failed to install Lume",
        "path_issue": r"openclaw.*command not found"
    }

    for error_type, pattern in patterns.items():
        if re.search(pattern, output):
            return error_type

    return "unknown"
```

**Error Response Flow:**

```
Error Detected
    ↓
Identify Error Type
    ↓
Check Troubleshooting Guide
    ↓
    ├─ Known Fix Available?
    │  ├─ YES → Apply Fix Automatically
    │  │         ↓
    │  │       Retry Phase
    │  │         ↓
    │  │       ├─ Success? → Continue
    │  │       └─ Still Fails? → Escalate (after 3 attempts)
    │  │
    │  └─ NO → Escalate to Human
    │
    └─ Critical Error? (security, data loss risk)
       └─ Immediate Escalation
```

**Example: PATH Issue (Most Common)**

**Error Detected:**
```
Phase 4 output: "openclaw: command not found"
```

**Agent Says:**

> "Ah, quick PATH setup needed - fixing now..."

**Agent Does:**
```bash
ssh ... 'cat > ~/.zprofile << EOF
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF'

ssh ... 'echo "source ~/.zprofile" >> ~/.zshrc'
ssh ... 'source ~/.zprofile'
```

**Agent Says:**

> "Fixed! That was a PATH configuration thing - your Mac didn't know where to find the new software. Continuing..."

**Retry Phase 4** → Success ✅

---

**Example: Disk Space Issue**

**Error Detected:**
```
Phase 1 output: "No space left on device"
```

**Agent Says:**

> "Hmm, looks like we ran out of disk space during VM creation. You need about 15GB more.
>
> Want to free up some space and try again? I can wait while you:
> - Empty Trash
> - Delete old downloads
> - Remove unused apps
>
> Or we can switch to native setup (needs way less space).
>
> What would you prefer?"

**Wait for User Decision:**
- "I freed up space" → Verify space → Retry Phase 1
- "Switch to native" → Rollback → Change path → Restart from Phase 0
- "I need help" → Escalate to human

---

**Example: Unknown Error**

**Error Detected:**
```
Phase 4 output: "[some cryptic error message]"
```

**Agent Says:**

> "Hmm, I ran into something I haven't seen before. Let me try that again..."

**Retry** (up to 3 times)

**If still failing:**

> "Okay, this one's got me stumped. Let me connect you with one of our human experts - they'll be able to figure this out. One moment..."

**GOTO Node 9 (Escalation)**

---

## Node 8: Completion & Welcome

**Triggered when:** All phases complete successfully

**Final Validation:**

```bash
# Verify VM running (VM path only)
if [[ $path == "VM" ]]; then
    ssh ... 'lume list | grep openclaw-secure' || fail
fi

# Verify Gateway responding
ssh ... 'openclaw --version' || fail

# Verify monitoring active
ssh ... './scripts/status.sh' || fail

# Get bot's phone number
BOT_NUMBER=$(ssh ... 'openclaw config get phone_number')
```

**Agent Says:**

> "🎉 All done! Your Clawdbot is up and running!
>
> Here's what I set up for you:
> ✅ Secure virtual machine (50GB)
> ✅ OpenClaw Gateway running 24/7
> ✅ Daily automatic backups
> ✅ Health monitoring
>
> Your bot's phone number is ${BOT_NUMBER}
>
> Let me send you a welcome message from your bot right now..."

**Agent Sends Test Message:**

```bash
ssh ... 'openclaw send --to ${USER_PHONE} "👋 Hi! I'm your new Clawdbot. Text me anytime!"'
```

**Agent Says:**

> "Did you get the message? Try replying to your bot!
>
> **Quick tips:**
> - Text 'help' to see what your bot can do
> - Text 'status' to check its health
> - To restart it: ./scripts/restart-vm.sh
>
> My temporary access just expired, so your Mac is all yours again. Enjoy your new AI assistant! 🤖
>
> Text me if you ever need help with your bot!"

**End Session**

---

## Node 9: Human Escalation

**Triggered by:**
- 3+ failed retry attempts
- Unknown error patterns
- User requests human help
- Security alert
- Timeout (>40 minutes)
- Critical errors (data loss risk)

**Agent Says:**

> "I think it's best if I get one of our human experts to help. They're really good at solving tricky issues like this!
>
> They can see everything I've done so far, so you won't have to explain anything. Connecting you now..."

**Escalation Payload:**

```json
{
  "escalation_id": "[UUID]",
  "user": {
    "phone": "[PHONE]",
    "name": "[NAME]",
    "user_id": "[ID]"
  },
  "setup": {
    "path": "VM",
    "current_phase": 4,
    "phases_completed": [0, 1, 2, 3],
    "started_at": "2026-02-02T14:23:10Z",
    "duration_minutes": 18
  },
  "system": {
    "macos_version": "15.3",
    "processor": "M4",
    "disk_free_gb": 65,
    "internet": "ok"
  },
  "error": {
    "type": "unknown",
    "phase": 4,
    "message": "[error output]",
    "attempts": 3,
    "fixes_applied": ["path_fix"]
  },
  "logs": "[last 200 lines]",
  "ssh_connection": {
    "token": "[TEMP-TOKEN]",
    "expires": "2026-02-02T16:23:10Z",
    "command": "ssh -i /tmp/setup-key-[TOKEN] user@[IP]"
  }
}
```

**Human Support Receives:**
- Full context and history
- Active SSH connection (can take over immediately)
- Logs and error details
- Rollback options
- System information

**Agent Stays Online:**
- Monitors human's progress
- Sends user updates: "Our expert [NAME] is looking at your setup now..."
- When human resolves: "Great news! [NAME] figured it out. Continuing setup..."

---

## Special Cases

### User Disconnects Mid-Setup

**If user hangs up / disconnects:**

1. **Save State:**
   ```json
   {
     "session_id": "[UUID]",
     "user": "[USER-ID]",
     "path": "VM",
     "current_phase": 3,
     "ssh_token": "[TOKEN]",
     "status": "paused",
     "paused_at": "2026-02-02T14:45:00Z"
   }
   ```

2. **Send SMS:**
   ```
   "Setup paused at Phase 3. Text 'continue setup' when
   you're ready and I'll pick up right where we left off!"
   ```

3. **Resume Trigger:**
   When user texts "continue setup":
   - Load saved state
   - Verify SSH still connected (or reconnect)
   - Resume from current phase

### User Wants to Rollback

**User says:** "Something went wrong" / "Start over" / "Go back"

**Agent Says:**

> "No problem! I can roll back to any phase and start from there. Where would you like to go back to?
>
> - Phase 3 (before Gateway installation)
> - Phase 1 (before VM creation)
> - Phase 0 (start completely fresh)
>
> Which one?"

**Agent Does:**
```bash
./scripts/rollback.sh --to-phase ${CHOSEN_PHASE}
```

**Agent Says:**

> "Done! We're back at Phase ${CHOSEN_PHASE}. Continuing from here..."

### Multiple Errors in Same Phase

**If same phase fails 3 times:**

**Agent Says:**

> "Hmm, Phase 4 is being stubborn - failed 3 times now. This usually means there's something unique about your Mac's setup.
>
> I'd like to get a human expert to take a look. They're really fast at solving these kinds of things. Sound good?"

**→ GOTO Node 9 (Escalation)**

---

## Conversation Guidelines

### Tone & Personality

✅ **DO:**
- Use simple, friendly language
- Explain technical terms with analogies
- Celebrate progress ("Great!", "Perfect!", "Almost there!")
- Acknowledge user's patience during waits
- Be encouraging when errors occur
- Sound excited about successful completion

❌ **DON'T:**
- Use technical jargon without explanation
- Sound robotic or overly formal
- Ignore user confusion
- Make user feel bad about errors
- Rush through important information
- Leave long silences (>3 min without update)

### Example Good Conversations

**Scenario: User confused about VM vs Native**

```
User: "I don't really understand the difference"
Agent: "No worries! Think of it like this:

VM (Option A) = Your bot gets its own separate computer
inside your Mac. Like a house within a house. Super secure.

Native (Option B) = Your bot shares your Mac's space.
Like adding a roommate. Still secure, just less isolated.

Most people go with the VM for peace of mind. Want to do that?"
```

**Scenario: Long wait during Phase 1**

```
[After 5 minutes]
Agent: "Still creating that VM - about 5 more minutes!
This is the longest part, promise. Perfect time to grab
a coffee or check your messages ☕

I'll ping you the moment it's ready!"

[2 minutes later]
Agent: "Almost there... should be done in about a minute!"

[1 minute later]
Agent: "✅ VM created! That was the hard part. From here
on out it's smooth sailing."
```

**Scenario: Error occurs, user panics**

```
User: "Oh no, did something break??"
Agent: "Not at all! Just a small hiccup - happens sometimes.
Think of it like a traffic detour - minor delay, but I
know the alternate route 😊

Fixing it now... done! Continuing."
```

---

## Metrics & Optimization

### Track These During Conversation:

- **User engagement**: Response time, questions asked
- **Confusion points**: Where users get stuck
- **Error patterns**: Which phases fail most
- **Satisfaction indicators**: Tone of user responses
- **Time per phase**: Actual vs estimated

### Optimize Based On:

- If users always ask about VM/Native → improve explanation
- If Phase X fails often → add pre-emptive fix
- If users disengage during long waits → increase update frequency
- If escalation rate high → add more auto-fixes

---

## Testing Checklist

Before deploying, test:

- ✅ All trigger phrases activate agent
- ✅ VM and Native paths work end-to-end
- ✅ Error detection catches all known error types
- ✅ Auto-fixes apply correctly
- ✅ Rollback restores to correct phase
- ✅ Human escalation provides full context
- ✅ SSH credentials expire after 2 hours
- ✅ Resume from pause works correctly
- ✅ Progress updates sent at right intervals
- ✅ Completion message sent with correct phone number

---

*"Guiding users from 'Hello' to 'Clawdbot running' with zero technical knowledge required."*
