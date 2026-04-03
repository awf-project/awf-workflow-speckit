#!/usr/bin/env bash
set -e

# Build a KEY=VALUE manifest of feature file existence
# Usage: build-context-manifest.sh <feature_dir>

# ASCII wireframe:
# ┌─────────────────────────────────────────────────────┐
# │  INPUT: feature_dir                                 │
# ├─────────────────────────────────────────────────────┤
# │  RESOLVE: abs paths for 6 files + contracts/ dir    │
# │           + constitution at REPO_ROOT/specs/        │
# ├─────────────────────────────────────────────────────┤
# │  OUTPUT: KEY=VALUE pairs (existence booleans)         │
# └─────────────────────────────────────────────────────┘

FEATURE_DIR="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$FEATURE_DIR" ]; then
    echo "Usage: build-context-manifest.sh <feature_dir>" >&2
    exit 1
fi

# Resolve to absolute path
FEATURE_DIR="$(cd "$FEATURE_DIR" && pwd)"

REPO_ROOT=$(get_repo_root)

# --- resolve each artifact ---

resolve_file() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "true|$path"
    else
        echo "false|"
    fi
}

resolve_contracts() {
    local dir="$1/contracts"
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "true|$dir"
    else
        echo "false|"
    fi
}

spec_result=$(resolve_file "$FEATURE_DIR/spec.md")
plan_result=$(resolve_file "$FEATURE_DIR/plan.md")
tasks_result=$(resolve_file "$FEATURE_DIR/tasks.md")
research_result=$(resolve_file "$FEATURE_DIR/research.md")
data_model_result=$(resolve_file "$FEATURE_DIR/data-model.md")
quickstart_result=$(resolve_file "$FEATURE_DIR/quickstart.md")
contracts_result=$(resolve_contracts "$FEATURE_DIR")
constitution_result=$(resolve_file "$REPO_ROOT/specs/constitution.md")

# Split "exists|path" pairs
spec_exists="${spec_result%%|*}";           spec_path="${spec_result#*|}"
plan_exists="${plan_result%%|*}";           plan_path="${plan_result#*|}"
tasks_exists="${tasks_result%%|*}";         tasks_path="${tasks_result#*|}"
research_exists="${research_result%%|*}";   research_path="${research_result#*|}"
data_model_exists="${data_model_result%%|*}"; data_model_path="${data_model_result#*|}"
quickstart_exists="${quickstart_result%%|*}"; quickstart_path="${quickstart_result#*|}"
contracts_exists="${contracts_result%%|*}"; contracts_path="${contracts_result#*|}"
constitution_exists="${constitution_result%%|*}"; constitution_path="${constitution_result#*|}"

echo "FEATURE_DIR=$FEATURE_DIR"
echo "SPEC=$spec_exists"
echo "PLAN=$plan_exists"
echo "TASKS=$tasks_exists"
echo "RESEARCH=$research_exists"
echo "DATA_MODEL=$data_model_exists"
echo "QUICKSTART=$quickstart_exists"
echo "CONTRACTS=$contracts_exists"
echo "CONSTITUTION=$constitution_exists"
