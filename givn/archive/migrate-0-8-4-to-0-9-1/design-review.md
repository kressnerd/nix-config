# Design Review — migrate-0-8-4-to-0-9-1

Fresh-context grilling (2026-10-17) over the proposal, the generated migration
design, `migration.yaml`, and the arc42 impact assessment. The grilling agent
made no repository edits; it exercised `givn instructions`, `givn skills sync`,
and `givn upgrade` in an isolated probe at `/tmp/givnprobe`.

## Questions and resolutions

### Q1 — Which installed-files completion criterion is authoritative?

- **Status:** closed 2026-10-17 (orchestrator, from the proposal's settled
  scope)
- **Blocks:** the Phase 3 spot-check and the completion boundary.
- **Context:** the bundle requires both "project-owned replacements stay
  byte-for-byte" and "installed files carry only trigger and direction". Ten
  tracked skill templates (`givn/skills/*/SKILL.md.tmpl`) render full project
  rules into all four agent targets (40 files). The pre-upgrade revision tracks
  zero generated files (`rules: local-only`).
- **Question:** which criterion does the implementation verify?
- **Options:**
  1. **Scope by replacement presence (chosen).** Files without a replacement
     (5 built-in skills, 15 commands in each command-owning target) must carry
     trigger and direction only; replacement-backed skills must equal the
     `givn skills sync` render and carry no extension text. Gain: a check that
     can pass while preserving the templates; cost: one design clarification.
     In practice: `givn-ideation` remains 10 lines of trigger plus direction;
     `givn-tasks` remains the 182-line tracked rule copy, byte-identical to its
     template render.
  2. **Convert the ten templates to trigger-only and move their rules into
     `extensions:`.** Gain: the literal criterion becomes true; cost: a large
     rewrite of tracked files, contradicting the proposal's out-of-scope rule.
     In practice: every project rule in `givn-tasks` would move into
     `givn/config.yaml`, changing the durable home the proposal says stays.
  3. **Drop the "no rule copy" check.** Gain: minimal edit; cost: no signal
     that a stale hand edit survives. In practice: a manually edited built-in
     skill from 0.8.4 would pass unnoticed.
- **Resolution:** Option 1. The proposal's out-of-scope section settles the
  intent (replacements stay). Rejected: Option 2 as scope expansion against a
  stated boundary; Option 3 as losing the only stale-edit signal. Recorded in
  `design.md` under "Installed-file criterion".

### Q2 — Did any hand edit exist under 0.8.4?

- **Status:** closed 2026-10-17 (operator)
- **Blocks:** the inventory disposition and the completion boundary ("every
  displaced project rule has a disposition").
- **Context:** generated rules were never tracked; the upgrade overwrote them
  locally at 14:24. The only tracked evidence is empty: zero generated files at
  `9207d06^`, empty `AGENTS.md` block diff, unchanged replacement templates.
- **Question:** did a hand-edited generated skill/command file or a hand edit
  inside the managed `givn-project` block exist, and if so what rule text?
- **Options:**
  1. **No hand edits (chosen).** Record "none found" with the checked file
     list; add no extension; archive normally. Gain: closes honestly; cost:
     none.
  2. **Yes — text or backup available.** Compare the rule against the served
     instruction and the tracked template, then record an extension or a
     stale-drop reason. Gain: the rule survives; cost: one config edit plus a
     serve check.
  3. **Not sure, no backup.** Record a named residual risk and follow-up;
     archive cannot claim completeness. Gain: honest; cost: an open risk.
- **Resolution:** Option 1. Operator stated no hand edits. Rejected: Option 2
  as unnecessary; Option 3 as it would leave an unproven boundary against the
  operator's statement. Recorded in the inventory.

### Q3 — How does a no-spec maintenance change satisfy tasks and review?

- **Status:** closed 2026-10-17 (orchestrator, from the bundle's execution
  model)
- **Blocks:** the shape of `tasks.md` and the review evidence.
- **Context:** `.givn-skip` = `specs`; no `.feature` exists. The design says to
  derive tasks from inventory rows and evidence the validation; the project's
  tasks instruction is scenario-shaped by default.
- **Question:** scenario-shaped tasks, a new check target, or a maintenance
  checklist?
- **Options:**
  1. **Maintenance checklist with exact commands and observed output
     (chosen).** Gain: honest and auditable; cost: deviates from the
     scenario-shaped default for a zero-scenario change. In practice: task 1
     runs the pre-upgrade scan and pastes "no output"; task 2 runs sync
     idempotence and pastes the empty diff.
  2. **Add one repository `@check:` derivation.** Gain: durable RED/GREEN;
     cost: new Nix check and scope growth for a tooling-only change. In
     practice: a derivation asserting no extension text in generated files.
  3. **Rely on `verify.command` plus manual spot-checks.** Gain: least work;
     cost: no audit trail, indistinguishable from an assertion.
- **Resolution:** Option 1. Recorded in `design.md` under "Verification binding
  and task evidence". Rejected: Option 2 as product-scope growth; Option 3 as
  unreviewable.

### Q4 — Is an extension actually served on every entry point?

- **Status:** closed 2026-10-17 (no rule displaced; recorded as an observation)
- **Context:** the installed skill templates for `archive`, `characterize`,
  `steps`, and `implement` do not all load their served instruction, though the
  slash commands do. A rule recorded there could be preserved yet unseen.
- **Resolution:** no rule was displaced, so no entry-point check is needed now.
  The observation is recorded in `design.md` under "Recorded observations" for
  the next migration. Rejected: rewriting the four templates (scope violation).

### Q5 — Do arc42 chapters 8 and 12 change?

- **Status:** closed 2026-10-17 (orchestrator)
- **Context:** chapter 8 names `givn/config.yaml` as the graph and hooks;
  chapter 12 already holds Givn workflow terms. With no extension recorded, the
  mechanism is not part of the project's documented architecture.
- **Resolution:** both stay "No". Row 12's rationale was broadened incorrectly
  ("Givn tooling vocabulary is not a domain term") and was replaced with the
  accurate reason: no term is introduced because no extension was recorded.
  The inventory outcome is stated in `arc42.md`. Rejected: adding
  `Project extension` to the glossary for a mechanism the project does not use.

## Findings resolved without the human

| # | Finding | Disposition |
|---|---|---|
| F1 | Inventory compared only against the served instruction, which would flag tracked template rules as displaced. | Corrected in `design.md`: compare against both the served instruction and the tracked replacement; template content is preserved by definition. |
| F2 | "No rule copy" is unsatisfiable for 40 replacement-backed files. | Scoped by replacement presence (Q1). |
| F3 | Preflight names invalid change id `migrate-0.8.4-to-0.9.1`. | Corrected to `migrate-0-8-4-to-0-9-1`; dotted form is title only. |
| F4 | Required inventory record absent. | Appended with checked file list and "none found" row. |
| F5 | Phase 2 conflates the served-base replacement with the installed-skill template. | Corrected: the artifact instruction is the served base; the `.tmpl` is the installed-file replacement; neither is edited. |
| F6 | "Output must end with `## Project extension`" is false; the CLI appends a trailing skill directive. | Corrected to "contains the section after the base rules"; no extension recorded, so nothing to serve. |
| F7 | `AGENTS.md` "was refreshed" claim is false. | Corrected: machine-owned, unchanged by this upgrade, empty diff recorded. |
| F8 | No procedure for a rule surviving in a current untracked generated file. | Added a current-file scan to Phase 1; run during hardening (no findings). |
| F9 | Design lacks project-owned sections (decisions, binding, blast radius, rollback, Persona). | Added: verification binding (no spec), architecture impact, blast radius, rollback N/A, Persona `none` with reason. |
| F10 | Task evidence format undefined. | Maintenance checklist with exact commands and observed output (Q3). |
| F11 | Proposal has no release note. | Proposal is the generated migration artifact and is left untouched per the design-review rule; the release note is recorded in `design.md` and used as the revision subject. |
| F12 | Bundle label `0.8.0 -> 0.9.0` vs change versions `0.8.4 -> 0.9.1`. | Recorded: bundle label is the applied route, top-level versions are the installed contract. |
| F13 | Phase 1 example command does not filter to `skills.targets`. | Recorded; all four targets are configured, so no current difference. |
| F14 | `givn-characterize` maps wholly to `characterize` though it carries `review-reverse` rules. | Recorded for the next migration; no rule displaced now. |
| F15 | Chapter 12 rationale too broad. | Replaced with the accurate no-extension reason. |
| F16 | Semantics probes (duplicate keys, unknown-id warnings, upgrade preservation, sync idempotence, commands config). | Verified as documented; no action. |

## Required-branch coverage

| Branch | Result |
|---|---|
| Scope | Proposal completion boundary mirrored; item 3 scoped by Q1; inventory present. No unexplained scope. |
| Tech choices | `extensions:` is the correct additive home; no extension is needed. Simpler alternative (editing templates) rejected as out of scope. |
| Missing behaviors | Current untracked files scanned; contradiction disposition stays visible per Givn semantics; `AGENTS.md` premise corrected; template rules no longer misclassified. |
| Testability / verification | Exact commands recorded with expected output; invalid id and false EOF claim corrected; criterion scoped. |
| Verification-binding completeness | N/A — no spec (`.givn-skip` = `specs`). `givn/commands.yaml` resolves; `verify.command` and `verify.e2e_command` are distinct and executable. |
| Deployment & rollback | N/A — no dangerous area. Blast radius and rollback recorded. |
| Risk | Most likely failure: silent loss of a hand-edited rule; mitigated by operator confirmation plus the current-file scan. Secondary: stale generated file; mitigated by sync idempotence check. |
| Decision ledger | No `D<n>` items in the proposal; hashes consistent across proposal/design/`migration.yaml`; version/id inconsistencies corrected or recorded. |
| Use-case / Persona | `none` — developer tooling change, no user-visible surface; no use-case ID. |
| Deferrals | None. The entry-point observation is recorded, not deferred work. |
| arc42 | Independently re-walked all 12 rows: all No, matching `arc42.md`. All 12 chapter files exist with real content; no ASCII-art diagrams. ADR candidate correctly NOT_QUALIFIED with one canonical artifact. Chapter 8/12 rationales corrected. |
| Ubiquitous language | No term introduced; glossary unchanged. |

## Hardening edits applied

| File | Edit |
|---|---|
| `givn/changes/migrate-0-8-4-to-0-9-1/design.md` | Appended preflight corrections, inventory, installed-file criterion, evidence commands, task-evidence format, architecture impact/blast radius/rollback, Persona `none`, observations, release note. |
| `givn/changes/migrate-0-8-4-to-0-9-1/arc42.md` | Row 12 rationale corrected; inventory outcome stated. |
| `givn/config.yaml` | Unchanged — no extension recorded. |
| `docs/arc42/**` | Unchanged — no chapter affected. |
| `specs/**` | None exist (intentionally skipped). No scenario added. |

`givn lint --change migrate-0-8-4-to-0-9-1`: no delta spec to lint (exit 0).
`python3 scripts/givn-spec-trace.py`: exit 0, 29 permanent scenarios, 0
findings.

DESIGN-REVIEW: PASS
