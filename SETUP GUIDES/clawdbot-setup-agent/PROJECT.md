# Clawdbot Setup Agent - Project Overview

**Status**: ✅ Ready for Deployment
**Version**: 1.0.0
**Created**: 2026-02-02

---

## What This Is

An **optional, supplementary** AI agent that provides automated setup assistance for non-technical users who want to deploy Clawdbot on their Mac. This is a **separate layer** on top of your existing manual setup guides - it doesn't replace or modify them.

### Key Principles

1. **Non-Intrusive**: Uses existing setup scripts from `SETUP GUIDES/` without modification
2. **Opt-In**: Users can choose automated agent setup OR manual guided setup
3. **Parallel Systems**: Both manual and agent-assisted paths work independently
4. **Copies, Never Modifies**: Agent references existing docs/scripts, doesn't change them

---

## How It Fits Into Your Project

```
Clawdbot Ready/
├── SETUP GUIDES/                    ← YOUR EXISTING SYSTEM (unchanged)
│   ├── openclaw-vm-setup/           ← Manual VM setup (works standalone)
│   └── openclaw-native-setup/       ← Manual native setup (works standalone)
│
├── .claude/
│   └── skills/
│       └── openclaw-onboarding/     ← YOUR EXISTING SKILL (unchanged)
│           └── SKILL.md             ← Manual guidance for Claude Code
│
└── clawdbot-setup-agent/            ← NEW: Separate agent system (this project)
    ├── agent-config.md              ← Agent behavior/personality
    ├── conversation-flow.md         ← Decision tree for phone calls
    ├── scripts/                     ← Agent-specific utilities
    │   ├── ssh-manager.sh           ← Temporary SSH credentials
    │   └── remote-setup.sh          ← Remote execution wrapper
    ├── config/
    │   └── agent-exec-approvals.json ← Agent-specific security rules
    └── DEPLOYMENT-GUIDE.md          ← How to deploy THIS agent

```

### Relationship Diagram

```
Non-Technical User
    ↓
    CHOOSES ONE:
    ├─→ [Manual Path]
    │   └─→ Follows SETUP GUIDES/ with Claude Code skill
    │
    └─→ [Agent Path]
        └─→ Calls phone number → Agent takes over
            └─→ Agent USES existing SETUP GUIDES/ scripts
                └─→ Same outcome as manual path
```

---

## What Changed vs Existing System

### Nothing Changed ✅

- `SETUP GUIDES/openclaw-vm-setup/` - Untouched
- `SETUP GUIDES/openclaw-native-setup/` - Untouched
- `.claude/skills/openclaw-onboarding/` - Untouched
- All setup scripts (`setup.sh`, helper scripts) - Untouched
- Existing exec-approvals configs - Untouched

### What's New ✨

1. **New Directory**: `clawdbot-setup-agent/`
   - Self-contained agent system
   - Separate from manual setup guides
   - Can be removed without affecting manual setup

2. **Agent Config**: `clawdbot-setup-agent/agent-config.md`
   - AI agent personality and prompts
   - Only used when agent handles setup calls
   - Doesn't interfere with Claude Code skill

3. **SSH Automation**: `clawdbot-setup-agent/scripts/`
   - Temporary credential generation
   - Remote execution wrapper around existing scripts
   - Security-focused (2hr expiry, deny-by-default)

4. **Agent Exec-Approvals**: `clawdbot-setup-agent/config/agent-exec-approvals.json`
   - **Separate** from VM/native exec-approvals
   - Agent-specific security rules
   - More restrictive (agent can only run setup commands)

---

## Summary

| Aspect | Manual Setup | Agent Setup |
|--------|--------------|-------------|
| **Target User** | Technical / guided | Non-technical |
| **Interface** | Terminal commands | Phone conversation |
| **Automation** | User runs commands | Agent runs commands |
| **Scripts Used** | SETUP GUIDES/ directly | SETUP GUIDES/ via agent |
| **Security Config** | setup exec-approvals | agent exec-approvals |
| **Human Involvement** | Throughout | Only on escalation |
| **Can Remove Agent** | N/A | ✅ Manual still works |

---

**The agent is an optional enhancement, not a replacement. Your carefully-built manual setup system remains the foundation. 🎯**
