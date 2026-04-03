#!/usr/bin/env bash
set -e

# Verify task format compliance in generated tasks.md
# Usage: post-check-tasks.sh <tasks_file>

TASKS_FILE="$1"

if [ -z "$TASKS_FILE" ] || [ ! -f "$TASKS_FILE" ]; then
    echo "ERROR: Tasks file not found: $TASKS_FILE" >&2
    exit 1
fi

# Count all checkbox lines (task candidates)
total=$(grep -cE '^\s*- \[[ x]\]' "$TASKS_FILE" 2>/dev/null) || total=0

# Count well-formed task lines: - [ ] T001 ...
wellformed=$(grep -cE '^\s*- \[[ x]\] T[0-9]{3,}' "$TASKS_FILE" 2>/dev/null) || wellformed=0

malformed=$((total - wellformed))

echo "TOTAL_TASKS=$total"
echo "WELLFORMED=$wellformed"
echo "MALFORMED=$malformed"

if [ "$malformed" -gt 0 ]; then
    echo "FORMAT_CHECK=fail"
    echo "Malformed task lines:" >&2
    grep -nE '^\s*- \[[ x]\]' "$TASKS_FILE" | grep -vE '^\s*[0-9]+:\s*- \[[ x]\] T[0-9]{3,}' | head -10 | sed 's/^/  /' >&2
else
    echo "FORMAT_CHECK=pass"
fi
