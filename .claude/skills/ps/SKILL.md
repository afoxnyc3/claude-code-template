---
name: ps
description: Check parallel session status - shows worktrees, git branches, PR readiness, and recommended merge order
allowed-tools: Bash, Read
---

# Parallel Session Status

Check the status of all parallel work sessions (worktrees, branches, PRs).

## Instructions

### Step 1: Discover Worktrees

```bash
# List all worktrees
git worktree list

# Get project name for pattern matching
PROJECT_NAME=$(basename $(git rev-parse --show-toplevel))
```

### Step 2: Check Each Worktree Status

```bash
# For each worktree, gather status
for wt in $(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2); do
    echo "=== $(basename $wt) ==="

    # Branch name
    git -C "$wt" branch --show-current

    # Uncommitted changes
    git -C "$wt" status --short | head -5

    # Unpushed commits
    git -C "$wt" log @{u}..HEAD --oneline 2>/dev/null || echo "(no upstream)"

    # Last commit
    git -C "$wt" log -1 --format="%ar: %s"
done
```

### Step 3: Check PR Status

```bash
# List open PRs
gh pr list --state open --json number,title,headRefName,statusCheckRollup \
  --jq '.[] | "\(.number) | \(.headRefName) | \(.title) | CI: \(.statusCheckRollup | map(select(.conclusion != null)) | if length > 0 then (if all(.conclusion == "SUCCESS") then "pass" else "fail" end) else "pending" end)"'
```

### Step 4: Check tmux Sessions (if using tmux)

```bash
# List tmux sessions
tmux list-sessions 2>/dev/null || echo "No tmux sessions"

# List panes in work session
tmux list-panes -t "${PROJECT_NAME}-work" -F "#{pane_index}: #{pane_current_path} (#{pane_current_command})" 2>/dev/null || true
```

### Step 5: Generate Status Report

Present the results in this format:

```markdown
## Parallel Session Status

**Project**: {{PROJECT_NAME}}
**Timestamp**: {{YYYY-MM-DD HH:MM}}

### Active Worktrees

| Worktree | Branch | Status | Last Commit |
|----------|--------|--------|-------------|
| ../{{project}}-backend | feat/backend-api | Clean | 5 min ago: "feat: add user endpoint" |
| ../{{project}}-frontend | feat/frontend-ui | 2 files | 12 min ago: "wip: dashboard" |

### Open PRs

| PR | Branch | Title | CI |
|----|--------|-------|-----|
| #42 | feat/backend-api | Add user management | pass |
| #43 | feat/frontend-ui | Dashboard components | pending |

### PR Readiness

| Branch | Uncommitted | Unpushed | Tests | Lint | Ready? |
|--------|-------------|----------|-------|------|--------|
| feat/backend-api | 0 | 0 | Pass | Pass | ✅ Ready |
| feat/frontend-ui | 2 | 3 | Pass | Pass | ❌ Push needed |

### Recommended Merge Order

Based on dependencies (customize for your project):

1. **feat/infrastructure** - No dependencies, provisions resources
2. **feat/backend-api** - Depends on infra
3. **feat/frontend-ui** - Depends on backend
4. **feat/docs** - Staff Engineer, merge last

### Action Items

- [ ] Push unpushed commits in `feat/frontend-ui`
- [ ] Create PR for `feat/backend-api`
- [ ] Wait for CI on PR #43
```

---

## PR Readiness Criteria

A branch is ready for PR when:

| Criterion | Check |
|-----------|-------|
| No uncommitted changes | `git status --short` is empty |
| All commits pushed | `git log @{u}..HEAD` is empty |
| Tests pass | `pytest` or `npm test` succeeds |
| Lint passes | `ruff check .` or `eslint .` succeeds |
| No WIP commits | No "wip:" commit messages |

---

## Merge Order Guidelines

Customize this for your project's dependency graph:

1. **Infrastructure** (`terraform/`, `.github/`) - First, enables everything else
2. **Shared libraries** (`packages/common/`) - Before consumers
3. **Backend/API** - Before frontend that consumes it
4. **Frontend** - After backend
5. **Documentation** (`docs/`) - Last, summarizes everything

---

## Troubleshooting

### Worktree shows stale status
```bash
# Fetch latest from remote
git -C ../{{project}}-{{suffix}} fetch origin
```

### tmux session not found
```bash
# List all sessions
tmux list-sessions

# Reattach to session
tmux attach -t {{session_name}}
```

### Branch diverged from main
```bash
# Rebase on main (in worktree)
cd ../{{project}}-{{suffix}}
git fetch origin main
git rebase origin/main
```

---

## Related Skills

- `/work` - Launch parallel sessions
- `/progress` - Overall project progress
- `/pr-check` - Validate single branch PR readiness
