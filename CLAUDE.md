# CLAUDE.md - Project Context for AI Agents

## Project Overview

**{{PROJECT_NAME}}** is {{PROJECT_DESCRIPTION}}.

## Architecture Summary

- **{{COMPONENT_A}}**: {{COMPONENT_A_DESCRIPTION}}
- **{{COMPONENT_B}}**: {{COMPONENT_B_DESCRIPTION}}
- **Infrastructure**: {{INFRASTRUCTURE_DESCRIPTION}}

---

## Hierarchical Context

Claude Code automatically loads context from:

### Project Rules (`.claude/rules/`)
Auto-loaded rules that apply project-wide:
- `01-code-standards.md` - Language, formatting, testing standards
- `02-self-review.md` - Knowledge navigation, mandatory review checklist
- `03-parallel-workflow.md` - Agent ownership, skills, conflict avoidance (optional)

### Component-Specific Context
When working in a component directory, read its local CLAUDE.md:
- `{{COMPONENT_A_DIR}}/CLAUDE.md` - {{COMPONENT_A}} patterns
- `{{COMPONENT_B_DIR}}/CLAUDE.md` - {{COMPONENT_B}} patterns

### Knowledge Directory
Domain expertise in `knowledge/` - see `.claude/rules/02-self-review.md` for the lookup table.

---

## Quick Reference

### Required Environment
```bash
{{REQUIRED_ENV_VARS}}
```

### Common Commands
```bash
# Lint
{{LINT_COMMAND}}

# Format
{{FORMAT_COMMAND}}

# Test
{{TEST_COMMAND}}

# Build
{{BUILD_COMMAND}}
```

---

## Testing Strategy

- **Unit tests**: {{UNIT_TEST_STRATEGY}}
- **Integration tests**: {{INTEGRATION_TEST_STRATEGY}}
- **Local testing**: {{LOCAL_TEST_STRATEGY}}

## Acceptance Criteria

Before marking a task complete:
1. Code compiles/runs without errors
2. Unit tests pass
3. Pre-commit hooks pass
4. Committed and pushed to feature branch

## Getting Help

- Check `docs/ARCHITECTURE.md` for detailed design decisions
- Check `knowledge/` for domain expertise
- For non-Claude LLMs, see `AGENTS.md` for LLM-agnostic instructions
