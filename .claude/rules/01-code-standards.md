# Code Standards

These standards apply to all code in the {{PROJECT_NAME}} project.

## Python

- Python {{PYTHON_VERSION}}+
- Use `pyproject.toml` for dependencies (no `requirements.txt`)
- Type hints required on all functions
- Formatting: `ruff format`
- Linting: `ruff check`
- Testing: `pytest`

## TypeScript/JavaScript (if applicable)

- Node.js {{NODE_VERSION}}+
- Use `package.json` for dependencies
- Formatting: `prettier`
- Linting: `eslint`
- Testing: `vitest` or `jest`

## Terraform (if applicable)

- Terraform >= 1.5
- Use modules for reusability
- Environment separation: `environments/dev/`, `environments/prod/`
- Always include `outputs.tf` for cross-module references

## Docker (if applicable)

- Multi-stage builds where appropriate
- Non-root user in production images
- Security hardening: `read_only`, `no-new-privileges`, `cap_drop: ALL`
- See `@knowledge/docker-best-practices/SKILL.md` for patterns

## Git

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`
- Commit frequently with descriptive messages
- Push to your feature branch regularly
- Pre-commit hooks run linting and secret detection automatically
