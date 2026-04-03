#!/usr/bin/env bash
set -e

# Resolve next CHK ID and prepare checklist directory
# Usage: resolve-chk-id.sh [--json] <feature_dir> <domain>

JSON_MODE=false
args=()

for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        *) args+=("$arg") ;;
    esac
done

FEATURE_DIR="${args[0]}"
DOMAIN="${args[1]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$FEATURE_DIR" ] || [ -z "$DOMAIN" ]; then
    echo "Usage: $0 [--json] <feature_dir> <domain>" >&2
    exit 1
fi

CHECKLISTS_DIR="$FEATURE_DIR/checklists"
CHECKLIST_FILE="$CHECKLISTS_DIR/$DOMAIN.md"

mkdir -p "$CHECKLISTS_DIR"

next_id=1
file_exists=false

if [ -f "$CHECKLIST_FILE" ]; then
    file_exists=true
    last_id=$(grep -oE 'CHK[0-9]+' "$CHECKLIST_FILE" 2>/dev/null | sed 's/CHK//' | sort -n | tail -1 || echo "0")
    [ -z "$last_id" ] && last_id=0
    next_id=$((10#$last_id + 1))
fi

next_chk_id=$(printf "CHK%03d" "$next_id")

if $JSON_MODE; then
    if has_jq; then
        jq -cn \
            --arg file "$CHECKLIST_FILE" \
            --arg dir "$CHECKLISTS_DIR" \
            --arg next_id "$next_chk_id" \
            --argjson next_num "$next_id" \
            --argjson exists "$file_exists" \
            '{checklist_file:$file,checklists_dir:$dir,next_chk_id:$next_id,next_num:$next_num,file_exists:$exists}'
    else
        echo "{\"checklist_file\":\"$(json_escape "$CHECKLIST_FILE")\",\"checklists_dir\":\"$(json_escape "$CHECKLISTS_DIR")\",\"next_chk_id\":\"$next_chk_id\",\"next_num\":$next_id,\"file_exists\":$file_exists}"
    fi
else
    echo "CHECKLIST_FILE=$CHECKLIST_FILE"
    echo "CHECKLISTS_DIR=$CHECKLISTS_DIR"
    echo "NEXT_CHK_ID=$next_chk_id"
    echo "NEXT_NUM=$next_id"
    echo "FILE_EXISTS=$file_exists"
fi
