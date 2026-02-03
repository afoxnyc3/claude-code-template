# Parallel Agent Workflow

This project supports **parallel Claude Code agents**, each working on isolated branches.

> **Note**: This file is optional. Remove it if you're not using multi-agent workflows.

## Skills (Slash Commands)

Skills live in `.claude/skills/` and create slash commands:
- **Auto-invoked** by Claude when contextually relevant
- **Manual-only** when `disable-model-invocation: true` is set

| Command | Purpose | Auto-Invoke? |
|---------|---------|--------------|
| `/prime` | Load project context | Yes |
| `/work` | Analyze issues, launch parallel agents | No |
| `/ps` | Check parallel session status | Yes |
| `/progress` | Generate visual progress report | Yes |
| `/pr-check` | Validate PR readiness | No |
| `/review-pr` | Process PR review comments | No |
| `/session-wrap` | End-of-session documentation | No |

## Workflow Quick Reference

### Single-Agent Workflow
```
/prime → Work on tasks → /pr-check → Create PR → /session-wrap
```

### Multi-Agent Workflow
```
/work → Launches N parallel agents in worktrees
        ├── Agent 1: worktree + branch + assigned issues
        ├── Agent 2: worktree + branch + assigned issues
        └── ...

Monitor with: /ps (check status of all agents)

Each agent: /prime → Work → /pr-check → Create PR → /session-wrap

Staff Engineer merges last (handles docs, conflicts)
```

| When... | Run... |
|---------|--------|
| Starting a session | `/prime` (auto-loads) |
| Launching parallel agents | `/work` |
| Checking parallel status | `/ps` |
| Before creating a PR | `/pr-check` |
| After PR review comments | `/review-pr` |
| Generating status update | `/progress` |
| Ending a session | `/session-wrap` |

## Git Hooks

Claude Code hooks in `.claude/hooks/` run automatically:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-commit.sh` | Before `git commit` | Validates linting, blocks secrets |
| `post-commit.sh` | After `git commit` | Runs tests (non-blocking) |
| `pre-pr-lint.sh` | Before `gh pr create` | Full repo linting |

## Agent Ownership (Multi-Agent)

If using multiple agents, define ownership to prevent conflicts:

| Agent | Branch | Owns |
|-------|--------|------|
| {{AGENT_1}} | `feat/{{agent-1-branch}}` | `{{agent-1-dirs}}/` |
| {{AGENT_2}} | `feat/{{agent-2-branch}}` | `{{agent-2-dirs}}/` |
| Staff Engineer | `feat/docs` | `docs/`, `knowledge/`, `CLAUDE.md` |

## Conflict Avoidance Rules

1. **Only modify files in your owned directories**
2. **Never touch** files owned by other agents
3. **Shared files** (`pyproject.toml`, `docker-compose.yml`) - designate one agent as owner
4. **If you need something from another agent's domain**, document it in `docs/INTEGRATION_REQUESTS.md`

## Worktree Workflow

Parallel agents use git worktrees for branch isolation:

```bash
# Create worktree for a new agent
git worktree add ../{{project}}-{{suffix}} -b feat/{{branch-name}}

# List all worktrees
git worktree list

# Remove after merge
git worktree remove ../{{project}}-{{suffix}}
```
