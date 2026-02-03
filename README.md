# Claude Code Project Template

A battle-tested template for integrating Claude Code into software projects. Extracted from production patterns.

## Quick Start

### New Project (Recommended)

```bash
# Clone this template
git clone https://github.com/afoxnyc3/claude-code-template.git ~/Projects/claude-code-template

# Create a new project
~/Projects/claude-code-template/setup.sh my-new-project

# Start working
cd ~/Projects/my-new-project
claude
```

### Manual Setup

```bash
# Clone and copy to existing project
git clone https://github.com/afoxnyc3/claude-code-template.git /tmp/cct
cp -r /tmp/cct/{.claude,knowledge,docs,CLAUDE.md,AGENTS.md,.gitignore} /path/to/your/project/
chmod +x /path/to/your/project/.claude/hooks/*.sh
```

### Minimal Setup (Brownfield)

For adding to an existing project incrementally:

```bash
mkdir -p .claude/{hooks,rules} knowledge/staff-engineer-review

# Copy essentials only
curl -sL https://raw.githubusercontent.com/afoxnyc3/claude-code-template/main/CLAUDE.md > CLAUDE.md
curl -sL https://raw.githubusercontent.com/afoxnyc3/claude-code-template/main/.claude/rules/01-code-standards.md > .claude/rules/01-code-standards.md
curl -sL https://raw.githubusercontent.com/afoxnyc3/claude-code-template/main/.claude/hooks/pre-commit.sh > .claude/hooks/pre-commit.sh
curl -sL https://raw.githubusercontent.com/afoxnyc3/claude-code-template/main/.claude/settings.json > .claude/settings.json
curl -sL https://raw.githubusercontent.com/afoxnyc3/claude-code-template/main/knowledge/staff-engineer-review/SKILL.md > knowledge/staff-engineer-review/SKILL.md

chmod +x .claude/hooks/*.sh
```

---

## Setup Script

The `setup.sh` script automates new project creation:

```bash
./setup.sh <project-name> [target-directory]

# Examples
./setup.sh my-app                      # Creates ~/Projects/my-app
./setup.sh my-app /path/to/my-app      # Creates at specified path
./setup.sh my-app .                    # Creates in current directory
```

**What it does:**
1. Copies template files to target directory
2. Makes hooks executable
3. Replaces `{{PROJECT_NAME}}` placeholder
4. Initializes git repository
5. Creates initial commit

---

## Template Structure

```
project-root/
├── CLAUDE.md                    # Universal entry point (~90 lines)
├── AGENTS.md                    # LLM-agnostic alternative
├── .gitignore
│
├── .claude/
│   ├── settings.json            # Hook triggers
│   ├── settings.local.json      # Permission whitelist (gitignored)
│   ├── hooks/
│   │   ├── pre-commit.sh        # Lint + secret scan
│   │   ├── post-commit.sh       # Tests (non-blocking)
│   │   └── pre-pr-lint.sh       # Full lint before PR
│   ├── rules/
│   │   ├── 01-code-standards.md # Language/tool standards
│   │   ├── 02-self-review.md    # Knowledge navigation
│   │   └── 03-parallel-workflow.md # Multi-agent coordination
│   └── skills/
│       ├── prime/SKILL.md       # Load project context
│       ├── work/SKILL.md        # Launch parallel agents
│       ├── ps/SKILL.md          # Monitor parallel sessions
│       ├── progress/SKILL.md    # Status report
│       ├── pr-check/SKILL.md    # PR validation
│       ├── review-pr/SKILL.md   # Process PR comments
│       └── session-wrap/SKILL.md # Session documentation
│
├── knowledge/                   # Domain expertise
│   ├── staff-engineer-review/SKILL.md
│   ├── security-hardening/SKILL.md
│   └── production-readiness/SKILL.md
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── adr/                     # Decision records
│   └── sessions/                # Session summaries
│
└── src/                         # Your code (example component)
    └── CLAUDE.md                # Component-specific context
```

---

## Workflows

### Single-Agent Workflow

For most development work with one Claude Code instance:

```
/prime → Work on tasks → /pr-check → Create PR → /session-wrap
```

### Multi-Agent Parallel Workflow

For accelerating development with multiple Claude Code instances:

```
/work
  │
  ├── Fetches open GitHub issues
  ├── Groups by component (avoids merge conflicts)
  ├── Creates git worktrees for isolation
  ├── Launches N parallel Claude Code sessions (via tmux)
  │
  ▼
┌─────────────────────────────────────────────────────┐
│  Agent 1          Agent 2          Agent 3         │
│  (backend)        (frontend)       (infra)         │
│                                                     │
│  /prime           /prime           /prime          │
│  Work on #1,#2    Work on #3,#4    Work on #5      │
│  /pr-check        /pr-check        /pr-check       │
│  Create PR        Create PR        Create PR       │
│  /session-wrap    /session-wrap    /session-wrap   │
└─────────────────────────────────────────────────────┘
  │
  ├── Monitor with: /ps
  │
  ▼
Staff Engineer merges PRs in dependency order
```

**Requirements for `/work`:**
- GitHub CLI (`gh`) installed and authenticated
- tmux installed
- Component ownership defined in `.claude/rules/03-parallel-workflow.md`
- Open GitHub issues to work on

---

## Skills (Slash Commands)

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/prime` | Load project context | Start of session (auto) |
| `/work` | Launch parallel agents | When you have multiple issues to parallelize |
| `/ps` | Check parallel session status | Monitor running agents |
| `/progress` | Generate status report | Status updates, standups |
| `/pr-check` | Validate PR readiness | Before creating PR |
| `/review-pr` | Process PR comments | After receiving review feedback |
| `/session-wrap` | Document session | End of session |

---

## Customization After Setup

### 1. Edit CLAUDE.md

Replace remaining placeholders:

| Placeholder | Replace With |
|-------------|--------------|
| `{{PROJECT_DESCRIPTION}}` | One-line description |
| `{{COMPONENT_A}}` | First major component |
| `{{COMPONENT_A_DIR}}` | Directory path |
| `{{LINT_COMMAND}}` | e.g., `ruff check .` |
| `{{TEST_COMMAND}}` | e.g., `pytest` |

### 2. Configure Code Standards

Edit `.claude/rules/01-code-standards.md`:
- Set your Python/Node/Go version
- Configure linting/formatting tools
- Add project-specific conventions

### 3. Define Component Ownership

Edit `.claude/rules/03-parallel-workflow.md`:

```markdown
| Agent | Branch Pattern | Owns |
|-------|----------------|------|
| Backend | `feat/backend-*` | `src/api/`, `src/services/` |
| Frontend | `feat/frontend-*` | `src/components/`, `src/pages/` |
| Infrastructure | `feat/infra-*` | `terraform/`, `.github/` |
```

### 4. Add Domain Knowledge

Create knowledge skills for your project's domain:

```bash
mkdir -p knowledge/my-domain
# Copy template and customize
cp knowledge/staff-engineer-review/SKILL.md knowledge/my-domain/SKILL.md
```

---

## Hooks

| Hook | Trigger | Blocking? | Purpose |
|------|---------|-----------|---------|
| `pre-commit.sh` | `git commit` | Yes | Lint staged files, block secrets |
| `post-commit.sh` | After commit | No | Run tests, report failures |
| `pre-pr-lint.sh` | `gh pr create` | Yes | Full repo lint check |

---

## Greenfield vs Brownfield

### Greenfield (New Project)

```bash
./setup.sh my-new-project
cd ~/Projects/my-new-project
# Edit CLAUDE.md, then start working
claude
```

### Brownfield (Existing Project)

1. Start with just CLAUDE.md (map your architecture)
2. Add `.claude/rules/01-code-standards.md` (document existing conventions)
3. Add pre-commit hook (lint only at first)
4. Progressively add component CLAUDE.md files
5. Create knowledge skills from tribal knowledge
6. Add parallel workflow when ready for multi-agent

---

## Anti-Patterns

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Monolithic CLAUDE.md (500+ lines) | Hierarchical: root → component → knowledge |
| Duplicated instructions | Single source, cross-reference with `@` |
| No skill for repeating workflow | Encode as skill (< 200 lines) |
| Blocking hooks that are slow | Make slow checks non-blocking |
| All skills auto-invoke | Heavy workflows should be manual-only |

---

## Best Practices

1. **Keep CLAUDE.md small** - < 100 lines, a map not a manual
2. **Use knowledge skills for patterns** - Not inline in CLAUDE.md
3. **Reference with @** - `@knowledge/api-patterns/SKILL.md`
4. **Document sessions** - Use `/session-wrap` to capture learnings
5. **Define ownership** - Prevents merge conflicts in parallel work

---

## License

MIT - Use freely in your projects.
