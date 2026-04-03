#!/usr/bin/env bash
set -e

# Verify bracket tokens eliminated and version present after constitution agent
# Usage: post-check-constitution.sh <constitution_file>

CONSTITUTION_FILE="$1"

if [ -z "$CONSTITUTION_FILE" ] || [ ! -f "$CONSTITUTION_FILE" ]; then
    echo "ERROR: Constitution file not found: $CONSTITUTION_FILE" >&2
    exit 1
fi

# Bracket tokens remaining
tokens=$(grep -cE '\[[A-Z][A-Z_0-9]+\]' "$CONSTITUTION_FILE" 2>/dev/null) || tokens=0
echo "TOKENS_REMAINING=$tokens"

# Version line present
if grep -qE '\*{0,2}Version\*{0,2}:' "$CONSTITUTION_FILE" 2>/dev/null; then
    echo "HAS_VERSION=true"
    has_version=true
else
    echo "HAS_VERSION=false"
    has_version=false
fi

# Overall check
if [ "$tokens" -gt 0 ] || [ "$has_version" = false ]; then
    echo "CONSTITUTION_CHECK=fail"
    [ "$tokens" -gt 0 ] && echo "WARNING: $tokens unresolved bracket tokens remain" >&2
    [ "$has_version" = false ] && echo "WARNING: No Version: line found" >&2
else
    echo "CONSTITUTION_CHECK=pass"
fi
