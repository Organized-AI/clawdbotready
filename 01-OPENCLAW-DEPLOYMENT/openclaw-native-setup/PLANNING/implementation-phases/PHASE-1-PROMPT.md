# Phase 1: User Account Creation

## Objective
Create a dedicated `openclaw` user account with minimal privileges for running the Gateway in isolation.

## Implementation

### 1. Generate Secure Password
```bash
# Generate 24-character random password
PASSWORD=$(openssl rand -base64 24)

# Save to secure location (admin access only)
echo "$PASSWORD" > backups/.openclaw-password-$(date +%Y%m%d_%H%M%S).txt
chmod 600 backups/.openclaw-password-*.txt
```

### 2. Create User Account
```bash
# Create user
sudo dscl . -create /Users/openclaw
sudo dscl . -create /Users/openclaw UserShell /bin/bash
sudo dscl . -create /Users/openclaw RealName "OpenClaw Gateway"
sudo dscl . -create /Users/openclaw UniqueID "502"
sudo dscl . -create /Users/openclaw PrimaryGroupID 20
sudo dscl . -create /Users/openclaw NFSHomeDirectory /Users/openclaw

# Set password
sudo dscl . -passwd /Users/openclaw "$PASSWORD"
```

### 3. Create Home Directory Structure
```bash
# Create directories
sudo mkdir -p /Users/openclaw
sudo mkdir -p /Users/openclaw/.openclaw/gateway
sudo mkdir -p /Users/openclaw/.openclaw/data
sudo mkdir -p /Users/openclaw/.openclaw/logs
sudo mkdir -p /Users/openclaw/Library/LaunchAgents

# Set ownership
sudo chown -R openclaw:staff /Users/openclaw

# Set restrictive permissions
sudo chmod 700 /Users/openclaw
sudo chmod 700 /Users/openclaw/.openclaw
sudo chmod 700 /Users/openclaw/.openclaw/gateway
sudo chmod 700 /Users/openclaw/.openclaw/data
sudo chmod 700 /Users/openclaw/.openclaw/logs
```

## Security Rationale

- **Separate User**: Isolates Gateway from host system
- **Minimal Privileges**: Standard user, no admin rights
- **Restrictive Permissions**: 700 prevents access by other users
- **Secure Password**: 24-character random password stored securely

## Verification

```bash
# Verify user exists
id openclaw
# Output: uid=502(openclaw) gid=20(staff) groups=20(staff)

# Check home directory
ls -la /Users/openclaw
# Should show openclaw:staff ownership, 700 permissions

# Verify directory structure
tree /Users/openclaw/.openclaw
```

## Rollback Procedure

```bash
# Delete user account
sudo dscl . -delete /Users/openclaw

# Remove home directory
sudo rm -rf /Users/openclaw

# Remove password file
rm backups/.openclaw-password-*.txt
```

## Next Phase
Phase 2: exec-approvals Configuration
