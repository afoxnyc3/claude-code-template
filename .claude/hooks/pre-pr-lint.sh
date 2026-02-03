#!/bin/bash
# Pre-PR hook: Run before Claude Code creates a pull request
# Ensures linting passes to prevent CI failures

# Read JSON input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only validate for gh pr create commands
if ! echo "$COMMAND" | grep -qE 'gh\s+pr\s+create'; then
    exit 0  # Not a PR creation command, allow it
fi

echo "Pre-PR check: Validating linting before PR creation..." >&2

# Find project root
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
cd "$PROJECT_DIR" || exit 0

# Python linting with ruff
if command -v ruff &> /dev/null; then
    LINT_OUTPUT=$(ruff check . 2>&1) || {
        echo "BLOCKED: ruff check failed. Fix linting errors before creating PR:" >&2
        echo "" >&2
        echo "$LINT_OUTPUT" >&2
        echo "" >&2
        echo "Run 'ruff check . --fix' to auto-fix issues, then retry." >&2
        exit 2  # Block the PR creation
    }

    FORMAT_OUTPUT=$(ruff format --check . 2>&1) || {
        echo "BLOCKED: ruff format check failed. Files need formatting:" >&2
        echo "" >&2
        echo "$FORMAT_OUTPUT" >&2
        echo "" >&2
        echo "Run 'ruff format .' to fix formatting, then retry." >&2
        exit 2  # Block the PR creation
    }
fi

# TypeScript/JavaScript linting with eslint (optional)
if [ -f "package.json" ] && command -v eslint &> /dev/null; then
    ESLINT_OUTPUT=$(eslint . 2>&1) || {
        echo "BLOCKED: eslint failed. Fix linting errors before creating PR:" >&2
        echo "" >&2
        echo "$ESLINT_OUTPUT" >&2
        exit 2
    }
fi

echo "Pre-PR check passed: Linting OK" >&2
exit 0
