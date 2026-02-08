# 02-CLI-TOOLS

**Secondary Focus**: Workflow utilities and session management

This directory contains supporting CLI tools for Claude Code workflow management, session history tracking, and cross-machine synchronization.

## Contents

### [`CLI/`](CLI/)
Session management and synchronization tools

Tools for working with Claude Code sessions across multiple machines via iCloud:

- **`session-tools.sh`** - Session history management
  - List recent sessions
  - Search session content
  - Export session archives
  - Sync across machines

- **`claude-auto-sync.sh`** - Automatic iCloud synchronization
  - Background sync daemon
  - Conflict resolution
  - Session deduplication

See [`CLI/README.md`](CLI/README.md) for detailed usage instructions.

---

## Usage Examples

### List Recent Sessions
```bash
cd CLI
./session-tools.sh list
```

### Search Session Content
```bash
./session-tools.sh search "OpenClaw deployment"
```

### Sync Sessions to iCloud
```bash
./session-tools.sh sync
```

### Auto-Sync Setup
```bash
./claude-auto-sync.sh install  # Set up LaunchAgent
./claude-auto-sync.sh start    # Start background sync
```

---

## Relationship to OpenClaw

These tools are **not specific to OpenClaw deployment**. They provide general workflow utilities for:
- Managing long-running Claude Code sessions
- Syncing session history across development machines
- Searching through past session conversations
- Archiving session artifacts

For OpenClaw-specific tools, see [`../01-OPENCLAW-DEPLOYMENT/`](../01-OPENCLAW-DEPLOYMENT/).

---

## Integration with .claude-sessions/

These tools work with the [`../.claude-sessions/`](../.claude-sessions/) directory for session archival and synchronization across machines via iCloud Drive.
