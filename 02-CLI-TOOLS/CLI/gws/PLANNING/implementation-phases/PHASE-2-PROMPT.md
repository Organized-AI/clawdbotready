# Phase 2 — OpenClaw Skills Integration

## Context
Read CLAUDE.md and PHASE-1-COMPLETE.md first.

## Tasks
1. Check if ~/.openclaw/skills/ directory exists, create if not
2. Run: `npx skills add https://github.com/googleworkspace/cli` to install all gws skills
   OR symlink: `ln -s $(npm root -g)/@googleworkspace/cli/skills/gws-* ~/.openclaw/skills/`
3. Verify skills are present: ls ~/.openclaw/skills/ | grep gws
4. Test a gws skill fires in OpenClaw (drive file list)
5. Document installed skills with descriptions in DOCUMENTATION/skills-inventory.md
6. Note which skills are most useful for BHT/Myosin client work

## Success Criteria
- [ ] gws-drive skill installed in OpenClaw
- [ ] gws-gmail skill installed in OpenClaw
- [ ] gws-calendar skill installed in OpenClaw
- [ ] DOCUMENTATION/skills-inventory.md written with all skill descriptions
