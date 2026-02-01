# Phase: Host User Creation (Optional)

**Safety Level:** 🟡 Review (modifies host system - creates user account)
**Estimated Tasks:** 4
**Dependencies:** None (can run before any other phase)

---

## Overview

This optional phase creates a dedicated macOS user account on the HOST machine for VM access. This is recommended for:

- **Isolation**: Keep VM operations separate from admin account
- **Multi-user access**: Allow team members to access VM without sharing admin credentials
- **Security**: Limit the attack surface if the VM is compromised
- **Screen Sharing**: Dedicated user for remote VM management

---

## Pre-Execution Safety Check

Before running this phase, verify:

- [ ] You are on the Mac host machine (not inside a VM)
- [ ] You have admin/sudo access
- [ ] You want a dedicated user account for VM management
- [ ] You have chosen a secure password for the new user

**This phase CREATES a new macOS user account. Requires sudo.**

---

## Context Files to Read First

```
READ: config/settings.env  (HOST_USER_* settings)
READ: setup.sh             (phase_create_host_user function)
```

---

## Configuration

### Option 1: Unified Naming (Recommended)

Set `INSTANCE_NAME` in `config/settings.env` to automatically configure all names:

```bash
# Unified naming - one name for everything
INSTANCE_NAME="clawbot1"
HOST_USER_PASSWORD="secure-password"  # Still need to set the password

# This automatically sets:
#   HOST_USER_NAME="clawbot1"
#   HOST_USER_FULLNAME="Clawbot1 Operator"
#   VM_NAME="clawbot1-vm"
#   VM_USER="clawbot1"
#   SSH key: ~/.ssh/openclaw_clawbot1_ed25519
```

### Option 2: Individual Configuration

Set each value separately in `config/settings.env`:

```bash
# Host User Configuration
HOST_USER_NAME="vmoperator"           # Username (lowercase, no spaces)
HOST_USER_FULLNAME="VM Operator"      # Display name
HOST_USER_PASSWORD="secure-password"  # Account password (required)
HOST_USER_ADMIN="false"               # "true" for admin, "false" for standard
HOST_USER_AUTOLOGIN="false"           # Enable auto-login (less secure)
HOST_USER_SHELL="/bin/zsh"            # Shell (default: zsh)
```

---

## Tasks

### Task 1: Verify No Existing User

```bash
# Check if user already exists
USERNAME="vmoperator"  # Change to your desired username

if dscl . -read /Users/"$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists:"
    dscl . -read /Users/"$USERNAME" RealName UniqueID PrimaryGroupID
else
    echo "User '$USERNAME' does not exist - ready to create"
fi
```

**Expected Output:** User does not exist, or confirmation to use existing

---

### Task 2: Create User Account

Run via setup.sh (recommended):
```bash
cd openclaw-vm-setup
./setup.sh create-user
```

Or use the standalone script:
```bash
cd openclaw-vm-setup/scripts
./create-user.sh vmoperator "VM Operator"
```

Or create manually with sysadminctl:
```bash
# Create standard user (non-admin)
sudo sysadminctl -addUser vmoperator \
    -fullName "VM Operator" \
    -password "your-secure-password" \
    -shell /bin/zsh

# Or create admin user
sudo sysadminctl -addUser vmoperator \
    -fullName "VM Operator" \
    -password "your-secure-password" \
    -shell /bin/zsh \
    -admin
```

**Expected Output:** User created successfully

---

### Task 3: Enable Screen Sharing Access

Screen Sharing allows the new user to access the VM display remotely.

```bash
# Enable Screen Sharing service (if not already enabled)
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

# Add user to screen sharing access group (for non-admin users)
USERNAME="vmoperator"
if dscl . -read /Groups/com.apple.access_screensharing &>/dev/null; then
    sudo dscl . -append /Groups/com.apple.access_screensharing GroupMembership "$USERNAME"
    echo "User added to screen sharing access group"
fi

# Verify Screen Sharing is running
if sudo launchctl list | grep -q screensharing; then
    echo "Screen Sharing service is running"
else
    echo "Warning: Screen Sharing may not be enabled"
fi
```

**Alternative: Enable via System Settings**
1. System Settings → General → Sharing
2. Enable "Screen Sharing"
3. Click "Allow access for: Only these users"
4. Add the new user

---

### Task 4: Verify User Creation

```bash
USERNAME="vmoperator"

echo "=== User Verification ==="

# Check user exists
if dscl . -read /Users/"$USERNAME" &>/dev/null; then
    echo "User exists"

    # Show details
    echo ""
    echo "User Details:"
    dscl . -read /Users/"$USERNAME" RealName UniqueID PrimaryGroupID NFSHomeDirectory UserShell

    # Check admin status
    echo ""
    if dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -qw "$USERNAME"; then
        echo "Admin: Yes"
    else
        echo "Admin: No (standard user)"
    fi

    # Check home directory
    HOME_DIR=$(dscl . -read /Users/"$USERNAME" NFSHomeDirectory | awk '{print $2}')
    if [[ -d "$HOME_DIR" ]]; then
        echo "Home directory exists: $HOME_DIR"
    else
        echo "Warning: Home directory not found"
    fi
else
    echo "ERROR: User does not exist"
fi
```

---

## Rollback Procedure

To delete the created user if needed:

```bash
USERNAME="vmoperator"

# Delete user (keep home folder)
sudo sysadminctl -deleteUser "$USERNAME"

# Or delete user AND home folder
sudo sysadminctl -deleteUser "$USERNAME" -deleteHomeDir

# Verify deletion
if ! dscl . -read /Users/"$USERNAME" &>/dev/null; then
    echo "User deleted successfully"
fi
```

**Warning:** Deleting a user is permanent. Backup any important data first.

---

## Success Criteria

- [ ] New user account exists
- [ ] User can log in to the Mac
- [ ] Screen Sharing access is configured
- [ ] Home directory was created
- [ ] Password is set and working

---

## Post-Phase Workflow

After creating the host user:

1. **Log out** of current admin session (Apple menu → Log Out)

2. **Log in** as the new user (e.g., "vmoperator")

3. **Run VM setup** from the new user account:
   ```bash
   cd /path/to/openclaw-vm-setup
   ./setup.sh start
   ```

4. **Access VM** via Screen Sharing once created:
   - Finder → Go → Connect to Server (Cmd+K)
   - Enter: `vnc://<VM-IP-ADDRESS>`
   - Or from Terminal: `open vnc://<VM-IP-ADDRESS>`

---

## Security Considerations

### Standard User vs Admin

**Standard User (Recommended):**
- Cannot install system-wide software
- Cannot modify system settings
- Limited blast radius if compromised
- Sufficient for VM management

**Admin User:**
- Can install Homebrew and other tools
- Can modify system settings
- Higher risk if compromised
- Only use if necessary

### Password Security

- Use a strong, unique password (12+ characters)
- Consider using a password manager
- Don't reuse passwords from other accounts
- Store password securely (not in plain text files)

### Auto-Login Warning

If `HOST_USER_AUTOLOGIN="true"`:
- Anyone with physical access can use the account
- Password is stored in recoverable format
- Only use for physically secured machines
- Not recommended for shared environments

---

## Troubleshooting

### "Operation not permitted" Error

```bash
# Check System Integrity Protection status
csrutil status

# If SIP is enabled (normal), ensure you're running with sudo
sudo sysadminctl -addUser ...
```

### User Created But Can't Login

```bash
# Verify password is set
sudo dscl . -passwd /Users/vmoperator "new-password"

# Check account is not disabled
sudo pwpolicy -u vmoperator -getpolicy
```

### Home Directory Issues

```bash
# Manually create home directory
sudo createhomedir -c -u vmoperator

# Or manually:
sudo mkdir -p /Users/vmoperator
sudo chown vmoperator:staff /Users/vmoperator
sudo chmod 755 /Users/vmoperator
```

### Screen Sharing Not Working

1. Verify service is running:
   ```bash
   sudo launchctl list | grep screensharing
   ```

2. Check firewall allows VNC (port 5900):
   ```bash
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
   ```

3. Enable via System Settings if launchctl fails

---

## Next Phase

After logging in as the new user:

```
"Run ./setup.sh start to begin VM creation"
"Then ./setup.sh continue when VM is ready"
```

Or if staying on admin account:
```
"Read PLANNING/implementation-phases/PHASE-0-PROMPT.md and execute"
```
