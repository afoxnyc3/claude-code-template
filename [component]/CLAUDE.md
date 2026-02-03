# {{COMPONENT_NAME}} Component

{{COMPONENT_DESCRIPTION}}

## Knowledge References

Before modifying this component, read:
- `@knowledge/staff-engineer-review/SKILL.md` - Code quality standards
- `@knowledge/{{RELEVANT_SKILL}}/SKILL.md` - {{RELEVANT_SKILL_DESCRIPTION}}

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `{{DEP_1}}` | {{DEP_1_PURPOSE}} |
| `{{DEP_2}}` | {{DEP_2_PURPOSE}} |

## Environment Variables

```bash
# Required
{{REQUIRED_VAR_1}}={{EXAMPLE_VALUE_1}}

# Optional
{{OPTIONAL_VAR_1}}={{DEFAULT_VALUE_1}}
```

## Directory Structure

```
{{COMPONENT_DIR}}/
├── src/
│   └── {{package_name}}/
│       ├── __init__.py
│       ├── main.py           # Entry point
│       └── ...
├── tests/
│   ├── __init__.py
│   ├── conftest.py           # Fixtures
│   └── test_*.py
├── pyproject.toml
└── Dockerfile
```

## Testing

```bash
cd {{COMPONENT_DIR}}

# Run tests
pytest

# Run with coverage
pytest --cov={{package_name}}

# Lint
ruff check .
ruff format --check .
```

## Common Tasks

### Adding a new endpoint/feature
1. Read relevant knowledge docs
2. Write tests first (TDD)
3. Implement feature
4. Run `/pr-check` before PR

### Debugging
```bash
# Run with debug logging
LOG_LEVEL=DEBUG python -m {{package_name}}

# Run specific test
pytest tests/test_specific.py -v
```
