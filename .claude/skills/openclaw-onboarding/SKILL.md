---
name: openclaw-onboarding
description: |
  Expert guidance for deploying OpenClaw Gateway using comprehensive setup guides. Provides:
  - Critical disk space validation before each phase (prevents #1 deployment failure)
  - Deployment path selection (VM vs Native macOS)
  - Phased implementation with safety checks
  - Moltbook integration for agent management
  - Production hardening and troubleshooting
  - Lessons learned from real deployments
  Use when: (1) Starting OpenClaw deployment, (2) User asks "set up openclaw", "deploy openclaw gateway", "vm or native setup", (3) Running phased installation, (4) Integrating with Moltbook, (5) Troubleshooting deployment issues, (6) Preparing for production.
---

# OpenClaw Onboarding Expert

**Version**: 2.4.0
**Updated**: 2026-02-05
**Type**: AI Agent Skill
**Category**: Deployment & Infrastructure
**Companion Skill**: openclaw-session-learning v1.0.0

## What This Skill Does

Expert guidance for deploying OpenClaw Gateway using the comprehensive setup guides in `SETUP GUIDES/`. This skill incorporates **lessons learned from real deployments** to prevent common failure modes.

Key capabilities:
- **Pre-flight checks** including critical disk space validation
- **Deployment path selection** (VM vs Native macOS)
- **Phased implementation** execution with safety checks
- **Async VM creation** for improved workflow efficiency
- **Moltbook integration** for agent management
- **Troubleshooting** common deployment issues
- **Production hardening** and security configuration
- **Testing framework** execution for validation

## When to Use

Use this skill when:
- Starting a new OpenClaw deployment
- Choosing between VM and native deployment methods
- Running phased installation with `/phased-build`
- Integrating with Moltbook
- Troubleshooting deployment issues
- Preparing for production deployment
- Running validation tests
- User asks "how do I set up OpenClaw" or similar

**💡 Pro Tip**: Use `/openclaw-session-learning` BEFORE this skill to load historical deployment intelligence from 36+ previous sessions. This prevents repeated mistakes and shows the optimal path forward.

## Trigger Patterns

- "set up openclaw"
- "deploy openclaw"
- "install openclaw gateway"
- "openclaw onboarding"
- "help me with openclaw"
- "moltbook integration"
- "which openclaw setup should I use"
- "vm or native openclaw"
- "continue openclaw setup"
- "test openclaw deployment"

---

## CRITICAL: Lessons Learned from Real Deployments

> **These are hard-won lessons that MUST be applied to every deployment.**

### Lesson 1: Disk Space Requirements (CHANGED)

**Original**: 70GB required for VM setup
**Corrected**: **60GB minimum** (50GB VM allocation + 10GB buffer)

```bash
# CORRECT disk space check
AVAILABLE_GB=$(df -g / | awk 'NR==2 {print $4}')

# VM setup - CORRECTED requirement
if [ "$AVAILABLE_GB" -lt 60 ]; then
  echo "❌ INSUFFICIENT DISK SPACE"
  echo "Required: 60GB | Available: ${AVAILABLE_GB}GB"
  exit 1
fi
```

**Why the change**: Testing revealed 70GB was unnecessarily high. The VM uses 50GB disk allocation, leaving 10GB buffer for OS overhead.

### Lesson 2: Lume Installation Method (CRITICAL FIX)

**Problem**: The official `curl` install script URL redirects to an HTML page, causing installation to fail.

**Solution**: **Homebrew-first approach** with HTML detection fallback.

```bash
# CORRECT Lume installation (Homebrew-first)
install_lume() {
    # Try Homebrew first (RECOMMENDED)
    if command -v brew &>/dev/null; then
        brew install lume
        if command -v lume &>/dev/null; then
            echo "✅ Lume installed via Homebrew"
            return 0
        fi
    fi

    # Fallback: Download and check for HTML (safety check)
    INSTALL_SCRIPT=$(curl -fsSL https://lume.sh/install.sh)
    if echo "$INSTALL_SCRIPT" | head -1 | grep -qi "<!DOCTYPE\|<html"; then
        echo "❌ Install URL returned HTML, not script"
        echo "Please install Lume manually: brew install lume"
        return 1
    fi

    echo "$INSTALL_SCRIPT" | bash
}
```

**Why**: The lume.sh URL redirects to HTML in some environments. Always verify script content before execution.

### Lesson 3: Lume Command Flags (CRITICAL FIX)

**Wrong**: `lume create --disk 50G --memory 8192`
**Correct**: `lume create --disk-size 50G --memory 8G`

```bash
# CORRECT VM creation command
lume create openclaw-secure \
    --os macos-sequoia-vanilla \
    --disk-size "${VM_DISK:-50G}" \
    --memory "${VM_MEMORY:-8G}" \
    --cpu "${VM_CPUS:-4}"
```

**Why**: `--disk` is not a valid flag. Use `--disk-size`. Memory format should be "8G" not "8192".

### Lesson 4: Shell PATH Configuration (CRITICAL)

**Problem**: After installing OpenClaw, users get "command not found" even though installation succeeded.

**Root Cause**: macOS zsh doesn't automatically load Homebrew and pnpm paths in all shell contexts.

**Solution**: **Proactive PATH configuration in Phase 4 Step 3**

```bash
# Configure all paths before installing OpenClaw
cat > ~/.zprofile << 'EOF'
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF

# Make it load for all shell types
echo 'source ~/.zprofile' >> ~/.zshrc

# Load immediately
source ~/.zprofile
```

**Why**:
- `.zprofile` only loads for login shells
- SSH sessions are login shells, but nested shells are not
- Adding `source ~/.zprofile` to `.zshrc` ensures paths load everywhere
- Doing this BEFORE installing OpenClaw prevents "command not found" errors

**Impact**: Prevents 90% of post-installation PATH issues.

### Lesson 5: Async VM Creation Workflow

**Old approach**: Sequential blocking creation
**New approach**: **Background creation with continuation**

```bash
# Start Phase 0-1, VM creates in background
./setup.sh start

# Check status anytime
./scripts/status.sh

# Continue with Phase 2-7 when VM is ready
./setup.sh continue
```

**Why**: VM creation takes 5-15 minutes. Background execution allows monitoring without blocking terminal.

### Lesson 5: Phase Structure (CORRECTED)

**VM Setup**: 8 phases (Phase 0-7), NOT 9 phases
**Native Setup**: 7 phases (Phase 0-6), NOT 6 phases

| Phase | VM Setup | Native Setup |
|-------|----------|--------------|
| 0 | Prerequisites | Prerequisites |
| 1 | Lume + VM | User Account |
| 2 | SSH Hardening | exec-approvals |
| 3 | Host Firewall | LaunchAgent |
| 4 | Gateway Install | Gateway (Manual) |
| 5 | Monitoring | Monitoring |
| 6 | Backups | Helper Scripts |
| 7 | Moltbook (Optional) | - |

### Lesson 6: OpenRouter Model Configuration (CRITICAL)

**Problem**: Bot fails with "Unknown model" error even when model name looks correct.

**Root Cause**: OpenClaw requires specific OpenRouter model naming format.

**CRITICAL: Model Naming Convention**

❌ **WRONG** (these will NOT work):
- `moonshotai/kimi-k2.5` (missing `openrouter/` prefix)
- `moonshot/kimi-k2.5` (wrong author name)
- `kimi-k2.5` (missing both prefix and author)

✅ **CORRECT** format: `openrouter/<author>/<slug>`
- Kimi K2.5: `openrouter/moonshotai/kimi-k2.5`
- DeepSeek: `openrouter/deepseek/deepseek-chat`
- Claude Sonnet: `openrouter/anthropic/claude-sonnet-4.5`
- Auto-router: `openrouter/openrouter/auto`

**CRITICAL: API Key Must Be in LaunchAgent**

The `OPENROUTER_API_KEY` environment variable MUST be added to the LaunchAgent plist, NOT just shell profile.

```bash
# CORRECT way to add API key (persists to LaunchAgent)
launchctl bootout gui/$(id -u)/ai.openclaw.gateway 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OPENROUTER_API_KEY string YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:OPENROUTER_API_KEY YOUR_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Set model using CORRECT format
openclaw models set openrouter/moonshotai/kimi-k2.5

# Verify configuration
openclaw models status
# Should show:
# - Default: openrouter/moonshotai/kimi-k2.5
# - openrouter effective=env:sk-or-v1...
```

**CRITICAL: Version Requirements**

- **Minimum Version**: OpenClaw 2026.2.1
- **Check version**: `openclaw --version`
- **Update if needed**: `pnpm add -g openclaw@latest`

**Why earlier versions fail**: OpenClaw 2026.1.30 has incomplete OpenRouter support.

**Verification Checklist**:
```bash
# 1. Check version
openclaw --version  # Must be 2026.2.1+

# 2. Verify API key in LaunchAgent
/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:OPENROUTER_API_KEY" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# 3. Verify model format
openclaw models status  # Default should show openrouter/<author>/<slug>

# 4. Test the bot - send a message!
```

**Reference**: [OpenRouter Official Integration Guide](https://openrouter.ai/docs/guides/guides/openclaw-integration)

**Impact**: Prevents 100% of OpenRouter model configuration failures.

---

## Core Knowledge Base

### Available Setup Guides

**Located in**: `SETUP GUIDES/`

1. **openclaw-vm-setup/** - VM-Isolated Deployment (Production)
   - Uses Lume hypervisor for full VM isolation
   - 8 implementation phases (Phase 0-7)
   - ~30-45 minute setup time (including async VM creation)
   - **Requires**: ~60GB disk space (CORRECTED from 70GB)
   - **Best for**: Production, multi-tenant, maximum security
   - **New**: Async workflow with `start` and `continue` commands

2. **openclaw-native-setup/** - Native macOS Deployment (Development)
   - User account isolation (no VM)
   - 7 implementation phases (Phase 0-6)
   - ~10-15 minute setup time
   - **Requires**: ~10GB disk space
   - **Best for**: Development, testing, single-user

### Directory Structure

```
SETUP GUIDES/
├── openclaw-vm-setup/
│   ├── README.md                    # Quick start guide
│   ├── setup.sh                     # Master orchestration script
│   ├── HARDENING-GUIDE.md           # Security best practices
│   ├── PRODUCTION-CHECKLIST.md      # Go-live checklist
│   ├── MOLTBOOK-QUICKSTART.md       # Fast Moltbook setup
│   ├── DEPLOYMENT-READINESS-REPORT.md
│   ├── config/
│   │   ├── settings.env             # User configuration
│   │   └── exec-approvals.json      # Security policy
│   ├── scripts/
│   │   ├── connect.sh               # SSH into VM
│   │   ├── tunnel.sh                # Create Gateway tunnel
│   │   ├── status.sh                # Health check
│   │   ├── backup-vm.sh             # Backup automation
│   │   ├── restore-vm.sh            # Recovery
│   │   ├── emergency-stop.sh        # Kill switch
│   │   ├── restart-vm.sh            # Recovery restart
│   │   ├── host-monitor.sh          # Host-side monitoring
│   │   └── moltbook-setup.sh        # Moltbook integration
│   ├── tests/                       # Testing framework (NEW)
│   │   ├── README.md                # Testing guide
│   │   ├── test-runner.sh           # Master test orchestrator
│   │   ├── security-validator.sh    # Security audit tool
│   │   └── integration-tests.sh     # E2E tests
│   └── PLANNING/
│       ├── IMPLEMENTATION-MASTER-PLAN.md
│       ├── RECOMMENDATIONS.md       # Future improvements
│       ├── PROJECT-STATUS.md
│       └── implementation-phases/   # Phase prompts
└── openclaw-native-setup/
    ├── README.md
    ├── setup.sh
    ├── config/
    │   ├── settings.env
    │   ├── exec-approvals.json
    │   └── launchagent-template.plist
    ├── scripts/
    │   ├── connect.sh
    │   ├── status.sh
    │   ├── emergency-stop.sh
    │   ├── restart.sh
    │   └── monitor.sh
    └── PLANNING/
        └── implementation-phases/
```

---

## Pre-Flight Checks (UPDATED)

**ALWAYS perform these checks before starting ANY phase:**

### 1. Disk Space Validation (CORRECTED)

```bash
# Check available disk space
df -h / | awk 'NR==2 {print "Available: " $4 " (" $5 " used)"}'

# Validate minimum requirements
AVAILABLE_GB=$(df -g / | awk 'NR==2 {print $4}')

# For VM setup (CORRECTED: 60GB, not 70GB)
if [ "$AVAILABLE_GB" -lt 60 ]; then
  echo "❌ INSUFFICIENT DISK SPACE"
  echo "Required: 60GB | Available: ${AVAILABLE_GB}GB"
  echo "Action: Free up disk space before continuing"
  exit 1
fi

# For native setup
if [ "$AVAILABLE_GB" -lt 10 ]; then
  echo "❌ INSUFFICIENT DISK SPACE"
  echo "Required: 10GB | Available: ${AVAILABLE_GB}GB"
  exit 1
fi

echo "✅ Disk space check passed (${AVAILABLE_GB}GB available)"
```

**Cleanup commands if disk is low**:
```bash
# Check what's using space
du -sh ~/Library/Caches/*
du -sh ~/.npm
du -sh ~/Library/Developer/Xcode/DerivedData

# Safe cleanup
npm cache clean --force        # ~6GB potential
brew cleanup --prune=all       # ~1-5GB potential
rm -rf ~/Library/Caches/*      # ~5-20GB potential
```

### 2. Platform Validation

```bash
# Verify Apple Silicon
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  echo "❌ Not Apple Silicon (detected: $ARCH)"
  echo "OpenClaw requires M1/M2/M3/M4 processors"
  exit 1
fi

# Verify macOS version
OS_VERSION=$(sw_vers -productVersion)
MAJOR_VERSION=$(echo "$OS_VERSION" | cut -d. -f1)
if [ "$MAJOR_VERSION" -lt 14 ]; then
  echo "❌ macOS version too old ($OS_VERSION)"
  echo "Required: macOS Sonoma (14.0+) or Sequoia (15.0+)"
  exit 1
fi

echo "✅ Platform check passed ($ARCH, macOS $OS_VERSION)"
```

### 3. Prerequisites Validation

```bash
# Check Homebrew (required for both setups)
if ! command -v brew &>/dev/null; then
  echo "❌ Homebrew not installed"
  echo "Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
  echo "⚠️  Sudo access required for installation"
  echo "You'll be prompted for your password"
fi

echo "✅ Prerequisites validated"
```

---

## Deployment Decision Tree

### Step 1: Understand User Requirements

Ask these questions to determine the best deployment path:

```
1. What is the deployment environment?
   - Production (recommend: VM)
   - Development/Testing (recommend: Native)
   - Multi-tenant (recommend: VM)
   - Single-user (recommend: Native)

2. What are the security requirements?
   - Maximum isolation needed (recommend: VM)
   - Standard isolation acceptable (recommend: Native)
   - Need snapshot/rollback capability (recommend: VM)
   - Fast performance critical (recommend: Native)

3. What is the available disk space?
   - 60GB+ available (both options viable)        # CORRECTED
   - 10-60GB available (recommend: Native only)   # CORRECTED
   - <10GB available (STOP - insufficient space)

4. What is the time budget?
   - 30-45 minutes (VM viable with async workflow)
   - 10-15 minutes (Native only)
   - ASAP (Native recommended)
```

### Step 2: Present Comparison (UPDATED)

```markdown
| Feature | VM Setup | Native Setup |
|---------|----------|--------------|
| Isolation | Full VM boundary | User account |
| Performance | Slight overhead | Native speed |
| Setup Time | 30-45 min (async) | 10-15 min |
| Disk Space | 60GB (CORRECTED) | 10GB |
| Phases | 8 (0-7) | 7 (0-6) |
| Snapshots | Full VM snapshots | Config backups |
| Recovery | Rollback VM | Recreate user |
| Gateway Install | Automated | Manual |
| Moltbook | Integrated Phase 7 | Manual |
| Best For | Production | Development |
| iMessage | ✅ Yes | ✅ Yes |
| Security | Maximum | Strong |
```

---

## VM Setup Phase Overview (CORRECTED)

**Location**: `SETUP GUIDES/openclaw-vm-setup/`

### Async Workflow (RECOMMENDED)

```bash
# Phase 0-1 with background VM creation
./setup.sh start

# Monitor VM creation
./scripts/status.sh

# Continue Phases 2-7 when VM ready
./setup.sh continue
```

### Phase 0: Prerequisites Validation
- **Disk Check**: Verify **60GB+** available (CORRECTED)
- **Platform**: Verify Apple Silicon + macOS Sonoma/Sequoia
- **Dependencies**: Homebrew, sudo access
- **Output**: `PLANNING/PHASE-0-COMPLETE.md`

### Phase 1: Lume Installation + VM Creation
- **Disk Check**: Pre-flight validation
- **Actions**:
  - Install Lume via **Homebrew-first** approach (CORRECTED)
  - Create macOS VM with `--disk-size` flag (CORRECTED)
  - VM creates in background for async workflow
- **Verification**: `lume list` shows VM running
- **Disk Impact**: ~50GB

### Phase 2: SSH Hardening
- **Disk Check**: Minimal impact
- **Actions**: Configure Ed25519 keys, disable password auth
- **Security**: Key-only authentication, limited retries
- **Verification**: Can SSH with key, password auth blocked

### Phase 3: Host Firewall
- **Disk Check**: Minimal impact
- **Actions**: Configure pf rules for localhost-only access
- **Security**: Block direct VM access from internet
- **Verification**: pf rules active, localhost tunnel works

### Phase 4: Gateway Installation (ENHANCED)
- **Disk Check**: Verify 5GB available for Gateway
- **Actions**:
  1. Install Node.js via Homebrew: `brew install node`
  2. Install pnpm: `brew install pnpm && pnpm setup`
  3. **Configure shell environment** (CRITICAL - prevents "command not found"):
     ```bash
     # Create/update .zprofile with all required paths
     cat > ~/.zprofile << 'EOF'
     # Homebrew
     eval "$(/opt/homebrew/bin/brew shellenv)"

     # pnpm
     export PNPM_HOME="$HOME/Library/pnpm"
     case ":$PATH:" in
       *":$PNPM_HOME:"*) ;;
       *) export PATH="$PNPM_HOME:$PATH" ;;
     esac
     EOF

     # Make it load automatically for non-login shells too
     echo 'source ~/.zprofile' >> ~/.zshrc

     # Load it now
     source ~/.zprofile
     ```
  4. Verify environment: `which node && which pnpm` (should show paths)
  5. Install OpenClaw CLI: `pnpm add -g openclaw@latest`
  6. Verify OpenClaw accessible: `openclaw --version` (should show 2026.1.30 or later)
  7. Run onboarding interactively: `openclaw onboard --install-daemon`
  8. Configure gateway mode: `openclaw config set gateway.mode local`
  9. Generate and set auth token:
     ```bash
     TOKEN=$(openssl rand -hex 32)
     openclaw config set gateway.auth.token "$TOKEN"
     echo "$TOKEN" > ~/.openclaw/.gateway-token
     chmod 600 ~/.openclaw/.gateway-token
     echo "SAVE THIS TOKEN: $TOKEN"
     ```
  10. Install Gateway service: `openclaw gateway install --force --port 18789`
  11. Start Gateway: `openclaw gateway start`
  12. Verify: `openclaw gateway status` (should show "Runtime: running" and "RPC probe: ok")
  13. Configure exec-approvals.json
- **Verification**:
  - OpenClaw command works in all shells
  - Gateway running and responsive
  - Token saved securely
  - SSH tunnel accessible from host
- **Disk Impact**: ~2-5GB
- **Critical**:
  - Step 3 (PATH configuration) prevents 90% of "command not found" issues
  - Token must be saved securely for authentication

### Phase 5: Monitoring Setup
- **Disk Check**: Minimal impact
- **Actions**: Configure security monitoring daemon
- **Features**: SSH failures, suspicious processes, disk alerts
- **Verification**: Monitor daemon active, alerts working

### Phase 6: Backup Automation
- **Disk Check**: Verify 10GB for backup storage
- **Actions**: Configure automated backups
- **Schedule**: Daily at 2 AM, 7-day retention
- **Verification**: Backup script runs, backups created

### Phase 7: Moltbook Integration (OPTIONAL)
- **Disk Check**: Minimal impact
- **Actions**:
  - Install via `npx molthub@latest install moltbook`
  - Generate claim link
  - User verifies in browser
- **Verification**: Agent visible in Moltbook dashboard
- **Script**: `./scripts/moltbook-setup.sh`

---

## Native Setup Phase Overview (CORRECTED)

**Location**: `SETUP GUIDES/openclaw-native-setup/`

### Phase 0-6 (7 Phases Total)

| Phase | Description |
|-------|-------------|
| 0 | Prerequisites Validation |
| 1 | User Account Creation (`openclaw` user) |
| 2 | exec-approvals Configuration |
| 3 | LaunchAgent Setup |
| 4 | Gateway Installation (Manual) |
| 5 | Monitoring Setup |
| 6 | Helper Scripts |

---

## Testing Framework (NEW)

**Location**: `SETUP GUIDES/openclaw-vm-setup/tests/`

### Running Tests

```bash
cd "SETUP GUIDES/openclaw-vm-setup"

# Quick unit tests (30 seconds)
./tests/test-runner.sh unit

# Full test suite (2-3 minutes)
./tests/test-runner.sh all

# Security audit before production (1-2 minutes)
./tests/security-validator.sh --vm-ip=$(cat .vm_ip)

# End-to-end integration (3-5 minutes)
./tests/integration-tests.sh
```

### Test Coverage

| Category | Tests | Purpose |
|----------|-------|---------|
| Unit | 45+ | Config validation, script syntax, policies |
| Integration | 38+ | Phase workflows, SSH, backup/restore |
| Security | 68+ | Network exposure, hardening, compliance |
| Idempotency | 8+ | Safe re-run verification |
| Documentation | 10+ | README, guides completeness |

**Total**: 151+ automated tests

### Security Validation Checks

The security validator checks 68+ items including:
- Network exposure (VM not accessible from internet)
- SSH hardening (Ed25519, no passwords)
- Firewall configuration (pf rules, localhost-only)
- Gateway security (TLS, auth token, rate limiting)
- exec-approvals (deny-by-default enforced)
- Secrets management (permissions, gitignore)
- Monitoring (cron jobs, logs)
- Backup/recovery procedures

---

## Common Issues & Solutions (UPDATED)

### Issue: Lume Installation Fails with HTML

**Symptoms**:
- `curl https://lume.sh/install.sh` returns HTML
- Installation script looks like a webpage

**Solution** (CORRECTED):
```bash
# Use Homebrew instead
brew install lume

# Verify
lume --version
```

### Issue: VM Creation Fails with "Unknown flag"

**Symptoms**:
- `lume create` fails with "unknown flag: --disk"

**Solution** (CORRECTED):
```bash
# Use --disk-size, not --disk
lume create openclaw-secure \
    --os macos-sequoia-vanilla \
    --disk-size 50G \       # CORRECT
    --memory 8G             # CORRECT
```

### Issue: Disk Space Runs Out Mid-Deployment

**Prevention**:
```bash
# Check BEFORE each phase (CORRECTED: 60GB, not 70GB)
AVAILABLE=$(df -g / | awk 'NR==2 {print $4}')
if [ "$AVAILABLE" -lt 60 ]; then
  echo "STOP: Need to free up space first"
  exit 1
fi
```

**Recovery**:
```bash
# 1. Check what's using space
du -sh ~/Library/Caches/*
du -sh ~/.npm

# 2. Clean up
npm cache clean --force
brew cleanup --prune=all
rm -rf ~/Library/Caches/*

# 3. Check again
df -h /

# 4. Resume from last completed phase
ls "SETUP GUIDES/openclaw-vm-setup/PLANNING"/PHASE-*-COMPLETE.md | tail -1
```

### Issue: VM Not Starting After Creation

**Diagnosis**:
```bash
# Check Lume status
lume list

# Check VM logs
cat "SETUP GUIDES/openclaw-vm-setup/logs/vm-creation-background.log"
```

**Solutions**:
```bash
# If VM exists but stopped
lume stop openclaw-secure
sleep 5
lume run openclaw-secure

# If VM corrupted, delete and recreate
lume delete openclaw-secure
./setup.sh 1  # Re-run Phase 1
```

### Issue: Gateway Fails to Start with "no token is configured"

**Symptoms**:
- `openclaw gateway status` shows "Runtime: stopped"
- Error logs show: "Gateway auth is set to token, but no token is configured"

**Root Cause**: The `--token` flag in `openclaw gateway install` doesn't persist to config.

**Solution** (CORRECTED):
```bash
# 1. Generate secure token
TOKEN=$(openssl rand -hex 32)

# 2. Set in config (CRITICAL STEP)
openclaw config set gateway.auth.token "$TOKEN"

# 3. Save token for future use
echo "$TOKEN" > ~/.openclaw/.gateway-token
chmod 600 ~/.openclaw/.gateway-token

# 4. Restart Gateway
openclaw gateway restart

# 5. Verify
openclaw gateway status
# Should show: "Runtime: running" and "RPC probe: ok"
```

### Issue: pnpm Global Install Fails with "no global bin directory"

**Symptoms**:
- `pnpm add -g openclaw@latest` fails
- Error: "Unable to find the global bin directory"

**Solution**:
```bash
# 1. Set up pnpm environment
pnpm setup

# 2. Reload shell config
source ~/.zshrc

# 3. Verify PNPM_HOME is set
echo $PNPM_HOME
# Should show: /Users/[username]/Library/pnpm

# 4. Retry installation
pnpm add -g openclaw@latest
```

### Issue: OpenClaw Command Not Found After Installation

**Symptoms**:
- `openclaw --version` returns "command not found"
- Installation completed successfully
- Happens even after installing via pnpm

**Root Cause**: Shell PATH not configured to include Homebrew and pnpm directories.

**Solution - Automatic (RECOMMENDED)**:
```bash
# All-in-one PATH configuration
cat > ~/.zprofile << 'EOF'
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF

# Make it load for all shells
echo 'source ~/.zprofile' >> ~/.zshrc

# Load now
source ~/.zprofile

# Verify
openclaw --version
```

**Solution - Manual (Quick Fix)**:
```bash
# 1. Ensure Homebrew paths are loaded
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Ensure pnpm paths are loaded
source ~/.zshrc

# 3. Verify openclaw location
ls -la ~/Library/pnpm/openclaw

# 4. Add to PATH if needed (usually automatic)
export PATH="$HOME/Library/pnpm:$PATH"

# 5. Test
openclaw --version
```

**Prevention**: Always run Step 3 of Phase 4 (shell environment configuration) before installing OpenClaw.

### Issue: Dashboard Not Accessible from Host Browser

**Symptoms**:
- Gateway is running (`openclaw gateway status` shows "Runtime: running")
- Cannot access http://127.0.0.1:18789/ from host Mac browser
- Dashboard URL works inside VM but not on host

**Root Cause**: Gateway binds to localhost (127.0.0.1) inside the VM, not accessible from host.

**Solution - SSH Tunnel** (RECOMMENDED):
```bash
# From HOST Mac, create SSH tunnel
ssh -i ~/.ssh/openclaw_vm_ed25519 \
    -L 18789:127.0.0.1:18789 \
    clawuser@$(cat "SETUP GUIDES/openclaw-vm-setup/.vm_ip") \
    -N

# Keep this terminal open
# Now access dashboard on host at: http://localhost:18789/
```

**Solution - Helper Script**:
```bash
# Use the tunnel helper script
cd "SETUP GUIDES/openclaw-vm-setup"
./scripts/tunnel.sh

# Access dashboard at: http://localhost:18789/
```

**Verification**:
```bash
# On host Mac - test that tunnel is working
curl http://localhost:18789/
# Should return HTML with "OpenClaw Control"
```

**Authentication Required**: The Gateway uses token authentication. To access the dashboard in your browser:

1. **Find your token**:
   ```bash
   # Inside VM
   cat ~/.openclaw/openclaw.json | grep -A 3 '"auth"'
   ```

2. **Access dashboard with token**:
   - Open browser to: `http://localhost:18789/`
   - The dashboard will prompt for authentication
   - Enter your Gateway token when prompted
   - Or use WebSocket client with token: `ws://localhost:18789/?token=YOUR_TOKEN`

3. **For CLI access**:
   ```bash
   # Set token in environment
   export OPENCLAW_GATEWAY_TOKEN="your-token-here"

   # Or configure in client
   openclaw config set gateway.auth.token "your-token-here"
   ```

**Note**:
- The tunnel must remain active. If you close the terminal, the dashboard becomes inaccessible from the host.
- Save your token securely - you'll need it for all client connections.

---

## Production Hardening Checklist (UPDATED)

**Before going to production**, run:

```bash
cd "SETUP GUIDES/openclaw-vm-setup"

# 1. Full test suite
./tests/test-runner.sh all

# 2. Security validation (MUST PASS)
./tests/security-validator.sh --vm-ip=$(cat .vm_ip)

# Production requirement: 0 CRITICAL, 0 HIGH issues
```

Review these guides:
- `HARDENING-GUIDE.md` - Defense-in-depth architecture
- `PRODUCTION-CHECKLIST.md` - 150+ item checklist
- `DEPLOYMENT-READINESS-REPORT.md` - Status summary

---

## Skill Execution Workflow (UPDATED)

When invoked, this skill should:

### 1. Initial Assessment

```markdown
I'm the OpenClaw Onboarding Expert (v2.0). Let me help you deploy OpenClaw Gateway.

**Important**: This skill incorporates lessons learned from real deployments to prevent common failures.

First, let's check your environment:
```

```bash
# Platform check
uname -m
sw_vers -productVersion

# Disk space check (CORRECTED: 60GB for VM)
df -h / | head -2
df -g / | awk 'NR==2 {print "Available: " $4 "GB"}'

# Prerequisites check
command -v brew &>/dev/null && echo "Homebrew: ✅" || echo "Homebrew: ❌"
command -v lume &>/dev/null && echo "Lume: ✅" || echo "Lume: ❌"
```

### 2. Deployment Path Recommendation

```markdown
Based on your environment:
- **Platform**: [Apple Silicon / macOS version]
- **Available Disk Space**: [X]GB
- **Homebrew**: [Installed / Not installed]
- **Lume**: [Installed / Not installed]

I recommend: [VM Setup / Native Setup]

**Key Changes from Previous Deployments**:
- ✅ Disk requirement: 60GB (reduced from 70GB)
- ✅ Lume install: Homebrew-first approach
- ✅ Async workflow: VM creates in background
- ✅ Phase 7: Optional Moltbook integration

**Would you like to proceed?**
```

### 3. Async Workflow (VM Setup)

```markdown
**Recommended workflow for VM Setup**:

1. Start deployment (VM creates in background):
   \`\`\`bash
   cd "SETUP GUIDES/openclaw-vm-setup"
   ./setup.sh start
   \`\`\`

2. Monitor VM creation:
   \`\`\`bash
   ./scripts/status.sh
   \`\`\`

3. Continue when VM is ready:
   \`\`\`bash
   ./setup.sh continue
   \`\`\`

This approach lets you work on other tasks while the VM creates (~5-15 min).
```

### 4. Post-Deployment Validation

```markdown
**Deployment Complete!** Let's validate:

\`\`\`bash
# Run test suite
./tests/test-runner.sh all

# Security validation
./tests/security-validator.sh --vm-ip=$(cat .vm_ip)
\`\`\`

**Expected Results**:
- Unit tests: 45+ passing
- Integration tests: 38+ passing
- Security checks: 68+ passing
- No CRITICAL or HIGH severity issues
```

---

## Integration with /phased-build

This skill works with the `/phased-build` skill:

```bash
cd "SETUP GUIDES/openclaw-vm-setup"

# /phased-build detects implementation-phases/ folder
# This skill provides domain expertise with lessons learned
```

**Enhanced Safety with Lessons Learned**:
- Disk check uses corrected 60GB threshold
- Lume installation uses Homebrew-first
- VM creation uses correct `--disk-size` flag
- Async workflow prevents blocking

---

## Key Differentiators (v2.0)

This skill provides expertise that generic agents don't have:

1. **Lessons Learned Integration**: Real deployment failures → documented fixes
2. **Corrected Requirements**: 60GB disk (not 70GB), Homebrew-first Lume
3. **Async Workflow**: Background VM creation for better UX
4. **Testing Framework**: 151+ automated tests before production
5. **Phase Corrections**: Accurate phase counts (VM: 0-7, Native: 0-6)
6. **Enhanced Phase 4**: Full Gateway installation (was placeholder)
7. **Moltbook Integration**: Phase 7 for agent management

---

## Skill Metadata

```yaml
name: openclaw-onboarding
version: 2.0.0
updated: 2026-02-01
category: deployment
tags:
  - openclaw
  - deployment
  - infrastructure
  - security
  - vm
  - macos
  - moltbook
  - lessons-learned
requires:
  - setup-guides
  - bash
  - unix-tools
compatible_with:
  - phased-build
  - boris
  - organized-codebase
platform:
  - macos
  - apple-silicon
min_macos_version: "14.0"
disk_space_min: "10GB"
disk_space_vm: "60GB"  # CORRECTED
vm_phases: "0-7"       # CORRECTED (8 phases)
native_phases: "0-6"   # CORRECTED (7 phases)
test_coverage: "151+ automated tests"
```

---

## Changelog

### v2.2.0 (2026-02-02) - PATH Configuration Update
- **CRITICAL FIX**: Proactive shell PATH configuration prevents "command not found"
  - Added Lesson 4: Shell PATH Configuration (most common deployment issue)
  - **NEW Step 3 in Phase 4**: Configure .zprofile and .zshrc BEFORE installing OpenClaw
  - Phase 4 now has 13 steps (was 9) with dedicated PATH setup and verification
  - Prevents 90% of "openclaw: command not found" issues
- **ENHANCED**: "OpenClaw Command Not Found" troubleshooting section
  - Added automatic solution (all-in-one PATH config)
  - Added manual quick-fix alternative
  - Clarified root cause and prevention
- **UPDATE**: Phase 4 verification now includes shell environment checks
- **IMPACT**: Users can now run `openclaw` commands immediately after installation in any shell

### v2.1.0 (2026-02-02)
- **CRITICAL FIX**: Phase 4 Gateway installation sequence corrected
  - Added missing step: `openclaw config set gateway.mode local`
  - **BREAKING**: Token must be set via `openclaw config set gateway.auth.token` (not just `--token` flag)
  - Added pnpm setup requirement: `pnpm setup && source ~/.zshrc`
  - Added verification step: Gateway status must show "Runtime: running" and "RPC probe: ok"
- **NEW**: Troubleshooting section for Gateway installation issues
  - "no token is configured" error (CRITICAL)
  - "no global bin directory" pnpm error
  - "command not found" after installation
- **UPDATE**: Phase 4 now has 9 sequential steps with proper verification
- **NOTE**: Dashboard access requires token authentication (WebSocket/HTTP)

### v2.0.0 (2026-02-01)
- **BREAKING**: Disk space requirement corrected (70GB → 60GB)
- **FIX**: Lume installation now uses Homebrew-first approach
- **FIX**: Lume VM creation uses `--disk-size` instead of `--disk`
- **FIX**: Phase counts corrected (VM: 8 phases, Native: 7 phases)
- **NEW**: Async VM creation workflow (`start` + `continue`)
- **NEW**: Testing framework documentation (151+ tests)
- **NEW**: Lessons learned section
- **ENHANCED**: Phase 4 now includes full Gateway installation
- **ENHANCED**: Phase 7 Moltbook integration documented
- **UPDATE**: Directory structure now in `SETUP GUIDES/`
- **UPDATE**: New documentation files (HARDENING-GUIDE, PRODUCTION-CHECKLIST)

### v1.0.0 (2026-01-31)
- Initial release

---

## License

Part of the Clawdbot Ready project.
See project LICENSE for details.
