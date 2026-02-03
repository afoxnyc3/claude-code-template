# Knowledge Navigation & Self-Review

## Before Writing ANY Code

Read the relevant knowledge docs in `knowledge/` directory:

| If Working On... | Read These Skills |
|------------------|-------------------|
| API endpoints | `fastapi-standards`, `production-readiness` |
| Database code | `db-patterns`, `security-hardening` |
| Infrastructure | `terraform-standards`, `security-hardening` |
| HTTP clients | `resilient-api-clients` |
| Authentication | `security-hardening` |
| New features | `staff-engineer-review` |
| Bug fixes | `staff-engineer-review` |

## Before Your FINAL Commit

**MANDATORY**: Run self-review against `@knowledge/staff-engineer-review/SKILL.md`

1. Read `knowledge/staff-engineer-review/SKILL.md`
2. Review every file you changed against the checklist
3. Fix any violations
4. Add tests for edge cases you missed
5. Then commit with message: `"feat: [description] - reviewed against standards"`

## Knowledge Directory Structure

```
knowledge/
├── staff-engineer-review/   # Code quality standards (ALL AGENTS)
├── security-hardening/      # Security requirements (ALL AGENTS)
├── production-readiness/    # Production checklist (ALL AGENTS)
├── [domain-specific]/       # Add domain skills as needed
└── ...
```

## Adding New Knowledge

When you identify a pattern worth documenting:

1. Create `knowledge/[domain]/SKILL.md`
2. Use the standard SKILL.md template (see existing examples)
3. Include ✅/❌ code examples
4. Add a persona ("You are a [role] who has experienced...")
5. Include a checklist for the domain
6. Update this lookup table
