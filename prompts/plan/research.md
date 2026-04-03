## Pre-computed Data

### Detected Tech Stack

The following was detected heuristically from project files before this agent was invoked:

{{.states.detect_stack.Output}}

Use these values to pre-populate the Technical Context section. Override with user input or spec details where they conflict. Values showing `NEEDS CLARIFICATION` were not auto-detectable and become Phase 0 research tasks.

## Pre-loaded Context

### Feature Specification

{{.states.load_spec.Output}}

### Constitution

{{.states.load_constitution.Output}}

## Setup Info

{{.states.setup_plan.Output}}

Contains: `FEATURE_SPEC` (spec path), `IMPL_PLAN` (plan path, template already copied), `SPECS_DIR` (feature dir), `BRANCH` (current branch).

## User Input

```text
{{.inputs.description}}
```

Consider this input before proceeding (if not empty).

## Task: Phase 0 — Research

Your sole responsibility is to resolve all unknowns and produce `research.md`.

### Steps

1. **Parse Setup Info** above to get IMPL_PLAN path, FEATURE_SPEC path, SPECS_DIR, and BRANCH. The IMPL_PLAN template has already been copied — write to it directly.

2. **Extract Technical Context** from the pre-computed tech stack. For items marked `NEEDS CLARIFICATION`, add them as research tasks below.

3. **Extract unknowns**:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

4. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

5. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

### Constitution Check

If the Constitution section above is not `NO_CONSTITUTION`:

1. **Review the pre-loaded constitution** above before generating any artifacts
2. **Map each constraint** to a technical decision
3. **Gate evaluation**:
   - All mandatory constraints must be satisfied — ERROR and stop if any are violated without justification
   - Justification must be explicit and documented

### Complexity Tracking

For each research finding, annotate with complexity markers:
- `[LOW]` — straightforward, well-understood, no unknowns
- `[MEDIUM]` — requires research or non-trivial design
- `[HIGH]` — architectural decisions, external dependencies, significant unknowns

### Output

Write `research.md` to `SPECS_DIR` (path from Setup Info). All NEEDS CLARIFICATION items must be resolved before writing.

### Key Rules

- Use absolute paths
- ERROR on unresolved clarifications after research
- Do not create or modify files outside SPECS_DIR
- speckit/ (not /speckit.xxx) for any internal references
