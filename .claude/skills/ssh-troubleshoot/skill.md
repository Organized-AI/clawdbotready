# SSH Connection Troubleshooting & Setup

Expert guidance for SSH key generation, authentication troubleshooting, and secure file transfer using modern tools like `croc`.

## When to Use This Skill

Use this skill when:
- Setting up SSH keys for the first time
- Troubleshooting "Permission denied" or "Too many authentication failures" errors
- Transferring SSH keys or files securely between machines
- Configuring passwordless SSH access
- Testing SSH connectivity
- Debugging SSH authentication issues

## SSH Key Generation

### Generate Ed25519 Key (Recommended)

```bash
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
```

**Parameters:**
- `-t ed25519`: Use modern Ed25519 algorithm (faster, more secure than RSA)
- `-C "comment"`: Add a comment (usually email or username@hostname)
- `-f ~/.ssh/id_ed25519`: Output file path
- `-N ""`: Empty passphrase (use `-N "your-passphrase"` for added security)

**Output:**
- Private key: `~/.ssh/id_ed25519` (keep secret!)
- Public key: `~/.ssh/id_ed25519.pub` (share this)

### View Your Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

### Copy Public Key to Clipboard (macOS)

```bash
cat ~/.ssh/id_ed25519.pub | pbcopy
```

## Common SSH Authentication Errors

### Error: "Too many authentication failures"

**Cause:** SSH tries multiple keys before password authentication, exceeding the server's `MaxAuthTries` limit.

**Solution 1:** Use password authentication only
```bash
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password user@host
```

**Solution 2:** Specify which key to use
```bash
ssh -i ~/.ssh/id_ed25519 user@host
```

**Solution 3:** Configure `~/.ssh/config`
```
Host myserver
    HostName 192.168.1.100
    User myuser
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

### Error: "Permission denied (publickey)"

**Cause:** Public key not installed on remote server or incorrect permissions.

**Debug with verbose output:**
```bash
ssh -v user@host
```

Look for:
- `Offering public key:` - which keys are being tried
- `Authentications that can continue:` - which auth methods are available

**Check remote server permissions:**
```bash
# On remote server
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Error: "Connection refused"

**Cause:** SSH service not running or firewall blocking port 22.

**Check if SSH is listening:**
```bash
# On remote server
sudo lsof -i :22
# or
netstat -an | grep :22
```

**Test connectivity:**
```bash
telnet host 22
# or
nc -zv host 22
```

## Transferring SSH Keys

### Method 1: ssh-copy-id (Traditional)

```bash
ssh-copy-id user@host
```

**If you get "too many authentication failures":**
```bash
ssh-copy-id -o PubkeyAuthentication=no -o PreferredAuthentications=password user@host
```

### Method 2: Manual Copy via SSH

```bash
cat ~/.ssh/id_ed25519.pub | ssh user@host "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Method 3: Using `croc` (Modern, No Password Needed)

**On sending machine:**
```bash
croc send ~/.ssh/id_ed25519.pub
```

Output will show a code like: `1615-aroma-nectar-theory`

**On receiving machine:**
```bash
croc 1615-aroma-nectar-theory
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
rm id_ed25519.pub
```

**One-liner for receiving and installing:**
```bash
croc YOUR-CODE-HERE && mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat id_ed25519.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm id_ed25519.pub && echo "SSH key installed successfully!"
```

### Method 4: Physical Access

If you have physical or screen sharing access:

1. Copy the public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

2. On the remote machine:
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys  # Paste the key, save
chmod 600 ~/.ssh/authorized_keys
```

## Testing SSH Connections

### Basic Connection Test

```bash
ssh user@host "echo 'Connection successful!'"
```

### Check Which Keys Are Being Offered

```bash
ssh -v user@host 2>&1 | grep -E "(Offering|Authentications that can continue)"
```

### Test Specific Key

```bash
ssh -i ~/.ssh/id_ed25519 user@host "whoami"
```

### Check SSH Config

```bash
ssh -G user@host
```

## Verifying SSH Key Installation

### On Local Machine

Check your SSH keys:
```bash
ls -la ~/.ssh/
```

Verify key fingerprints:
```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

### On Remote Server

List authorized keys:
```bash
cat ~/.ssh/authorized_keys
```

Check permissions:
```bash
ls -la ~/.ssh/
# Should show:
# drwx------ (700) for .ssh directory
# -rw------- (600) for authorized_keys file
```

## SSH Configuration Best Practices

### Client Config (~/.ssh/config)

```
# Global settings
Host *
    AddKeysToAgent yes
    UseKeychain yes  # macOS only
    IdentitiesOnly yes

# Specific host
Host myserver
    HostName 100.66.145.48
    User openclaw
    IdentityFile ~/.ssh/id_ed25519
    Port 22

# Through bastion/jump host
Host internal-server
    HostName 192.168.1.100
    User admin
    ProxyJump bastion-host
```

### Server Config (/etc/ssh/sshd_config)

**Security recommendations:**
```
# Use public key authentication
PubkeyAuthentication yes

# Disable password authentication (after keys are working!)
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Limit authentication attempts
MaxAuthTries 3

# Use modern algorithms only
PubkeyAcceptedKeyTypes ssh-ed25519,ssh-ed25519-cert-v01@openssh.com

# Enable key-based authentication
AuthorizedKeysFile .ssh/authorized_keys

# Disable empty passwords
PermitEmptyPasswords no
```

After editing, restart SSH:
```bash
sudo systemctl restart sshd  # Linux
# or
sudo launchctl stop com.openssh.sshd && sudo launchctl start com.openssh.sshd  # macOS
```

## Secure File Transfer Methods

### scp (Secure Copy)

```bash
# Copy to remote
scp /local/file user@host:/remote/path/

# Copy from remote
scp user@host:/remote/file /local/path/

# Recursive directory copy
scp -r /local/dir user@host:/remote/path/
```

### rsync (Efficient, Resumable)

```bash
# Sync directory
rsync -avz /local/dir/ user@host:/remote/dir/

# Resume interrupted transfer
rsync -avz --partial /local/file user@host:/remote/path/

# Show progress
rsync -avz --progress /local/file user@host:/remote/path/
```

### croc (No SSH Required)

```bash
# Send file
croc send file.txt

# Send directory
croc send --recursive ./my-directory/

# Receive (use code from sender)
croc YOUR-CODE-HERE
```

## Troubleshooting Workflows

### Workflow 1: First-Time SSH Setup

1. **Generate key:**
   ```bash
   ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519
   ```

2. **Transfer key (choose one method):**
   - `ssh-copy-id user@host`
   - `croc send ~/.ssh/id_ed25519.pub` (then install on remote)
   - Manual copy (see Method 4 above)

3. **Test connection:**
   ```bash
   ssh user@host "echo 'Success!'"
   ```

4. **Configure SSH client:**
   ```bash
   nano ~/.ssh/config
   # Add host configuration
   ```

### Workflow 2: "Permission Denied" Debug

1. **Enable verbose logging:**
   ```bash
   ssh -vv user@host
   ```

2. **Check which keys are being tried:**
   ```bash
   ssh -v user@host 2>&1 | grep "Offering public key"
   ```

3. **Verify key exists on remote:**
   ```bash
   ssh -o PubkeyAuthentication=no user@host "cat ~/.ssh/authorized_keys"
   ```

4. **Check remote permissions:**
   ```bash
   ssh -o PubkeyAuthentication=no user@host "ls -la ~/.ssh/"
   ```

5. **Fix permissions if needed:**
   ```bash
   ssh -o PubkeyAuthentication=no user@host "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
   ```

### Workflow 3: Too Many Keys

1. **List your keys:**
   ```bash
   ls -la ~/.ssh/id_*
   ```

2. **Test with specific key only:**
   ```bash
   ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 user@host
   ```

3. **Configure to use only one key:**
   ```bash
   # Add to ~/.ssh/config
   Host myserver
       HostName host
       IdentityFile ~/.ssh/id_ed25519
       IdentitiesOnly yes
   ```

## Security Best Practices

### Key Management

1. **Use strong keys:**
   - Ed25519 (recommended): Modern, fast, secure
   - RSA 4096-bit: Legacy systems only

2. **Protect private keys:**
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   ```

3. **Use passphrases:**
   ```bash
   ssh-keygen -t ed25519 -N "strong-passphrase"
   ```

4. **Use SSH agent:**
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

5. **Rotate keys periodically:**
   - Generate new keys annually
   - Remove old keys from `authorized_keys`

### Connection Security

1. **Verify host fingerprints:**
   ```bash
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. **Use SSH config for consistency:**
   - Prevents man-in-the-middle attacks
   - Enforces known_hosts checking

3. **Limit key usage:**
   - Use different keys for different purposes
   - Add `command=` restrictions in authorized_keys if needed

### Server Hardening

1. **Change default SSH port:**
   ```
   Port 2222  # in /etc/ssh/sshd_config
   ```

2. **Use fail2ban:**
   ```bash
   sudo apt install fail2ban
   ```

3. **Enable two-factor authentication:**
   ```bash
   sudo apt install libpam-google-authenticator
   ```

4. **Monitor SSH logs:**
   ```bash
   tail -f /var/log/auth.log  # Linux
   log show --predicate 'process == "sshd"' --last 1h  # macOS
   ```

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| Generate Ed25519 key | `ssh-keygen -t ed25519 -C "user@host"` |
| Copy key to server | `ssh-copy-id user@host` |
| Test connection | `ssh user@host "echo test"` |
| Debug connection | `ssh -vv user@host` |
| Copy file to remote | `scp file user@host:/path/` |
| Check key fingerprint | `ssh-keygen -lf ~/.ssh/id_ed25519.pub` |
| Remove host from known_hosts | `ssh-keygen -R hostname` |
| Transfer via croc | `croc send file` |

### File Permissions

| File/Directory | Permissions | Command |
|----------------|-------------|---------|
| `~/.ssh/` | 700 (drwx------) | `chmod 700 ~/.ssh` |
| `~/.ssh/id_ed25519` | 600 (-rw-------) | `chmod 600 ~/.ssh/id_ed25519` |
| `~/.ssh/id_ed25519.pub` | 644 (-rw-r--r--) | `chmod 644 ~/.ssh/id_ed25519.pub` |
| `~/.ssh/authorized_keys` | 600 (-rw-------) | `chmod 600 ~/.ssh/authorized_keys` |
| `~/.ssh/config` | 600 (-rw-------) | `chmod 600 ~/.ssh/config` |

### Error Code Quick Reference

| Error | Common Cause | Quick Fix |
|-------|--------------|-----------|
| "Permission denied (publickey)" | Key not installed | `ssh-copy-id user@host` |
| "Too many authentication failures" | Multiple keys tried | Use `-i` to specify key |
| "Connection refused" | SSH not running | Check `sshd` status |
| "Host key verification failed" | Host key changed | `ssh-keygen -R hostname` |
| "Bad permissions" | Wrong file permissions | `chmod 600 ~/.ssh/id_ed25519` |

## Testing OpenClaw Telegram Bot Before Delivery

**Critical Pre-Deployment Step:** Always test the Telegram bot works before delivering to client.

### Step 1: Temporarily Allow All Users

```bash
ssh user@host "jq '.channels.telegram.dmPolicy = \"open\" | .channels.telegram.allowFrom = [\"*\"]' ~/.openclaw/openclaw.json > /tmp/openclaw-temp.json && cat /tmp/openclaw-temp.json > ~/.openclaw/openclaw.json"
```

### Step 2: Reload Gateway

```bash
ssh user@host "pkill -SIGUSR1 openclaw-gateway"
```

Wait 5 seconds for reload.

### Step 3: Test the Bot

1. Open Telegram
2. Search for the bot (e.g., `@SAMyosin_bot`)
3. Send a test message like "Hello" or "Test"
4. **Verify:** Bot responds within a few seconds

### Step 4: Get Your Telegram User ID

Check the gateway logs for your user ID:

```bash
ssh user@host "grep -i 'telegram.*user' ~/.openclaw/logs/gateway.log | tail -5"
```

Or check for incoming messages:

```bash
ssh user@host "tail -50 ~/.openclaw/logs/gateway.log | grep -E '(message|user|chat)'"
```

### Step 5: Restore Client-Only Access

Once testing is complete, restore the allowlist to only include the client's Telegram user ID:

```bash
ssh user@host "jq '.channels.telegram.dmPolicy = \"allowlist\" | .channels.telegram.allowFrom = [\"337198\"]' ~/.openclaw/openclaw.json > /tmp/openclaw-restore.json && cat /tmp/openclaw-restore.json > ~/.openclaw/openclaw.json"
```

Reload gateway:

```bash
ssh user@host "pkill -SIGUSR1 openclaw-gateway"
```

### Verification Checklist

Before delivering to client:

- [ ] SSH access works from your machine
- [ ] OpenClaw Gateway starts successfully
- [ ] Telegram bot responds to test messages
- [ ] Bot is restricted to client's user ID only
- [ ] Auto-start is configured (LaunchAgent)
- [ ] Power settings prevent sleep
- [ ] All setup scripts are on the Mac Mini

## Real-World Example: Today's Session

**Scenario:** Setting up SSH access to Mac Mini at `100.66.145.48` and deploying OpenClaw Telegram bot

**Problem 1:** `ssh-copy-id` failed with "Too many authentication failures"

**Solution 1:**
1. Generated Ed25519 key
2. Used `croc` to transfer public key
3. Installed key with one-liner:
   ```bash
   croc 1615-aroma-nectar-theory && mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat id_ed25519.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm id_ed25519.pub && echo "SSH key installed successfully!"
   ```
4. Verified: `ssh openclaw@100.66.145.48 "echo 'Success!'"`

**Result:** Passwordless SSH access established.

**Problem 2:** Telegram bot had wrong token (typo: lowercase 'l' vs uppercase 'I')

**Solution 2:**
1. Updated bot token in config:
   ```bash
   ssh openclaw@100.66.145.48 "jq '.channels.telegram.botToken = \"8055366403:AAHqwqIayKI0PEv4rV5Xmvie4BMzY4Gcob4\"' ~/.openclaw/openclaw.json > /tmp/updated.json && cat /tmp/updated.json > ~/.openclaw/openclaw.json"
   ```
2. Reloaded gateway: `pkill -SIGUSR1 openclaw-gateway`

**Problem 3:** Model `openrouter/auto` not recognized

**Solution 3:**
1. Changed to specific model:
   ```bash
   jq '.agents.defaults.model.primary = "openrouter/anthropic/claude-3.5-sonnet"' ~/.openclaw/openclaw.json
   ```
2. Restarted gateway completely

**Problem 4:** Config validation error - `dmPolicy="open"` requires `allowFrom=["*"]`

**Solution 4:**
```bash
jq '.channels.telegram.dmPolicy = "open" | .channels.telegram.allowFrom = ["*"]' ~/.openclaw/openclaw.json
```

**Final Result:**
- Passwordless SSH access established
- Bot `@SAMyosin_bot` responding successfully
- Tested with user `@jordaaanh`
- Restored allowlist to client-only access

## Additional Resources

### Tools Referenced
- **ssh-keygen**: Generate SSH keys
- **ssh-copy-id**: Copy keys to remote servers
- **croc**: Secure file transfer without SSH
- **ssh-agent**: Manage SSH keys in memory
- **fail2ban**: Automatic IP blocking for failed SSH attempts

### Log Locations
- **Linux**: `/var/log/auth.log` or `/var/log/secure`
- **macOS**: `log show --predicate 'process == "sshd"'`
- **Client debug**: `ssh -vvv user@host`

### Related Skills
- **remote-server-management**: Managing remote servers
- **security-hardening**: Server security best practices
- **network-troubleshooting**: Network connectivity issues

---

*This skill is based on real troubleshooting performed on 2026-02-03*
*macOS Sequoia, Apple Silicon M1 Mac Mini*
