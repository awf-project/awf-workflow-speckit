#!/usr/bin/env bash
set -e

# Build coverage report: FR/SC/T inventories + cross-reference mapping
# Usage: build-coverage-report.sh <feature_dir>

FEATURE_DIR="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

for f in "$SPEC_FILE" "$PLAN_FILE" "$TASKS_FILE"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Required file not found: $f" >&2
        exit 1
    fi
done

# Extract requirement IDs from spec.md
requirements=$(grep -oE 'FR-[0-9]+' "$SPEC_FILE" 2>/dev/null | sort -u || true)
req_count=0
[ -n "$requirements" ] && req_count=$(echo "$requirements" | wc -l)

# Extract success criteria IDs
success_criteria=$(grep -oE 'SC-[0-9]+' "$SPEC_FILE" 2>/dev/null | sort -u || true)
sc_count=0
[ -n "$success_criteria" ] && sc_count=$(echo "$success_criteria" | wc -l)

# Extract task IDs from tasks.md
task_ids=$(grep -oE 'T[0-9]{3}' "$TASKS_FILE" 2>/dev/null | sort -u || true)
task_count=0
[ -n "$task_ids" ] && task_count=$(echo "$task_ids" | wc -l)

# Coverage mapping
covered=0
uncovered_list=""
coverage_lines=""

all_ids=""
[ -n "$requirements" ] && all_ids="$requirements"
[ -n "$success_criteria" ] && all_ids="${all_ids:+$all_ids"$'\n'"}$success_criteria"

while IFS= read -r req_id; do
    [ -z "$req_id" ] && continue
    matching=$(grep "$req_id" "$TASKS_FILE" 2>/dev/null | grep -oE 'T[0-9]{3}' | sort -u | tr '\n' ',' | sed 's/,$//' || true)
    if [ -n "$matching" ]; then
        covered=$((covered + 1))
        coverage_lines="${coverage_lines}${req_id} -> ${matching}"$'\n'
    else
        uncovered_list="${uncovered_list}${req_id}"$'\n'
    fi
done <<< "$all_ids"

total_reqs=$((req_count + sc_count))
if [ "$total_reqs" -gt 0 ]; then
    coverage_pct=$((covered * 100 / total_reqs))
else
    coverage_pct=100
fi

# Orphan tasks (referencing no FR/SC)
orphan_list=""
while IFS= read -r tid; do
    [ -z "$tid" ] && continue
    task_line=$(grep "$tid" "$TASKS_FILE" 2>/dev/null || true)
    has_ref=false
    while IFS= read -r rid; do
        [ -z "$rid" ] && continue
        if echo "$task_line" | grep -q "$rid" 2>/dev/null; then
            has_ref=true
            break
        fi
    done <<< "$all_ids"
    [ "$has_ref" = false ] && orphan_list="${orphan_list}${tid}"$'\n'
done <<< "$task_ids"

orphan_count=0
[ -n "$orphan_list" ] && { orphan_count=$(echo "$orphan_list" | grep -c '.' 2>/dev/null) || orphan_count=0; }

# Unresolved placeholders across files
placeholders=0
for f in "$SPEC_FILE" "$PLAN_FILE" "$TASKS_FILE"; do
    p=$(grep -cE '(TODO|TKTK|\?\?\?|\[NEEDS CLARIFICATION)' "$f" 2>/dev/null) || p=0
    placeholders=$((placeholders + p))
done

# Vague terms across files
vague=0
for f in "$SPEC_FILE" "$PLAN_FILE" "$TASKS_FILE"; do
    v=$(grep -ciE '\b(robust|intuitive|fast|scalable|secure|efficient|seamless)\b' "$f" 2>/dev/null) || v=0
    vague=$((vague + v))
done

# Terminology drift: bold entities in plan not in spec
spec_entities=$(grep -oE '\*\*[A-Z][a-zA-Z]+\*\*' "$SPEC_FILE" 2>/dev/null | sort -u | tr -d '*' || true)
plan_entities=$(grep -oE '\*\*[A-Z][a-zA-Z]+\*\*' "$PLAN_FILE" 2>/dev/null | sort -u | tr -d '*' || true)

drift_list=""
while IFS= read -r entity; do
    [ -z "$entity" ] && continue
    if [ -n "$spec_entities" ]; then
        echo "$spec_entities" | grep -qx "$entity" 2>/dev/null || drift_list="${drift_list}${entity}"$'\n'
    else
        drift_list="${drift_list}${entity}"$'\n'
    fi
done <<< "$plan_entities"

drift_count=0
[ -n "$drift_list" ] && { drift_count=$(echo "$drift_list" | grep -c '.' 2>/dev/null) || drift_count=0; }

echo "=== Coverage Report ==="
echo "REQUIREMENTS=$req_count"
echo "SUCCESS_CRITERIA=$sc_count"
echo "TASKS=$task_count"
echo "COVERED=$covered/$total_reqs ($coverage_pct%)"
[ -n "$uncovered_list" ] && echo "UNCOVERED:" && echo "$uncovered_list" | grep '.' | sed 's/^/  /'
[ -n "$orphan_list" ] && echo "ORPHAN_TASKS:" && echo "$orphan_list" | grep '.' | sed 's/^/  /'
echo "PLACEHOLDERS=$placeholders"
echo "VAGUE_TERMS=$vague"
[ -n "$drift_list" ] && echo "TERMINOLOGY_DRIFT:" && echo "$drift_list" | grep '.' | sed 's/^/  /'
