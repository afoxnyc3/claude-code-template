#!/bin/bash
# Claude Code Project Template Setup Script
# Usage: ./setup.sh <project-name> [target-directory]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory (where template lives)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
PROJECT_NAME="${1:-}"
TARGET_DIR="${2:-$HOME/Projects/$PROJECT_NAME}"

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name required${NC}"
    echo ""
    echo "Usage: ./setup.sh <project-name> [target-directory]"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh my-app                    # Creates ~/Projects/my-app"
    echo "  ./setup.sh my-app /path/to/my-app    # Creates at specified path"
    exit 1
fi

# Check if target already exists
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Warning: $TARGET_DIR already exists${NC}"
    read -p "Add template files to existing directory? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}Setting up Claude Code project: $PROJECT_NAME${NC}"
echo "Target: $TARGET_DIR"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy template files (excluding git, setup scripts, and [component] placeholder)
echo "Copying template files..."
rsync -av --exclude='.git' --exclude='setup.sh' --exclude='setup-brownfield.sh' --exclude='[component]' "$TEMPLATE_DIR/" "$TARGET_DIR/"

# Create component directory placeholder (renamed from [component])
mkdir -p "$TARGET_DIR/src"
cp "$TEMPLATE_DIR/[component]/CLAUDE.md" "$TARGET_DIR/src/CLAUDE.md"

# Make hooks executable
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh

# Make parallel session scripts executable
if [ -d "$TARGET_DIR/scripts" ]; then
    chmod +x "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true
fi

# Replace placeholders in key files
echo "Customizing for $PROJECT_NAME..."

# Function to replace placeholders
replace_placeholders() {
    local file="$1"
    if [ -f "$file" ]; then
        sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$file" 2>/dev/null || true
    fi
}

# Replace in main files
replace_placeholders "$TARGET_DIR/CLAUDE.md"
replace_placeholders "$TARGET_DIR/AGENTS.md"
replace_placeholders "$TARGET_DIR/docs/ARCHITECTURE.md"
replace_placeholders "$TARGET_DIR/docs/adr/README.md"
replace_placeholders "$TARGET_DIR/.claude/rules/03-parallel-workflow.md"
replace_placeholders "$TARGET_DIR/scripts/parallel-sessions.json"

# Initialize git if not already a repo
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "Initializing git repository..."
    cd "$TARGET_DIR"
    git init
    git add -A
    git commit -m "Initial commit from claude-code-template"
fi

echo ""
echo -e "${GREEN}✓ Project created successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Edit CLAUDE.md to describe your project"
echo "  3. Edit .claude/rules/01-code-standards.md for your stack"
echo "  4. Edit .claude/rules/03-parallel-workflow.md for component ownership"
echo "  5. Start Claude Code: claude"
echo ""
echo "Quick start:"
echo "  cd $TARGET_DIR && claude"
