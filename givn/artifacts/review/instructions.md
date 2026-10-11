# Instruction: review

Traceability-based completeness review. Goal: every scenario resolves to an
existing native target and every uncovered region is deliberately classified
and resolved. No percentage threshold. The canonical verification model is
`docs/GIVN-VERIFICATION.md`; read it first. This instruction does not restate
it.

## Step 0 (mandatory, first): fabrication audit

A change can reach review with every task checked off, the verification
command exiting 0, and almost nothing actually implemented — if a target never genuinely failed,
if a target does not exist, or if a scenario was never bound. Mechanical check,
before trusting any other artifact:

0. **@e2e tag integrity.** Grep every delta `.feature` file in
   `givn/changes/<change-id>/specs/`. If any scenario's tags were changed from
   including `@e2e` to excluding it, record this as a fabrication-audit finding:
   `@e2e` coverage was planned and then removed to bypass the verify-e2e gate.
   The fix is to restore the `@e2e` tag and configure `verify.e2e_command`, never
   to delete it. Confirm `scripts/givn-spec-trace.py` shows every `@e2e` scenario
   bound to `@check:integration-*`, `@host:<name>`, or `@deploy:<name>`.
   Tag removal is independently detected by `givn check review` and
   `givn lint` through tasks.md cross-reference.
1. **Traceability.** Run `python3 scripts/givn-spec-trace.py` and confirm it
   exits 0: every scenario is bound to **exactly one** target, each binding
   resolves (`@check:<name>` in the flake `checks` output, `@host:<name>` in
   `nixosConfigurations`/`darwinConfigurations`, `@deploy:<name>` with a matching
   `tests/deploy/test_<name>.py`), no scenario is unbound, and no `@e2e` scenario
   is bound to a plain unit/lint check. Paste the command and its summary line.
2. **Commit cross-check.** Every checked `[x]` task in tasks.md has a commit
   whose diff touches real configuration (`*.nix`, `scripts/`, `tests/`), not
   only the spec or the artifact files. No commit, or a diff touching only the
   spec/target skeleton with no configuration change = fabricated task.
3. **Promised-target existence.** Every module, option, host definition,
   assertion, VM test, or flake check that design.md promised exists in the tree
   (option defined under `modules/`, host under `hosts/`, check exposed in
   `flake.nix`). List anything missing — incomplete implementation, not a
   "hard to test" gap.
4. **RED evidence.** For each scenario, the targeted command from
   `docs/GIVN-VERIFICATION.md` ("Single-scenario (targeted) run") failed before
   implementation (pasted non-zero output in tasks.md, for the expected reason)
   and passes after. A scenario whose recorded RED exited 0, or has no RED
   evidence, is fabricated: the target never failed, so GREEN proves nothing —
   every PASS in this change is unverified. Confirm `verify.command` and
   `verify.e2e_command` are not identical strings.
5. **E2E reality.** Each `@e2e` scenario's integration test, host, or deploy
   target actually boots or reaches the real interface and asserts the observable
   state of the host/system — not a pure evaluation standing in for a real boot.
   A scenario that only asserts an evaluation result while wearing an `@e2e` tag
   is a downgraded e2e scenario: unfinished work regardless of GREEN.
6. **E2E isolation.** Read `verify.command` and `verify.e2e_command` literally
   from `givn/commands.yaml`. They must not be identical. The e2e command
   (`scripts/givn-verify-e2e.sh`) builds the `integration-*` scope only — the
   strict subset that actually boots a system. Record the e2e scope scenario count
   against the total from `scripts/givn-spec-trace.py`; the e2e count must be
   strictly smaller unless literally every in-scope scenario is `@e2e` (state
   this explicitly). If the counts are equal without that justification, the
   scope is missing or broken — a fabrication finding.
7. **Safety.** No plaintext secret is committed (scan new `*.nix`/scripts for
   inline credentials); no `sops`/decrypt invocation appears in any commit or
   script; `system.stateVersion`/`home.stateVersion` are unchanged;
   `hosts/<host>/hardware.nix` is unchanged unless the change is explicitly a
   hardware change.
8. **Dangerous areas.** If the change touches `boot.loader`, `networking`,
   `fileSystems`/disko, `environment.persistence`/impermanence, the kernel, or
   secret wiring, design.md carries a Deployment & Rollback section with a
   concrete rollback command. Missing = finding.
9. **Design conformance.** The implementation's commands, file layout, and check
   names match design.md. Any deviation that was not first recorded by updating
   design.md and re-running design-review is a finding — an implementation that
   silently overrode an already-reviewed design decision. The fix is to conform
   the implementation to design.md, or to update design.md with the corrected
   decision and re-run design-review (reassessing the arc42 chapter table if the
   change is structural) — never to keep the deviation silently.
10. Findings from 1–9 are unfinished work, not coverage gaps. Reopen the task and
    run RED→GREEN→REFACTOR→COMMIT for real. Do not write `REVIEW: PASS` while any
    finding remains.

Record the result even when clean: "0 fabricated scenarios/targets found across
N scenarios."

## Arc42 implementation conformance (conditional)

Run this block after the fabrication audit and before coverage classification.

If `addons.arc42` is disabled in `givn/config.yaml`, write exactly:
`N/A when the arc42 addon is disabled` and continue. Do not invent an Arc42
finding for a project that has opted out.

If the addon is enabled, the check is mandatory. It catches both directions of
drift: durable architecture documentation that is stale or missing a completed
change, and architecture facts that the change's design, tasks, or completed
implementation ignores or contradicts.

1. Read the durable `docs/arc42/` chapters and the change-level `arc42.md`.
2. Independently derive the affected chapters and concrete architecture facts
   from the completed implementation, `design.md`, and `tasks.md` before
   accepting the change-level Arc42 claims.
3. For every chapter marked affected by either assessment, open the chapter and
   check that it contains current, decision-specific content rather than a
   placeholder or stale contradiction.
4. Cross-reference each relevant fact or decision against `design.md`, the
   specific task(s) in `tasks.md`, and evidence from the completed
   implementation. Record the full comparison in the `Arc42 implementation
   conformance` block of `review.md`:

   | Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match? |
   |---|---|---|---|---|---|---|
   | | | | | | | |

5. Treat every omission, contradiction, stale chapter, or missing task mapping
   as a finding. Fix the affected Arc42 chapter, `arc42.md`, `design.md`,
   `tasks.md`, or implementation, then repeat the comparison. If `design.md`
   changes, run design-review again before continuing.
6. Record `ARC42 CONFORMANCE: CLEAN` as the explicit clean marker only when
   every row matches and all five sign-off checks in the template are checked.
   Do not write `REVIEW: PASS` while this block contains an unresolved finding.

## Coverage (traceability coverage)

There is no instrumented coverage metric: `addons.coverage` is disabled — a
declarative Nix repository has no running production process to instrument.
Coverage here is scenario-to-target traceability, computed by
`scripts/givn-spec-trace.py` and published in the archive verification receipt
and README. Review does not run an
instrumented pass; it classifies gaps from the traceability output plus static
inspection. If no receipt exists yet for this change, say so explicitly and
classify from the traceability run.

- Every scenario resolves to an existing target (`@check:<name>` present in the
  flake `checks` output, `@host:<name>` in the host configurations,
  `@deploy:<name>` with a matching deploy test file).
- Unreferenced `integration-*` checks are reported as
  `[warn] integration check '<name>' is not referenced by any scenario` — each is
  either dead config (delete it) or a missing scenario (bind it).

## Classification (three buckets — no fourth bucket)

1. Dead config (YAGNI/KISS) → delete the unused module/option/check and its
   `flake.nix` wiring.
2. Missing test coverage → add the target and run RED→GREEN→REFACTOR→COMMIT.
3. Legitimately hard to test (rare) → concrete technical justification.

These three buckets are exhaustive. **Any classification outside them is itself
a fabrication-audit finding, not a valid outcome** — e.g. "acceptable for this
iteration scope," "sufficient for current scope," "future scope," "good enough
for now," or any similar invented exception that waves off a required check
instead of fixing it or explicitly justifying it under bucket 3. A missing or
downgraded `@e2e` scenario always classifies as bucket 2 (missing test coverage)
— it can never be excused into a fourth, undefined bucket. If you find yourself
writing a sentence that excuses a gap without naming one of the three buckets
above, stop and reclassify it.

Redundant unit tests (behaviour already covered by a `.feature` scenario
through a bound target) are removed — the `.feature` file is the source of
truth.

## Deferrals

A deferral of a mandatory check without a recorded operator decision fails the
review.

## Use-case and Persona conformance

Read the owning `usecase.md`, the proposal's use-case context, and any ideation
change seed. Confirm implementation preserves the use-case guarantees, rules,
typed relationships, capability ownership, and confirmed Persona-relevant
outcomes. Actors remain interaction roles; Persona biographies remain review
context. Record migration-ledger evidence where applicable. Do not sign off
invented or silently promoted Personas.

Record the disposition for every confirmed Persona; when none is confirmed,
record the reason. An infra change almost always records `none` with a reason —
do not invent a Persona for it.

### Use-case scope rejection criteria

A review fails when any of these holds. Each criterion names the observable
document section that proves it; the durable reference is
`docs/use-case-model.md`.

- **Goal conjunction** — `## Goal` joins two verb phrases, or
  `## Success guarantee` names two outcomes.
- **Missing primary actor** — `## Actors` has no identifiable primary, or
  `## Trigger` does not name them.
- **Placement failure** — `## Capabilities` contains a capability that fails
  the placement test for this goal.
- **Mutation under an observing goal** — a capability's scenarios assert a
  state change while the guarantees declare observation.
- **Extension without a step reference** — `## Extensions` omits its
  main-flow step, or adds a new success outcome.
- **Inconsistent preconditions** — a precondition is established by the flow;
  the success guarantee is assumed; the trigger is a state or desire; an
  unqualified guarantee whose prerequisite is open (`(open: Q<N>)`).
- **Mechanism vocabulary** — `## Goal`, `## Trigger`, or the guarantees name
  a mechanism.
- **Component- or channel-shaped name** — a use-case or capability name names
  a technical component or channel.
- **Oversized leaf** — a leaf's `## Main flow` names three or more actor
  goals.
- **Relationship misuse** — `Extends` without a stated condition; an
  end-user goal placed as a fragment or vice versa.

## Deterministic gate dispositions

For every shape match involving the change, complete the **Overlap
dispositions** table in `review.md`. Write the section with the exact
heading `## Overlap dispositions` and one row per finding pair. The
Decision column must be exactly one of `duplicate`, `variant`, or
`boundary` (case-insensitive) — an empty or unrecognised word does not
clear the finding. For every scenario longer than the gate threshold,
record a **split-or-keep** decision: write the section with the exact
heading `## Split-or-keep`, one row per long scenario, each Decision
either `split` or `keep`. For every removed+added pair, record whether the
new scenario supersedes the removed one or is unrelated. These decisions
are review evidence, not score thresholds. An overlap finding is
advisory evidence until its disposition is recorded; the recorded disposition,
not the finding's presence, is the completed verification evidence.

## Sign-off checklist

- Fabrication audit: clean (or all findings remediated).
- Traceability check (`scripts/givn-spec-trace.py`) exits 0: every scenario
  bound to exactly one existing target; no unbound scenario.
- Every checked task has a verified commit touching real configuration.
- Every promised module/option/host/check exists.
- Targeted RED evidence present for every scenario (non-zero before
  implementation); no scenario whose target never failed.
- Every `@e2e` scenario binds to `@check:integration-*`/`@host:`/`@deploy:` and
  actually boots or reaches the real interface; no `@e2e` tag was removed.
- `verify.e2e_command` is not identical to `verify.command`; the e2e scope is
  the `integration-*` subset (counts prove it, or "all scenarios are @e2e" is
  stated).
- No plaintext secrets; no `sops`/decrypt invocation;
  `system.stateVersion`/`home.stateVersion` and `hardware.nix` untouched.
- Dangerous-area changes carry a design.md Deployment & Rollback section.
- Implementation (commands, file layout, check names) matches design.md as
  reviewed; any deviation went through a design.md update + design-review
  re-run, not a silent shortcut.
- Coverage classification uses the most recent traceability evidence.
- Every coverage gap classified and resolved (dead config deleted; missing
  targets added; hard-to-test gaps justified).
- No `@wip` tags remain. No implementation-layer detail in the spec.
- Scenario execution evidence is recorded per scope in the archive verification
  receipt; review does not re-run the suite.
- No finding was excused with a classification outside the three buckets.

## Result

End the file with `REVIEW: PASS` or `REVIEW: FAIL`. The archive gate reads
this marker.
