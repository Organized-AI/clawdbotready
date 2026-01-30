# Teleport Requirements Checklist

Detailed requirements and verification steps for successful teleport operations.

---

## Pre-Teleport Requirements Matrix

| Requirement | Check Command | Resolution |
|-------------|---------------|------------|
| Clean git state | `git status` | Stash, commit, or discard |
| Correct repository | `git remote -v` | Navigate to correct repo |
| Branch on remote | `git branch -r` | Push or fetch branch |
| Authenticated | `claude auth status` | Re-login if needed |

---

## 1. Clean Git State

### What It Means
Your working directory must have no uncommitted changes. This includes:
- Modified tracked files
- Staged but uncommitted changes
- Untracked files in tracked directories

### Verification

```bash
git status
```

**Clean state looks like:**
```
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

**Dirty state looks like:**
```
On branch main
Changes not staged for commit:
  modified:   src/app.ts

Untracked files:
  test.log
```

### Resolution Options

#### Option A: Stash Changes (Recommended)

```bash
# Stash everything including untracked
git stash push -u -m "Pre-teleport: $(date +%Y%m%d-%H%M%S)"

# After teleport, restore:
git stash pop
```

#### Option B: Quick Commit

```bash
git add -A
git commit -m "WIP: checkpoint before teleport"
```

#### Option C: Selective Stash

```bash
# Stash only specific files
git stash push -m "Pre-teleport" -- src/experimental.ts

# Or stash staged changes only
git stash push --staged -m "Pre-teleport staged"
```

#### Option D: Discard Changes (Destructive)

```bash
# Discard all changes (CAUTION: data loss)
git checkout -- .
git clean -fd
```

---

## 2. Correct Repository

### What It Means
You must run teleport from a checkout of the **same repository** as the web session. Forks are not considered the same repository.

### Verification

```bash
# Check your remotes
git remote -v

# Expected output matches web session repo:
origin  git@github.com:username/repo-name.git (fetch)
origin  git@github.com:username/repo-name.git (push)
```

### Common Issues

#### Working in a Fork

If you're in a fork but the web session used the upstream:

```bash
# Add upstream remote
git remote add upstream git@github.com:original-owner/repo-name.git

# You may need to clone the original repo instead
cd ..
git clone git@github.com:original-owner/repo-name.git
cd repo-name
```

#### Wrong Local Directory

```bash
# Find correct repo
find ~ -name ".git" -type d 2>/dev/null | xargs -I {} dirname {} | grep "repo-name"

# Navigate there
cd /path/to/correct/repo
```

#### Multiple Remotes

If you have multiple remotes and origin isn't the web session repo:

```bash
# List all remotes
git remote -v

# Teleport checks origin by default
# Ensure origin points to the correct repo
git remote set-url origin git@github.com:correct/repo.git
```

---

## 3. Branch Availability

### What It Means
The branch from the web session must exist on the remote. Web sessions push their branches when work is complete.

### Verification

```bash
# Fetch latest from remote
git fetch --all

# List remote branches
git branch -r | grep "branch-name"
```

### Resolution

#### Branch Not Yet Pushed (Session Still Running)

Wait for the web session to complete. Check status:
```
/tasks
```

#### Branch Exists But Not Fetched

```bash
git fetch --all --prune
git branch -r
```

#### Branch Name Unknown

Check `/tasks` for the session details, or look in the web interface for the branch name.

---

## 4. Account Authentication

### What It Means
You must be logged into the same Claude.ai account in your terminal as was used for the web session.

### Verification

```bash
claude auth status
```

**Expected output:**
```
Logged in as: your-email@example.com
Organization: Your Org (if applicable)
```

### Resolution

#### Not Logged In

```bash
claude auth login
```

Follow the browser authentication flow.

#### Wrong Account

```bash
# Log out first
claude auth logout

# Log in with correct account
claude auth login
```

#### Enterprise/Team Accounts

Ensure you're logging into the correct organization:

```bash
claude auth login --org your-org-slug
```

---

## Quick Pre-Teleport Script

Run this before teleporting to verify all requirements:

```bash
#!/bin/bash
echo "=== Teleport Readiness Check ==="

echo -e "\n1. Git State:"
if [ -z "$(git status --porcelain)" ]; then
    echo "   ✓ Clean"
else
    echo "   ✗ Dirty - run: git stash push -u -m 'pre-teleport'"
    git status --short
fi

echo -e "\n2. Repository:"
echo "   Origin: $(git remote get-url origin 2>/dev/null || echo 'Not set')"

echo -e "\n3. Branch:"
echo "   Current: $(git branch --show-current)"
echo "   Tracking: $(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo 'None')"

echo -e "\n4. Auth:"
claude auth status 2>/dev/null || echo "   Run: claude auth login"

echo -e "\n=== End Check ==="
```

Save as `teleport-check.sh` and run before teleporting.

---

## Network Requirements

While not strictly required, these network conditions help:

| Requirement | Purpose |
|-------------|---------|
| Internet access | Fetch branches, authenticate |
| GitHub/GitLab access | Pull web session branch |
| claude.ai access | Session metadata |

If behind a corporate firewall, ensure these domains are accessible:
- `github.com` (or your git host)
- `api.anthropic.com`
- `claude.ai`

---

## Post-Teleport Verification

After successful teleport, verify:

```bash
# Correct branch
git branch --show-current

# Latest changes present
git log --oneline -5

# No conflicts with your work
git status
```

Then continue with your workflow:
```
/status    # Orient yourself
/verify    # Check the work (if using Boris)
```
