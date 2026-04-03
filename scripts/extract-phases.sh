#!/usr/bin/env bash
set -e

# Parse tasks.md into a JSON array of phases, skipping fully-completed phases.
# Usage: extract-phases.sh <tasks_file>
#
# Output: JSON array of objects with keys: number, title, tasks
# A phase is skipped when ALL its task lines are completed (- [x]).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

TASKS_FILE="$1"

if [[ -z "$TASKS_FILE" || ! -f "$TASKS_FILE" ]]; then
    echo "ERROR: tasks.md not found: $TASKS_FILE" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Pass 1: collect raw phase data into parallel arrays
# ---------------------------------------------------------------------------

declare -a phase_numbers   # numeric value of N (letter "N" -> 100)
declare -a phase_titles    # title string after "Phase X: "
declare -a phase_tasks_raw # raw task lines (newline-separated)

current_phase_index=-1
current_tasks=""

flush_phase() {
    if [[ $current_phase_index -ge 0 ]]; then
        phase_tasks_raw[$current_phase_index]="$current_tasks"
    fi
}

while IFS= read -r line; do
    # Match: ## Phase N: Title  (N may be a digit sequence or the letter N)
    if [[ "$line" =~ ^##[[:space:]]Phase[[:space:]]([0-9]+|N):[[:space:]](.+)$ ]]; then
        flush_phase

        raw_number="${BASH_REMATCH[1]}"
        raw_title="${BASH_REMATCH[2]}"

        # Strip trailing whitespace / emoji from title (keep text only up to end of line)
        # We preserve the full title including emoji — callers can strip if needed.
        if [[ "$raw_number" == "N" ]]; then
            phase_num=100
        else
            phase_num=$((10#$raw_number))
        fi

        current_phase_index=$(( ${#phase_numbers[@]} ))
        phase_numbers[$current_phase_index]=$phase_num
        phase_titles[$current_phase_index]="$raw_title"
        current_tasks=""
        continue
    fi

    # Accumulate task lines for the current phase
    if [[ $current_phase_index -ge 0 ]]; then
        if [[ "$line" =~ ^[[:space:]]*-\ \[[[:space:]]?\]  || "$line" =~ ^[[:space:]]*-\ \[[xX]\] ]]; then
            if [[ -n "$current_tasks" ]]; then
                current_tasks="${current_tasks}"$'\n'"${line}"
            else
                current_tasks="${line}"
            fi
        fi
    fi
done < "$TASKS_FILE"

# Flush the last phase
flush_phase

# ---------------------------------------------------------------------------
# Pass 2: filter out fully-completed phases and build JSON
# ---------------------------------------------------------------------------

build_json_with_jq() {
    local json_array="[]"

    for i in "${!phase_numbers[@]}"; do
        local tasks="${phase_tasks_raw[$i]}"

        # Skip phase if no task lines at all, or if no incomplete tasks remain
        if [[ -z "$tasks" ]]; then
            continue
        fi
        if ! echo "$tasks" | grep -qE '^[[:space:]]*-[[:space:]]\[[[:space:]]\]'; then
            continue
        fi

        local num="${phase_numbers[$i]}"
        local title="${phase_titles[$i]}"

        json_array=$(printf '%s' "$json_array" | jq \
            --argjson num "$num" \
            --arg title "$title" \
            --arg tasks "$tasks" \
            '. + [{"number": $num, "title": $title, "tasks": $tasks}]')
    done

    printf '%s\n' "$json_array"
}

build_json_manual() {
    local first=1
    printf '['

    for i in "${!phase_numbers[@]}"; do
        local tasks="${phase_tasks_raw[$i]}"

        if [[ -z "$tasks" ]]; then
            continue
        fi
        if ! echo "$tasks" | grep -qE '^[[:space:]]*-[[:space:]]\[[[:space:]]\]'; then
            continue
        fi

        local num="${phase_numbers[$i]}"
        local title
        title=$(json_escape "${phase_titles[$i]}")
        local escaped_tasks
        escaped_tasks=$(json_escape "$tasks")

        if [[ $first -eq 0 ]]; then
            printf ','
        fi
        printf '\n  {"number": %d, "title": "%s", "tasks": "%s"}' \
            "$num" "$title" "$escaped_tasks"
        first=0
    done

    printf '\n]\n'
}

if has_jq; then
    build_json_with_jq
else
    build_json_manual
fi
