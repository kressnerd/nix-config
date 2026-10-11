# Review: {{CHANGE_ID}}

## Fabrication Audit (do this first)

**Traceability scan** — run `python3 scripts/givn-spec-trace.py`. It must exit
0: every scenario bound to exactly one existing target, no unbound scenario, no
`@e2e` scenario bound to a plain unit/lint check:

```
<!-- paste the trace summary line, e.g.
givn-spec-trace: N scenario(s) across F feature file(s), 0 finding(s)
plus any [FAIL]/[warn] lines -->
```

**@e2e tag integrity** — none of this change's delta scenarios had `@e2e`
removed; every `@e2e` scenario binds to `@check:integration-*`/`@host:`/`@deploy:`:

| Requirement | Evidence | Clean? |
|---|---|---|
| No scenario's tags were changed from including `@e2e` to excluding it | | |
| Every `@e2e` scenario binds to `@check:integration-*`, `@host:`, or `@deploy:` | | |

**Binding table** — each scenario's single binding tag and whether it resolves:

| Scenario | Binding tag | Target exists in flake / tree? |
|---|---|---|
| | | |

**Commit cross-check** — every checked-off `[x]` task in tasks.md has a matching
commit whose diff touches real configuration (`*.nix`, `scripts/`, `tests/`),
not only the spec/artifact files:

| Scenario | Commit hash | Touches real configuration? |
|---|---|---|
| | | |

**Promised-target existence** — every module, option, host definition,
assertion, VM test, or flake check design.md promised actually exists:

| Promised target (from design.md) | Kind (module/option/host/check) | Exists in tree? | Path |
|---|---|---|---|
| | | | |

**RED evidence** — for each scenario the targeted command from
`docs/GIVN-VERIFICATION.md` failed before implementation (pasted non-zero) and
passes after; a target that never failed is fabricated:

| Scenario | Targeted command | RED exit non-zero (for expected reason)? | GREEN passes? |
|---|---|---|---|
| | | | |

**E2E reality** — each `@e2e` scenario's integration/host/deploy target
actually boots or reaches the real interface and asserts the observable state
of the host/system, not a pure evaluation standing in for a real boot:

| @e2e Scenario | Target | Boots / reaches real interface? | Real observable assertion? | Downgraded? |
|---|---|---|---|---|
| | | | | |

**E2E isolation** — `verify.command` and `verify.e2e_command` read literally
from `givn/commands.yaml`. If identical, this is always a finding (the "e2e
run" is not isolating `@e2e` scenarios at all). Prove isolation with the
per-scope scenario counts:

| `verify.command` value | `verify.e2e_command` value | Identical? | Total scenario count | E2e scenario count | E2e strictly smaller (or all @e2e)? |
|---|---|---|---|---|---|
| | | | | | |

**Safety** — no plaintext secret, no `sops`/decrypt invocation,
`stateVersion`/`hardware.nix` untouched:

| Check | Evidence | Clean? |
|---|---|---|
| No plaintext secret committed in the change | | |
| No `sops`/decrypt invocation in any commit or script | | |
| `system.stateVersion`/`home.stateVersion` unchanged | | |
| `hosts/<host>/hardware.nix` unchanged (unless an explicit hardware change) | | |

**Dangerous areas** — if the change touches `boot.loader`, `networking`,
`fileSystems`/disko, `environment.persistence`/impermanence, the kernel, or
secret wiring, design.md carries a Deployment & Rollback section with a concrete
rollback command:

| Dangerous area touched | design.md Deployment & Rollback section | Concrete rollback command |
|---|---|---|
| | | |

**Design conformance** — implementation's commands, file layout, and check
names compared to what design.md explicitly named. Any deviation implemented
without first updating design.md and re-running design-review is a finding,
not an acceptable shortcut:

| Decision (from design.md) | design.md says | Actually built | Matches? | If not: was design.md updated + design-review re-run? |
|---|---|---|---|---|
| | | | | |

**Result even when clean:** `0 fabricated scenarios/targets found across N scenarios.`

## Use-Case And Persona Conformance

| Contract | Evidence | Pass? |
|---|---|---|
| Owning use-case guarantees and rules preserved | | |
| Capability ownership and typed relationships preserved | | |
| Confirmed Persona-relevant outcomes preserved | | |
| Actors remain distinct from Persona biographies | | |
| Migration ledger and coverage evidence complete, if applicable | | |

Record the persona disposition as a real `PERSONAS:` line outside any code
fence. An infra change with no user-visible surface records the reason instead
of inventing one:

```
PERSONAS: none — <reason + operator confirmation>
```

## Deferred mandatory checks

A mandatory check may be deferred only after an operator question. Record the
pair as real lines outside any code fence; a `DEFERRAL:` without a matching
`OPERATOR-DECISION:` fails the review. Omit both lines when nothing is
deferred.

```
DEFERRAL: <mandatory check>
OPERATOR-DECISION: <the operator's recorded decision>
```

## Retirements

For every capability retired by this change (a delta tagged
`@givn.retired`), one line naming it and why:

RETIRE: <capability-id> — <reason>

N/A if this change retires nothing.

## Arc42 implementation conformance

**N/A when the arc42 addon is disabled.** When `addons.arc42` is enabled, this
is a mandatory comparison of the durable `docs/arc42/` chapters and the
change-level `arc42.md` assessment against `design.md`, `tasks.md`, and the
completed implementation. This is a fresh implementation review, not a copy of
the design-review table.

First derive the architectural facts and affected chapters from the completed
change and the current durable documentation. Then compare the change-level
Arc42 claims. Read each chapter named by either assessment and record concrete
evidence in the table:

| Arc42 chapter or architectural fact | Durable-doc source | `arc42.md` claim | `design.md` treatment | `tasks.md` treatment | Completed implementation evidence | Match? / finding |
|---|---|---|---|---|---|---|
| | | | | | | |

- [ ] Every chapter marked affected by either the independent review or
      `arc42.md` was opened and checked for stale, contradictory, or placeholder
      content.
- [ ] Every Arc42 fact or architecture decision relevant to this change is
      represented in `design.md` and mapped to one or more tasks in `tasks.md`.
- [ ] The completed implementation follows those facts and decisions; evidence
      names the built file, command, test, or observable result.
- [ ] Architecture changes discovered in the completed implementation are
      recorded in the durable Arc42 chapter and the change-level assessment.
- [ ] No mismatch remains. A mismatch was fixed in the affected documentation,
      design, tasks, or implementation and this comparison was repeated; a
      design change also triggered design-review again.

ARC42 CONFORMANCE: CLEAN / FINDINGS

**Result:** CLEAN / FINDINGS (if findings, list remediation taken — reopened
tasks, re-run RED/GREEN/REFACTOR/COMMIT, or design.md corrected + design-review
re-run — before continuing this review).

---

## Coverage (traceability coverage)

Coverage here is scenario-to-target traceability, computed by
`scripts/givn-spec-trace.py` and recorded in the archive verification receipt.
There is no instrumented coverage metric (`addons.coverage` is disabled — a
declarative Nix repository has no running production process to instrument).
Review does not run an instrumented pass; classify gaps from the most recent
traceability output plus static inspection, and say explicitly when no receipt
exists yet.

**Traceability result:** <!-- paste the trace summary and any unreferenced
`integration-*` warnings from givn/archive/<id>/verification.json, or state
explicitly that no receipt exists yet. -->

```
<!-- paste the traceability summary / integration-check warnings here -->
```

## Coverage gap classification

Every gap must be classified as exactly one of:
1. **Dead config** (YAGNI/KISS) → delete the unused module/option/check and its
   `flake.nix` wiring.
2. **Missing test coverage** → add the target and run RED/GREEN/REFACTOR/COMMIT.
3. **Legitimately hard to test** — rare; requires concrete technical
   justification.

These three buckets are exhaustive — **no fourth bucket**. Do not excuse a gap
with invented language such as "acceptable for this iteration scope,"
"sufficient for current scope," or "future scope" — a missing or downgraded
`@e2e` scenario is always bucket 2 (missing test coverage).

Coverage is **complete** when every gap — including every unreferenced
`integration-*` check — is classified and resolved.

| Location (scenario / unreferenced check) | Traceability finding | Classification | Action taken |
|---|---|---|---|
| | | | |

---

## Scenario execution evidence

Review does not re-run the suite. Record the last archive verification receipt
for this change (or state that the change has not been archived yet):

```
<!-- paste the receipt's per-scope status and counts from
     givn/archive/<id>/verification.json, or state "unproven candidate — no
     receipt yet". Never paste a fresh manual full-suite run here: the archive
     is the single full-suite authority. -->
```

**Receipt status:** proven / unproven / not archived yet

## Overlap dispositions

For every shape-match finding involving this change's delta, one row.
Decision must be one of: `duplicate`, `variant`, `boundary`.

| Scenario A | Scenario B | Disposition |
|---|---|---|
| | | |

## Split-or-keep

For every scenario longer than the lint threshold, one row: `split` or `keep`.

| Scenario | Decision |
|---|---|
| | |

## Sign-off

- [ ] Fabrication audit: CLEAN (traceability exits 0, every checked task has a
      commit touching real configuration, every promised target exists, targeted
      RED evidence present for every scenario, no downgraded e2e scenario, no
      `@e2e` tag removed).
- [ ] Every `@e2e` scenario binds to `@check:integration-*`/`@host:`/`@deploy:`
      and actually boots or reaches the real interface.
- [ ] `verify.e2e_command` is not identical to `verify.command`; the e2e scope
      count is strictly smaller (or "all scenarios are @e2e" is stated).
- [ ] No plaintext secrets; no `sops`/decrypt invocation;
      `system.stateVersion`/`home.stateVersion` and `hardware.nix` untouched.
- [ ] Dangerous-area changes carry a design.md Deployment & Rollback section
      with a concrete rollback command.
- [ ] Implementation (commands, file layout, check names) matches design.md as
      reviewed; any deviation went through a design.md update + design-review
      re-run, not a silent shortcut.
- [ ] Scenario execution evidence recorded per scope in the archive verification
      receipt (review does not run the suite).
- [ ] Every coverage gap (including unreferenced `integration-*` checks) is
      classified and resolved from the most recent traceability evidence plus
      static inspection.
- [ ] No `@wip` tags remain in the delta spec.
- [ ] The delta spec contains no implementation-layer detail.
- [ ] No finding anywhere in this report is excused with a classification
      outside the three buckets (no "acceptable for now," "future scope,"
      "sufficient for current scope," or similar invented exception).

**REVIEW: PASS** <!-- change to FAIL if any sign-off item is unchecked -->
