#!/bin/bash
#
# Parallel Session Status - Check status of all Claude Code tmux sessions
#
# Usage: ./parallel-session-status.sh [session-name]
#
# Checks:
#   - tmux session and pane status
#   - Git branch and working tree status
#   - PR status for each branch
#   - Dynamic merge order recommendation
#   - Writes machine-readable status to /tmp for inter-agent coordination

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Default session name — derive from project or use generic default
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "project")
SESSION="${1:-${PROJECT_NAME}-parallel}"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}── $1 ──${NC}"
}

# -----------------------------------------------------------------------------
# Check tmux Session
# -----------------------------------------------------------------------------

print_header "PARALLEL SESSION STATUS"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}No tmux session found: $SESSION${NC}"
    echo "Start sessions with: ./scripts/start-parallel-sessions.sh"
    exit 1
fi

# -----------------------------------------------------------------------------
# Gather Pane Information
# -----------------------------------------------------------------------------

print_section "TMUX PANES"

echo ""
printf "%-6s %-25s %-30s %s\n" "PANE" "DIRECTORY" "BRANCH" "PROCESS"
printf "%-6s %-25s %-30s %s\n" "----" "---------" "------" "-------"

# Arrays to store pane info
PANE_INDICES=""
declare -a PANE_DIRS_ARR=()
declare -a PANE_BRANCHES_ARR=()
declare -a PANE_STATUS_ARR=()

idx=0
while IFS='|' read -r pane_idx pane_dir pane_cmd; do
    dir_name=$(basename "$pane_dir")

    # Get git branch if in a git repo
    if git -C "$pane_dir" rev-parse --git-dir > /dev/null 2>&1; then
        branch=$(git -C "$pane_dir" branch --show-current 2>/dev/null || echo "detached")
        PANE_INDICES="$PANE_INDICES $pane_idx"
        PANE_DIRS_ARR+=("$pane_dir")
        PANE_BRANCHES_ARR+=("$branch")
        PANE_STATUS_ARR+=("")
    else
        branch="(not a repo)"
    fi

    printf "%-6s %-25s %-30s %s\n" "$pane_idx" "$dir_name" "$branch" "$pane_cmd"
    ((idx++)) || true
done < <(tmux list-panes -t "$SESSION" -F '#{pane_index}|#{pane_current_path}|#{pane_current_command}')

# -----------------------------------------------------------------------------
# Git Status for Each Worktree
# -----------------------------------------------------------------------------

print_section "GIT STATUS"
echo ""

idx=0
for pane_idx in $PANE_INDICES; do
    dir="${PANE_DIRS_ARR[$idx]}"
    branch="${PANE_BRANCHES_ARR[$idx]}"
    dir_name=$(basename "$dir")

    echo -e "${BOLD}[$pane_idx] $dir_name ($branch)${NC}"

    status=""

    # Check for uncommitted changes
    changes=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$changes" -gt 0 ]]; then
        echo -e "  ${YELLOW}! $changes uncommitted changes${NC}"
        git -C "$dir" status --porcelain 2>/dev/null | head -5 | sed 's/^/    /'
        if [[ "$changes" -gt 5 ]]; then
            echo "    ... and $((changes - 5)) more"
        fi
        status="uncommitted"
    else
        echo -e "  ${GREEN}+ Working tree clean${NC}"
    fi

    # Check for unpushed commits
    if git -C "$dir" rev-parse --verify "origin/$branch" > /dev/null 2>&1; then
        unpushed=$(git -C "$dir" log "origin/$branch..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$unpushed" -gt 0 ]]; then
            echo -e "  ${YELLOW}! $unpushed unpushed commits${NC}"
            status="${status}+unpushed"
        else
            echo -e "  ${GREEN}+ Up to date with remote${NC}"
        fi
    else
        echo -e "  ${YELLOW}! No remote tracking branch${NC}"
        status="${status}+no-remote"
    fi

    PANE_STATUS_ARR[$idx]="$status"
    echo ""
    ((idx++)) || true
done

# -----------------------------------------------------------------------------
# PR Status
# -----------------------------------------------------------------------------

print_section "PULL REQUEST STATUS"
echo ""

printf "%-30s %-10s %s\n" "BRANCH" "PR" "STATUS"
printf "%-30s %-10s %s\n" "------" "--" "------"

idx=0
for pane_idx in $PANE_INDICES; do
    dir="${PANE_DIRS_ARR[$idx]}"
    branch="${PANE_BRANCHES_ARR[$idx]}"
    status="${PANE_STATUS_ARR[$idx]}"

    # Check for existing PR
    pr_info=$(gh pr list --repo "$(git -C "$dir" remote get-url origin 2>/dev/null)" \
        --head "$branch" --json number,state,title,url 2>/dev/null || echo "[]")

    if [[ "$pr_info" != "[]" ]] && [[ "$pr_info" != "" ]]; then
        pr_num=$(echo "$pr_info" | jq -r '.[0].number // empty')
        pr_title=$(echo "$pr_info" | jq -r '.[0].title // empty' | cut -c1-40)

        if [[ -n "$pr_num" ]]; then
            printf "%-30s ${GREEN}#%-8s${NC} %s\n" "$branch" "$pr_num" "$pr_title"
        else
            printf "%-30s ${YELLOW}%-10s${NC} %s\n" "$branch" "None" "Ready to create"
        fi
    else
        if [[ "$status" == *"uncommitted"* ]]; then
            printf "%-30s ${RED}%-10s${NC} %s\n" "$branch" "None" "Has uncommitted changes"
        elif [[ "$status" == *"unpushed"* ]]; then
            printf "%-30s ${YELLOW}%-10s${NC} %s\n" "$branch" "None" "Needs push first"
        else
            printf "%-30s ${GREEN}%-10s${NC} %s\n" "$branch" "None" "Ready to create"
        fi
    fi

    ((idx++)) || true
done

# -----------------------------------------------------------------------------
# Session Activity (last few lines from each pane)
# -----------------------------------------------------------------------------

print_section "RECENT ACTIVITY"
echo ""

idx=0
for pane_idx in $PANE_INDICES; do
    dir_name=$(basename "${PANE_DIRS_ARR[$idx]}")

    echo -e "${BOLD}[$pane_idx] $dir_name${NC}"

    # Capture last few lines of pane output
    output=$(tmux capture-pane -t "$SESSION:0.$pane_idx" -p -S -10 2>/dev/null | grep -v '^$' | tail -3)
    if [[ -n "$output" ]]; then
        echo "$output" | sed 's/^/  | /'
    else
        echo "  | (no recent output)"
    fi
    echo ""
    ((idx++)) || true
done

# -----------------------------------------------------------------------------
# Dynamic Merge Order
# -----------------------------------------------------------------------------

print_section "RECOMMENDED MERGE ORDER"
echo ""

# Derive merge priority from branch name patterns
# Customize these patterns for your project
get_merge_priority() {
    local branch="$1"
    case "$branch" in
        *infra*|*terraform*|*iam*|*ci*|*cd*) echo "1" ;;
        *ecs*|*deploy*|*k8s*|*docker*)       echo "2" ;;
        *backend*|*api*|*server*|*orchestrat*) echo "3" ;;
        *frontend*|*ui*|*web*|*client*)      echo "4" ;;
        *worker*|*service*|*lib*)            echo "4" ;;
        *staff*|*docs*|*doc*|*knowledge*)    echo "5" ;;
        *)                                    echo "4" ;;
    esac
}

get_priority_label() {
    case "$1" in
        1) echo "Infrastructure first" ;;
        2) echo "Deployment/container configs" ;;
        3) echo "Backend/API" ;;
        4) echo "Services/frontend" ;;
        5) echo "Docs/staff engineer — merge last" ;;
    esac
}

# Collect branches with priorities and sort
MERGE_ORDER=""
merge_idx=0
for pane_idx in $PANE_INDICES; do
    branch="${PANE_BRANCHES_ARR[$merge_idx]}"
    dir_name=$(basename "${PANE_DIRS_ARR[$merge_idx]}")
    priority=$(get_merge_priority "$branch")
    label=$(get_priority_label "$priority")
    MERGE_ORDER="${MERGE_ORDER}${priority}|${branch}|${dir_name}|${label}\n"
    ((merge_idx++)) || true
done

echo "Based on branch analysis:"
echo ""
order_num=1
echo -e "$MERGE_ORDER" | sort -t'|' -k1,1n | while IFS='|' read -r pri br dn lbl; do
    [[ -z "$pri" ]] && continue
    printf "  %d. %-30s (%s) - %s\n" "$order_num" "$br" "$dn" "$lbl"
    ((order_num++)) || true
done
echo ""

# -----------------------------------------------------------------------------
# Next Actions
# -----------------------------------------------------------------------------

print_section "NEXT ACTIONS"
echo ""

idx=0
for pane_idx in $PANE_INDICES; do
    dir="${PANE_DIRS_ARR[$idx]}"
    branch="${PANE_BRANCHES_ARR[$idx]}"
    dir_name=$(basename "$dir")
    status="${PANE_STATUS_ARR[$idx]}"

    echo -n "  [$pane_idx] $dir_name: "

    if [[ "$status" == *"uncommitted"* ]]; then
        echo -e "${YELLOW}Commit changes, run tests, then push${NC}"
    elif [[ "$status" == *"unpushed"* ]] || [[ "$status" == *"no-remote"* ]]; then
        echo -e "${YELLOW}Push to remote, then create PR${NC}"
    else
        # Check if PR exists
        pr_exists=$(gh pr list --repo "$(git -C "$dir" remote get-url origin 2>/dev/null)" \
            --head "$branch" --json number 2>/dev/null | jq 'length')
        if [[ "$pr_exists" -gt 0 ]]; then
            echo -e "${GREEN}PR exists - await review/merge${NC}"
        else
            echo -e "${GREEN}Ready to create PR${NC}"
        fi
    fi

    ((idx++)) || true
done

# -----------------------------------------------------------------------------
# Write Machine-Readable Status File (for inter-agent coordination)
# -----------------------------------------------------------------------------

STATUS_FILE="${TMPDIR:-/tmp}/${PROJECT_NAME}-agent-status.json"

# Build JSON status
JSON_AGENTS="["
json_idx=0
for pane_idx in $PANE_INDICES; do
    dir="${PANE_DIRS_ARR[$json_idx]}"
    branch="${PANE_BRANCHES_ARR[$json_idx]}"
    dir_name=$(basename "$dir")
    status="${PANE_STATUS_ARR[$json_idx]}"

    # Determine agent state
    if [[ "$status" == *"uncommitted"* ]]; then
        state="working"
    elif [[ "$status" == *"unpushed"* ]]; then
        state="needs_push"
    else
        state="idle_or_done"
    fi

    # Get last commit message
    last_commit=$(git -C "$dir" log -1 --format="%s" 2>/dev/null || echo "")

    [[ $json_idx -gt 0 ]] && JSON_AGENTS="${JSON_AGENTS},"
    JSON_AGENTS="${JSON_AGENTS}{\"pane\":$pane_idx,\"name\":\"$dir_name\",\"branch\":\"$branch\",\"state\":\"$state\",\"last_commit\":\"$last_commit\"}"

    ((json_idx++)) || true
done
JSON_AGENTS="${JSON_AGENTS}]"

# Write status file with timestamp
cat > "$STATUS_FILE" << STATUSEOF
{
  "session": "$SESSION",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "agents": $JSON_AGENTS
}
STATUSEOF

print_section "STATUS FILE"
echo ""
echo -e "  Written to: ${GREEN}$STATUS_FILE${NC}"
echo "  Agents can read this file to see other agents' progress."
echo ""
