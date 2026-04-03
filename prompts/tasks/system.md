## Pre-loaded Context

### Context Manifest

{{.states.build_manifest.Output}}

### Implementation Plan

{{.states.load_plan.Output}}

### Feature Specification

{{.states.load_spec.Output}}

### Optional Documents

{{.states.load_optional.Output}}

## User Input

```text
{{.inputs.context}}
```

Consider this input before proceeding (if not empty).

---

## Outline

1. **Execute task generation workflow** from the pre-loaded documents above (ignore sections marked "(not available)"):
   - From plan: extract tech stack, libraries, project structure
   - From spec: extract user stories with their priorities (P1, P2, P3, etc.)
   - From data-model: extract entities and map to user stories
   - From contracts: map interface contracts to user stories
   - From research: extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

2. **Generate tasks.md**: Use `.awf/templates/speckit/tasks-template.md` as structure, fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

3. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

The tasks.md should be immediately executable — each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **Description**: Clear action with exact file path

**Examples**:

- CORRECT: `- [ ] T001 Create project structure per implementation plan`
- CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- WRONG: `- [ ] Create User model` (missing ID and Story label)
- WRONG: `T001 [US1] Create model` (missing checkbox)
- WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** — PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Interfaces/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each interface contract to the user story it serves
   - If tests requested: Each interface contract gets a contract test task [P] before implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships map to service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites — MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns

### Dependency Graph

After the task list, generate a dependency graph section:
- Show which phases must complete before others can start
- Identify which tasks within a phase are truly parallel
- Highlight the critical path (longest chain of sequential tasks)

### Parallel Execution Examples

For each user story phase, provide a concrete parallel execution example:
- Group tasks that can run simultaneously
- Show the sequence of parallel batches
- Estimate relative effort if enough context is available

### Implementation Strategy

End tasks.md with an implementation strategy section:
- **MVP scope**: Which user story (or subset) delivers the minimum viable product
- **Incremental delivery**: Order for releasing value incrementally
- **Risk items**: Tasks with the most unknowns or external dependencies
- **Quick wins**: Tasks that are low-effort and high-value

## Key Rules

- Use absolute paths for all generated file references
- Do not create or modify files outside FEATURE_DIR
- speckit/ (not /speckit.xxx) for any internal references
- Each user story phase must be independently testable before moving to the next
