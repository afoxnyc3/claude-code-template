#!/bin/bash
# Pre-commit hook: Run before Claude Code commits
# Prevents commits that don't meet quality standards

set -e

echo "Running pre-commit checks..."

# ---------------------------------------------------------------------------
# File Ownership Check (parallel agent isolation)
# ---------------------------------------------------------------------------
# AGENT_OWNS is a comma-separated list of path prefixes this agent may modify.
# Set automatically by start-parallel-sessions.sh from config owned_paths.
# Example: AGENT_OWNS="src/api/,tests/api/"

if [ -n "$AGENT_OWNS" ]; then
    echo "Checking file ownership (AGENT_OWNS=$AGENT_OWNS)..."

    # Build grep pattern from comma-separated prefixes
    OWNS_PATTERN=$(echo "$AGENT_OWNS" | tr ',' '\n' | sed 's/^/^/' | paste -sd'|' -)

    # Find staged files outside owned paths
    VIOLATIONS=$(git diff --cached --name-only | grep -v -E "$OWNS_PATTERN" || true)

    if [ -n "$VIOLATIONS" ]; then
        echo "BLOCKED: Agent modifying files outside owned paths."
        echo ""
        echo "Owned paths: $AGENT_OWNS"
        echo ""
        echo "Out-of-scope files:"
        echo "$VIOLATIONS" | sed 's/^/  - /'
        echo ""
        echo "If this is intentional, unset AGENT_OWNS and retry."
        exit 1
    fi

    echo "File ownership check passed."
fi

# Find changed Python files
CHANGED_PY=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' || true)

if [ -n "$CHANGED_PY" ]; then
    echo "Checking Python files..."

    # Ruff check
    if command -v ruff &> /dev/null; then
        ruff check $CHANGED_PY || {
            echo "BLOCKED: ruff check failed. Fix linting errors before committing."
            exit 1
        }
        ruff format --check $CHANGED_PY || {
            echo "BLOCKED: ruff format failed. Run 'ruff format .' before committing."
            exit 1
        }
    fi
fi

# Find changed TypeScript/JavaScript files (optional)
CHANGED_TS=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx|js|jsx)$' || true)

if [ -n "$CHANGED_TS" ]; then
    echo "Checking TypeScript/JavaScript files..."

    if command -v eslint &> /dev/null; then
        eslint $CHANGED_TS || {
            echo "BLOCKED: eslint failed. Fix linting errors before committing."
            exit 1
        }
    fi
fi

# Check for secrets
if git diff --cached --name-only | xargs grep -l -E '(sk-ant-|AKIA|password\s*=\s*["\047][^"\047]+["\047])' 2>/dev/null; then
    echo "BLOCKED: Potential secrets detected in staged files."
    exit 1
fi

# Check for .env files
if git diff --cached --name-only | grep -E '^\.env$|\.env\.local$|\.env\.prod'; then
    echo "BLOCKED: Attempting to commit .env file."
    exit 1
fi

echo "Pre-commit checks passed."
