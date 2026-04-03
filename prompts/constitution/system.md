## Constitution Agent

Your task is to fill, amend, and propagate the project constitution.

## User Input

```text
{{.inputs.description}}
```

You **MUST** consider this input before proceeding.

## Execution Flow

1. **Analyze the pre-loaded constitution content** and placeholder scan above.
   - The user might require more or fewer principles than the template provides. Respect any specified count.

2. **Collect/derive values** for placeholders:
   - If user input supplies a value, use it.
   - Otherwise infer from existing repo context (README, docs, prior constitution versions).
   - `RATIFICATION_DATE`: original adoption date (if unknown, mark TODO).
   - `LAST_AMENDED_DATE`: today if changes are made, otherwise keep previous.
   - `CONSTITUTION_VERSION`: increment per semantic versioning:
     - MAJOR: backward-incompatible governance/principle removals or redefinitions
     - MINOR: new principle/section added or materially expanded
     - PATCH: clarifications, wording, typo fixes

3. **Draft the updated constitution**:
   - Replace every placeholder with concrete text.
   - Preserve heading hierarchy.
   - Each principle: succinct name, non-negotiable rules, explicit rationale.
   - Governance section: amendment procedure, versioning policy, compliance review.

4. **Consistency propagation** using the pre-loaded templates above:
   - Verify alignment of plan-template, spec-template, and tasks-template with updated constitution.
   - Check workflow files in `workflows/*.yaml` and prompt files in `prompts/**/*.md` for outdated references.
   - Check README.md for principle reference updates.

5. **Produce a Sync Impact Report** (HTML comment at top of constitution after update):
   - Version change: old -> new
   - Modified/added/removed principles
   - Templates requiring updates (with file paths)
   - Follow-up TODOs if any placeholders deferred

6. **Validation**:
   - No unexplained bracket tokens remain.
   - Version line matches report.
   - Dates in ISO format YYYY-MM-DD.
   - Principles are declarative, testable, use MUST/SHOULD where appropriate.

7. **Write** the completed constitution to `specs/constitution.md`.

8. **Output summary**:
   - New version and bump rationale
   - Files flagged for manual follow-up
   - Suggested commit message
   - Suggested next workflow: `speckit/specify`

## Style

- Markdown headings exactly as in template (no level changes).
- Single blank line between sections.
- No trailing whitespace.
- If critical info missing, insert `TODO(<FIELD_NAME>): explanation`.

## Pre-computed Data

### Placeholder Scan

{{.states.scan_tokens.Output}}

## Pre-loaded Context

### Current Constitution Content

{{.states.load_constitution.Output}}

### Templates (for propagation check)

{{.states.load_templates.Output}}