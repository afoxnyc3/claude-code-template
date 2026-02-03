#!/bin/bash
# Post-commit hook: Run after Claude Code commits
# Automatically runs tests and reports status (non-blocking)

echo "Running post-commit validation..."

# Find the project root
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Look for test directories
if [ -d "$PROJECT_ROOT/tests" ] || [ -d "$PROJECT_ROOT/*/tests" ]; then
    echo "Running pytest..."

    # Find and run tests
    if command -v pytest &> /dev/null; then
        pytest --tb=short -q 2>&1 | tail -20

        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            echo ""
            echo "WARNING: Tests failed after commit. Consider fixing before PR."
        fi
    fi
fi

# TypeScript/JavaScript tests (optional)
if [ -f "$PROJECT_ROOT/package.json" ]; then
    if grep -q '"test"' "$PROJECT_ROOT/package.json"; then
        echo "Running npm test..."
        npm test 2>&1 | tail -20 || echo "WARNING: Tests had failures (non-blocking)"
    fi
fi

echo "Post-commit validation complete."
