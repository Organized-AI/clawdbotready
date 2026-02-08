# Phase 5: Gateway Configuration

**Safety Level:** 🟢 Safe (VM only, doesn't affect host)
**Estimated Tasks:** 5
**Dependencies:** Phase 3 complete (SSH), Phase 4 recommended

---

## Pre-Execution Safety Check

This phase will configure OpenClaw Gateway inside the VM:
1. Create configuration directories
2. Generate TLS certificates (self-signed)
3. Generate authentication token
4. Create Gateway configuration file
5. Copy exec-approvals security rules

**This is SAFE because:**
- All changes are inside the VM
- Gateway binds to localhost only (127.0.0.1)
- Access requires SSH tunnel from host

Before proceeding, verify:
- [ ] Phase 3 (SSH) is complete
- [ ] Phase 4 (Firewall) is complete (recommended)
- [ ] VM is running and SSH accessible

---

## Context Files to Read First

```
READ: .vm_ip (VM IP address)
READ: config/exec-approvals.json (security rules)
READ: config/settings.env (configuration)
```

---

## Tasks

### Task 1: Generate Authentication Token

```bash
echo "=== Generating Gateway Auth Token ==="
echo ""

# Generate a secure random token
AUTH_TOKEN=$(openssl rand -hex 32)

echo "Token generated (64 hex characters)"
echo ""

# Save token locally (on host)
echo "$AUTH_TOKEN" > .gateway_token
chmod 600 .gateway_token

echo "Token saved to: .gateway_token"
echo ""
echo "⚠️ IMPORTANT: Keep this token secure!"
echo "   You'll need it to authenticate with the Gateway"
echo ""
echo "Token: $AUTH_TOKEN"
```

---

### Task 2: Create Configuration on VM

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"
AUTH_TOKEN=$(cat .gateway_token 2>/dev/null)

echo "=== Creating Gateway Configuration ==="
echo ""

if [[ -z "$VM_IP" ]] || [[ -z "$AUTH_TOKEN" ]]; then
    echo "❌ Error: VM IP or auth token not found"
    exit 1
fi

# Create directories and config on VM
ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << REMOTE_SCRIPT
echo "Creating directories..."
mkdir -p ~/.openclaw/certs
mkdir -p ~/.openclaw/logs
mkdir -p ~/.openclaw/workspace

echo ""
echo "Generating TLS certificates..."
cd ~/.openclaw/certs

# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 \
    -keyout server.key \
    -out server.crt \
    -days 365 \
    -nodes \
    -subj "/CN=openclaw-vm/O=OpenClaw/C=US" \
    2>/dev/null

# Secure the private key
chmod 600 server.key
chmod 644 server.crt

echo "Certificate generated:"
ls -la ~/.openclaw/certs/

echo ""
echo "Creating Gateway configuration..."
cat > ~/.openclaw/config.yaml << 'GATEWAY_CONFIG'
# OpenClaw Gateway Configuration
# Generated: $(date)

gateway:
  # SECURITY: Bind to localhost only
  # Access via SSH tunnel from host
  bind: "127.0.0.1:8080"

  # Authentication
  auth:
    enabled: true
    token: "${AUTH_TOKEN}"

  # TLS encryption
  tls:
    enabled: true
    cert: "~/.openclaw/certs/server.crt"
    key: "~/.openclaw/certs/server.key"

  # Rate limiting
  rate_limit:
    requests_per_minute: 60
    burst: 10

  # Logging
  logging:
    level: "info"
    file: "~/.openclaw/logs/gateway.log"

# Execution security
exec:
  approvals_file: "~/.openclaw/exec-approvals.json"
  log_all: true
  default_action: "deny"
GATEWAY_CONFIG

echo ""
echo "Configuration created:"
cat ~/.openclaw/config.yaml
REMOTE_SCRIPT

echo ""
echo "✅ Gateway configuration created in VM"
```

---

### Task 3: Copy exec-approvals Security Rules

⚠️ **SAFETY REVIEW**

The exec-approvals file defines what commands the agent can run.
Review the rules in `config/exec-approvals.json` before copying.

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Copying Security Rules ==="
echo ""

if [[ ! -f "config/exec-approvals.json" ]]; then
    echo "❌ Error: config/exec-approvals.json not found"
    exit 1
fi

echo "Exec-approvals summary:"
echo ""
echo "ALLOWED commands:"
grep -A2 '"action": "allow"' config/exec-approvals.json | grep '"id"' | sed 's/.*"id": "\([^"]*\)".*/  - \1/'

echo ""
echo "DENIED commands:"
grep -A2 '"action": "deny"' config/exec-approvals.json | grep '"id"' | sed 's/.*"id": "\([^"]*\)".*/  - \1/'

echo ""
echo "Copying to VM..."

# Copy the file
scp -i "$KEY_PATH" config/exec-approvals.json "${VM_USER}@${VM_IP}:~/.openclaw/exec-approvals.json"

echo ""
echo "Verifying on VM..."
ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << 'REMOTE_VERIFY'
echo "File copied:"
ls -la ~/.openclaw/exec-approvals.json

echo ""
echo "Rule count:"
echo "  Allow rules: $(grep -c '"action": "allow"' ~/.openclaw/exec-approvals.json)"
echo "  Deny rules: $(grep -c '"action": "deny"' ~/.openclaw/exec-approvals.json)"
REMOTE_VERIFY

echo ""
echo "✅ Security rules copied to VM"
```

---

### Task 4: Create Helper Scripts on VM

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Creating Helper Scripts ==="
echo ""

ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << 'REMOTE_SCRIPTS'
# Create bin directory
mkdir -p ~/bin

# Create Gateway start script
cat > ~/bin/start-gateway.sh << 'SCRIPT'
#!/bin/bash
echo "Starting OpenClaw Gateway..."
echo "Logs: ~/.openclaw/logs/gateway.log"
echo "Press Ctrl+C to stop"
echo ""
# This would start the actual OpenClaw Gateway
# openclaw-gateway --config ~/.openclaw/config.yaml
echo "Gateway would start here (install OpenClaw first)"
SCRIPT
chmod +x ~/bin/start-gateway.sh

# Create Gateway status script
cat > ~/bin/gateway-status.sh << 'SCRIPT'
#!/bin/bash
echo "=== Gateway Status ==="
echo ""
if pgrep -f "openclaw" > /dev/null; then
    echo "Gateway: RUNNING"
    echo "PID: $(pgrep -f openclaw)"
else
    echo "Gateway: NOT RUNNING"
fi
echo ""
echo "Config: ~/.openclaw/config.yaml"
echo "Logs: ~/.openclaw/logs/gateway.log"
echo ""
if [[ -f ~/.openclaw/logs/gateway.log ]]; then
    echo "Recent logs:"
    tail -10 ~/.openclaw/logs/gateway.log
fi
SCRIPT
chmod +x ~/bin/gateway-status.sh

# Create log viewer
cat > ~/bin/view-logs.sh << 'SCRIPT'
#!/bin/bash
echo "Gateway logs (Ctrl+C to stop):"
tail -f ~/.openclaw/logs/gateway.log 2>/dev/null || echo "No logs yet"
SCRIPT
chmod +x ~/bin/view-logs.sh

echo "Helper scripts created in ~/bin/"
ls -la ~/bin/
REMOTE_SCRIPTS

echo ""
echo "✅ Helper scripts created"
```

---

### Task 5: Verify Configuration

```bash
source config/settings.env 2>/dev/null
VM_USER="${VM_USER:-openclaw}"
VM_IP=$(cat .vm_ip 2>/dev/null)
KEY_PATH="$HOME/.ssh/openclaw_vm_ed25519"

echo "=== Verification ==="
echo ""

ssh -i "$KEY_PATH" "${VM_USER}@${VM_IP}" << 'REMOTE_VERIFY'
echo "Directory structure:"
ls -la ~/.openclaw/

echo ""
echo "Certificates:"
ls -la ~/.openclaw/certs/

echo ""
echo "Certificate details:"
openssl x509 -in ~/.openclaw/certs/server.crt -noout -subject -dates 2>/dev/null

echo ""
echo "Config file:"
cat ~/.openclaw/config.yaml | grep -v token

echo ""
echo "Exec-approvals:"
head -20 ~/.openclaw/exec-approvals.json
echo "..."

echo ""
echo "Helper scripts:"
ls -la ~/bin/
REMOTE_VERIFY

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Gateway Configuration Complete"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "To access the Gateway from your host:"
echo ""
echo "1. Create SSH tunnel:"
echo "   ssh -i $KEY_PATH -L 8080:127.0.0.1:8080 -N ${VM_USER}@${VM_IP}"
echo ""
echo "2. Access Gateway:"
echo "   https://localhost:8080"
echo ""
echo "3. Auth token:"
echo "   $(cat .gateway_token)"
echo ""
```

---

## Rollback Procedure

```bash
# SSH into VM
ssh -i ~/.ssh/openclaw_vm_ed25519 openclaw@$(cat .vm_ip)

# In VM:
rm -rf ~/.openclaw
rm -rf ~/bin/start-gateway.sh ~/bin/gateway-status.sh ~/bin/view-logs.sh
```

---

## Success Criteria

- [ ] Auth token generated and saved to `.gateway_token`
- [ ] TLS certificates created in VM
- [ ] Gateway config at `~/.openclaw/config.yaml`
- [ ] exec-approvals copied to VM
- [ ] Helper scripts created

---

## Phase 5 Completion

```bash
cat > PLANNING/PHASE-5-COMPLETE.md << 'EOF'
# Phase 5 Complete: Gateway Configuration

**Completed:** $(date)

## Results

- Auth token: .gateway_token
- TLS certs: ~/.openclaw/certs/ (in VM)
- Config: ~/.openclaw/config.yaml (in VM)
- Security: exec-approvals.json (in VM)

## Gateway Access

```bash
# Create tunnel
ssh -i ~/.ssh/openclaw_vm_ed25519 -L 8080:127.0.0.1:8080 -N openclaw@$(cat .vm_ip)

# Access
https://localhost:8080
```

## Security Features

- Binds to localhost only
- TLS encryption
- Token authentication
- Deny-by-default exec-approvals

## Ready for Phase 6
EOF

echo "✅ Phase 5 complete. Ready for Phase 6 (Monitoring)"
```

---

## Next Phase

```
"Read PLANNING/implementation-phases/PHASE-6-PROMPT.md and execute"
```
