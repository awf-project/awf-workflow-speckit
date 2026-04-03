#!/usr/bin/env bash
set -e

DRY_RUN=false
ALLOW_EXISTING=false
SHORT_NAME=""
BRANCH_NUMBER=""
USE_TIMESTAMP=false
ARGS=()

i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --allow-existing-branch) ALLOW_EXISTING=true ;;
        --short-name)
            i=$((i + 1))
            [[ $i -gt $# ]] && { echo 'Error: --short-name requires a value' >&2; exit 1; }
            SHORT_NAME="${!i}"
            [[ "$SHORT_NAME" == --* ]] && { echo 'Error: --short-name requires a value' >&2; exit 1; }
            ;;
        --number)
            i=$((i + 1))
            [[ $i -gt $# ]] && { echo 'Error: --number requires a value' >&2; exit 1; }
            BRANCH_NUMBER="${!i}"
            [[ "$BRANCH_NUMBER" == --* ]] && { echo 'Error: --number requires a value' >&2; exit 1; }
            ;;
        --timestamp) USE_TIMESTAMP=true ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--allow-existing-branch] [--short-name <name>] [--number N] [--timestamp] <description>"
            echo ""
            echo "Options:"
            echo "  --dry-run                Compute paths without creating branches, directories, or files"
            echo "  --allow-existing-branch  Switch to branch if it already exists instead of failing"
            echo "  --short-name <name>      Provide a custom short name for the branch"
            echo "  --number N               Specify branch number manually (overrides auto-detection)"
            echo "  --timestamp              Use timestamp prefix (YYYYMMDD-HHMMSS) instead of sequential numbering"
            echo "  --help, -h               Show this help message"
            exit 0
            ;;
        *) ARGS+=("$arg") ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Usage: $0 [--short-name <name>] <feature_description>" >&2
    exit 1
fi

FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | xargs)
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Error: Feature description cannot be empty" >&2
    exit 1
fi

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root)
cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
[[ "$DRY_RUN" != true ]] && mkdir -p "$SPECS_DIR"

# Get highest sequential number from specs directory
get_highest_from_specs() {
    local specs_dir="$1"
    local highest=0
    if [ -d "$specs_dir" ]; then
        for dir in "$specs_dir"/*; do
            [ -d "$dir" ] || continue
            local dirname
            dirname=$(basename "$dir")
            if echo "$dirname" | grep -Eq '^[0-9]{3,}-' && ! echo "$dirname" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
                local number
                number=$(echo "$dirname" | grep -Eo '^[0-9]+')
                number=$((10#$number))
                [ "$number" -gt "$highest" ] && highest=$number
            fi
        done
    fi
    echo "$highest"
}

# Get highest sequential number from git branches
get_highest_from_branches() {
    local highest=0
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        if echo "$name" | grep -Eq '^[0-9]{3,}-' && ! echo "$name" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
            local number
            number=$(echo "$name" | grep -Eo '^[0-9]+' || echo "0")
            number=$((10#$number))
            [ "$number" -gt "$highest" ] && highest=$number
        fi
    done < <(git branch -a 2>/dev/null | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
    echo "$highest"
}

# Clean and format a branch name segment
clean_branch_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Generate branch name with stop word filtering
generate_branch_name() {
    local description="$1"
    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"
    local clean_name
    clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

    local meaningful_words=()
    for word in $clean_name; do
        [ -z "$word" ] && continue
        if ! echo "$word" | grep -qiE "$stop_words"; then
            [ ${#word} -ge 3 ] && meaningful_words+=("$word")
        fi
    done

    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        [ ${#meaningful_words[@]} -eq 4 ] && max_words=4
        local result="" count=0
        for word in "${meaningful_words[@]}"; do
            [ $count -ge $max_words ] && break
            [ -n "$result" ] && result="$result-"
            result="$result$word"
            count=$((count + 1))
        done
        echo "$result"
    else
        clean_branch_name "$description" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

# Generate branch suffix
if [ -n "$SHORT_NAME" ]; then
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
fi

# Handle timestamp vs sequential numbering
if [ "$USE_TIMESTAMP" = true ] && [ -n "$BRANCH_NUMBER" ]; then
    echo "[speckit] Warning: --number is ignored when --timestamp is used" >&2
    BRANCH_NUMBER=""
fi

if [ "$USE_TIMESTAMP" = true ]; then
    FEATURE_NUM=$(date +%Y%m%d-%H%M%S)
    BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
else
    if [ -z "$BRANCH_NUMBER" ]; then
        local_highest=$(get_highest_from_specs "$SPECS_DIR")
        if has_git; then
            branch_highest=$(get_highest_from_branches)
            [ "$branch_highest" -gt "$local_highest" ] && local_highest=$branch_highest
        fi
        BRANCH_NUMBER=$((local_highest + 1))
    fi
    # Force base-10 to prevent octal interpretation (e.g. 010 → 10, not 8)
    FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
    BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
fi

# Enforce GitHub's 244-byte branch name limit
MAX_BRANCH_LENGTH=244
if [ ${#BRANCH_NAME} -gt $MAX_BRANCH_LENGTH ]; then
    PREFIX_LENGTH=$(( ${#FEATURE_NUM} + 1 ))
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - PREFIX_LENGTH))
    BRANCH_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH | sed 's/-$//')
    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
    echo "[speckit] Warning: Branch name exceeded GitHub's 244-byte limit" >&2
    echo "[speckit] Original: $ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} bytes)" >&2
    echo "[speckit] Truncated to: $BRANCH_NAME (${#BRANCH_NAME} bytes)" >&2
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
SPEC_FILE="$FEATURE_DIR/spec.md"

if [ "$DRY_RUN" != true ]; then
    if has_git; then
        if ! git checkout -b "$BRANCH_NAME" 2>/dev/null; then
            if git branch --list "$BRANCH_NAME" | grep -q .; then
                if [ "$ALLOW_EXISTING" = true ]; then
                    git checkout "$BRANCH_NAME" 2>/dev/null || { echo "Error: Failed to switch to branch '$BRANCH_NAME'" >&2; exit 1; }
                else
                    echo "Error: Branch '$BRANCH_NAME' already exists" >&2
                    exit 1
                fi
            else
                echo "Error: Failed to create branch '$BRANCH_NAME'" >&2
                exit 1
            fi
        fi
    else
        echo "[speckit] Warning: Git not detected; skipped branch creation for $BRANCH_NAME" >&2
    fi

    mkdir -p "$FEATURE_DIR"

    if [ ! -f "$SPEC_FILE" ]; then
        TEMPLATE=$(resolve_template "spec-template" "$REPO_ROOT") || true
        if [ -n "$TEMPLATE" ] && [ -f "$TEMPLATE" ]; then
            cp "$TEMPLATE" "$SPEC_FILE"
        else
            echo "Warning: Spec template not found; created empty spec file" >&2
            touch "$SPEC_FILE"
        fi
    fi
fi

# Output results
echo "BRANCH_NAME=$BRANCH_NAME"
echo "SPEC_FILE=$SPEC_FILE"
echo "FEATURE_DIR=$FEATURE_DIR"
echo "FEATURE_NUM=$FEATURE_NUM"
