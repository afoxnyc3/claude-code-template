---
name: work
description: Analyze GitHub issues, assign to parallel agents, and launch work sessions in isolated worktrees
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Grep, Glob, Task
---

# Work Command

Analyze open GitHub issues, determine parallelization opportunities, and launch 3-5 AI agents in isolated git worktrees.

## Overview

This skill orchestrates parallel development by:
1. Fetching open GitHub issues
2. Grouping them by component to avoid merge conflicts
3. Creating isolated git worktrees for each agent
4. Launching parallel Claude Code sessions

## Instructions

### Step 1: Gather Context

Read project context to understand component ownership:

```bash
# Read project configuration
cat CLAUDE.md
cat .claude/rules/03-parallel-workflow.md  # Component ownership table
```

### Step 2: Fetch Open Issues

```bash
# Get all open issues with details
gh issue list --state open --limit 50 --json number,title,labels,body,assignees

# Check existing PRs to avoid duplicate work
gh pr list --state open --json number,title,headRefName

# Check existing worktrees
git worktree list
```

### Step 3: Analyze Issues for Parallelization

For each issue, determine:

| Attribute | How to Determine |
|-----------|------------------|
| **Component** | Labels (e.g., `component:backend`), title keywords, or file paths mentioned |
| **Dependencies** | Parse body for "blocked by #N", "depends on #N", "after #N" |
| **Priority** | Labels (`priority:high`), age, or explicit priority field |
| **Complexity** | Simple (1-2 files), Medium (3-5 files), Complex (6+ files) |

### Step 4: Create Work Packages

Group issues into 3-5 work packages following these rules:

1. **One component per agent** - Prevents merge conflicts
2. **Related issues together** - Reduces context switching
3. **Include quick wins** - Each agent should have at least one small task
4. **Respect dependencies** - Blocked issues go to agent that unblocks them
5. **Balance workload** - Distribute complexity evenly

**Component Ownership** (customize in `03-parallel-workflow.md`):

```
# Example ownership mapping - CUSTOMIZE FOR YOUR PROJECT
backend/         → Backend Agent
frontend/        → Frontend Agent
infrastructure/  → Infrastructure Agent
docs/, knowledge/ → Staff Engineer Agent
```

### Step 5: Generate Agent Prompts

For each agent, create a detailed prompt:

```markdown
## Agent: {{AGENT_NAME}}

You are an autonomous AI agent working on {{PROJECT_NAME}}.

### CRITICAL: First Steps (DO NOT SKIP)

1. Read CLAUDE.md at the project root
2. Read relevant knowledge skills for your domain
3. Review existing patterns in your owned directories

### Your Assignment

**Branch**: feat/{{component}}-{{description}}
**Issues**: #{{N}}, #{{M}}, ...
**Owned Paths**: {{paths}}

### Issue Details

{{For each issue:}}
#### Issue #{{number}}: {{title}}

**Acceptance Criteria**:
{{criteria from issue body}}

**Implementation Notes**:
{{any technical guidance}}

---

### Validation Checklist

Before EACH commit:
- [ ] Linting passes (`ruff check .` or `eslint .`)
- [ ] Formatting passes (`ruff format --check .` or `prettier --check .`)
- [ ] Tests pass (`pytest` or `npm test`)
- [ ] No secrets committed

### Before Creating PR

1. Run `/pr-check` to validate readiness
2. Run `/session-wrap` to document your work
3. Create PR with `gh pr create`
4. Reference issues: "Fixes #N" or "Part of #N"

### Git Workflow

- Commit often with conventional commits (feat:, fix:, test:, docs:)
- Push after each logical unit of work
- Stay within your owned paths only

### START NOW

Begin by reading CLAUDE.md, then start on your first issue.
```

### Step 6: Setup Worktrees

For each agent, create an isolated worktree:

```bash
PROJECT_ROOT=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# For each agent
AGENT_SUFFIX="{{suffix}}"  # e.g., "backend", "frontend"
BRANCH="feat/{{component}}-{{description}}"
WORKTREE_PATH="../${PROJECT_NAME}-${AGENT_SUFFIX}"

# Create worktree if it doesn't exist
if ! git worktree list | grep -q "$WORKTREE_PATH"; then
    git worktree add "$WORKTREE_PATH" -b "$BRANCH"
    echo "Created worktree: $WORKTREE_PATH on branch $BRANCH"
else
    echo "Worktree exists: $WORKTREE_PATH"
    # Verify it's on the right branch
    git -C "$WORKTREE_PATH" checkout "$BRANCH" 2>/dev/null || true
fi
```

### Step 7: Launch Parallel Sessions

**Option A: tmux (Recommended)**

```bash
SESSION_NAME="${PROJECT_NAME}-work-$(date +%Y%m%d-%H%M)"

# Create tmux session
tmux new-session -d -s "$SESSION_NAME"

# For each agent, create a pane and launch Claude
WORKTREE_PATH="../${PROJECT_NAME}-{{suffix}}"
PROMPT="{{agent_prompt}}"

tmux split-window -t "$SESSION_NAME" -h
tmux send-keys -t "$SESSION_NAME" "cd $WORKTREE_PATH && claude --dangerously-skip-permissions" Enter
# Wait for Claude to start, then send prompt
sleep 3
tmux send-keys -t "$SESSION_NAME" "$PROMPT" Enter

# Attach to session for monitoring
tmux attach -t "$SESSION_NAME"
```

**Option B: Separate Terminal Windows**

```bash
# Generate launch script
cat > /tmp/launch-agents.sh << 'EOF'
#!/bin/bash
# Launch each agent in a new terminal window

{{FOR_EACH_AGENT}}
osascript -e 'tell app "Terminal" to do script "cd {{WORKTREE_PATH}} && claude --dangerously-skip-permissions -p \"{{PROMPT}}\""'
{{END_FOR_EACH}}
EOF

chmod +x /tmp/launch-agents.sh
/tmp/launch-agents.sh
```

### Step 8: Output Summary

Display the work session summary:

```markdown
## Work Session Launched

**Session**: {{PROJECT_NAME}}-work-{{timestamp}}
**Agents**: {{N}}

| Agent | Branch | Issues | Worktree |
|-------|--------|--------|----------|
| {{name}} | feat/{{branch}} | #{{issues}} | ../{{project}}-{{suffix}} |
| ... | ... | ... | ... |

### Monitoring

- Check status: `/ps` or `tmux list-panes -t {{session}}`
- View agent: `tmux select-pane -t {{session}}:0.{{N}}`
- Kill session: `tmux kill-session -t {{session}}`

### After Completion

1. Each agent creates their PR
2. Review PRs in dependency order
3. Staff Engineer merges last (handles docs, CLAUDE.md updates)

### Worktree Cleanup (after merge)

```bash
git worktree remove ../{{project}}-{{suffix}}
git branch -d feat/{{branch}}
```
```

---

## Agent Count Heuristics

| Open Issues | Recommended Agents |
|-------------|-------------------|
| 1-5 | 2 |
| 6-12 | 3 |
| 13-20 | 4 |
| 21+ | 5 |

Always include a Staff Engineer agent when there are documentation or knowledge updates needed.

---

## Conflict Avoidance Rules

**NEVER assign two agents to:**
- Same source directory
- Same configuration files
- Overlapping module paths

**Shared files** (`package.json`, `pyproject.toml`, `docker-compose.yml`):
- Assign to Infrastructure or Staff Engineer agent only
- Other agents must not modify these

---

## Error Handling

| Situation | Action |
|-----------|--------|
| No open issues | Report and suggest creating issues first |
| Worktree already exists | Reuse existing, verify correct branch |
| < 3 parallelizable issues | Run with 2 agents or work sequentially |
| All issues blocked | Identify and assign blocker-resolver first |
| Conflicting assignments | Re-analyze, split differently |

---

## Example Session

```
$ /work

Fetching issues... 12 open issues found
Analyzing parallelization opportunities...

Work Packages:
1. Backend Agent (4 issues): #23, #25, #28, #31
2. Frontend Agent (3 issues): #24, #26, #29
3. Infrastructure Agent (2 issues): #27, #30
4. Staff Engineer Agent (3 issues): #22, #32, #33

Creating worktrees...
✓ ../myproject-backend (feat/backend-api-improvements)
✓ ../myproject-frontend (feat/frontend-dashboard)
✓ ../myproject-infra (feat/infra-monitoring)
✓ ../myproject-staff (feat/docs-updates)

Launching tmux session: myproject-work-20260203-1430

Session launched! Use `/ps` to monitor progress.
```

---

## Required Setup

For this skill to work, ensure:

1. **GitHub CLI** installed and authenticated (`gh auth login`)
2. **tmux** installed (for parallel session management)
3. **Component ownership** defined in `.claude/rules/03-parallel-workflow.md`
4. **Git** configured with your credentials

---

## Customization

Edit the component ownership mapping in `.claude/rules/03-parallel-workflow.md` to match your project structure:

```markdown
| Agent | Branch Pattern | Owns |
|-------|----------------|------|
| Backend | `feat/backend-*` | `src/api/`, `src/services/` |
| Frontend | `feat/frontend-*` | `src/components/`, `src/pages/` |
| Infrastructure | `feat/infra-*` | `terraform/`, `.github/`, `docker/` |
| Staff Engineer | `feat/docs-*` | `docs/`, `knowledge/`, `*.md` |
```
