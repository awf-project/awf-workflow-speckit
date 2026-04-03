#!/usr/bin/env bash
set -e

# Create GitHub issues from uncompleted tasks in tasks.md
# Usage: tasks-to-github-issues.sh <tasks_file> <owner/repo>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TASKS_FILE="$1"
OWNER_REPO="$2"

if [ -z "$TASKS_FILE" ] || [ ! -f "$TASKS_FILE" ]; then
    echo "ERROR: tasks.md not found: $TASKS_FILE" >&2
    exit 1
fi

if [ -z "$OWNER_REPO" ]; then
    echo "ERROR: owner/repo not provided" >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI is required" >&2
    exit 1
fi

current_phase=""
created=0
failed=0
skipped=0

while IFS= read -r line; do
    if [[ "$line" =~ ^##\ Phase ]]; then
        current_phase=$(echo "$line" | sed 's/^## //' | sed 's/ *$//')
    fi

    # Match uncompleted tasks: - [ ] TXXX description
    if [[ "$line" =~ ^[[:space:]]*-\ \[\ \]\ (T[0-9]+)[[:space:]]+(.+)$ ]]; then
        task_id="${BASH_REMATCH[1]}"
        description="${BASH_REMATCH[2]}"

        files=$(echo "$description" | grep -oE '[a-zA-Z0-9_./-]+\.[a-zA-Z]{1,10}' | sort -u || true)
        deps=$(echo "$description" | grep -oiE '(depends on|blocked by) T[0-9]+' | grep -oE 'T[0-9]+' || true)

        title="$task_id: $description"
        body="## Task $task_id"$'\n\n'"$description"$'\n\n'"**Phase:** ${current_phase:-N/A}"$'\n\n'"**Dependencies:** ${deps:-None}"$'\n\n'"**Files:**"$'\n'
        if [ -n "$files" ]; then
            while IFS= read -r f; do
                [ -n "$f" ] && body="$body- $f"$'\n'
            done <<< "$files"
        else
            body="${body}None mentioned"
        fi

        if gh issue create --repo "$OWNER_REPO" --title "$title" --body "$body" 2>/dev/null; then
            created=$((created + 1))
            echo "Created: $title"
        else
            failed=$((failed + 1))
            echo "FAILED: $title" >&2
        fi
    fi

    # Count completed (skipped)
    if [[ "$line" =~ ^[[:space:]]*-\ \[[xX]\]\ T[0-9]+ ]]; then
        skipped=$((skipped + 1))
    fi
done < "$TASKS_FILE"

echo ""
echo "CREATED=$created"
echo "FAILED=$failed"
echo "SKIPPED=$skipped"

[ "$failed" -gt 0 ] && exit 1
exit 0
