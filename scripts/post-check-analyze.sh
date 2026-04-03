#!/usr/bin/env bash
set -e

# Verify analyze agent didn't modify any files (read-only enforcement)
# Usage: post-check-analyze.sh
# Compares current git status against pre-agent snapshot from stdin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SNAP_FILE="$1"

if [ -z "$SNAP_FILE" ] || [ ! -f "$SNAP_FILE" ]; then
    echo "READONLY_CHECK=fail"
    echo "ERROR: Snapshot file not found: $SNAP_FILE" >&2
    exit 1
fi

AFTER=$(git status --porcelain 2>/dev/null || true)

if ! diff -q "$SNAP_FILE" <(echo "$AFTER") >/dev/null 2>&1; then
    echo "READONLY_CHECK=fail"
    echo "ERROR: Agent modified files during read-only analysis:" >&2
    diff "$SNAP_FILE" <(echo "$AFTER") | grep '^[<>]' | sed 's/^/  /' >&2
    rm -f "$SNAP_FILE"
    exit 1
fi

rm -f "$SNAP_FILE"

echo "READONLY_CHECK=pass"
