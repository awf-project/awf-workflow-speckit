# awf-workflow-speckit

Specification-Driven Development (SDD) workflow pack for [AWF CLI](https://github.com/awf-project/cli).

Transforms feature descriptions into structured specifications, implementation plans, and executable tasks through AI-assisted workflows.

## Why this project?

This is a **reimplementation of [SpecKit](https://github.com/pmusic-project/speckit)** as an AWF workflow pack, created to illustrate how to build multi-step AI workflows with AWF.

The reimplementation attempts to optimize the original SpecKit processes (deterministic pre-steps, token reduction, post-agent validation) without altering the core methodology. It should be considered as **a practical example of AWF workflow design**, not as the definitive approach. Real-world workflows will have different constraints, and AWF supports patterns well beyond what this pack demonstrates.

## Overview

SpecKit guides you through a structured development process:

```
init ─► constitution ─► specify ─► clarify ─► plan ─► tasks ─► analyze ─► checklist ─► implement
                                                                                           │
                                                                                    taskstoissues
```

Each workflow produces artifacts that feed into the next. You can skip optional workflows or re-run them as your understanding evolves.

## Compatibility

> **AWF v0.6.0**: Fully compatible and functional.
>
> **AWF v0.7.0**: Work in progress — some workflows may not yet leverage v0.7.0 features or may require adjustments.

## Prerequisites

- [AWF CLI](https://github.com/awf-project/cli) >= 0.6.0
- Git
- An AI provider CLI: `claude`, `codex`, `gemini`, or `opencode`
- `gh` CLI (only for `taskstoissues`)

## Install

```bash
# From GitHub (recommended)
awf workflow install awf-project/awf-workflow-speckit

# Local development
make install          # .awf/workflow-packs/speckit/
```

## Workflows

### 1. `init` — Bootstrap SDD structure

Creates the `specs/` directory and copies customizable templates to `.awf/templates/speckit/`.

```bash
awf run speckit/init
```

**Creates:**

```
your-project/
├── specs/                              # Feature specifications directory
└── .awf/templates/speckit/             # Customizable templates
    ├── spec-template.md
    ├── plan-template.md
    ├── tasks-template.md
    ├── constitution-template.md
    ├── checklist-template.md
    └── agent-file-template.md
```

Templates are only copied if they don't already exist — your customizations are preserved.

---

### 2. `constitution` — Define project principles

Creates or updates the project constitution at `specs/constitution.md`. The constitution defines non-negotiable development principles that all other workflows respect (TDD, architecture rules, quality gates, etc.).

```bash
awf run speckit/constitution --input description="TDD mandatory, hexagonal architecture, Go 1.22"
awf run speckit/constitution --input description="Add observability principle"
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `description` | Yes | — | Principles or update instructions |

**Workflow steps:**
1. Load existing constitution (or create from template)
2. Scan placeholder tokens (`[ALL_CAPS_IDENTIFIER]`)
3. Pre-load constitution content and templates
4. Agent fills placeholders, propagates changes across templates

**Output:** `specs/constitution.md` with versioned principles and a sync impact report.

---

### 3. `specify` — Create a feature specification

Creates a feature branch, initializes a spec directory, and generates a structured specification from a natural language description.

```bash
awf run speckit/specify --input description="Real-time chat with message history and typing indicators"
awf run speckit/specify --input description="OAuth2 login" --input short_name="oauth2-login"
awf run speckit/specify --input description="Fix payment bug" --input numbering=timestamp
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `description` | Yes | — | Feature description in natural language |
| `short_name` | No | Auto-generated | Custom 2-4 word branch name |
| `numbering` | No | `sequential` | Branch numbering: `sequential` (001-...) or `timestamp` (20260403-143022-...) |

**Workflow steps:**
1. Create feature branch and spec directory (`specs/NNN-feature-name/`)
2. Pre-load spec template
3. Agent generates specification (user stories, requirements, success criteria)
4. Create requirements quality checklist (`checklists/requirements.md`)
5. Validate spec structure (mandatory sections, clarification count)

**Output:**

```
specs/001-feature-name/
├── spec.md                         # Feature specification
└── checklists/
    └── requirements.md             # Spec quality checklist (CHK001-CHK016)
```

**Spec structure:** User stories with priorities (P1, P2, P3), functional requirements (FR-001, FR-002...), success criteria (SC-001...), edge cases, assumptions. Maximum 3 `[NEEDS CLARIFICATION]` markers.

---

### 4. `clarify` — Reduce specification ambiguity

Interactive workflow that asks targeted questions (max 5) to resolve ambiguities in the spec. Each answer is immediately integrated into the spec file.

```bash
awf run speckit/clarify
awf run speckit/clarify --input context="Focus on security requirements"
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `context` | No | — | Prioritization context |

**Workflow steps:**
1. Validate feature branch and resolve paths
2. Scan spec for ambiguities (placeholders, vague terms, TODOs)
3. Build context manifest (file existence check)
4. Pre-load spec content
5. Interactive loop (max 5 iterations): agent asks one question at a time, integrates answers

**How it works:**
- Agent presents one multiple-choice or short-answer question
- Recommends the best option with reasoning
- You answer (letter, "yes" to accept recommendation, or custom answer)
- Spec is updated immediately after each answer
- Loop exits when: all questions answered, you say "done", or 5 questions reached

**Output:** Updated `spec.md` with a `## Clarifications` section and resolved ambiguities throughout.

---

### 5. `plan` — Create implementation plan

Generates a technical implementation plan in two phases: research (resolve unknowns) then design (data model, contracts, validation scenarios).

```bash
awf run speckit/plan
awf run speckit/plan --input description="Use PostgreSQL, deploy on Kubernetes"
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `description` | No | — | Tech stack and architecture preferences |

**Workflow steps:**
1. Copy plan template to feature directory
2. Detect tech stack from project files (go.mod, package.json, composer.json, etc.)
3. Build context manifest
4. Pre-load spec and constitution
5. **Research agent** (Phase 0): resolve all `NEEDS CLARIFICATION` items, produce `research.md`
6. Verify research.md was created
7. **Design agent** (Phase 1): produce `data-model.md`, `contracts/`, `quickstart.md`

**Output:**

```
specs/001-feature-name/
├── plan.md                         # Implementation plan (tech context, structure, complexity)
├── research.md                     # Decisions with rationale and alternatives
├── data-model.md                   # Entities, fields, relationships, validations
├── quickstart.md                   # Key validation scenarios
└── contracts/                      # Interface contracts (API specs, CLI schemas, etc.)
```

**Constitution check:** If `specs/constitution.md` exists, both agents validate compliance. Violations without justification cause an error.

---

### 6. `tasks` — Generate task list

Generates an actionable, dependency-ordered task list organized by user story.

```bash
awf run speckit/tasks
awf run speckit/tasks --input context="Include TDD test tasks"
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `context` | No | — | Additional context (e.g., "Include test tasks", "Focus on MVP") |

**Workflow steps:**
1. Validate prerequisites (plan.md must exist)
2. Build context manifest
3. Pre-load plan, spec, and optional documents (data-model, contracts, research, quickstart)
4. Agent generates tasks organized by user story

**Output:** `specs/001-feature-name/tasks.md`

**Task format:** Each task follows strict checklist format:

```markdown
- [ ] T001 Create project structure per implementation plan
- [ ] T005 [P] Implement auth middleware in src/middleware/auth.py
- [ ] T012 [P] [US1] Create User model in src/models/user.py
```

- `[P]` = parallelizable (different files, no dependencies)
- `[US1]`, `[US2]` = user story association

**Phase structure:**
1. Setup (shared infrastructure)
2. Foundational (blocking prerequisites)
3. User Story 1 (P1) — MVP
4. User Story 2 (P2)
5. ... (one phase per story)
6. Polish & Cross-Cutting Concerns

Includes dependency graph, parallel execution examples, and implementation strategy.

---

### 7. `analyze` — Cross-artifact consistency analysis

Read-only analysis that detects inconsistencies, duplications, and gaps across spec, plan, and tasks before implementation.

```bash
awf run speckit/analyze
awf run speckit/analyze --input context="Focus on security requirements"
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `context` | No | — | Analysis focus area |

**Prerequisite:** `tasks.md` must exist (run `speckit/tasks` first).

**Workflow steps:**
1. Validate prerequisites (spec, plan, tasks must all exist)
2. Build coverage report (FR/SC/T inventories, coverage %, orphan tasks, vague terms)
3. Build context manifest
4. Pre-load all three artifacts + constitution
5. Agent performs semantic analysis

**Detection passes:**
- **Duplication** — near-duplicate requirements
- **Ambiguity** — vague terms without quantification
- **Underspecification** — requirements missing outcomes, tasks referencing undefined components
- **Constitution alignment** — MUST principle violations (always CRITICAL)
- **Coverage gaps** — requirements with no tasks, orphan tasks
- **Inconsistency** — terminology drift, conflicting requirements, ordering contradictions

**Output:** Structured report (to stdout, not written to file) with severity-ranked findings table, coverage summary, and next actions.

**Severities:** CRITICAL > HIGH > MEDIUM > LOW

---

### 8. `checklist` — Generate quality checklists

Creates domain-specific quality checklists that validate the **requirements themselves** (not the implementation).

```bash
awf run speckit/checklist --input domain=security
awf run speckit/checklist --input domain=ux
awf run speckit/checklist --input domain=performance
awf run speckit/checklist --input domain=api
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `domain` | Yes | — | Checklist domain (ux, api, security, performance, etc.) |

**Concept: "Unit tests for English"** — Checklists test whether requirements are complete, clear, consistent, and measurable. They do NOT test whether the implementation works.

```markdown
# Correct (tests requirement quality):
- [ ] CHK001 Are error response formats specified for all failure scenarios? [Completeness]
- [ ] CHK002 Is 'fast loading' quantified with specific timing thresholds? [Clarity, Spec FR-2]

# Wrong (tests implementation):
- [ ] CHK001 Verify the API returns 200 on success
```

**Workflow steps:**
1. Validate prerequisites
2. Resolve next CHK ID (appends to existing checklists)
3. Build context manifest
4. Pre-load spec and optional documents (plan, tasks — if they exist)
5. Agent asks up to 3 clarifying questions about scope/depth, then generates checklist

**Output:** `specs/001-feature-name/checklists/<domain>.md`

Multiple checklists can coexist: `ux.md`, `security.md`, `api.md`, `performance.md`.

---

### 9. `implement` — Execute the task plan

Executes the implementation plan phase-by-phase. Each phase gets its own focused AI agent call with only the relevant context.

```bash
awf run speckit/implement
awf run speckit/implement --input context="Start with Phase 3 only"
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | `claude` | AI provider |
| `context` | No | — | Additional instructions (scope, phase selection, etc.) |

**Prerequisite:** `tasks.md` must exist (run `speckit/tasks` first).

**Workflow steps:**
1. Validate prerequisites (spec, plan, tasks must exist)
2. Scan checklists (warn if incomplete, but proceed)
3. Build context manifest
4. Pre-load plan and optional documents (data-model, contracts, research, quickstart)
5. Extract phases from tasks.md (skip fully-completed phases)
6. **For each phase**: dispatch a focused agent that executes only that phase's tasks

**How it works:**
- Each phase agent receives: phase tasks, plan, and optional documents
- Completed tasks are marked `[x]` in tasks.md
- `[P]` tasks can be executed in parallel
- Sequential tasks respect dependency order
- Failed phases report errors; subsequent phases continue if possible

**Phase execution order:** Setup → Foundational → User Stories (priority order) → Polish

---

### 10. `taskstoissues` — Convert tasks to GitHub Issues

Parses `tasks.md` and creates GitHub Issues for all uncompleted tasks.

```bash
awf run speckit/taskstoissues
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `provider` | No | — | Unused (kept for interface compatibility) |

**Prerequisites:**
- `tasks.md` must exist
- Git remote must be a GitHub URL
- `gh` CLI must be installed and authenticated

**What it creates:** One issue per uncompleted task (`- [ ] TXXX ...`) with:
- Title: `TXXX: task description`
- Body: phase, dependencies, referenced files
- Skips completed tasks (`- [x]`)

---

## Typical Workflow

### Full SDD cycle

```bash
# 1. Bootstrap
awf run speckit/init

# 2. Define principles (optional but recommended)
awf run speckit/constitution --input description="TDD, clean architecture, Go 1.22"

# 3. Specify the feature
awf run speckit/specify --input description="User authentication with OAuth2 and session management"

# 4. Clarify ambiguities (optional)
awf run speckit/clarify

# 5. Plan implementation
awf run speckit/plan --input description="PostgreSQL, Redis for sessions, Chi router"

# 6. Generate tasks
awf run speckit/tasks

# 7. Quality checks (optional)
awf run speckit/analyze                          # Cross-artifact consistency
awf run speckit/checklist --input domain=security  # Security requirements quality
awf run speckit/checklist --input domain=api       # API requirements quality

# 8. Implement
awf run speckit/implement

# 9. Create GitHub Issues for remaining tasks (optional)
awf run speckit/taskstoissues
```

### Minimal cycle (skip optional steps)

```bash
awf run speckit/init
awf run speckit/specify --input description="Add search functionality"
awf run speckit/plan
awf run speckit/tasks
awf run speckit/implement
```

### Iterative refinement

```bash
# Specify, then refine
awf run speckit/specify --input description="Dashboard with analytics"
awf run speckit/clarify                     # Resolve ambiguities
awf run speckit/plan
awf run speckit/analyze                     # Find gaps before tasks
awf run speckit/plan                        # Re-plan if analyze found issues
awf run speckit/tasks
awf run speckit/checklist --input domain=ux # Validate UX requirements
awf run speckit/implement
```

## Configuration

### AI Provider

All agent-backed workflows accept a `provider` input:

```bash
awf run speckit/specify --input provider=gemini --input description="..."
awf run speckit/plan --input provider=codex
```

Supported providers: `claude` (default), `codex`, `gemini`, `opencode`.

### Template Customization

Templates are copied to `.awf/templates/speckit/` during `init`. Edit them to customize output format:

| Template | Used by | Controls |
|----------|---------|----------|
| `spec-template.md` | `specify` | Spec sections, user story format |
| `plan-template.md` | `plan` | Plan structure, technical context fields |
| `tasks-template.md` | `tasks` | Task format, phase structure |
| `constitution-template.md` | `constitution` | Principle sections, governance format |
| `checklist-template.md` | `checklist` | Checklist format, category headings |
| `agent-file-template.md` | `plan` | Development guidelines format |

### Branch Numbering

`specify` supports two numbering modes:

- **Sequential** (default): `001-feature-name`, `002-another-feature`
- **Timestamp**: `20260403-143022-feature-name`

```bash
awf run speckit/specify --input numbering=timestamp --input description="..."
```

## Project Structure

After running the full workflow, your project will have:

```
your-project/
├── specs/
│   ├── constitution.md                 # Project principles (optional)
│   └── 001-feature-name/              # Per-feature directory
│       ├── spec.md                     # Feature specification
│       ├── plan.md                     # Implementation plan
│       ├── tasks.md                    # Task list
│       ├── research.md                 # Research findings & decisions
│       ├── data-model.md              # Entity definitions
│       ├── quickstart.md              # Key validation scenarios
│       ├── contracts/                  # Interface contracts
│       └── checklists/                # Quality checklists
│           ├── requirements.md        # Auto-generated spec quality checks
│           ├── security.md            # Security requirements quality
│           └── ux.md                  # UX requirements quality
└── .awf/templates/speckit/            # Customizable templates
```

## Architecture

SpecKit follows a **deterministic pre-steps + focused agent** pattern:

```
Shell pre-steps          Template injection         Agent (AI-only)
(file checks,     --->   {{.states.xxx.Output}} --> (semantic work,
 counting,                                           generation,
 tech detection)                                     judgment)
```

- **Shell scripts** handle all deterministic operations (file existence, content loading, scanning, counting)
- **Workflow steps** inject pre-computed results into agent prompts via AWF template interpolation
- **Agents** receive pre-loaded context and focus exclusively on semantic/creative work

This saves 30-50% of AI tokens per workflow and prevents agents from hallucinating about missing files.

## Build

```bash
make validate  # Check manifest + all 10 workflow files
make install   # Copy to .awf/workflow-packs/speckit/
make clean     # Remove local install
```

## License

MIT
