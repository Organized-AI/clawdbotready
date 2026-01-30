# Teleport Troubleshooting Guide

Extended troubleshooting for teleport issues beyond the basics covered in SKILL.md.

---

## Error Categories

| Category | Common Causes |
|----------|---------------|
| Git State | Uncommitted changes, conflicts |
| Repository | Wrong repo, fork vs original |
| Branch | Not pushed, not fetched, diverged |
| Auth | Wrong account, expired session |
| Network | Firewall, proxy issues |
| Session | Expired, still running, not found |

---

## Git State Issues

### Error: "You have uncommitted changes"

**Full Error:**
```
Cannot teleport: working directory has uncommitted changes.
Would you like to stash them? [y/n]
```

**Solutions:**

1. **Accept the prompt** - Say yes to stash automatically

2. **Manual stash with message:**
   ```bash
   git stash push -u -m "teleport-$(date +%s)"
   ```

3. **Commit if changes are ready:**
   ```bash
   git add -A && git commit -m "WIP: pre-teleport save"
   ```

4. **Review changes first:**
   ```bash
   git diff                    # Unstaged changes
   git diff --staged           # Staged changes
   git status                  # Overview
   ```

---

### Error: "Merge conflict in progress"

**Full Error:**
```
Cannot teleport: repository has unresolved merge conflicts.
```

**Solution:**

```bash
# See conflicted files
git diff --name-only --diff-filter=U

# Option 1: Abort the merge
git merge --abort

# Option 2: Resolve conflicts
# Edit conflicted files, then:
git add <resolved-files>
git commit -m "Resolve merge conflicts"
```

---

### Error: "Rebase in progress"

**Solution:**

```bash
# Option 1: Abort rebase
git rebase --abort

# Option 2: Continue rebase
git rebase --continue

# Option 3: Skip problematic commit
git rebase --skip
```

---

## Repository Issues

### Error: "Repository mismatch"

**Full Error:**
```
Cannot teleport: current repository does not match session repository.
Session repo: github.com/org/project
Current repo: github.com/user/project-fork
```

**Solutions:**

1. **Navigate to correct repo:**
   ```bash
   cd ~/projects/project   # Or wherever the correct repo is
   ```

2. **Clone the correct repo:**
   ```bash
   git clone git@github.com:org/project.git
   cd project
   ```

3. **If you need to work from your fork:**

   Unfortunately, you cannot teleport into a fork. Options:
   - Clone the original repo for teleport work
   - Use git worktree for isolation
   - Push changes from web, then cherry-pick to your fork

---

### Error: "Not a git repository"

**Solution:**

```bash
# Find the repo root
git rev-parse --show-toplevel 2>/dev/null || echo "Not in a repo"

# Navigate to repo root
cd $(git rev-parse --show-toplevel)

# Or clone if needed
git clone <repo-url>
```

---

### Error: "Detached HEAD state"

**Solution:**

```bash
# Check where you are
git log --oneline -1

# Checkout a branch
git checkout main

# Or create branch from current state
git checkout -b recovery-branch
```

---

## Branch Issues

### Error: "Branch not found on remote"

**Full Error:**
```
Cannot teleport: branch 'feature/xyz' not found on remote 'origin'.
```

**Possible Causes:**

1. **Session still running** - Branch hasn't been pushed yet
   ```
   /tasks   # Check session status
   ```

2. **Branch was deleted** - May have been merged and cleaned up
   ```bash
   # Check if merged to main
   git log main --oneline | grep "feature/xyz"
   ```

3. **Not fetched yet:**
   ```bash
   git fetch --all --prune
   git branch -r | grep "xyz"
   ```

---

### Error: "Branch has diverged"

**Full Error:**
```
Warning: local branch 'feature/xyz' has diverged from remote.
```

**Solutions:**

1. **Use remote version (discard local):**
   ```bash
   git checkout feature/xyz
   git reset --hard origin/feature/xyz
   ```

2. **Merge remote changes:**
   ```bash
   git checkout feature/xyz
   git merge origin/feature/xyz
   ```

3. **Rebase on remote:**
   ```bash
   git checkout feature/xyz
   git rebase origin/feature/xyz
   ```

---

### Error: "Checkout would overwrite local changes"

**Solution:**

```bash
# Stash changes
git stash push -u -m "before-teleport-checkout"

# Retry teleport or:
git checkout <branch>

# Restore changes
git stash pop
```

---

## Authentication Issues

### Error: "Session not found"

**Possible Causes:**

1. **Wrong account** - Logged into different Claude.ai account
   ```bash
   claude auth status
   claude auth logout
   claude auth login
   ```

2. **Session expired** - Web sessions have a lifespan
   - Check web interface for session list
   - Session may need to be restarted

3. **Session ID typo:**
   ```bash
   # List available sessions
   claude --teleport
   # Pick from interactive list
   ```

---

### Error: "Authentication expired"

**Solution:**

```bash
claude auth logout
claude auth login
```

Follow browser flow to re-authenticate.

---

### Error: "Organization access denied"

For enterprise/team accounts:

```bash
# Log in with specific org
claude auth login --org <org-slug>

# Or check current org
claude auth status
```

---

## Network Issues

### Error: "Connection timeout"

**Solutions:**

1. **Check internet connectivity:**
   ```bash
   ping github.com
   curl -I https://api.anthropic.com
   ```

2. **Behind proxy:**
   ```bash
   export HTTPS_PROXY=http://proxy:port
   export HTTP_PROXY=http://proxy:port
   ```

3. **VPN issues:**
   - Try disconnecting VPN
   - Or ensure VPN allows required domains

---

### Error: "SSL certificate error"

**Solutions:**

1. **Update certificates:**
   ```bash
   # macOS
   brew install ca-certificates

   # Linux
   sudo apt update && sudo apt install ca-certificates
   ```

2. **Corporate proxy with SSL inspection:**
   - Add corporate CA to trust store
   - Contact IT for certificate bundle

---

## Session Issues

### Session Shows as "Running" But Seems Stuck

**Actions:**

1. **Check web interface** - Open session on claude.ai
2. **Send a message** - Sometimes sessions need prompting
3. **Check for questions** - Claude may be waiting for input
4. **Cancel and restart** if truly stuck

---

### Session Completed But Can't Teleport

**Checklist:**

1. Did the session push its branch?
   ```bash
   git fetch --all
   git branch -r
   ```

2. Was there an error in the session?
   - Check web interface for error messages

3. Is the session from today?
   - Very old sessions may have expired

---

### Multiple Sessions for Same Task

If you accidentally created duplicate sessions:

1. Check `/tasks` for all sessions
2. Pick the most recent or most complete
3. Cancel others if still running

---

## Recovery Procedures

### Recover After Failed Teleport

```bash
# 1. Check current state
git status
git branch --show-current

# 2. Fetch all remote data
git fetch --all --prune

# 3. Find the branch from web session
git branch -r | grep "your-feature"

# 4. Manually checkout
git checkout -b your-feature origin/your-feature

# 5. Continue work normally
```

---

### Recover Stashed Changes After Teleport

```bash
# List all stashes
git stash list

# Find your pre-teleport stash
git stash show stash@{0}

# Apply it
git stash pop stash@{0}

# Or apply without removing from stash
git stash apply stash@{0}
```

---

### Recover From Accidental Branch Override

If teleport overwrote local changes you needed:

```bash
# Check reflog for lost commits
git reflog

# Find the commit before teleport
# Look for entries like "checkout: moving from..."

# Create branch from that point
git branch recovery-branch <commit-hash>

# Cherry-pick needed commits
git cherry-pick <commit-hash>
```

---

## Getting Help

If issues persist:

1. **Check Claude Code status:** https://status.anthropic.com
2. **GitHub issues:** https://github.com/anthropics/claude-code/issues
3. **Documentation:** https://code.claude.com/docs/en/claude-code-on-the-web

When reporting issues, include:
- Error message (full text)
- `claude --version` output
- `git status` output
- Operating system and version
