# Phase 4: Verify & Harden

## Objective
Confirm the full deployment is working end-to-end, set up backups, and configure secure remote access.

## Steps

### 1. End-to-End Verification

```bash
# From your local machine
./scripts/status.sh YOUR_DROPLET_IP
```

Confirm:
- [ ] SSH connected
- [ ] OpenClaw service active
- [ ] Docker container running
- [ ] Gateway responding on port 18789
- [ ] Memory and disk within healthy ranges

### 2. Test Agent Capabilities

Send a message via your configured channel and verify the agent can:
- [ ] Respond to basic questions
- [ ] Execute tool calls (if configured)
- [ ] Maintain conversation context

### 3. Set Up Backups

**Option A: Automated backups (recommended)**
- DigitalOcean dashboard → Droplets → Your Droplet → Backups → Enable
- Cost: 20% of Droplet price ($2.40/mo for $12 Droplet)
- Frequency: Weekly

**Option B: Manual snapshots**
```bash
./scripts/backup.sh
# Or via doctl:
doctl compute droplet-action snapshot YOUR_DROPLET_ID --snapshot-name "openclaw-verified"
```

### 4. Configure Remote Access

Choose one method:

**SSH Tunnel (most secure, no additional setup):**
```bash
ssh -N -L 18789:127.0.0.1:18789 root@YOUR_DROPLET_IP
# Then access at http://127.0.0.1:18789/
```

**Tailscale (best for persistent access):**
```bash
# On the Droplet
ssh root@YOUR_DROPLET_IP
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Note the Tailscale IP
```

**Direct IP (simplest, least secure):**
- Already accessible at `http://YOUR_DROPLET_IP:18789/`
- Consider restricting with UFW if you use this method

### 5. Security Review

Verify the built-in hardening:

```bash
ssh root@YOUR_DROPLET_IP

# Check firewall
ufw status verbose

# Check fail2ban
fail2ban-client status
fail2ban-client status sshd

# Verify non-root container execution
docker exec openclaw whoami
# Expected: not root

# Check gateway auth is required
curl -s http://127.0.0.1:18789/  # Should require token
```

### 6. Create a Non-Root SSH User (Optional but Recommended)

```bash
ssh root@YOUR_DROPLET_IP

# Create user
adduser openclaw-admin
usermod -aG sudo openclaw-admin

# Copy SSH key
mkdir -p /home/openclaw-admin/.ssh
cp ~/.ssh/authorized_keys /home/openclaw-admin/.ssh/
chown -R openclaw-admin:openclaw-admin /home/openclaw-admin/.ssh

# Test login from local machine
ssh openclaw-admin@YOUR_DROPLET_IP
```

## Final Verification Checklist
- [ ] Agent responds to messages on all configured channels
- [ ] Backup strategy in place (automated or snapshot)
- [ ] Remote access method chosen and working
- [ ] Firewall active (UFW)
- [ ] fail2ban active
- [ ] Gateway token saved locally
- [ ] (Optional) Non-root SSH user created

## Deployment Complete

Your OpenClaw instance is live on DigitalOcean. For ongoing management:

```bash
# Check status
./scripts/status.sh

# View logs
./scripts/logs.sh

# Restart service
./scripts/restart.sh

# Add more channels
./scripts/channels.sh
```
