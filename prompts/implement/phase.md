## Pre-computed Data

### Checklist Status

{{.states.scan_checklists.Output}}

### Context Manifest

{{.states.build_manifest.Output}}

## Pre-loaded Context

### Implementation Plan

{{.states.load_plan.Output}}

### Optional Documents

{{.states.load_optional.Output}}

## Current Phase

{{.loop.Item}}

Phase {{.loop.Index1}} of {{.loop.Length}}.

## User Input

```text
{{.inputs.context}}
```

Consider this input before proceeding (if not empty).

## Task: Execute This Phase

You are implementing ONE phase of the task plan. The phase details are in "Current Phase" above — it contains a JSON object with `number`, `title`, and `tasks` fields.

### Rules

1. **Execute only the tasks listed in this phase.** Do not work on tasks from other phases.

2. **For each task**:
   - Read the task description carefully.
   - Use the implementation plan and optional documents for context (tech stack, architecture, data model, contracts).
   - Implement the task following the plan's file structure and conventions.
   - Mark completed tasks as `[x]` in the tasks.md file.

3. **Respect task markers**:
   - `[P]` — Can run in parallel (different files, no dependencies).
   - `[US1]`, `[US2]`, etc. — User story association for traceability.
   - Tasks WITHOUT `[P]` must be executed sequentially.

4. **Phase-by-phase execution**:
   - Complete setup/foundational tasks before user story tasks.
   - Follow the dependency order within the phase.
   - Report progress after each completed task.

5. **Error handling**:
   - If a task fails, report the error with context.
   - For `[P]` tasks, continue with other parallel tasks if one fails.
   - For sequential tasks, halt and report.

6. **Validation**:
   - After completing all tasks in this phase, verify the phase checkpoint.
   - Run any relevant tests.
   - Confirm the implementation follows the technical plan.

7. **Output**: Report which tasks were completed, any issues encountered, and readiness for the next phase.
