#!/usr/bin/env bash
set -e

# Scan a file for ambiguities, placeholders, and vague terms
# Usage: scan-ambiguities.sh <file>

FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE" >&2
    exit 1
fi

# NEEDS CLARIFICATION markers
clarification_lines=$(grep -n '\[NEEDS CLARIFICATION' "$FILE" 2>/dev/null || true)
clarification_count=0
[ -n "$clarification_lines" ] && clarification_count=$(echo "$clarification_lines" | wc -l)

# TODO/TKTK/??? markers
todo_lines=$(grep -nE '(TODO|TKTK|\?\?\?)' "$FILE" 2>/dev/null || true)
todo_count=0
[ -n "$todo_lines" ] && todo_count=$(echo "$todo_lines" | wc -l)

# Vague adjectives
vague_pattern='\b(robust|intuitive|fast|scalable|secure|efficient|seamless|simple|easy|flexible|powerful|modern|user-friendly|high-performance|reliable)\b'
vague_lines=$(grep -niE "$vague_pattern" "$FILE" 2>/dev/null || true)
vague_count=0
[ -n "$vague_lines" ] && vague_count=$(echo "$vague_lines" | wc -l)

# Bracket tokens [ALL_CAPS]
bracket_tokens=$(grep -oE '\[[A-Z][A-Z_]{2,}\]' "$FILE" 2>/dev/null | sort -u || true)
bracket_count=0
[ -n "$bracket_tokens" ] && bracket_count=$(echo "$bracket_tokens" | wc -l)

total_issues=$((clarification_count + todo_count + vague_count + bracket_count))

echo "=== Ambiguity Scan ==="
echo "CLARIFICATIONS=$clarification_count"
[ -n "$clarification_lines" ] && echo "$clarification_lines" | sed 's/^/  /'
echo "TODOS=$todo_count"
[ -n "$todo_lines" ] && echo "$todo_lines" | sed 's/^/  /'
echo "VAGUE_TERMS=$vague_count"
[ -n "$vague_lines" ] && echo "$vague_lines" | sed 's/^/  /'
echo "BRACKET_TOKENS=$bracket_count"
[ -n "$bracket_tokens" ] && echo "$bracket_tokens" | sed 's/^/  /'
echo "TOTAL_ISSUES=$total_issues"
