#!/usr/bin/env bash
set -e

# Verify specify agent didn't exceed 3 NEEDS CLARIFICATION markers
# Usage: post-check-specify.sh <spec_file>

SPEC_FILE="$1"

if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: Spec file not found: $SPEC_FILE" >&2
    exit 1
fi

count=$(grep -c '\[NEEDS CLARIFICATION' "$SPEC_FILE" 2>/dev/null) || count=0

echo "CLARIFICATION_COUNT=$count"

if [ "$count" -gt 3 ]; then
    echo "CLARIFICATION_CHECK=warn"
    echo "WARNING: $count NEEDS CLARIFICATION markers found (max 3)" >&2
else
    echo "CLARIFICATION_CHECK=pass"
fi
