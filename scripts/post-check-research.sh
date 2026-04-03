#!/usr/bin/env bash
set -e

# Verify no unresolved NEEDS CLARIFICATION in research.md
# Usage: post-check-research.sh <research_file>

RESEARCH_FILE="$1"

if [ -z "$RESEARCH_FILE" ] || [ ! -f "$RESEARCH_FILE" ]; then
    echo "ERROR: Research file not found: $RESEARCH_FILE" >&2
    exit 1
fi

# Match only structured bullet items (- ... NEEDS CLARIFICATION)
# Excludes narrative/resolved mentions like "All NEEDS CLARIFICATION items resolved"
count=$(grep -cE '^\s*[-*] .*NEEDS CLARIFICATION' "$RESEARCH_FILE" 2>/dev/null) || count=0

echo "UNRESOLVED=$count"

if [ "$count" -gt 0 ]; then
    echo "RESEARCH_CHECK=fail"
    echo "ERROR: $count unresolved NEEDS CLARIFICATION in research.md:" >&2
    grep -nE '^\s*[-*] .*NEEDS CLARIFICATION' "$RESEARCH_FILE" | sed 's/^/  /' >&2
    exit 1
fi

echo "RESEARCH_CHECK=pass"
