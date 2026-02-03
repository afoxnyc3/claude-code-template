# AGENTS.md - LLM-Agnostic Project Instructions

This file provides project context for any LLM (GPT-4, Gemini, Llama, etc.).
For Claude Code-specific features, see `CLAUDE.md`.

## Project Overview

**{{PROJECT_NAME}}** is {{PROJECT_DESCRIPTION}}.

## Architecture Summary

- **{{COMPONENT_A}}**: {{COMPONENT_A_DESCRIPTION}}
- **{{COMPONENT_B}}**: {{COMPONENT_B_DESCRIPTION}}
- **Infrastructure**: {{INFRASTRUCTURE_DESCRIPTION}}

## Directory Structure

```
{{PROJECT_NAME}}/
├── {{COMPONENT_A_DIR}}/        # {{COMPONENT_A_DESCRIPTION}}
├── {{COMPONENT_B_DIR}}/        # {{COMPONENT_B_DESCRIPTION}}
├── knowledge/                   # Domain expertise documents
└── docs/                        # Architecture, ADRs
```

## Code Standards

### Python
- Python {{PYTHON_VERSION}}+
- Use `pyproject.toml` for dependencies (no `requirements.txt`)
- Type hints required on all functions
- Formatting: `ruff format`
- Linting: `ruff check`
- Testing: `pytest`

### TypeScript/JavaScript (if applicable)
- Node.js {{NODE_VERSION}}+
- Use `package.json` for dependencies
- Formatting: `prettier`
- Linting: `eslint`
- Testing: `vitest` or `jest`

### Terraform (if applicable)
- Terraform >= 1.5
- Use modules for reusability
- Environment separation: `environments/dev/`, `environments/prod/`
- Always include `outputs.tf` for cross-module references

### Docker (if applicable)
- Multi-stage builds where appropriate
- Non-root user in production images
- Security hardening: `read_only`, `no-new-privileges`, `cap_drop: ALL`

### Git
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`
- Commit frequently with descriptive messages

## Key Dependencies

### {{COMPONENT_A}}
{{COMPONENT_A_DEPENDENCIES}}

### {{COMPONENT_B}}
{{COMPONENT_B_DEPENDENCIES}}

## Environment Variables

### Required for All
```
{{REQUIRED_ENV_VARS}}
```

### {{COMPONENT_A}}
```
{{COMPONENT_A_ENV_VARS}}
```

### {{COMPONENT_B}}
```
{{COMPONENT_B_ENV_VARS}}
```

## Testing Strategy

- **Unit tests**: {{UNIT_TEST_STRATEGY}}
- **Integration tests**: {{INTEGRATION_TEST_STRATEGY}}
- **Local testing**: {{LOCAL_TEST_STRATEGY}}

## Acceptance Criteria

Before marking a task complete:
1. Code compiles/runs without errors
2. Unit tests pass
3. Linting passes (`ruff check`, `ruff format --check`)
4. Committed with conventional commit message

## Getting Help

- `docs/ARCHITECTURE.md` - Detailed design decisions
- `knowledge/` - Domain expertise documents
