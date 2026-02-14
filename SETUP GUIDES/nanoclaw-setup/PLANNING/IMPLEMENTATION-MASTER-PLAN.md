# NanoClaw Setup — Implementation Master Plan

## Overview

NanoClaw is a lightweight personal Claude assistant accessible via WhatsApp, running agents in isolated containers on macOS. This plan covers deploying NanoClaw from scratch on an Apple Silicon Mac.

## Phase Summary

| Phase | Name | Duration | Description |
|-------|------|----------|-------------|
| 0 | Prerequisites | 5 min | Validate hardware, software, and network requirements |
| 1 | Clone & Dependencies | 3 min | Clone repo, install Node.js dependencies |
| 2 | Claude Authentication | 5 min | Configure Claude subscription or API key |
| 3 | Container Setup | 5 min | Install Apple Container, build agent image |
| 4 | WhatsApp Authentication | 5 min | QR code scan, session establishment |
| 5 | Configure Assistant | 5 min | Trigger word, main channel, group registration |
| 6 | Security Configuration | 5 min | Mount allowlist, review trust boundaries |
| 7 | Service Installation | 3 min | Build, launchd plist, start service |
| 8 | Testing & Validation | 5 min | End-to-end test, health check, log review |

**Total estimated time: 35-45 minutes**

## Dependencies

```
Phase 0 (Prerequisites)
  └─→ Phase 1 (Clone & Dependencies)
        └─→ Phase 2 (Claude Auth) ─────┐
        └─→ Phase 3 (Container Setup) ──┤
                                         └─→ Phase 4 (WhatsApp Auth)
                                               └─→ Phase 5 (Configure Assistant)
                                                     └─→ Phase 6 (Security)
                                                           └─→ Phase 7 (Service Install)
                                                                 └─→ Phase 8 (Testing)
```

Phases 2 and 3 can be done in parallel.

## Success Criteria

- [ ] NanoClaw process running via launchd (auto-restarts on crash/reboot)
- [ ] WhatsApp connected and responding to trigger messages
- [ ] Agent containers spawning and executing Claude prompts
- [ ] At least one group registered with isolated memory
- [ ] Health check passes all checks
- [ ] Mount allowlist configured (if external directories needed)

## Architecture Reference

```
WhatsApp (baileys) → SQLite → Polling loop → Container (Claude Agent SDK) → Response
```

Single Node.js process. SQLite for persistence. Apple Container (or Docker) for agent isolation.

## Key Paths

| Resource | Location |
|----------|----------|
| NanoClaw clone | `~/nanoclaw/` |
| Database | `~/nanoclaw/data/nanoclaw.db` |
| WhatsApp session | `~/nanoclaw/store/auth/` |
| Group memory | `~/nanoclaw/groups/{name}/CLAUDE.md` |
| Global memory | `~/nanoclaw/groups/CLAUDE.md` |
| Logs | `~/nanoclaw/logs/` |
| Mount allowlist | `~/.config/nanoclaw/mount-allowlist.json` |
| launchd plist | `~/Library/LaunchAgents/com.nanoclaw.plist` |
| Container image | `nanoclaw-agent:latest` |
