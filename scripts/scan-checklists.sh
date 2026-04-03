#!/usr/bin/env bash
set -e

# Scan checklists directory for completion status
# Usage: scan-checklists.sh [--json] <feature_dir>

JSON_MODE=false
FEATURE_DIR=""

for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        *) FEATURE_DIR="$arg" ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

CHECKLISTS_DIR="$FEATURE_DIR/checklists"

if [ ! -d "$CHECKLISTS_DIR" ]; then
    if $JSON_MODE; then
        echo '{"status":"NO_CHECKLISTS","checklists":[],"total_incomplete":0}'
    else
        echo "NO_CHECKLISTS"
    fi
    exit 0
fi

overall_incomplete=0
checklists_json=""
table_output=""

for f in "$CHECKLISTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    total=$(grep -cE '^\s*- \[[ xX]\]' "$f" 2>/dev/null) || total=0
    done_count=$(grep -cE '^\s*- \[[xX]\]' "$f" 2>/dev/null) || done_count=0
    incomplete=$((total - done_count))

    if [ "$incomplete" -gt 0 ]; then
        status="FAIL"
        overall_incomplete=$((overall_incomplete + incomplete))
    else
        status="PASS"
    fi

    table_output="${table_output}| ${name} | ${total} | ${done_count} | ${incomplete} | ${status} |"$'\n'

    if $JSON_MODE; then
        if has_jq; then
            entry=$(jq -cn --arg n "$name" --argjson t "$total" --argjson d "$done_count" --argjson i "$incomplete" --arg s "$status" \
                '{name:$n,total:$t,done:$d,incomplete:$i,status:$s}')
        else
            entry="{\"name\":\"$(json_escape "$name")\",\"total\":$total,\"done\":$done_count,\"incomplete\":$incomplete,\"status\":\"$status\"}"
        fi
        [ -n "$checklists_json" ] && checklists_json="$checklists_json,"
        checklists_json="$checklists_json$entry"
    fi
done

if [ "$overall_incomplete" -gt 0 ]; then
    overall_status="CHECKLISTS_INCOMPLETE"
else
    overall_status="CHECKLISTS_OK"
fi

if $JSON_MODE; then
    if has_jq; then
        jq -cn --arg status "$overall_status" --argjson incomplete "$overall_incomplete" --argjson checklists "[$checklists_json]" \
            '{status:$status,total_incomplete:$incomplete,checklists:$checklists}'
    else
        echo "{\"status\":\"$overall_status\",\"total_incomplete\":$overall_incomplete,\"checklists\":[$checklists_json]}"
    fi
else
    echo "| Checklist | Total | Done | Incomplete | Status |"
    echo "|-----------|-------|------|------------|--------|"
    echo -n "$table_output"
    echo ""
    echo "$overall_status (incomplete: $overall_incomplete)"
fi
