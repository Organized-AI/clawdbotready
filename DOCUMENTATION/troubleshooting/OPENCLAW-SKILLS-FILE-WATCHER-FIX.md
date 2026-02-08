# OpenClaw Skills File Watcher - EMFILE Fix

**Critical Issue**: OpenClaw's file watcher exhausts file descriptors when skills contain large directories (Python venvs, node_modules, etc.)

**Date Discovered**: 2026-02-05
**Affected Versions**: OpenClaw 2026.2.1+
**Business Impact**: HIGH - Breaks Telegram bot functionality

---

## Problem Summary

OpenClaw Gateway opens a file descriptor for **EVERY file** in `~/.openclaw/skills/` when starting the file watcher. Skills with Python virtual environments or node_modules can contain **15,000+ files**, causing immediate EMFILE errors even with increased limits.

### Example

The `google-ads-pro` skill had a Python venv with **15,923 files**:
- Gateway opened **10,267 file descriptors** immediately on startup
- Even with limit increased to 65,536, this was unsustainable
- Bot failed with EMFILE errors on every message

---

## Root Cause

From gateway error log:

```
[skills] watcher error (/Users/openclaw/.openclaw/workspace): Error: EMFILE: too many open files, watch '/Users/openclaw/.openclaw/skills/google-ads-pro/venv/lib/python3.14/site-packages/...'
```

OpenClaw's file watcher (`chokidar` or similar) tries to watch:
- Every `.py` file in venv
- Every `.pyc` file in `__pycache__` directories
- Every package in `site-packages/`

This is **unnecessary** as venv files don't change during gateway operation.

---

## Immediate Fix

### Step 1: Identify Problematic Skills

```bash
# Count files in each skill
for skill in ~/.openclaw/skills/*/; do
    count=$(find "$skill" -type f 2>/dev/null | wc -l)
    echo "$count files in $(basename $skill)"
done | sort -rn
```

**Red flags:**
- More than 1,000 files = Warning
- More than 5,000 files = Critical

### Step 2: Move Large Skills Out

```bash
# Create backup directory
mkdir -p ~/.openclaw-backup/skills/

# Move problematic skills
mv ~/.openclaw/skills/google-ads-pro ~/.openclaw-backup/skills/

# Restart gateway
launchctl stop ai.openclaw.gateway
sleep 3
launchctl start ai.openclaw.gateway
```

### Step 3: Verify Fix

```bash
# Check file descriptors (should be under 100)
lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l

# Monitor stability
for i in {1..5}; do
    echo "$(date): $(lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l) FDs"
    sleep 5
done
```

---

## Long-Term Solutions

### Option 1: Exclude Patterns (Recommended)

If OpenClaw supports ignore patterns in file watcher config, add:

```json
{
  "skills": {
    "watcherIgnore": [
      "**/venv/**",
      "**/node_modules/**",
      "**/__pycache__/**",
      "**/*.pyc",
      "**/site-packages/**"
    ]
  }
}
```

**Location**: `~/.openclaw/openclaw.json`

### Option 2: Symlink Strategy

Keep skills in a different location and symlink only the essential files:

```bash
# Move skill to external location
mv ~/.openclaw/skills/google-ads-pro ~/external-skills/

# Create symlink to just the main files (not venv)
cd ~/.openclaw/skills/
mkdir google-ads-pro
cd google-ads-pro
ln -s ~/external-skills/google-ads-pro/*.py .
ln -s ~/external-skills/google-ads-pro/config ./
```

### Option 3: Disable File Watcher

If skills don't need hot-reload:

```json
{
  "skills": {
    "watchEnabled": false
  }
}
```

**Trade-off**: Must restart gateway to pick up skill changes.

---

## Prevention Checklist

Before adding a new skill:

- [ ] Check file count: `find ~/.openclaw/skills/NEW_SKILL -type f | wc -l`
- [ ] If > 1,000 files, investigate why
- [ ] Avoid committing venv, node_modules, or build artifacts
- [ ] Use `.gitignore` patterns in skill directory
- [ ] Test gateway startup after adding skill
- [ ] Monitor file descriptor count: `lsof -p $(pgrep openclaw-gateway) | wc -l`

---

## Automated Detection

Add this check to your health monitor:

```bash
check_skill_file_counts() {
    log "🔍 Checking for skills with excessive files..."

    for skill_dir in ~/.openclaw/skills/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            file_count=$(find "$skill_dir" -type f 2>/dev/null | wc -l)

            if [ "$file_count" -gt 5000 ]; then
                log_error "Skill '$skill_name' has $file_count files (critical)"
                log_alert "Skill with excessive files detected: $skill_name ($file_count files)"
            elif [ "$file_count" -gt 1000 ]; then
                log_warning "Skill '$skill_name' has $file_count files (warning)"
            fi
        fi
    done
}
```

---

## Recovery Procedure

If bot stops responding with EMFILE errors:

1. **Check file descriptors**:
   ```bash
   lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l
   ```
   If > 1,000, proceed to step 2.

2. **Identify culprit**:
   ```bash
   for skill in ~/.openclaw/skills/*/; do
       echo "$(find "$skill" -type f | wc -l) - $(basename $skill)"
   done | sort -rn | head -5
   ```

3. **Emergency fix**:
   ```bash
   # Move problematic skill
   mkdir -p ~/.openclaw-backup/skills/
   mv ~/.openclaw/skills/[PROBLEMATIC_SKILL] ~/.openclaw-backup/skills/

   # Restart
   launchctl stop ai.openclaw.gateway && sleep 3 && launchctl start ai.openclaw.gateway
   ```

4. **Verify**:
   ```bash
   # Wait for startup
   sleep 10

   # Check FDs (should be under 100)
   lsof -p $(pgrep openclaw-gateway) | wc -l

   # Test bot
   # Send message to @SAMyosin_bot
   ```

---

## Case Study: google-ads-pro Skill

**Before Fix**:
- Files in skill: **15,923**
- File descriptors: **10,267**
- Gateway status: Failing (EMFILE on every message)
- Bot functionality: **Broken**

**After Fix**:
- Moved skill to `~/.openclaw-backup/skills/google-ads-pro`
- File descriptors: **56**
- Gateway status: **Healthy**
- Bot functionality: **Working**

**Time to diagnose and fix**: 10 minutes
**Downtime**: 13 seconds (restart)

---

## Related Issues

This is separate from the LaunchAgent file descriptor limit issue. You need BOTH fixes:

1. **LaunchAgent Limits** ([EMFILE Troubleshooting](./OPENCLAW-EMFILE-TROUBLESHOOTING.md))
   - Increases limit from 256 to 65,536
   - Prevents hitting system limits

2. **Skills File Watcher** (this document)
   - Prevents gateway from opening thousands of FDs
   - Addresses root cause of file descriptor usage

**Both are required for production deployments.**

---

## Recommendations for OpenClaw Team

1. **Add ignore patterns** to file watcher by default:
   - `**/venv/**`
   - `**/node_modules/**`
   - `**/__pycache__/**`
   - `**/*.pyc`

2. **Warn on skill installation** if file count > 1,000

3. **Add monitoring** for file descriptor usage:
   - Log warning if FDs > 1,000
   - Restart with error if FDs > 10,000

4. **Document best practices** for skill development:
   - Don't commit venv or node_modules
   - Use `.gitignore` in skill directories
   - Keep skills lean

---

## Quick Reference

```bash
# Check current FD usage
lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l

# Find problematic skills
for s in ~/.openclaw/skills/*/; do
    echo "$(find "$s" -type f 2>/dev/null | wc -l) - $(basename $s)"
done | sort -rn

# Emergency fix
mkdir -p ~/.openclaw-backup/skills/
mv ~/.openclaw/skills/[SKILL_NAME] ~/.openclaw-backup/skills/
launchctl stop ai.openclaw.gateway && sleep 3 && launchctl start ai.openclaw.gateway

# Verify fix
sleep 10 && lsof -p $(pgrep openclaw-gateway) 2>/dev/null | wc -l
```

---

**Last Updated**: 2026-02-05
**OpenClaw Version**: 2026.2.1
**Status**: ✅ FIXED
**Business Impact**: RESOLVED - Bot functional after fix
