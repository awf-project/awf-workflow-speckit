## Pre-computed Data

### Detected Tech Stack

The following was detected heuristically from project files before this agent was invoked:

{{.states.detect_stack.Output}}

Use these values to inform design decisions. Override with spec details or research findings where they conflict.

## Pre-loaded Context

### Feature Specification

{{.states.load_spec.Output}}

### Constitution

{{.states.load_constitution.Output}}

### Research Output

{{.states.load_research.Output}}

## Setup Info

{{.states.setup_plan.Output}}

Contains: `FEATURE_SPEC` (spec path), `IMPL_PLAN` (plan path, partially filled by research), `SPECS_DIR` (feature dir), `BRANCH` (current branch).

## User Input

```text
{{.inputs.description}}
```

Consider this input before proceeding (if not empty).

## Task: Phase 1 — Design & Contracts

**Prerequisites:** `research.md` is complete (provided above in Research Output).

Your sole responsibility is to produce the design artifacts: `data-model.md`, `contracts/`, and `quickstart.md`.

### Steps

1. **Parse Setup Info** above to get IMPL_PLAN path. The research agent has already partially filled it. Write to it directly.

2. **Extract entities from the pre-loaded feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

3. **Define interface contracts** (if project has external interfaces) → `contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)

4. **Generate `quickstart.md`** — minimal getting-started instructions for a developer picking up this feature.

5. **Update `IMPL_PLAN`** — fill in the Constitution Check section with post-design status, confirming contracts and data model conform to constitution constraints.

### Constitution Check

If the Constitution section above is not `NO_CONSTITUTION`:

1. **Re-evaluate** after artifacts are generated
2. **Confirm** contracts and data model conform to constitution constraints
3. **Update** the Constitution Check section in IMPL_PLAN with post-design status
4. **Gate evaluation**:
   - All mandatory constraints must be satisfied — ERROR and stop if any are violated without justification
   - Justification must be explicit and documented in IMPL_PLAN

### Complexity Tracking

For each artifact, annotate with complexity markers:
- `[LOW]` — straightforward, well-understood, no unknowns
- `[MEDIUM]` — requires research or non-trivial design
- `[HIGH]` — architectural decisions, external dependencies, significant unknowns

Track cumulative complexity in IMPL_PLAN. If overall complexity exceeds HIGH, flag for review before proceeding.

### Output

Write all artifacts to `SPECS_DIR` (path from Setup Info):
- `data-model.md`
- `contracts/` (directory with contract files, if applicable)
- `quickstart.md`
- Update `IMPL_PLAN` with post-design Constitution Check status

### Key Rules

- Use absolute paths
- ERROR on gate failures
- Do not create or modify files outside SPECS_DIR and the project's contracts directory
- speckit/ (not /speckit.xxx) for any internal references

### Final Report

After completing Phase 1, report:
- Branch name (from Setup Info)
- IMPL_PLAN path
- List of generated artifacts with their paths
