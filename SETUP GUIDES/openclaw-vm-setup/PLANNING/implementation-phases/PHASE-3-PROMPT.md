# Phase 3: SSH Hardening

**Safety Level:** 🟡 Review (modifies VM SSH config, generates keys on host)
**Estimated Tasks:** 5
**Dependencies:** Phase 2 complete

---

## Pre-Execution Safety Check

This phase will:
1. **On HOST:** Generate Ed25519 SSH key pair
2. **On HOST:** Copy public key to VM
3. **On VM:** Harden SSH configuration
4. **On VM:** Disable password authentication

**What this changes:**
- Creates `~/.ssh/openclaw_vm_ed25519` on your host
- Modifies `/etc/ssh/sshd_config` in the VM
- After this, you can ONLY access VM via SSH key

⚠️ **IMPORTANT:** Keep the VM console window open until you verify key auth works!

Before proceeding, verify:
- [ ] Phase 2 (VM Creation) is complete
- [ ] VM is running and accessible
- [ ] You have the VM user password ready

---

## Context Files to Read First

```
READ: .vm_ip (VM IP address)
READ: config/settings.env (VM user name)
READ: PLANNING/PHASE-2-COMPLETE.md (verify Phase 2 done)
```

---

## Tasks

### Task 1: Generate SSH Key Pair (Host)

```bash
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== SSH Key Generation ==="
echo ""

if [[ -f "$KEY_PATH" ]]; then
    echo "SSH key already exists: $KEY_PATH"
    echo ""
    echo "Public key:"
    cat "${KEY_PATH}.pub"
    echo ""
    echo "Using existing key."
else
    echo "Generating Ed25519 SSH key..."
    echo ""

    # Generate key with strong parameters
    ssh-keygen -t ed25519 -a 100 -f "$KEY_PATH" -C "openclaw-vm-access-$(date +%Y%m%d)" -N ""

    # Set secure permissions
    chmod 600 "$KEY_PATH"
    chmod 644 "${KEY_PATH}.pub"

    echo ""
    echo "✅ SSH key generated"
    echo ""
    echo "Private key: $KEY_PATH"
    echo "Public key: ${KEY_PATH}.pub"
    echo ""
    echo "Public key contents:"
    cat "${KEY_PATH}.pub"
fi
```

---

### Task 2: Copy Public Key to VM

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519.pub"

echo "=== Copying SSH Key to VM ==="
echo ""

if [[ -z "$VM_IP" ]]; then
    echo "❌ Error: VM IP not found. Run Phase 2 first."
    exit 1
fi

echo "Target: ${VM_USER}@${VM_IP}"
echo ""
echo "You will be prompted for the VM user's password."
echo ""

# Copy the public key
ssh-copy-id -i "$KEY_PATH" "${VM_USER}@${VM_IP}"

echo ""
echo "Key copied. Testing key-based authentication..."
```

---

### Task 3: Verify Key Authentication

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Testing Key Authentication ==="
echo ""

# Test SSH with key only (no password)
if ssh -i "$KEY_PATH" -o PasswordAuthentication=no -o ConnectTimeout=10 \
    "${VM_USER}@${VM_IP}" "echo 'SSH key authentication successful'" 2>/dev/null; then
    echo ""
    echo "✅ Key authentication works!"
else
    echo ""
    echo "❌ Key authentication failed"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify key was copied: ssh-copy-id -i ${KEY_PATH}.pub ${VM_USER}@${VM_IP}"
    echo "  2. Check VM ~/.ssh/authorized_keys"
    echo "  3. Ensure SSH service is running in VM"
    exit 1
fi
```

---

### Task 4: Harden SSH Configuration (VM)

⚠️ **SAFETY REVIEW**

This will modify the VM's SSH configuration to:
- Disable password authentication
- Allow only Ed25519 keys
- Limit authentication attempts
- Disable unnecessary features

**Review the configuration below before proceeding:**

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== SSH Hardening Configuration ==="
echo ""
echo "The following configuration will be applied to the VM:"
echo ""

# Show the config we'll apply
cat << 'CONFIG_PREVIEW'
# OpenClaw Hardened SSH Configuration

PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
PermitRootLogin no
PubkeyAuthentication yes

HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com,ssh-ed25519

MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2

X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no

LogLevel VERBOSE
AllowUsers [VM_USER]
CONFIG_PREVIEW

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Applying SSH hardening to VM..."
echo "═══════════════════════════════════════════════════════════════"

# Apply the configuration
ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << REMOTE_SCRIPT
# Backup original config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.\$(date +%Y%m%d)

# Create hardened config
sudo tee /etc/ssh/sshd_config > /dev/null << 'SSHD_CONFIG'
# OpenClaw Hardened SSH Configuration
# Generated: $(date)
# Backup: /etc/ssh/sshd_config.backup.*

# Authentication
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
PermitRootLogin no
PubkeyAuthentication yes

# Strong key algorithms only
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com,ssh-ed25519

# Session limits
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable unnecessary features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no

# Logging
LogLevel VERBOSE

# Restrict to specific user
AllowUsers ${VM_USER}
SSHD_CONFIG

# Restart SSH service
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist

echo "SSH configuration applied and service restarted"
REMOTE_SCRIPT

echo ""
echo "Configuration applied. Verifying..."
```

---

### Task 5: Verify Hardened SSH

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Verifying Hardened SSH ==="
echo ""

# Wait a moment for SSH to restart
sleep 3

# Test key-based auth still works
echo "Testing key authentication..."
if ssh -i "$KEY_PATH" -o ConnectTimeout=10 \
    "${VM_USER}@${VM_IP}" "echo 'Key auth: OK'" 2>/dev/null; then
    echo "✅ Key authentication works"
else
    echo "❌ Key authentication failed!"
    echo ""
    echo "RECOVERY: Use VM console to restore backup:"
    echo "  sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config"
    echo "  sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist"
    echo "  sudo launchctl load /System/Library/LaunchDaemons/ssh.plist"
    exit 1
fi

# Verify password auth is disabled
echo ""
echo "Testing that password auth is disabled..."
if ssh -o PasswordAuthentication=yes -o PubkeyAuthentication=no \
    -o ConnectTimeout=5 "${VM_USER}@${VM_IP}" "echo test" 2>&1 | grep -q "Permission denied"; then
    echo "✅ Password authentication disabled"
else
    echo "⚠️ Password auth may still work (check sshd_config)"
fi

echo ""
echo "✅ SSH hardening complete"
```

---

## Rollback Procedure

If SSH is broken, use the VM console (Lume window):

```bash
# In VM console
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
```

---

## Success Criteria

- [ ] SSH key generated at `~/.ssh/openclaw_vm_ed25519`
- [ ] Public key copied to VM
- [ ] Key-based authentication working
- [ ] Password authentication disabled
- [ ] SSH connection still works after hardening

---

## Phase 3 Completion

```bash
cat > PLANNING/PHASE-3-COMPLETE.md << 'EOF'
# Phase 3 Complete: SSH Hardening

**Completed:** $(date)

## Results

- SSH key: ~/.ssh/openclaw_vm_ed25519
- Key auth: ✅ Working
- Password auth: ❌ Disabled
- SSH config: Hardened

## Hardening Applied

- Ed25519 keys only
- 3 max auth attempts
- Session timeouts
- X11/Agent forwarding disabled
- Single user allowed

## Connect Command

```bash
ssh -i ~/.ssh/openclaw_vm_ed25519 ${VM_USER}@$(cat .vm_ip)
```

## Ready for Phase 4
EOF

echo "✅ Phase 3 complete. Ready for Phase 4 (Host Firewall)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-4-PROMPT.md and execute"
```
