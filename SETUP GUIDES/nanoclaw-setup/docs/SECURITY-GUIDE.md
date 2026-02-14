# NanoClaw Security Guide

Detailed security architecture and hardening recommendations for NanoClaw deployments.

---

## Security Philosophy

NanoClaw takes a fundamentally different approach to security than OpenClaw:

| Approach | OpenClaw | NanoClaw |
|----------|----------|----------|
| **Isolation** | Application-level (exec-approvals) | OS-level (containers) |
| **Boundary** | Permission checks in code | Linux VM boundary |
| **Attack surface** | Large codebase to audit | Small codebase + container walls |
| **Bash safety** | Commands run on host, filtered | Commands run in container |

The key insight: **agents run in containers, not behind permission checks**. A compromised agent can't escape the container boundary, regardless of what code it executes.

---

## Trust Model

| Entity | Trust Level | Rationale |
|--------|-------------|-----------|
| Host process | Trusted | You control it, runs on your Mac |
| Main channel | Trusted | Private self-chat, admin control |
| Non-main groups | Untrusted | Other users may be malicious |
| Container agents | Sandboxed | Isolated execution environment |
| WhatsApp messages | User input | Potential prompt injection |
| Network responses | External | Potentially malicious content |

---

## Security Boundaries

### 1. Container Isolation (Primary)

All agents execute in Apple Container (lightweight Linux VMs):

- **Process isolation**: Container processes cannot affect the host
- **Filesystem isolation**: Only explicitly mounted directories are visible
- **Non-root execution**: Runs as unprivileged `node` user (uid 1000)
- **Ephemeral containers**: Fresh environment per invocation (`--rm`)
- **Bash is safe**: Commands execute inside the container, not on your Mac

### 2. Mount Security (Secondary)

The mount allowlist at `~/.config/nanoclaw/mount-allowlist.json` controls what's visible:

**Protections**:
- Allowlist is stored **outside** the project root — agents can't modify it
- Symlink resolution before validation (prevents traversal attacks)
- Container path validation (rejects `..` and absolute paths)
- Default blocked patterns cover common sensitive files
- `nonMainReadOnly` forces read-only for non-admin groups

**Default blocked patterns**:
```
.ssh, .gnupg, .aws, .azure, .gcloud, .kube, .docker,
credentials, .env, .netrc, .npmrc, id_rsa, id_ed25519,
private_key, .secret
```

### 3. Session Isolation (Tertiary)

Each group has isolated Claude sessions:
- Groups cannot see other groups' conversation history
- Session data includes full message history and files read
- Prevents cross-group information disclosure

### 4. IPC Authorization

Inter-process communication is verified against group identity:

| Operation | Main Group | Non-Main Group |
|-----------|------------|----------------|
| Send message to own chat | Yes | Yes |
| Send message to other chats | Yes | No |
| Schedule task for self | Yes | Yes |
| Schedule task for others | Yes | No |
| View all tasks | Yes | Own only |
| Manage other groups | Yes | No |

### 5. Credential Handling

**Mounted (read-only)**:
- Claude auth tokens (filtered from `data/env/env`)

**Never mounted**:
- WhatsApp session (`store/auth/`)
- Mount allowlist (`~/.config/nanoclaw/`)
- Any paths matching blocked patterns

**Credential filtering**: Only these env vars are exposed to containers:
```
CLAUDE_CODE_OAUTH_TOKEN
ANTHROPIC_API_KEY
```

---

## Known Limitations

### 1. API Credentials in Containers

Anthropic credentials are mounted so Claude Code can authenticate. However, agents can discover these credentials via bash or file operations inside the container.

**Mitigation**: Use API keys with spending limits. Monitor usage at [console.anthropic.com](https://console.anthropic.com).

### 2. Unrestricted Network Access

Containers have full network access (needed for web search, API calls, browser automation).

**Risk**: A compromised agent could exfiltrate data to external servers.

**Mitigation**: This is inherent to the use case — agents need internet for useful work. Monitor outbound traffic if concerned.

### 3. Baileys (Unofficial WhatsApp API)

The `@whiskeysockets/baileys` library is an unofficial WhatsApp Web implementation. WhatsApp could block it or change the protocol.

**Risk**: Account suspension if WhatsApp detects automation.

**Mitigation**: Use a secondary WhatsApp number. Don't send at spam-like volumes.

---

## Hardening Recommendations

### Essential (Do These)

1. **Keep mount allowlist minimal** — only add directories agents actually need
2. **Enable `nonMainReadOnly`** — non-admin groups should be read-only by default
3. **Use API keys with spending limits** — set max monthly spend at Anthropic
4. **Back up regularly** — `data/`, `groups/`, `store/auth/`
5. **Review blocked patterns** — ensure `.ssh`, `.gnupg`, etc. are blocked

### Recommended

6. **Separate WhatsApp number** — don't use your primary phone number
7. **Regular container rebuilds** — stay updated with security patches:
   ```bash
   cd ~/nanoclaw && git pull && ./container/build.sh
   ```
8. **Monitor logs** — check error logs weekly for unusual activity
9. **Limit concurrent containers** — `MAX_CONCURRENT_CONTAINERS=3` reduces resource exhaustion risk

### Advanced

10. **Network monitoring** — use Little Snitch or similar to monitor NanoClaw's connections
11. **Separate user account** — run NanoClaw under a dedicated macOS user
12. **Time-based access** — use launchd `StartCalendarInterval` to only run during work hours
13. **Regular permission audits** — review what directories are accessible:
    ```bash
    cat ~/.config/nanoclaw/mount-allowlist.json
    ```

---

## Incident Response

### If You Suspect Compromise

1. **Emergency stop** — immediately kill NanoClaw and all containers:
   ```bash
   ./scripts/emergency-stop.sh
   ```

2. **Revoke credentials**:
   - Rotate your Anthropic API key at [console.anthropic.com](https://console.anthropic.com)
   - Remove linked WhatsApp device from your phone
   - Review any mounted directories for unauthorized changes

3. **Investigate**:
   ```bash
   # Check recent logs
   grep -i "error\|warn\|fail\|unauthorized" ~/nanoclaw/logs/nanoclaw.log

   # Check container activity
   container ps -a

   # Check database for unusual messages
   sqlite3 ~/nanoclaw/data/nanoclaw.db \
     "SELECT * FROM messages ORDER BY timestamp DESC LIMIT 50;"
   ```

4. **Clean reinstall** if compromise is confirmed:
   ```bash
   rm -rf ~/nanoclaw
   rm -rf ~/.config/nanoclaw
   rm ~/Library/LaunchAgents/com.nanoclaw.plist
   # Then reinstall from Phase 0
   ```

---

## Comparison with OpenClaw Security

| Feature | OpenClaw | NanoClaw |
|---------|----------|----------|
| Command filtering | exec-approvals.json (allowlist) | Container isolation (no filtering needed) |
| Filesystem protection | User account isolation | Container mounts (only explicit dirs) |
| Bash execution | On host, filtered by allowlist | In container, unrestricted but safe |
| Network isolation | Firewall rules possible | Unrestricted (by design) |
| Credential exposure | Gateway manages tokens | Auth vars mounted into container |
| Codebase audit | 52+ modules (hard to audit) | ~18 files (easy to audit) |
| Recovery | User account recreation | Container is ephemeral, just restart |

**Bottom line**: NanoClaw trades granular command-level control for stronger OS-level isolation. Neither approach is universally "better" — they make different tradeoffs appropriate for their use cases.
