# Phase 0: Prerequisites Validation

## Objective
Validate all system requirements before beginning OpenClaw native macOS deployment.

## Prerequisites

### Hardware
- Apple Silicon Mac (M1/M2/M3/M4)
- Minimum 10GB available disk space
- Internet connection for downloads

### Software
- macOS Sequoia (14.0+) or later
- Homebrew package manager
- Node.js (recommended, may be required by Gateway)
- Admin account with sudo access

## Validation Steps

### 1. Operating System Check
```bash
# Verify macOS
uname -s  # Should output: Darwin

# Check macOS version
sw_vers -productVersion  # Should be 14.0 or higher

# Verify Apple Silicon
uname -m  # Should output: arm64
```

### 2. Privilege Check
```bash
# Verify not running as root
whoami  # Should NOT be "root"

# Test sudo access
sudo -v  # Should prompt for password and succeed
```

### 3. Disk Space Check
```bash
# Check available space
df -h /  # Should show >10GB available
```

### 4. Dependency Check
```bash
# Homebrew
which brew  # Should show path to brew

# Node.js (optional but recommended)
which node  # Should show path to node
node --version  # Check version
```

### 5. User Conflict Check
```bash
# Verify openclaw user doesn't exist
id openclaw  # Should fail with "no such user"

# Check UID availability
dscl . -list /Users UniqueID | grep "502"  # Should be empty
```

## Expected Outcomes

- ✅ macOS Sequoia+ on Apple Silicon confirmed
- ✅ Sudo access verified
- ✅ Sufficient disk space available
- ✅ Homebrew installed
- ✅ No UID conflicts
- ✅ Log directory created
- ✅ Configuration file validated

## Rollback Procedure
If prerequisites fail, no changes have been made to the system. Simply:
1. Install missing dependencies (Homebrew, Node.js)
2. Free up disk space if needed
3. Resolve UID conflicts by choosing a different UID in `config/settings.env`

## Next Phase
Phase 1: User Account Creation
