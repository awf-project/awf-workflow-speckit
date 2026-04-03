#!/usr/bin/env bash
set -e

for arg in "$@"; do
    case "$arg" in
        --help|-h) echo "Usage: $0"; exit 0 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

_paths_output=$(get_feature_paths) || { echo "ERROR: Failed to resolve feature paths" >&2; exit 1; }
eval "$_paths_output"
unset _paths_output

check_feature_branch "$CURRENT_BRANCH" || exit 1

mkdir -p "$FEATURE_DIR"

# Copy plan template if not already present
if [[ ! -f "$IMPL_PLAN" ]]; then
    TEMPLATE=$(resolve_template "plan-template" "$REPO_ROOT") || true
    if [[ -n "$TEMPLATE" ]] && [[ -f "$TEMPLATE" ]]; then
        cp "$TEMPLATE" "$IMPL_PLAN"
    else
        echo "Warning: Plan template not found" >&2
        touch "$IMPL_PLAN"
    fi
fi

echo "FEATURE_SPEC=$FEATURE_SPEC"
echo "IMPL_PLAN=$IMPL_PLAN"
echo "SPECS_DIR=$FEATURE_DIR"
echo "BRANCH=$CURRENT_BRANCH"
