#!/usr/bin/env bash
set -e

# Validate specification structure and quality markers
# Usage: validate-spec.sh <spec_file>

SPEC_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: Spec file not found: $SPEC_FILE" >&2
    exit 1
fi

# Count NEEDS CLARIFICATION markers
clarifications=$(grep -c '\[NEEDS CLARIFICATION' "$SPEC_FILE" 2>/dev/null) || clarifications=0

# Check mandatory sections
has_scenarios=false
has_requirements=false
has_success_criteria=false

grep -q '## User Scenarios' "$SPEC_FILE" 2>/dev/null && has_scenarios=true
grep -q '## Requirements' "$SPEC_FILE" 2>/dev/null && has_requirements=true
grep -q '## Success Criteria' "$SPEC_FILE" 2>/dev/null && has_success_criteria=true

# Check for implementation details leaking
impl_leaks=$(grep -ciE '\b(framework|library|database|api endpoint|REST|GraphQL|SQL|NoSQL|React|Vue|Angular|Django|Rails|Express|Spring)\b' "$SPEC_FILE" 2>/dev/null) || impl_leaks=0

# Count identifiers
fr_count=$(grep -cE '^\s*-\s*\*\*FR-[0-9]+\*\*' "$SPEC_FILE" 2>/dev/null) || fr_count=0
sc_count=$(grep -cE '^\s*-\s*\*\*SC-[0-9]+\*\*' "$SPEC_FILE" 2>/dev/null) || sc_count=0
story_count=$(grep -cE '^###\s+User Story' "$SPEC_FILE" 2>/dev/null) || story_count=0

# Overall validation
valid=true
issues=""
[ "$clarifications" -gt 3 ] && valid=false && issues="${issues:+$issues,}TOO_MANY_CLARIFICATIONS"
[ "$has_scenarios" = false ] && valid=false && issues="${issues:+$issues,}MISSING_SCENARIOS"
[ "$has_requirements" = false ] && valid=false && issues="${issues:+$issues,}MISSING_REQUIREMENTS"
[ "$has_success_criteria" = false ] && valid=false && issues="${issues:+$issues,}MISSING_SUCCESS_CRITERIA"

echo "CLARIFICATIONS=$clarifications"
echo "HAS_SCENARIOS=$has_scenarios"
echo "HAS_REQUIREMENTS=$has_requirements"
echo "HAS_SUCCESS_CRITERIA=$has_success_criteria"
echo "IMPL_LEAKS=$impl_leaks"
echo "FR_COUNT=$fr_count"
echo "SC_COUNT=$sc_count"
echo "STORY_COUNT=$story_count"
echo "VALID=$valid"
[ -n "$issues" ] && echo "ISSUES=$issues"
