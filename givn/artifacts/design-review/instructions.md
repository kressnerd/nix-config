# Instruction: design-review

Stress-test the plan before the task list is written.

This review runs after design is complete — the full planning layer exists
(proposal, spec, design) but tasks have not been written and implementation has
not started. Its purpose is to catch scope, architecture, and verification
problems now, when changing a decision costs a markdown edit, not a rewrite.

Read `docs/GIVN-VERIFICATION.md` before reviewing. It is the canonical
verification model for this repository: every scenario carries exactly one
binding tag (`@check:<name>`, `@host:<name>`, or `@deploy:<name>`), RED/GREEN is
proven against native Nix targets, and there is no step runner. This
instruction does not restate the binding-tag semantics or the runner commands.

**Two phases, both required:**

### 1. Grilling — relentless interrogation of the plan

A grilling subagent reads the full plan and produces a ranked list of questions
with recommended answers. The orchestrator then presents the questions to the
user one at a time, waits for each answer, and records the outcome.

Required branches — cover every one (or explicitly record "no issue found"):

- **Scope** — does the spec contain exactly what the proposal asked for? Nothing
  extra, nothing missing? Is "done" unambiguous, and does it name the host(s)
  and the observable end state?
- **Tech choices** — are the Nix modules, option paths, and channel pins in
  design.md the right fit for the scenarios? Is a stable channel preferred, and
  is every `unstable` use justified? Are there simpler alternatives (an existing
  module, an existing option, an overlay already present) that still satisfy all
  observable behaviours?
- **Missing scenarios** — are there observable behaviours implied by the
  proposal but absent from the spec? Error paths? Failure modes (service down,
  reconnect, boot failure)? Boundary conditions?
- **Testability** — can every scenario go RED with no production change? Does
  the scenario's bound target (its `@check:`/`@host:`/`@deploy:`) actually fire
  the assertion the scenario describes, and does the targeted run command in
  `docs/GIVN-VERIFICATION.md` exit non-zero before the fix? A binding whose
  command cannot fail, or that does not exercise the described assertion, is a
  finding.
- **Verification-binding completeness** — every scenario carries exactly one
  binding tag; every `@check:`/`@host:` name resolves in the flake and every
  `@deploy:` name has a matching `tests/deploy/test_<name>.py`; every `@e2e`
  scenario binds to `@check:integration-*`, `@host:`, or `@deploy:`; and
  `verify.e2e_command` is not identical to `verify.command`. Use
  `scripts/givn-spec-trace.py` output where available, but confirm the bindings
  resolve yourself.
- **Deployment & rollback for dangerous areas** — for a change touching
  `boot.loader`, `networking`, `fileSystems`/disko,
  `environment.persistence`/impermanence, kernel, or secrets, design.md must
  record the apply command, the on-host verification, and the exact rollback.
  Missing for a dangerous-area change is a finding.
- **Risk** — what is the single most likely way this plan fails during
  implementation or deployment? Name it concretely — boot lockout, data loss,
  loss of connectivity (bricking remote access), or secret misconfiguration —
  and record its mitigation and the rollback that recovers it.
- **Decision ledger** — verify that every proposal question ID (`D<n>`)
  resolves in the design's `## Decisions` ledger or is explicitly carried with a
  named owner, and that a seed-sourced question keeps its seed reference
  (`D2 (seed Q5)`). An unresolved, unrecorded item is a finding.
- **Use-case and Persona context** — confirm use-case identity, contract,
  capability ownership, typed relationships, and explicit dispositions. Persona
  is optional: record the confirmed Personas and their relevance, or record
  `none` with the reason. A change with no user-visible surface records `none`
  (this repository's surface is host configuration, so `none` is normally
  correct). Reject invented or silently promoted Personas and any use of Persona
  biographies as Gherkin actors.
- **Deferrals** — a mandatory check may be deferred only after an operator
  question; record the operator's decision, otherwise do not sign off.
- **Architecture documentation (arc42)** — N/A if the arc42 addon is not
  enabled (`addons.arc42` in `givn/config.yaml`). Otherwise, do not just audit
  what `arc42.md` claims — independently re-derive the expected chapter set
  first, then diff against the claim:
  1. Read proposal.md/specs/design.md yourself and walk all 12 rows of the
     arc42-docs instruction's chapter-selection table, forming your own Yes/No
     per row, before opening `arc42.md`.
  2. Open `arc42.md` and compare its per-row Yes/No against your own. Any row
     where you say "Yes" and `arc42.md` says "No" (or omits the row) is a
     finding — an omission, not just a contradiction, is what slips through
     unnoticed and must block sign-off.
  3. For every chapter marked "Yes" (by either party): open the chapter file and
     confirm the content actually matches design.md, not placeholder text or a
     stale contradiction.
  4. **Chapter file integrity check (all 12 files):** For every one of the 12
     chapter files under `docs/arc42/`:
     - Confirm the file exists (not absent after a scaffold).
     - Confirm the file contains more than just the scaffolded placeholder
       template — at least some actual content or decision-specific text.
     - **Scan the file for ASCII art diagrams:** search for Unicode
       box-drawing characters
       (`┌┐└┘│─├┤┬┴┼╔╗╚╝║═╠╣╦╩╬╭╮╰╯`) and for multi-line blocks where lines
       begin with `+` or `|` and contain `---` or `===` (non-table
       pseudo-diagrams). If any are found, the content violates the diagram
       policy — treat this as a finding and require the diagram to be converted
       to Mermaid.
  5. Confirm every qualified ADR candidate in design.md has a MADR entry in
     chapter 09, and that any consequence of that decision (e.g. "Bad,
     because...") is reflected in chapter 11. Absence of a MADR for a
     non-qualifying design choice is correct when its canonical destination is
     recorded. Do not copy the canonical qualification procedure or verdict
     schema into this review instruction.
  `arc42.md`'s `STATUS: DONE` is a self-report from the same agent that wrote
  the docs — not verification; treat any mismatch, including a missing row, as a
  finding.

If a question can be answered by exploring the existing codebase, explore it and
record the finding — do not burden the user with it.

### 2. Hardening — fix what grilling found

After all questions are answered, a hardening subagent applies decisions:

- Update `design.md` if any tech decisions changed.
- Add missing scenarios to `specs/**/*.feature` with `@givn.added @wip` and a
  binding tag (`@check:`/`@host:`/`@deploy:`) if any were identified; run
  `givn lint --change <id>` to confirm exit 0 or 2.
- Do not write `tasks.md` — that is the next artifact.
- Do not change the proposal unless grilling revealed a fundamental scope
  mismatch and the user decided to fix it — flag that as a blocker instead.

**Rules:**
- Do not rubber-stamp. If the plan looks clean on first read, look harder.
- Grilling is complete only when every branch has been walked and every question
  answered or flagged as a blocker.
- Sign off by writing `DESIGN-REVIEW: PASS` at the end of `design-review.md`
  only when all questions are resolved and all hardening edits are applied.
  Write `DESIGN-REVIEW: FAIL` if any question remains unresolved.
