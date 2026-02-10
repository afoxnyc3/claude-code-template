#!/bin/bash
# Claude Code Brownfield Setup Script
# Adds Claude Code scaffolding to an existing project without overwriting anything
#
# Usage: ./setup-brownfield.sh /path/to/existing/project

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory (where template lives)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target project
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo -e "${CYAN}Claude Code Brownfield Setup${NC}"
echo "Target: $TARGET_DIR"
echo ""

# Verify it's an existing project
if [ ! -d "$TARGET_DIR/.git" ] && [ ! -f "$TARGET_DIR/package.json" ] && [ ! -f "$TARGET_DIR/pyproject.toml" ]; then
    echo -e "${YELLOW}Warning: This doesn't look like an existing project.${NC}"
    echo "For new projects, use: ./setup.sh <project-name>"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check what already exists
echo -e "${CYAN}Analyzing existing project...${NC}"

HAS_CLAUDE_MD=false
HAS_CLAUDE_DIR=false
HAS_KNOWLEDGE=false

[ -f "$TARGET_DIR/CLAUDE.md" ] && HAS_CLAUDE_MD=true
[ -d "$TARGET_DIR/.claude" ] && HAS_CLAUDE_DIR=true
[ -d "$TARGET_DIR/knowledge" ] && HAS_KNOWLEDGE=true

echo "  CLAUDE.md exists: $HAS_CLAUDE_MD"
echo "  .claude/ exists: $HAS_CLAUDE_DIR"
echo "  knowledge/ exists: $HAS_KNOWLEDGE"
echo ""

# Function to safely copy (don't overwrite)
safe_copy() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ]; then
        echo -e "  ${YELLOW}SKIP${NC} $dest (already exists)"
        return 1
    else
        cp -r "$src" "$dest"
        echo -e "  ${GREEN}ADD${NC}  $dest"
        return 0
    fi
}

# Function to safely create directory
safe_mkdir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        return 0
    else
        mkdir -p "$dir"
        echo -e "  ${GREEN}CREATE${NC} $dir/"
    fi
}

echo -e "${CYAN}Adding Claude Code scaffolding...${NC}"

# Create directories
safe_mkdir "$TARGET_DIR/.claude"
safe_mkdir "$TARGET_DIR/.claude/hooks"
safe_mkdir "$TARGET_DIR/.claude/rules"
safe_mkdir "$TARGET_DIR/.claude/skills"
safe_mkdir "$TARGET_DIR/.claude/agents"
safe_mkdir "$TARGET_DIR/knowledge"
safe_mkdir "$TARGET_DIR/docs"
safe_mkdir "$TARGET_DIR/docs/adr"
safe_mkdir "$TARGET_DIR/docs/sessions"
safe_mkdir "$TARGET_DIR/scripts"
safe_mkdir "$TARGET_DIR/scripts/configs"
safe_mkdir "$TARGET_DIR/scripts/configs/archive"

# Copy hooks (these are safe - they only run on Claude Code actions)
echo ""
echo -e "${CYAN}Adding hooks...${NC}"
safe_copy "$TEMPLATE_DIR/.claude/hooks/pre-commit.sh" "$TARGET_DIR/.claude/hooks/pre-commit.sh"
safe_copy "$TEMPLATE_DIR/.claude/hooks/post-commit.sh" "$TARGET_DIR/.claude/hooks/post-commit.sh"
safe_copy "$TEMPLATE_DIR/.claude/hooks/pre-pr-lint.sh" "$TARGET_DIR/.claude/hooks/pre-pr-lint.sh"
safe_copy "$TEMPLATE_DIR/.claude/hooks/auto-format.sh" "$TARGET_DIR/.claude/hooks/auto-format.sh"

# Make hooks executable
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# Copy settings (if not exists)
echo ""
echo -e "${CYAN}Adding configuration...${NC}"
safe_copy "$TEMPLATE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
safe_copy "$TEMPLATE_DIR/.claude/settings.local.json.example" "$TARGET_DIR/.claude/settings.local.json.example"

# Copy rules
echo ""
echo -e "${CYAN}Adding rules...${NC}"
safe_copy "$TEMPLATE_DIR/.claude/rules/01-code-standards.md" "$TARGET_DIR/.claude/rules/01-code-standards.md"
safe_copy "$TEMPLATE_DIR/.claude/rules/02-self-review.md" "$TARGET_DIR/.claude/rules/02-self-review.md"
# Skip parallel workflow by default for brownfield - it's optional
if [ ! -f "$TARGET_DIR/.claude/rules/03-parallel-workflow.md" ]; then
    echo -e "  ${YELLOW}SKIP${NC} 03-parallel-workflow.md (add manually if needed for multi-agent)"
fi

# Copy essential skills
echo ""
echo -e "${CYAN}Adding skills...${NC}"
for skill in init prime progress pr-check review-pr session-wrap work ps; do
    safe_mkdir "$TARGET_DIR/.claude/skills/$skill"
    safe_copy "$TEMPLATE_DIR/.claude/skills/$skill/SKILL.md" "$TARGET_DIR/.claude/skills/$skill/SKILL.md"
done

# Copy agents
echo ""
echo -e "${CYAN}Adding subagents...${NC}"
safe_copy "$TEMPLATE_DIR/.claude/agents/code-reviewer.md" "$TARGET_DIR/.claude/agents/code-reviewer.md"
safe_copy "$TEMPLATE_DIR/.claude/agents/researcher.md" "$TARGET_DIR/.claude/agents/researcher.md"
safe_copy "$TEMPLATE_DIR/.claude/agents/test-runner.md" "$TARGET_DIR/.claude/agents/test-runner.md"

# Copy knowledge (only if directory is empty or doesn't exist)
echo ""
echo -e "${CYAN}Adding knowledge skills...${NC}"
safe_mkdir "$TARGET_DIR/knowledge/staff-engineer-review"
safe_copy "$TEMPLATE_DIR/knowledge/staff-engineer-review/SKILL.md" "$TARGET_DIR/knowledge/staff-engineer-review/SKILL.md"
safe_mkdir "$TARGET_DIR/knowledge/security-hardening"
safe_copy "$TEMPLATE_DIR/knowledge/security-hardening/SKILL.md" "$TARGET_DIR/knowledge/security-hardening/SKILL.md"
safe_mkdir "$TARGET_DIR/knowledge/production-readiness"
safe_copy "$TEMPLATE_DIR/knowledge/production-readiness/SKILL.md" "$TARGET_DIR/knowledge/production-readiness/SKILL.md"

# Copy parallel session scripts
echo ""
echo -e "${CYAN}Adding parallel session scripts...${NC}"
safe_copy "$TEMPLATE_DIR/scripts/start-parallel-sessions.sh" "$TARGET_DIR/scripts/start-parallel-sessions.sh"
safe_copy "$TEMPLATE_DIR/scripts/parallel-session-status.sh" "$TARGET_DIR/scripts/parallel-session-status.sh"
safe_copy "$TEMPLATE_DIR/scripts/parallel-sessions.json" "$TARGET_DIR/scripts/parallel-sessions.json"
safe_copy "$TEMPLATE_DIR/scripts/configs/.gitignore" "$TARGET_DIR/scripts/configs/.gitignore"

# Make scripts executable
chmod +x "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true

# Copy docs templates (only if not exists)
echo ""
echo -e "${CYAN}Adding documentation templates...${NC}"
safe_copy "$TEMPLATE_DIR/docs/adr/0000-template.md" "$TARGET_DIR/docs/adr/0000-template.md"
safe_copy "$TEMPLATE_DIR/docs/adr/README.md" "$TARGET_DIR/docs/adr/README.md"

# Handle CLAUDE.md specially
echo ""
echo -e "${CYAN}CLAUDE.md setup...${NC}"
if [ "$HAS_CLAUDE_MD" = true ]; then
    echo -e "  ${YELLOW}EXISTS${NC} CLAUDE.md - keeping your existing file"
    echo -e "  ${CYAN}TIP${NC}: Run /init inside Claude to analyze and update it"
else
    # Don't copy template CLAUDE.md - it has placeholders
    # Instead, create a minimal one that prompts to run /init
    cat > "$TARGET_DIR/CLAUDE.md" << 'CLAUDEMD'
# CLAUDE.md - Project Context for AI Agents

> Run `/init` to auto-generate context from your codebase.

## Project Overview

<!-- Describe your project here -->

## Quick Reference

### Commands
```bash
# Add your common commands here
```

## Hierarchical Context

Claude Code auto-loads:
- `.claude/rules/*.md` - Project-wide rules
- `[component]/CLAUDE.md` - Component-specific context (create as needed)
- `knowledge/` - Domain expertise
CLAUDEMD
    echo -e "  ${GREEN}ADD${NC}  CLAUDE.md (minimal - run /init to populate)"
fi

# Update .gitignore if it exists
echo ""
echo -e "${CYAN}Updating .gitignore...${NC}"
if [ -f "$TARGET_DIR/.gitignore" ]; then
    # Add Claude-specific ignores if not present
    if ! grep -q "settings.local.json" "$TARGET_DIR/.gitignore" 2>/dev/null; then
        echo "" >> "$TARGET_DIR/.gitignore"
        echo "# Claude Code local settings" >> "$TARGET_DIR/.gitignore"
        echo ".claude/settings.local.json" >> "$TARGET_DIR/.gitignore"
        echo -e "  ${GREEN}ADD${NC}  .claude/settings.local.json to .gitignore"
    else
        echo -e "  ${YELLOW}SKIP${NC} .gitignore already has Claude entries"
    fi
else
    safe_copy "$TEMPLATE_DIR/.gitignore" "$TARGET_DIR/.gitignore"
fi

# Summary
echo ""
echo -e "${GREEN}✓ Brownfield setup complete!${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. cd $TARGET_DIR"
echo "  2. claude"
echo "  3. Run /init to auto-generate CLAUDE.md content"
echo "  4. Review and customize .claude/rules/01-code-standards.md"
echo "  5. Commit the new files: git add .claude knowledge docs CLAUDE.md"
echo ""
echo -e "${CYAN}What was added:${NC}"
echo "  .claude/hooks/     - Git lifecycle hooks (with file ownership enforcement)"
echo "  .claude/rules/     - Auto-loaded project rules"
echo "  .claude/skills/    - Workflow skills (/init, /prime, /work, /ps, etc.)"
echo "  .claude/agents/    - Subagents (code-reviewer, researcher, test-runner)"
echo "  scripts/           - Parallel session launcher, status monitor, config template"
echo "  knowledge/         - Domain expertise skills"
echo "  docs/adr/          - Architecture decision records"
echo ""
echo -e "${YELLOW}Important:${NC} Run /init to analyze your codebase and generate proper CLAUDE.md content."
