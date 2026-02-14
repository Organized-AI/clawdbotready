# Phase 1: Deploy the Droplet

## Objective
Create an OpenClaw Droplet from the DigitalOcean Marketplace 1-Click image.

## Steps

### 1. Open the Marketplace Listing
Navigate to: [marketplace.digitalocean.com/apps/moltbot](https://marketplace.digitalocean.com/apps/moltbot)

Click **Create OpenClaw Droplet**.

### 2. Configure the Droplet

**Region:** Choose the datacenter closest to your primary users.

**Size:** Select based on expected usage:
| Usage | Recommended Size | Cost |
|-------|-----------------|------|
| Personal (1-5 users) | Basic 4 GB / 2 vCPU | $12/mo |
| Small Team (5-20) | Basic 8 GB / 4 vCPU | $24/mo |
| Medium Team (20-50) | Basic 16 GB / 8 vCPU | $48/mo |

**Authentication:** Select your SSH key (uploaded in Phase 0).

**Hostname:** Give it a recognizable name (e.g., `openclaw-prod`).

### 3. Create and Wait

Click **Create Droplet**. Provisioning takes 1-2 minutes.

### 4. Note the IP Address

Copy the Droplet's public IPv4 address from the dashboard.

### 5. Verify SSH Access

Wait ~60 seconds after creation, then:

```bash
ssh root@YOUR_DROPLET_IP
```

You should see a welcome banner confirming OpenClaw is installed.

**If SSH fails:** Wait another 30 seconds — the provisioning script may still be running.

## Verification
- [ ] Droplet is in "Active" state on the dashboard
- [ ] SSH connection succeeds
- [ ] Welcome banner mentions OpenClaw
- [ ] Droplet IP noted for future use

## Update Local Config

```bash
# Save the IP to your local settings
echo "DROPLET_IP=YOUR_DROPLET_IP" >> config/settings.env
```

## Next Phase
Proceed to [Phase 2: Configure LLM Provider](PHASE-2-PROMPT.md)
