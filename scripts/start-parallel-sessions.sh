#!/bin/bash
#
# Start parallel Claude Code sessions in tmux panes
#
# Usage:
#   ./start-parallel-sessions.sh                    # Uses default config
#   ./start-parallel-sessions.sh ./my-config.json   # Uses custom config
#   ./start-parallel-sessions.sh --dry-run           # Preview only
#
# See: knowledge/parallel-sessions/ or .claude/rules/03-parallel-workflow.md

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${CLAUDE_LOGS_DIR:-$HOME/claude-logs}"

# Parse arguments - support both --config flag and positional argument
CONFIG_FILE=""
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --config|-c)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--config <config.json>] [--dry-run] [config.json]"
            echo ""
            echo "Options:"
            echo "  --config, -c  Path to config file"
            echo "  --dry-run, -n Preview what would launch without creating sessions"
            echo "  --help, -h    Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Use default config"
            echo "  $0 --config configs/my-session.json   # Use specific config"
            echo "  $0 configs/my-session.json            # Positional argument"
            echo "  $0 --dry-run configs/my-session.json  # Preview only"
            exit 0
            ;;
        *)
            # Positional argument (backwards compatible)
            if [[ -z "$CONFIG_FILE" ]]; then
                CONFIG_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Default to parallel-sessions.json if no config specified
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/parallel-sessions.json}"

# Resolve relative paths from script directory
if [[ ! "$CONFIG_FILE" = /* ]]; then
    CONFIG_FILE="$SCRIPT_DIR/$CONFIG_FILE"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Usage: $0 [--config <config.json>] [config.json]"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is required but not installed."
    echo "Install with: brew install tmux (macOS) or apt install tmux (Linux)"
    exit 1
fi

# -----------------------------------------------------------------------------
# Parse Configuration
# -----------------------------------------------------------------------------

PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "project")
SESSION=$(jq -r ".session_name // \"${PROJECT_NAME}-parallel\"" "$CONFIG_FILE")
DELAY=$(jq -r '.startup_delay_seconds // 2' "$CONFIG_FILE")
CLAUDE_FLAGS=$(jq -r '.claude_flags // ""' "$CONFIG_FILE")
PANE_COUNT=$(jq '.panes | length' "$CONFIG_FILE")

if [[ "$PANE_COUNT" -lt 1 ]]; then
    echo "Error: Config must define at least one pane"
    exit 1
fi

if [[ "$PANE_COUNT" -gt 9 ]]; then
    echo "Error: Maximum 9 panes supported"
    exit 1
fi

echo "Configuration:"
echo "  Session:    $SESSION"
echo "  Panes:      $PANE_COUNT"
echo "  Delay:      ${DELAY}s between launches"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  Mode:       DRY RUN (preview only)"
fi
echo ""

# -----------------------------------------------------------------------------
# Dry Run Preview
# -----------------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    SESSION PREVIEW (DRY RUN)                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "  %-4s %-20s %-30s %s\n" "PANE" "AGENT" "BRANCH" "OWNED PATHS"
    printf "  %-4s %-20s %-30s %s\n" "----" "-----" "------" "-----------"

    for i in $(seq 0 $((PANE_COUNT - 1))); do
        NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")
        DIR=$(jq -r ".panes[$i].directory" "$CONFIG_FILE")
        BRANCH=$(jq -r ".panes[$i].branch // \"(current)\"" "$CONFIG_FILE")
        OWNED=$(jq -r '(.panes['"$i"'].owned_paths // ["(none)"]) | join(", ")' "$CONFIG_FILE")
        DIR_EXISTS="ok"
        [[ ! -d "$DIR" ]] && DIR_EXISTS="MISSING"

        printf "  %-4s %-20s %-30s %s\n" "$i" "$NAME" "$BRANCH" "$OWNED"
        echo "       dir: $DIR [$DIR_EXISTS]"
    done

    echo ""
    echo "Claude flags: ${CLAUDE_FLAGS:-(none)}"
    echo "Log directory: $LOG_DIR"
    echo ""

    # Show prompt preview (first 120 chars of each)
    echo "Prompt previews:"
    for i in $(seq 0 $((PANE_COUNT - 1))); do
        NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")
        PROMPT=$(jq -r ".panes[$i].prompt" "$CONFIG_FILE")
        PREVIEW="${PROMPT:0:120}"
        echo "  [$i] $NAME: ${PREVIEW}..."
    done

    echo ""
    echo "To launch for real, run without --dry-run."
    exit 0
fi

# -----------------------------------------------------------------------------
# Validate Directories & Setup Logging
# -----------------------------------------------------------------------------

echo "Validating directories..."
for i in $(seq 0 $((PANE_COUNT - 1))); do
    DIR=$(jq -r ".panes[$i].directory" "$CONFIG_FILE")
    NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")

    if [[ ! -d "$DIR" ]]; then
        echo "Error: Directory for '$NAME' does not exist: $DIR"
        exit 1
    fi
done
echo "All directories valid."

# Create log directory
mkdir -p "$LOG_DIR"
echo "Logs: $LOG_DIR"
echo ""

# -----------------------------------------------------------------------------
# Generate Per-Agent Context Files
# -----------------------------------------------------------------------------

# Build agent summary for cross-agent awareness
AGENT_SUMMARY=""
for i in $(seq 0 $((PANE_COUNT - 1))); do
    A_NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")
    A_BRANCH=$(jq -r ".panes[$i].branch // \"(current)\"" "$CONFIG_FILE")
    A_OWNS=$(jq -r '(.panes['"$i"'].owned_paths // []) | join(", ")' "$CONFIG_FILE")
    AGENT_SUMMARY="${AGENT_SUMMARY}| ${A_NAME} | ${A_BRANCH} | ${A_OWNS} |\n"
done

echo "Generating per-agent context files..."
for i in $(seq 0 $((PANE_COUNT - 1))); do
    DIR=$(jq -r ".panes[$i].directory" "$CONFIG_FILE")
    NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")
    BRANCH=$(jq -r ".panes[$i].branch // \"(current)\"" "$CONFIG_FILE")
    OWNED=$(jq -r '(.panes['"$i"'].owned_paths // []) | join(", ")' "$CONFIG_FILE")

    AGENT_CONTEXT_FILE="$DIR/.claude-agent.md"

    cat > "$AGENT_CONTEXT_FILE" << AGENT_EOF
# Agent Context (auto-generated by start-parallel-sessions.sh)

## Your Identity

You are the **${NAME}** agent, working on branch \`${BRANCH}\`.

## File Ownership (ENFORCED)

You MUST only modify files under these paths:
${OWNED:-"(no restriction — ownership not configured for this agent)"}

The \`AGENT_OWNS\` env var is set and the pre-commit hook will BLOCK commits
that touch files outside your owned paths. Do not attempt to bypass this.

## Other Agents Running

Other agents are working in parallel. Do NOT modify their files.

| Agent | Branch | Owned Paths |
|-------|--------|-------------|
$(echo -e "$AGENT_SUMMARY")

## If You Need Something From Another Agent

1. Do NOT wait — continue with your other tasks
2. Document the request in \`docs/INTEGRATION_REQUESTS.md\`
3. The other agent or the human operator will handle it

## Standard Project Rules

All standard CLAUDE.md and .claude/rules/ instructions still apply.
Read CLAUDE.md first before starting any work.
AGENT_EOF

    echo "  [$i] $NAME -> $AGENT_CONTEXT_FILE"
done
echo ""

# -----------------------------------------------------------------------------
# Create tmux Session
# -----------------------------------------------------------------------------

# Kill existing session if present
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Get first pane's directory
FIRST_DIR=$(jq -r '.panes[0].directory' "$CONFIG_FILE")

# Create session with first pane
echo "Creating tmux session: $SESSION"
tmux new-session -d -s "$SESSION" -c "$FIRST_DIR" -n "parallel"

# -----------------------------------------------------------------------------
# Create Additional Panes
# -----------------------------------------------------------------------------

# Split strategy for up to 9 panes
if [[ "$PANE_COUNT" -ge 2 ]]; then
    DIR=$(jq -r '.panes[1].directory' "$CONFIG_FILE")
    tmux split-window -h -t "$SESSION:0.0" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 3 ]]; then
    DIR=$(jq -r '.panes[2].directory' "$CONFIG_FILE")
    tmux split-window -v -t "$SESSION:0.0" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 4 ]]; then
    DIR=$(jq -r '.panes[3].directory' "$CONFIG_FILE")
    tmux split-window -v -t "$SESSION:0.1" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 5 ]]; then
    DIR=$(jq -r '.panes[4].directory' "$CONFIG_FILE")
    tmux split-window -h -t "$SESSION:0.0" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 6 ]]; then
    DIR=$(jq -r '.panes[5].directory' "$CONFIG_FILE")
    tmux split-window -h -t "$SESSION:0.2" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 7 ]]; then
    DIR=$(jq -r '.panes[6].directory' "$CONFIG_FILE")
    tmux split-window -h -t "$SESSION:0.4" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 8 ]]; then
    DIR=$(jq -r '.panes[7].directory' "$CONFIG_FILE")
    tmux split-window -h -t "$SESSION:0.6" -c "$DIR"
fi

if [[ "$PANE_COUNT" -ge 9 ]]; then
    DIR=$(jq -r '.panes[8].directory' "$CONFIG_FILE")
    tmux split-window -v -t "$SESSION:0.4" -c "$DIR"
fi

# Apply tiled layout for even distribution
tmux select-layout -t "$SESSION" tiled

# -----------------------------------------------------------------------------
# Launch Claude Code Instances
# -----------------------------------------------------------------------------

echo ""
echo "Launching Claude Code instances..."

# Build pane index mapping after all splits
# tmux renumbers panes, so we query current state
PANE_IDS=($(tmux list-panes -t "$SESSION" -F '#{pane_index}' | sort -n))

for i in $(seq 0 $((PANE_COUNT - 1))); do
    NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")
    PROMPT=$(jq -r ".panes[$i].prompt" "$CONFIG_FILE")
    PANE_ID="${PANE_IDS[$i]}"

    # Read owned_paths for file ownership enforcement (comma-separated)
    OWNED_PATHS=$(jq -r '(.panes['"$i"'].owned_paths // []) | join(",")' "$CONFIG_FILE")

    # Create log filename from pane name (lowercase, dashes)
    LOG_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    LOG_FILE="$LOG_DIR/agent-${LOG_NAME}.log"

    if [[ -n "$OWNED_PATHS" ]]; then
        echo "  [$PANE_ID] $NAME -> $LOG_FILE (owns: $OWNED_PATHS)"
    else
        echo "  [$PANE_ID] $NAME -> $LOG_FILE (no ownership restriction)"
    fi

    # Prepend agent context file instruction to prompt
    AGENT_CTX="IMPORTANT: First read .claude-agent.md in this directory for your agent identity, owned paths, and other running agents. Then proceed with: "
    FULL_PROMPT="${AGENT_CTX}${PROMPT}"

    # Escape single quotes in prompt for shell
    ESCAPED_PROMPT="${FULL_PROMPT//\'/\'\\\'\'}"

    # Build env prefix for file ownership enforcement
    ENV_PREFIX=""
    if [[ -n "$OWNED_PATHS" ]]; then
        ENV_PREFIX="AGENT_OWNS='$OWNED_PATHS' AGENT_NAME='$NAME' "
    fi

    # Build claude command with optional log wrapper
    if command -v script &> /dev/null; then
        # Wrap with script for log capture
        if [[ -n "$CLAUDE_FLAGS" ]]; then
            CMD="script -q -a '$LOG_FILE' bash -c \"${ENV_PREFIX}claude $CLAUDE_FLAGS '$ESCAPED_PROMPT'\""
        else
            CMD="script -q -a '$LOG_FILE' bash -c \"${ENV_PREFIX}claude '$ESCAPED_PROMPT'\""
        fi
    else
        # No script command - run directly
        if [[ -n "$CLAUDE_FLAGS" ]]; then
            CMD="${ENV_PREFIX}claude $CLAUDE_FLAGS '$ESCAPED_PROMPT'"
        else
            CMD="${ENV_PREFIX}claude '$ESCAPED_PROMPT'"
        fi
    fi

    tmux send-keys -t "$SESSION:0.$PANE_ID" "$CMD" Enter

    # Delay between launches to prevent race conditions
    if [[ $i -lt $((PANE_COUNT - 1)) ]]; then
        sleep "$DELAY"
    fi
done

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
echo "Sessions started:"
echo ""

for i in $(seq 0 $((PANE_COUNT - 1))); do
    NAME=$(jq -r ".panes[$i].name" "$CONFIG_FILE")
    BRANCH=$(jq -r ".panes[$i].branch // \"(current)\"" "$CONFIG_FILE")
    PANE_ID="${PANE_IDS[$i]}"

    printf "  Pane %d: %-20s -> %s\n" "$PANE_ID" "$NAME" "$BRANCH"
done

echo ""
echo "tmux controls:"
echo "  Ctrl-b arrow  : Switch panes"
echo "  Ctrl-b z      : Zoom/unzoom pane"
echo "  Ctrl-b d      : Detach (keeps running)"
echo "  Ctrl-b [      : Scroll mode (q to exit)"
echo ""
echo "Attaching to session..."
sleep 1

tmux attach -t "$SESSION"
