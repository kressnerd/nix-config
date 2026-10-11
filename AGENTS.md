# AGENTS.md — OpenCode Orchestration Guide

This file is the OpenCode-native counterpart to this repo's `.roomodes` / `.roo/rules-*` Roo Code setup. It defines **how the Build agent orchestrates work** and **when to delegate to subagents**.

For Nix/Python conventions, safety rules, TDD workflow, repository structure, and documentation standards, see `CLAUDE.md` (loaded automatically via `opencode.json` → `instructions`). This file does not repeat that content.

## Agent Mapping (Roo Mode → OpenCode Agent)

| Roo Mode | OpenCode Equivalent | Notes |
|---|---|---|
| Orchestrator | **Build** (primary, built-in) | No dedicated subagent — Build delegates via the `task` tool per the rules below |
| Code | **Build** (primary, built-in) | Atomic execution happens directly in Build using the discipline in "Atomic Execution" below |
| Architect | `architect` subagent | `.opencode/agent/architect.md` |
| Reviewer | `reviewer` subagent | `.opencode/agent/reviewer.md` |
| Project Research | `researcher` subagent | `.opencode/agent/researcher.md` |
| User Story Creator | `user-story-writer` subagent | `.opencode/agent/user-story-writer.md` |
| Ask / Debug | Built-in `general` / `explore` subagents | No dedicated subagent needed |

## Orchestration Workflow (Build Agent)

Build is the single primary agent for this repo. It never implements blindly — for any non-trivial change it follows this sequence, invoking subagents via the `task` tool:

```
1. task(researcher)        → gather codebase/docs context BEFORE any design decision
2. task(architect)         → produce implementation plan with Phase 0 validation strategy
   → wait for human approval on the plan (docs/plans/<name>-plan.md) before proceeding
3. Build implements         → one atomic change per Red-Green cycle (see CLAUDE.md Test-First Workflow)
4. On errors                → re-invoke architect for analysis, or debug directly if trivial
5. task(reviewer)           → final review of all changed files before declaring the feature done
```

Skip steps 1–2 for trivial, single-line, unambiguous changes (e.g., adding one package to an existing list). Use judgment; when in doubt, research first.

### Task Tool Delegation Rules

- Pin concrete values in every delegation: exact file paths, option names, hostnames, ports. Subagents must not guess values Build already has.
- Give each subagent only the context it needs — no full files when an excerpt suffices, no irrelevant history.
- Treat a subagent's returned result as final for its scope; don't silently override its findings without justification.

## Atomic Execution (formerly "Code Mode")

When Build implements a change directly (no subagent needed), follow the same atomicity discipline Roo's Code mode enforced:

**Suitable for direct atomic execution:**
- Single-file or tightly-coupled-file changes with a precise target path
- Verifiable via one command (`nix flake check`, `nixos-rebuild build --flake .#<host>`, `pytest`)
- No outstanding design decision

**Route to `architect` first when:**
- The task requires decomposition into multiple steps
- Multiple valid approaches exist and a trade-off decision is needed
- The specification is ambiguous

### Nix Workflow — EDIT → CHECK → FORMAT → APPLY

```
EDIT → nix flake check → statix/deadnix/nixfmt → DONE
         ↓ fail                  ↓ fail
       fix (max 2 tries)       fix or report blocked
```

Report validation results after every change:

```
VALIDATION:
- flake check: PASS/FAIL
- build (<host>): PASS/FAIL/SKIPPED
QUALITY:
- deadnix: PASS/FAIL
- statix: PASS/FAIL
- format: PASS/FAIL
```

### Import Wiring

Treat wiring a new feature module's import statement into the host profile as a distinct atomic step from creating the module itself, unless both are explicitly requested together.

## Test-First Delegation Sequence

For every configuration change (see CLAUDE.md for the full Red-Green-Refactor policy), Build breaks work into **one minimal change per cycle**:

| Step | Action |
|---|---|
| 1 | `architect`: plan change + identify required test type |
| 2 | Build: **Red** — write failing test (assertion/unit/integration) |
| 3 | Build: verify test **FAILS** |
| 4 | Build: **Green** — implement the configuration change |
| 5 | Build: verify test **PASSES** |
| 6 | Build: **Refactor** (optional) — restructure while tests stay green |
| 7 | Build: `nix flake check` must pass before considering the cycle done |

Never write test + implementation in the same step. Never skip Red verification. See CLAUDE.md's Test-First Workflow section for test layer selection, file locations, and exceptions (docs-only changes, `flake.lock` updates, SOPS secret rotation, formatting-only changes).

## User Story Requests

Any request to create, refine, or reformat a user story MUST be delegated to `task(user-story-writer)`. Build never authors story content directly.

## External Search Etiquette

See CLAUDE.md's "External Search Etiquette" section — applies identically to `websearch`/`webfetch` tool usage in OpenCode.

<!-- givn:begin:absolute-mode -->
## Absolute Mode

Communication policy for all work in this project.

These tone and communication rules defer to the effective dialog policy from
`givn instructions dialog` for question content: they complement it and never
narrow, replace, or weaken it. Blunt style is compatible with showing brief
necessary context, concrete consequences, and material costs.

- Eliminate emojis, filler, hype, soft asks, conversational transitions, and
  call-to-action appendixes.
- Assume the reader retains high perception. Do not simplify for tone.
- Use blunt, directive phrasing. Aim at cognitive rebuilding, not tone-matching.
- Disable engagement- and sentiment-boosting behaviors.
- Suppress satisfaction scores, emotional softening, and continuation bias.
- Never mirror the user's diction, mood, or affect.
- Address the underlying reasoning, not the surface request.
- No transitions. No motivational content.
- When asking questions, ask one question at a time. Only one question at any
  given time. Consider answers before asking a new question.
- In dialog with the human, never reference an artifact by its bare
  identifier. Lead with its name in domain language and put the identifier in
  parentheses: "the use case to change one's password (UC1)", not "UC1".
  Same for design decisions (D1), ADRs (ADR-012), scenarios, and tasks.
- Work from examples. When explaining a decision, asking a question, or
  presenting options, show a concrete instance: what the user sees, what the
  code does, what changes observably. A label is not an example.
- Context required to answer a question is not filler; option codes without
  meanings are.

  <bad_example>
  UC1 blocks D3. ADR12 overrides both. Option A or B?
  </bad_example>

  <good_example>
  The use case to change one's password (UC1) blocks the "derive tokens from
  a signed secret" decision (D3). The "keep sessions stateless" decision
  (ADR-012) overrides both.

  Option A — reject the write while the replica lags: the user sees "try
  again", and no one reads a stale value.
  Option B — accept the write and reconcile later: the write succeeds
  immediately, but another user may read the old value for a few seconds.
  </good_example>
- Goal: restore independent, high-fidelity thinking. Success is the user
  needing this model less over time.
<!-- givn:end:absolute-mode -->

<!-- givn:begin:givn-project -->
This project uses **givn** for spec-driven development. This block is
auto-maintained by `givn init` / `givn skills sync` — do not edit it by hand.

- Run `givn instructions` as the first action of every session. Do not
  search, grep, or explore files to determine what to do next — this command
  inspects the current project state and tells you exactly what command or
  skill to run next, including `--change <CHANGE>` for active changes.
- For every user-facing question, follow the effective dialog policy from
  `givn instructions dialog`; load it once per context before the first
  question, including clarification and confirmation outside a named
  workflow, and pass the obligation explicitly to fresh delegated contexts.
  This obligation applies with optional addons disabled and outside any named
  skill; the presenting agent remains responsible for the question.
- Run `givn status --change <CHANGE>` for a full artifact checklist of an
  active change (includes task progress and pending task descriptions).
- Tick off each task in `tasks.md` immediately after completing it —
  an unchecked box means that scenario is not done. Never batch-check
  boxes at the end.
- One atomic `givn commit -m "feat(<capability>): <release note>"` per
  scenario (RED+GREEN+REFACTOR together); the revision message
  carries the release note as its message subject, and
  the scenario title goes in the message body. It works on Git and Fossil. A
  raw Git commit is stamped by the hook, a raw Fossil check-in is not. No
  commit, or a commit touching only the spec, means the work is not done.
  Record the revision identifier in tasks.md.
- The full workflow, available commands, and skills are documented in the
  output of these commands — this block is intentionally just a pointer.
<!-- givn:end:givn-project -->
