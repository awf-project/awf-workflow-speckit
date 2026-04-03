#!/usr/bin/env bash
# Common functions for AWF spec-kit workflows

# Get repository root via git or fallback to $PWD
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        echo "$PWD"
    fi
}

# Get current branch with fallback
get_current_branch() {
    # Check environment variable first
    if [[ -n "${SPECKIT_FEATURE:-}" ]]; then
        echo "$SPECKIT_FEATURE"
        return
    fi

    # Try git
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # Fallback: find latest spec directory
    local repo_root
    repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest_feature=""
        local highest=0
        local latest_timestamp=""

        for dir in "$specs_dir"/*; do
            [[ -d "$dir" ]] || continue
            local dirname
            dirname=$(basename "$dir")
            if [[ "$dirname" =~ ^([0-9]{8}-[0-9]{6})- ]]; then
                local ts="${BASH_REMATCH[1]}"
                if [[ "$ts" > "$latest_timestamp" ]]; then
                    latest_timestamp="$ts"
                    latest_feature=$dirname
                fi
            elif [[ "$dirname" =~ ^([0-9]{3,})- ]]; then
                local number=${BASH_REMATCH[1]}
                number=$((10#$number))
                if [[ "$number" -gt "$highest" ]]; then
                    highest=$number
                    [[ -z "$latest_timestamp" ]] && latest_feature=$dirname
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi

    echo "main"
}

# Check if git is available
has_git() {
    command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Validate feature branch naming
check_feature_branch() {
    local branch="$1"

    if ! has_git; then
        echo "[speckit] Warning: Git not detected; skipped branch validation" >&2
        return 0
    fi

    local is_sequential=false
    if [[ "$branch" =~ ^[0-9]{3,}- ]] && [[ ! "$branch" =~ ^[0-9]{7}-[0-9]{6}- ]] && [[ ! "$branch" =~ ^[0-9]{7,8}-[0-9]{6}$ ]]; then
        is_sequential=true
    fi
    if [[ "$is_sequential" != "true" ]] && [[ ! "$branch" =~ ^[0-9]{8}-[0-9]{6}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named like: 001-feature-name or 20260319-143022-feature-name" >&2
        return 1
    fi

    return 0
}

# Find feature directory by numeric prefix
find_feature_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local specs_dir="$repo_root/specs"

    local prefix=""
    if [[ "$branch_name" =~ ^([0-9]{8}-[0-9]{6})- ]]; then
        prefix="${BASH_REMATCH[1]}"
    elif [[ "$branch_name" =~ ^([0-9]{3,})- ]]; then
        prefix="${BASH_REMATCH[1]}"
    else
        echo "$specs_dir/$branch_name"
        return
    fi

    local matches=()
    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/"$prefix"-*; do
            [[ -d "$dir" ]] && matches+=("$(basename "$dir")")
        done
    fi

    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "$specs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        echo "$specs_dir/${matches[0]}"
    else
        echo "ERROR: Multiple spec directories found with prefix '$prefix': ${matches[*]}" >&2
        return 1
    fi
}

# Get all feature paths as shell variables
get_feature_paths() {
    local repo_root
    repo_root=$(get_repo_root)
    local current_branch
    current_branch=$(get_current_branch)

    local feature_dir
    if ! feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch"); then
        echo "ERROR: Failed to resolve feature directory" >&2
        return 1
    fi

    printf 'REPO_ROOT=%q\n' "$repo_root"
    printf 'CURRENT_BRANCH=%q\n' "$current_branch"
    printf 'FEATURE_DIR=%q\n' "$feature_dir"
    printf 'FEATURE_SPEC=%q\n' "$feature_dir/spec.md"
    printf 'IMPL_PLAN=%q\n' "$feature_dir/plan.md"
    printf 'TASKS=%q\n' "$feature_dir/tasks.md"
    printf 'RESEARCH=%q\n' "$feature_dir/research.md"
    printf 'DATA_MODEL=%q\n' "$feature_dir/data-model.md"
    printf 'QUICKSTART=%q\n' "$feature_dir/quickstart.md"
    printf 'CONTRACTS_DIR=%q\n' "$feature_dir/contracts"
}

# Check if jq is available
has_jq() {
    command -v jq >/dev/null 2>&1
}

# Escape string for JSON (fallback when jq unavailable)
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/\\r}"
    printf '%s' "$s"
}

# Resolve template from .awf/templates/speckit/
resolve_template() {
    local template_name="$1"
    local repo_root="$2"
    local path="$repo_root/.awf/templates/speckit/${template_name}.md"

    if [[ -f "$path" ]]; then
        echo "$path"
        return 0
    fi

    return 1
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
