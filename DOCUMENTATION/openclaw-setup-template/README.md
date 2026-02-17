# OpenClaw Client Setup Template

**What this is:** A complete set of workspace documents for deploying OpenClaw to a new client's Mac Mini. Copy this entire directory as the starting point for every new client install, then customize each file with the client's specifics.

## File Structure & Purpose

| File | Purpose | When to Customize |
|------|---------|-------------------|
| `AGENTS.md` | Agent behavior rules, safety defaults, session protocol | Rarely — core framework stays the same |
| `BOOTSTRAP.md` | First-run identity conversation script | Rarely — guides the agent's "birth" |
| `BOOT.md` | Startup task instructions (empty by default) | After initial setup — add scheduled startup tasks |
| `IDENTITY.md` | Agent's name, creature type, vibe, emoji | During first conversation with client |
| `SOUL.md` | Personality, tone, boundaries, continuity rules | Customize vibe section per client preference |
| `USER.md` | Client bio, role, communication preferences | **Always** — this is 100% client-specific |
| `COMPANIES.md` | Deep operational context on client's businesses | **Always** — business-specific intel |
| `MEMORY.md` | Long-term memory (starts empty) | Agent populates over time |
| `TOOLS.md` | Environment-specific tool config notes | After integrations are configured |
| `HEARTBEAT.md` | Scheduled agent tasks (morning briefing, etc.) | Customize schedule per client needs |
| `STRATEGY-DESK.md` | Active priorities, open decisions, next actions | **Always** — the client's operating context |
| `BRAND-NARRATIVE.md` | Brand story, positioning, public narrative | If client needs brand/content support |
| `GTM-STRATEGY.md` | Go-to-market strategy and revenue engine | If client needs GTM/sales support |
| `SCOPE.md` | Project scope, system architecture, build checklist | **Always** — defines what's being built |

## Setup Workflow

1. **Copy this directory** to the client's OpenClaw workspace
2. **Fill in USER.md first** — the agent needs to know who it's working for
3. **Fill in COMPANIES.md** — operational context for the businesses
4. **Fill in STRATEGY-DESK.md** — what's live, what's next
5. **Fill in SCOPE.md** — the system being built and its components
6. **Customize SOUL.md** — match the client's communication style
7. **Customize HEARTBEAT.md** — set the daily/weekly schedule
8. **Leave BOOTSTRAP.md intact** — the agent uses it on first run, then deletes it
9. **Leave IDENTITY.md empty** — the agent fills this during first conversation
10. **Optional:** Add BRAND-NARRATIVE.md and GTM-STRATEGY.md if applicable

## Notes

- Files marked with `<!-- TEMPLATE: ... -->` comments contain placeholder text to replace
- The agent reads SOUL.md, USER.md, MEMORY.md on every session start
- STRATEGY-DESK.md should be updated regularly — stale context = blind agent
- HEARTBEAT.md runs in SANDBOX mode by default (read/draft only, nothing auto-sends)
