#!/usr/bin/env bash
set -e

# Create static requirements quality checklist
# Usage: create-requirements-checklist.sh <feature_dir> <feature_name>

FEATURE_DIR="$1"
FEATURE_NAME="$2"

if [ -z "$FEATURE_DIR" ] || [ -z "$FEATURE_NAME" ]; then
    echo "Usage: $0 <feature_dir> <feature_name>" >&2
    exit 1
fi

CHECKLISTS_DIR="$FEATURE_DIR/checklists"
CHECKLIST_FILE="$CHECKLISTS_DIR/requirements.md"

mkdir -p "$CHECKLISTS_DIR"

if [ -f "$CHECKLIST_FILE" ]; then
    echo "EXISTS=$CHECKLIST_FILE"
    exit 0
fi

DATE=$(date +%Y-%m-%d)

cat > "$CHECKLIST_FILE" << TMPL
# Specification Quality Checklist: $FEATURE_NAME

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: $DATE
**Feature**: [spec.md](../spec.md)

## Content Quality

- [ ] CHK001 No implementation details (languages, frameworks, APIs)
- [ ] CHK002 Focused on user value and business needs
- [ ] CHK003 Written for non-technical stakeholders
- [ ] CHK004 All mandatory sections completed

## Requirement Completeness

- [ ] CHK005 No [NEEDS CLARIFICATION] markers remain
- [ ] CHK006 Requirements are testable and unambiguous
- [ ] CHK007 Success criteria are measurable
- [ ] CHK008 Success criteria are technology-agnostic (no implementation details)
- [ ] CHK009 All acceptance scenarios are defined
- [ ] CHK010 Edge cases are identified
- [ ] CHK011 Scope is clearly bounded
- [ ] CHK012 Dependencies and assumptions identified

## Feature Readiness

- [ ] CHK013 All functional requirements have clear acceptance criteria
- [ ] CHK014 User scenarios cover primary flows
- [ ] CHK015 Feature meets measurable outcomes defined in Success Criteria
- [ ] CHK016 No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before \`speckit/clarify\` or \`speckit/plan\`
TMPL

echo "CREATED=$CHECKLIST_FILE"
