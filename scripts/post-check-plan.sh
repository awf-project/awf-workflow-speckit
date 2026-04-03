#!/usr/bin/env bash
set -e

# Verify plan artifacts after design agent completes
# Usage: post-check-plan.sh <feature_dir>

FEATURE_DIR="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$FEATURE_DIR" ] || [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature directory not found: $FEATURE_DIR" >&2
    exit 1
fi

issues=0

# Check research.md for unresolved clarifications
if [ -f "$FEATURE_DIR/research.md" ]; then
    unresolved=$(grep -c 'NEEDS CLARIFICATION' "$FEATURE_DIR/research.md" 2>/dev/null) || unresolved=0
    echo "UNRESOLVED=$unresolved"
    if [ "$unresolved" -gt 0 ]; then
        echo "WARNING: $unresolved unresolved NEEDS CLARIFICATION in research.md" >&2
        issues=$((issues + 1))
    fi
else
    echo "UNRESOLVED=na"
fi

# Check plan.md for Constitution Check section (if constitution exists)
REPO_ROOT=$(get_repo_root)
if [ -f "$REPO_ROOT/specs/constitution.md" ]; then
    if [ -f "$FEATURE_DIR/plan.md" ] && grep -qE '^#{2,3} Constitution Check' "$FEATURE_DIR/plan.md" 2>/dev/null; then
        echo "HAS_CONSTITUTION_CHECK=true"
    else
        echo "HAS_CONSTITUTION_CHECK=false"
        echo "WARNING: Constitution exists but plan.md lacks Constitution Check section" >&2
        issues=$((issues + 1))
    fi
else
    echo "HAS_CONSTITUTION_CHECK=na"
fi

if [ "$issues" -gt 0 ]; then
    echo "PLAN_CHECK=fail"
else
    echo "PLAN_CHECK=pass"
fi
