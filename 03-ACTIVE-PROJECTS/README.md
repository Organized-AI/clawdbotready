# 03-ACTIVE-PROJECTS

**Tertiary Focus**: Other active work not directly related to OpenClaw deployment

This directory contains side projects and auxiliary development work that are in active development but separate from the primary OpenClaw deployment focus.

## Current Projects

### [`google-ads-cli/`](google-ads-cli/)
**Google Ads CLI Rebuild** - Lightweight Google Ads API access for OpenClaw agents

**Status**: Ready to Execute
**Priority**: High (business-critical bot functionality)
**Task File**: [`google-ads-cli/CLAUDE_TASK_google-ads-cli-rebuild.md`](google-ads-cli/CLAUDE_TASK_google-ads-cli-rebuild.md)

**Problem**: Original Python skill had 15,923 files in venv → caused OpenClaw file watcher to open 10,267 file descriptors → EMFILE error → Telegram bot broken

**Solution**: Rebuild as lightweight CLI tool using Node.js/TypeScript (1 file in skills/ vs 15,923)

**Estimated Time**: 3.75 hours

See task file for:
- Detailed execution checklist
- Phase-by-phase implementation
- Verification scripts
- Rollback plan
- Troubleshooting guide

---

## Adding New Projects

When adding new active projects to this directory:

1. Create project subdirectory: `03-ACTIVE-PROJECTS/project-name/`
2. Add project README with context
3. Include task specification if using phased execution
4. Update this README with project entry
5. Keep planning artifacts in project directory

---

## Relationship to Primary Focus

Projects in this directory are **not part of the core OpenClaw deployment workflow**. They are:
- Auxiliary development tasks
- Side projects that integrate with OpenClaw
- Experimental features
- One-off tooling needs

For core deployment work, see [`../01-OPENCLAW-DEPLOYMENT/`](../01-OPENCLAW-DEPLOYMENT/).

---

## Archive Policy

When a project in this directory is:
- ✅ **Deployed successfully** and stable for 24+ hours → Move to `.archive/`
- ❌ **Cancelled** or no longer needed → Move to `.archive/`
- 🔄 **On hold** but may resume → Keep in `03-ACTIVE-PROJECTS/` with status note

Archived projects go to [`../.archive/`](../.archive/) with dated folder name (e.g., `project-name-archived-2026-02-05`).
