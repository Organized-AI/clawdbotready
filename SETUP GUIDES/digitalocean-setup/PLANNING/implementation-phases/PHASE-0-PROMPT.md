# Phase 0: Prerequisites

## Objective
Verify all prerequisites are in place before deploying the DigitalOcean Droplet.

## Checklist

### 1. DigitalOcean Account
- [ ] Create account at [cloud.digitalocean.com](https://cloud.digitalocean.com)
- [ ] Add a payment method
- [ ] Verify email address

### 2. SSH Key
- [ ] Generate an SSH key if you don't have one:
  ```bash
  ssh-keygen -t ed25519 -C "openclaw-digitalocean"
  ```
- [ ] Add the public key to DigitalOcean:
  - Settings → Security → SSH Keys → Add SSH Key
  - Paste contents of `~/.ssh/id_ed25519.pub`

### 3. LLM Provider API Key
Choose one:
- [ ] **Anthropic** (recommended): Get key at [console.anthropic.com](https://console.anthropic.com)
- [ ] **OpenAI**: Get key at [platform.openai.com](https://platform.openai.com)
- [ ] **Gradient**: Get key at their dashboard

### 4. Optional: doctl CLI
For managing Droplets from your terminal:
```bash
brew install doctl
doctl auth init
# Paste your DigitalOcean API token
```

### 5. Optional: Tailscale
If you want private mesh networking to the Droplet:
```bash
brew install tailscale
sudo tailscale up
```

## Verification
- [ ] Can log into DigitalOcean dashboard
- [ ] SSH key is uploaded to DigitalOcean
- [ ] LLM API key is ready (not expired)
- [ ] (Optional) `doctl` authenticated

## Next Phase
Proceed to [Phase 1: Deploy Droplet](PHASE-1-PROMPT.md)
