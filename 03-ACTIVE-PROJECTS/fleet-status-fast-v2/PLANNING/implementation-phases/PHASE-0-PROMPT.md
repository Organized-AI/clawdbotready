# Phase 0: SSH Access Fix + Project Setup

**Project:** Fleet Status Fast v2 — Gateway Control API
**Dependencies:** Physical or remote access to openclaws-mac-mini
**Context Files:** Read PLANNING/IMPLEMENTATION-MASTER-PLAN.md first

---

## Objective

Fix SSH key authorization so the MacBook Pro can reach the Mac Mini, then initialize the Fleet Control API project with dependencies and config.

---

## Tasks

### Task 1: Authorize MacBook Pro SSH Key on Mac Mini

The MacBook Pro (supabowl) ed25519 public key needs to be added to the `openclaw` user's authorized_keys on the Mac Mini.

Get the MacBook Pro's public key:
```bash
cat /Users/supabowl/.ssh/id_ed25519.pub
```

On the Mac Mini (run locally or from a machine that has access):
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "<MACBOOK_PRO_PUBKEY>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Task 2: Initialize Project

```bash
mkdir -p ~/fleet-control-api
cd ~/fleet-control-api
npm init -y
```

### Task 3: Create Directory Structure

```
fleet-control-api/
├── src/
│   ├── server.js
│   ├── auth.js
│   ├── gateway.js
│   ├── system.js
│   └── logger.js
├── config/
│   └── default.json
├── scripts/
│   ├── generate-token.sh
│   └── install-service.sh
├── package.json
└── README.md
```

### Task 4: Generate Auth Token

Create `scripts/generate-token.sh` — generates 64-char token and stores in macOS Keychain as "fleet-control-token".

### Task 5: Create Config

Create `config/default.json` with port 3847, bind to 100.66.145.48 (Tailscale only), gateway port 18789.

### Task 6: Verify OpenClaw CLI Availability

```bash
which openclaw && openclaw --version && openclaw gateway status
```

### Task 7: Git Init

```bash
git init && git add -A && git commit -m "Phase 0: Project setup, auth token, config"
```

---

## Success Criteria

- [ ] SSH from MacBook Pro to Mac Mini works
- [ ] Project initialized with package.json and directory structure
- [ ] Auth token generated and stored in macOS Keychain
- [ ] Config file created with Tailscale-only bind address
- [ ] OpenClaw CLI confirmed available
- [ ] Git repo initialized with first commit
