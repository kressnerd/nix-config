# Review: migrate-0-8-4-to-0-9-1

Maintenance change with no product specification (`.givn-skip` = `specs`). The
fabrication-audit tables below are completed in that form: there are no delta
scenarios, no bindings, and no targeted RED runs. The audited claims are the
migration's verification steps, which `tasks.md` records command by command.

## Fabrication Audit (do this first)

**Traceability scan** — run `python3 scripts/givn-spec-trace.py`:

```
$ python3 scripts/givn-spec-trace.py
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)
[trace_exit=0]
```

**@e2e tag integrity** — this change has no delta spec, so no tag can have been
removed, and no `@e2e` scenario exists:

| Requirement | Evidence | Clean? |
|---|---|---|
| No scenario's tags were changed from including `@e2e` to excluding it | No delta `.feature` file exists (`givn/changes/migrate-0-8-4-to-0-9-1/specs/` absent; `.givn-skip` = `specs`) | Yes |
| Every `@e2e` scenario binds to `@check:integration-*`, `@host:`, or `@deploy:` | No `@e2e` scenario exists in this change | N/A |

**Binding table** — no scenario, therefore no binding:

| Scenario | Binding tag | Target exists in flake / tree? |
|---|---|---|
| — (no delta scenario) | — | — |

**Commit cross-check** — tasks in this change are verification steps, not
product modifications. The managed refresh that this change supervises is
commit `9207d06` (`.gitignore`, `givn/config.yaml`); the change's own commits
carry the artifacts and evidence:

| Task | Commit hash | Touches real configuration? |
|---|---|---|
| 1.1–4.2 verification steps | `971670a9eef5449d63dc85af6261eaa95ce3302b` | No product configuration change is claimed or required — the 0.9.1 contract and generated files are already installed by `9207d06`. The commit records the evidence. |
| 4.3 revision record | `bc7e0dc376da89aa549d5ad297a03f1352961cdb` | `tasks.md` revision record only |

The "checked task = configuration diff" rule is not satisfiable for a
verification-only maintenance task and is not claimed; the design review (Q3)
records the maintenance-checklist decision and its evidence format.

**Promised-target existence** — design.md promises no new module, option, host
definition, assertion, VM test, or flake check (inventory found no displaced
rule; no extension recorded):

| Promised target (from design.md) | Kind (module/option/host/check) | Exists in tree? | Path |
|---|---|---|---|
| — (none promised; no `extensions:` entry, no new target) | — | N/A | — |

**RED evidence** — no scenario exists, so no targeted RED run applies. Each
verification step in `tasks.md` records the exact command and observed output;
the negative checks (pre-upgrade scan, `AGENTS.md` diff, extension-text grep,
`extensions:` key) record empty output with their non-zero grep exit, and the
positive checks (`givn-verify.sh`, `givn-verify-e2e.sh`, trace, sync idempotence)
record exit 0:

| Scenario | Targeted command | RED exit non-zero (for expected reason)? | GREEN passes? |
|---|---|---|---|
| — (no delta scenario) | — | N/A | N/A |

**E2E reality** — no `@e2e` scenario exists:

| @e2e Scenario | Target | Boots / reaches real interface? | Real observable assertion? | Downgraded? |
|---|---|---|---|---|
| — | — | — | — | N/A |

**E2E isolation** — read from `givn/commands.yaml`:

| `verify.command` value | `verify.e2e_command` value | Identical? | Total scenario count | E2e scenario count | E2e strictly smaller (or all @e2e)? |
|---|---|---|---|---|---|
| `./scripts/givn-verify.sh` | `./scripts/givn-verify-e2e.sh` | No | 29 | 0 | Yes (0 < 29) |

The e2e runner was executed for this review: `./scripts/givn-verify-e2e.sh`
built `integration-adlerkopf`, `integration-agent-tooling`,
`integration-github-fetch-credential`, `integration-managed-file-displacement`,
`integration-private-data-separation`, `integration-ssh-identity-selection`,
`integration-vm-minimal-ssh`; `[givn-verify-e2e] OK`, exit 0.

**Safety**:

| Check | Evidence | Clean? |
|---|---|---|
| No plaintext secret committed in the change | `git diff 9207d06 HEAD --stat` lists only change artifacts (proposal/design/design-review/arc42/tasks/migration.yaml/.givn-skip) | Yes |
| No `sops`/decrypt invocation in any commit or script | No script or commit in this change invokes the secret tooling; the change touches no secret path | Yes |
| `system.stateVersion`/`home.stateVersion` unchanged | `git diff 9207d06 HEAD \| grep stateVersion` → no match | Yes |
| `hosts/<host>/hardware.nix` unchanged (unless an explicit hardware change) | `git diff 9207d06 HEAD -- 'hosts/**/hardware.nix'` → no output | Yes |

**Dangerous areas** — none touched:

| Dangerous area touched | design.md Deployment & Rollback section | Concrete rollback command |
|---|---|---|
| None (no boot loader, networking, filesystem/disko, persistence, kernel, or secret wiring) | Not required; design.md states N/A and records the rollback that would apply if an extension had been recorded | N/A — no deployment is involved |

**Design conformance**:

| Decision (from design.md) | design.md says | Actually built | Matches? | If not: was design.md updated + design-review re-run? |
|---|---|---|---|---|
| Inventory source | Compare pre-upgrade revision, `AGENTS.md` block, and current installed files against served instruction + tracked replacement | Exact commands recorded and run in tasks 2.1–2.4 | Yes | — |
| Installed-file criterion | Replacement-backed skills equal sync render; built-in skills/commands trigger-only; no extension text | tasks 3.1–3.3 record the checks and their output | Yes | — |
| Extension disposition | No entry added; `givn/config.yaml` unchanged | No `extensions:` key; `givn skills sync` idempotent | Yes | — |
| Verification | `./scripts/givn-verify.sh`, `python3 scripts/givn-spec-trace.py`, e2e not in scope | Both run and pass; e2e also run for the gate | Yes | — |
| Task evidence format | Maintenance checklist with exact command and observed output | `tasks.md` follows it | Yes | — |
| Arc42 | No chapter affected; marker records the inventory outcome | `arc42.md` rows all "No"; no chapter edited | Yes | — |

**Result:** 0 fabricated scenarios/targets found across 0 delta scenarios; 14
verification tasks with recorded command evidence, 0 fabricated.

## Use-Case And Persona Conformance

| Contract | Evidence | Pass? |
|---|---|---|
| Owning use-case guarantees and rules preserved | No use case applies (developer tooling migration; design.md and design-review record `none`) | N/A |
| Capability ownership and typed relationships preserved | No capability is added, removed, or moved | N/A |
| Confirmed Persona-relevant outcomes preserved | No Persona is confirmed for this change | N/A |
| Actors remain distinct from Persona biographies | No actor or Persona appears | N/A |
| Migration ledger and coverage evidence complete, if applicable | `migration.yaml` bundle recorded; inventory and evidence in `design.md` and `tasks.md` | Yes |

PERSONAS: none — developer tooling change with no user-visible system surface; no use-case ID applies (recorded in design.md; no Persona was requested or invented).

## Deferred mandatory checks

None.

## Retirements

N/A — this change retires nothing.

## Arc42 implementation conformance

The arc42 addon is enabled. This is a fresh review of the completed change against
the durable chapters, not a copy of the design-review table.

Independently derived facts: the change adds no module, host, option, check,
secret, or deployment step. It records a completed migration and its evidence.
Its only durable effects are the change directory and the fact that no
`extensions:` entry is needed. Every one of the 12 chapter rows was re-walked
against that implementation: all remain "No".

| Arc42 chapter or architectural fact | Durable-doc source | `arc42.md` claim | `design.md` treatment | `tasks.md` treatment | Completed implementation evidence | Match? / finding |
|---|---|---|---|---|---|---|
| No product component or module changed | [05](docs/arc42/05-building-block-view.md) | No | Blast radius section: developer tooling only | Tasks 1–4 touch no module | `git diff 9207d06 HEAD --stat` lists change artifacts only | Match |
| No runtime or deployment flow changed | [06](docs/arc42/06-runtime-view.md), [07](docs/arc42/07-deployment-view.md) | No | "Deployment and rollback are N/A" | No deployment task | No host file in the diff; e2e suite unchanged and green | Match |
| Specification-workflow facts (graph, hooks, verify commands) unchanged | [08](docs/arc42/08-crosscutting-concepts.md) | No | Installed-file and extension sections | Tasks 1.2, 3.3 | `givn/config.yaml` and `givn/commands.yaml` unchanged; commands distinct | Match |
| No ADR qualifies; canonical artifact is the change design | [09](docs/arc42/09-architecture-decisions.md) | No; verdict recorded | Decision recorded in design.md | Evidence tasks 1–3 | Register still holds ADR-0001 only; no ADR file added | Match |
| No new risk or debt item | [11](docs/arc42/11-risks-and-technical-debt.md) | No | Recorded: dropped-rule risk closed by operator confirmation; no new debt | No risk task | Inventory "none found"; no chapter edit | Match |
| No new vocabulary | [12](docs/arc42/12-glossary.md) | No | No extension recorded, so no term | No glossary task | No `extensions:` entry; glossary file unchanged | Match |

- [x] Every chapter marked affected by either the independent review or
      `arc42.md` was opened and checked — none are affected; all 12 were read.
- [x] Every Arc42 fact or decision relevant to this change is represented in
      `design.md` and mapped to tasks — the no-change facts map to tasks 1–4.
- [x] The completed implementation follows those facts and decisions; evidence
      names the diff and the commands.
- [x] Architecture changes discovered in the completed implementation are
      recorded — none discovered.
- [x] No mismatch remains; no design change was needed.

ARC42 CONFORMANCE: CLEAN

**Result:** CLEAN.

---

## Coverage (traceability coverage)

No archive verification receipt exists yet (the change is not archived).
Coverage is classified from the traceability run above and static inspection.
This change contributes no delta scenario; the 29 scenarios and 6 feature files
are the repository baseline.

**Traceability result:** 29 scenarios across 6 feature files, 0 findings; two
pre-existing unreferenced `integration-*` warnings.

```
$ python3 scripts/givn-spec-trace.py
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)
```

## Coverage gap classification

No coverage gap is introduced by this change (no delta scenario exists).

| Location (scenario / unreferenced check) | Traceability finding | Classification | Action taken |
|---|---|---|---|
| — (this change) | No delta scenario, so no new gap | N/A | None required |
| `integration-adlerkopf` (baseline warning, present before this change) | Not referenced by a scenario; the check exists and is documented as TD-011 | 3 — legitimately hard to bind for this maintenance change: there is no delta scenario to bind and no product spec in scope; the underlying unreachable `vmVariant` is already recorded as TD-011 | Left recorded in chapter 11 (TD-011); out of this change's scope |
| `integration-vm-minimal-ssh` (baseline warning, present before this change) | Not referenced by a scenario; documented in `docs/TESTING.md` and exercised by the e2e scope | 3 — legitimately hard to bind for this maintenance change: no delta scenario and no product spec in scope; it is a manually documented smoke check | Left recorded in `docs/TESTING.md`; out of this change's scope |

---

## Scenario execution evidence

The change is not archived yet, so no receipt exists:

**Receipt status:** unproven candidate — no receipt yet.

For the record, both scopes were run during implementation and review:
`./scripts/givn-verify.sh` exit 0 (`[givn-verify] OK`, 256 script tests passed)
and `./scripts/givn-verify-e2e.sh` exit 0 (`[givn-verify-e2e] OK`).

## Overlap dispositions

No delta scenario exists; the deterministic gate reports no overlap finding for
this change.

| Scenario A | Scenario B | Disposition |
|---|---|---|
| — | — | — |

## Split-or-keep

No delta scenario exists; no long-scenario finding applies.

| Scenario | Decision |
|---|---|
| — | — |

## Sign-off

- [x] Fabrication audit: CLEAN (traceability exits 0; no delta scenario exists,
      so no task claims a configuration diff, no promised target exists, and no
      targeted RED run applies — each verification step instead records its
      exact command and observed output).
- [x] Every `@e2e` scenario binds to `@check:integration-*`/`@host:`/`@deploy:`
      and actually boots or reaches the real interface — N/A, no `@e2e` scenario.
- [x] `verify.e2e_command` is not identical to `verify.command`; the e2e scope
      count is strictly smaller (0 < 29).
- [x] No plaintext secrets; no `sops`/decrypt invocation;
      `system.stateVersion`/`home.stateVersion` and `hardware.nix` untouched.
- [x] Dangerous-area changes carry a design.md Deployment & Rollback section —
      N/A, no dangerous area is touched.
- [x] Implementation (commands, file layout, check names) matches design.md as
      reviewed; no deviation was made.
- [x] Scenario execution evidence recorded per scope — archive receipt pending
      (change not archived); both runners exit 0 as recorded above.
- [x] Every coverage gap (including unreferenced `integration-*` checks) is
      classified and resolved from the most recent traceability evidence plus
      static inspection.
- [x] No `@wip` tags remain in the delta spec — no delta spec exists.
- [x] The delta spec contains no implementation-layer detail — no delta spec
      exists.
- [x] No finding anywhere in this report is excused with a classification
      outside the three buckets.

README-IMPACT: none

**REVIEW: PASS**
