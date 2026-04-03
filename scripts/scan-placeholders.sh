#!/usr/bin/env bash
set -e

# Scan a file for bracket placeholder tokens [ALL_CAPS_IDENTIFIER]
# Usage: scan-placeholders.sh <file>

FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE" >&2
    exit 1
fi

# Unique bracket tokens
tokens=$(grep -oE '\[[A-Z][A-Z_0-9]+\]' "$FILE" 2>/dev/null | sort -u || true)
token_count=0
[ -n "$tokens" ] && token_count=$(echo "$tokens" | wc -l)

# Tokens with line numbers
tokens_with_lines=$(grep -nE '\[[A-Z][A-Z_0-9]+\]' "$FILE" 2>/dev/null || true)

# Version line
version=$(grep -oE 'Version: [0-9]+\.[0-9]+\.[0-9]+' "$FILE" 2>/dev/null | head -1 | sed 's/Version: //' || true)

# ISO dates
dates=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$FILE" 2>/dev/null | sort -u || true)

echo "=== Placeholder Scan ==="
echo "PLACEHOLDER_COUNT=$token_count"
[ -n "$tokens" ] && echo "$tokens" | sed 's/^/  /'
echo "VERSION=${version:-none}"
[ -n "$dates" ] && echo "DATES:" && echo "$dates" | sed 's/^/  /'
