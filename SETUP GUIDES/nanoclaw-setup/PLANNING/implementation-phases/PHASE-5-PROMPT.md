# Phase 5: Configure Assistant

## Objective
Set the trigger word, designate the main (admin) channel, and register WhatsApp groups.

## Steps

### 1. Set Trigger Word

The trigger word is what you type in WhatsApp to invoke Claude (default: `@Andy`).

```bash
# Set in environment (or .env file)
export ASSISTANT_NAME="Andy"
# Or for a different name:
export ASSISTANT_NAME="Claude"
```

Add to `.env` for persistence:
```bash
echo 'ASSISTANT_NAME="Andy"' >> ~/nanoclaw/.env
```

### 2. Designate Main Channel

The main channel is your admin control channel — typically your WhatsApp self-chat (messaging yourself). It has elevated privileges:
- Write to global memory
- Schedule tasks for any group
- View/manage all tasks
- Configure directory mounts for groups

**To set up**: Simply send a message to yourself in WhatsApp after NanoClaw is running. The first interaction from your self-chat becomes the main channel.

### 3. Register WhatsApp Groups

Groups must be explicitly registered before NanoClaw will respond in them.

**From the main channel:**
```
@Andy join the "Project Alpha" group
@Andy register the family chat group
```

**Or manually** — add entries to the database or `data/registered_groups.json`.

### 4. Create Global Memory

```bash
# Create the global CLAUDE.md that all groups can read
cat > ~/nanoclaw/groups/CLAUDE.md << 'EOF'
# Global Memory

## About Me
- Name: [Your name]
- Preferences: [Your preferences]

## Important Context
- [Anything all groups should know]
EOF
```

## Group Isolation

Each registered group gets:
- `groups/{name}/CLAUDE.md` — per-group memory (read/write)
- `groups/{name}/` — per-group file storage
- Separate Claude session history
- Isolated container execution

Groups **cannot** see each other's data.

## Success Criteria
- [ ] Trigger word configured
- [ ] Main channel identified (self-chat)
- [ ] At least one group registered (can be just the main channel)
- [ ] Global `CLAUDE.md` created
- [ ] Group folder structure exists
