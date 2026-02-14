# Phase 6: Security Configuration

## Objective
Configure the mount allowlist and review security boundaries before going live.

## Steps

### 1. Configure Mount Allowlist

The mount allowlist controls which host directories agents can access. It lives **outside** the project at `~/.config/nanoclaw/mount-allowlist.json` so agents can never modify it.

```bash
# Create config directory
mkdir -p ~/.config/nanoclaw

# Start from the example template
cp "SETUP GUIDES/nanoclaw-setup/config/mount-allowlist.example.json" \
   ~/.config/nanoclaw/mount-allowlist.json
```

**Edit to match your needs:**
```json
{
  "allowedRoots": [
    {
      "path": "~/projects",
      "allowReadWrite": true,
      "description": "Development projects"
    }
  ],
  "blockedPatterns": [
    ".ssh", ".gnupg", ".aws", ".env", "credentials",
    "id_rsa", "id_ed25519", "private_key", ".secret"
  ],
  "nonMainReadOnly": true
}
```

Key settings:
- **allowedRoots**: Directories agents can access (beyond their group folder)
- **blockedPatterns**: Patterns that are always blocked from mounting
- **nonMainReadOnly**: Forces read-only for non-main groups (recommended: `true`)

### 2. Review Trust Boundaries

Verify you understand the security model:

| What | Protected? | How |
|------|-----------|-----|
| Host filesystem | Yes | Only mounted dirs are visible in containers |
| WhatsApp session | Yes | Never mounted into containers |
| Mount allowlist | Yes | External to project, never mounted |
| SSH keys | Yes | Blocked by default patterns |
| API credentials | Partial | Exposed inside containers (known limitation) |
| Network access | No | Containers have unrestricted network |

### 3. Verify Blocked Patterns

```bash
# Ensure these sensitive paths would be blocked
cat ~/.config/nanoclaw/mount-allowlist.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print('Blocked patterns:', data.get('blockedPatterns', []))
print('Non-main read-only:', data.get('nonMainReadOnly', False))
"
```

### 4. Test Mount Security

After NanoClaw is running, from a non-main group:
```
@Andy read the file at ~/.ssh/id_ed25519
```
This should fail — blocked by mount security.

## Success Criteria
- [ ] Mount allowlist created at `~/.config/nanoclaw/mount-allowlist.json`
- [ ] Sensitive patterns are blocked (`.ssh`, `.gnupg`, `.aws`, etc.)
- [ ] `nonMainReadOnly` is true (recommended)
- [ ] Allowlist is outside project root (cannot be agent-modified)
- [ ] Understand that API credentials are visible inside containers
