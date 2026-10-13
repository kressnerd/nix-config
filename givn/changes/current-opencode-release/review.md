# Review: current-opencode-release

## Method

A delegated reviewer (`reviewer`, fresh context, no part in writing the change)
performed the design-time grilling recorded in `design-review.md`, and a second
delegated reviewer re-checked the one design decision corrected during
implementation. The orchestrator ran the two gate runners on the working tree and
records their output below. Findings were remediated before sign-off.

Revisions of this change:

| Revision | Scenario / purpose | Configuration files touched |
|---|---|---|
| `006a49f` | The personal laptop carries a current OpenCode / The work MacBook carries the personal laptop's current OpenCode / A booted device starts its OpenCode (one commit: all three share one pin refresh) | `overlays/opencode/default.nix`, `home/dan/features/development/opencode.nix`, `flake.nix`, `tests/assertions/{thiniel,J6G6Y9JK7L}-invariants.nix`, `tests/integration/{agent-tooling-test,default}.nix`, `tests/unit/hm-dev-modules-test.nix`, `overlays/README.md`, nine `docs/arc42/` chapters |
| (artifact records) | the change's `proposal.md`, `specs/`, `design.md`, `arc42.md`, `design-review.md`, `tasks.md`, `review.md` | none (artifact records) |

## Fabrication Audit

**Traceability scan**

```
$ python3 scripts/givn-spec-trace.py
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
givn-spec-trace: 17 scenario(s) across 4 feature file(s), 0 finding(s)
trace exit=0
```

**@e2e tag integrity**

| Requirement | Evidence | Clean? |
|---|---|---|
| No scenario's tags were changed from including `@e2e` to excluding it | The commit's diff contains no `givn/specs/**` file (the permanent corpus is untouched); the delta adds one `@e2e` scenario | CLEAN |
| Every `@e2e` scenario binds to `@check:integration-*`, `@host:`, or `@deploy:` | `current-agent-tooling.feature:22` — `@givn.added @e2e @check:integration-agent-tooling` | CLEAN |

**Binding table**

| Scenario | Binding tag | Target exists in flake / tree? |
|---|---|---|
| The personal laptop carries a current OpenCode | `@host:thiniel` | yes — `nixosConfigurations.thiniel` |
| The work MacBook carries the personal laptop's current OpenCode | `@host:J6G6Y9JK7L` | yes — `darwinConfigurations.J6G6Y9JK7L` |
| A booted device starts its OpenCode | `@e2e @check:integration-agent-tooling` | yes — present in `nix eval .#checks.x86_64-linux --apply builtins.attrNames` |

**Commit cross-check**

| Scenario | Commit hash | Touches real configuration? |
|---|---|---|
| The personal laptop carries a current OpenCode | `006a49f` | yes — `overlays/opencode/default.nix`, `tests/assertions/thiniel-invariants.nix`, `flake.nix` |
| The work MacBook carries the personal laptop's current OpenCode | `006a49f` | yes — `tests/assertions/J6G6Y9JK7L-invariants.nix`, `flake.nix` |
| A booted device starts its OpenCode | `006a49f` | yes — `tests/integration/agent-tooling-test.nix`, `tests/integration/default.nix`, `flake.nix` |

All three scenarios share one commit because they share one implementation step
(the pin refresh); see `tasks.md` for why a second cycle cannot go RED.

**Promised-target existence**

| Promised target (from design.md) | Kind | Exists in tree? | Path |
|---|---|---|---|
| Refreshed package pin | overlay | yes | `overlays/opencode/default.nix` (`version = "2.0.28"`) |
| Module takes the package | module | yes | `home/dan/features/development/opencode.nix` (`{ pkgs, opencodePackage, ... }`) |
| Laptop floor assertion | assertion | yes | `tests/assertions/thiniel-invariants.nix` |
| Mac floor assertion | assertion | yes | `tests/assertions/J6G6Y9JK7L-invariants.nix` |
| Extended booted check | VM check | yes | `checks.integration-agent-tooling` |
| Integration aggregator forwarding | wiring | yes | `tests/integration/default.nix` |
| Flake passes the package (gated) | wiring | yes | `flake.nix` (linux-systems block, `builtins.elem system …meta.platforms`) |
| Unit instantiation | unit | yes | `tests/unit/hm-dev-modules-test.nix` |

**RED evidence**

| Scenario | Targeted command | RED exit non-zero (expected reason)? | GREEN passes? |
|---|---|---|---|
| The personal laptop carries a current OpenCode | `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath` | yes — exit 1, `- thiniel: OpenCode must be at version 2.0.28 or newer` | yes — exit 0 |
| The work MacBook carries the personal laptop's current OpenCode | `nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath` | yes — exit 1, `- daniel.kressner profile: opencode: OpenCode must be at version 2.0.28 or newer` | yes — exit 0 |
| A booted device starts its OpenCode | `nix build .#checks.x86_64-linux.integration-agent-tooling` | yes — exit 1 after a real boot, `AssertionError: OpenCode reports 'opencode v2.0.22', below the floor 2.0.28` | yes — exit 0 (guest starts OpenCode 2.0.28) |

**E2E reality**

| @e2e Scenario | Target | Boots / reaches real interface? | Real observable assertion? | Downgraded? |
|---|---|---|---|---|
| A booted device starts its OpenCode | `checks.integration-agent-tooling` (`pkgs.testers.runNixOSTest`) | yes — a real QEMU boot, `home-manager-test.service` waited for | yes — runs the declared package by store path and asserts the reported version triple is at least `(2, 0, 28)`, beside the omp assertions of the same node | no |

**E2E isolation**

| `verify.command` value | `verify.e2e_command` value | Identical? | Total scenario count | E2e scenario count | E2e strictly smaller (or all @e2e)? |
|---|---|---|---|---|---|
| `./scripts/givn-verify.sh` | `./scripts/givn-verify-e2e.sh` | no | 17 | 4 | yes — 4 < 17 |

**Safety**

| Check | Evidence | Clean? |
|---|---|---|
| No plaintext secret committed in the change | The diff adds only a version, two archive checksums, assertions, test code and prose; no credential material | CLEAN |
| No `sops`/decrypt invocation in any commit or script | `git show 006a49f` adds no such invocation (the added test text names none; the change is about a package version) | CLEAN |
| `system.stateVersion`/`home.stateVersion` unchanged | the commit's diff contains no such assignment (`git show 006a49f` — the only matches are prose in `design.md`) | CLEAN |
| `hosts/<host>/hardware.nix` unchanged | no `hardware.nix` in the diff | CLEAN |

**Dangerous areas**

| Dangerous area touched | design.md Deployment & Rollback section | Concrete rollback command |
|---|---|---|
| none — no `boot.loader`, `networking`, `fileSystems`/disko, impermanence, kernel or secret wiring | present anyway (`design.md` "Deployment & Rollback") | `sudo nixos-rebuild switch --rollback` / `sudo darwin-rebuild rollback` |

**Design conformance**

| Decision (from design.md) | design.md says | Actually built | Matches? | If not: was design.md updated + design-review re-run? |
|---|---|---|---|---|
| Package source | refresh `overlays/opencode` to 2.0.28 | version + both hashes replaced | yes | — |
| Floor | `lib.versionAtLeast … "2.0.28"` in both assertion modules | as specified | yes | — |
| Booted check | extend `integration-agent-tooling`, three-component comparison, gated package | as specified | yes | — |
| Package plumbing | **originally** `opencodePackage ? pkgs.opencode`, hosts use the default | argument is **required**; hosts pass their own `pkgs.opencode`, the booted check passes the overlay's package | no, corrected | yes — `design.md` (Technology Decisions, Decisions, Test Targets), `tasks.md` T2.2, `docs/arc42/05` updated, and design-review re-run (addendum below) |
| Check names, file paths | as listed in the Architecture Impact table | identical | yes | — |

**Result: 0 fabricated scenarios/targets found across 3 scenarios.** No
tautological target was found: the two host targets fail before the change for a
named reason (`2.0.22` below the floor), and the booted target failed on a real
boot with a real binary reporting `2.0.22`.

## Use-Case And Persona Conformance

| Contract | Evidence | Pass? |
|---|---|---|
| Owning use-case guarantees and rules preserved | the change-side `usecase.md` differs from the permanent contract by two rules (per-agent floors; guardrails scoped to the guarded agent), one interaction row, one example and one out-of-scope bullet | yes |
| Capability ownership and typed relationships preserved | `current-agent-tooling` extended (route: EXTEND, 12.60); `permitted-identity-selection` untouched and still green | yes |
| Confirmed Persona-relevant outcomes preserved | `owner--operator` (the operator runs OpenCode on both devices) | yes |
| Actors remain distinct from Persona biographies | the spec's actors are the device and the booted system; no Persona appears as an actor | yes |
| Migration ledger and coverage evidence complete, if applicable | n/a — no migration | n/a |

```
PERSONAS: owner--operator — relevant (the operator carries OpenCode on both personal devices and answered the Mac question); family--application-user unaffected — no application surface changes
```

## Deferred mandatory checks

None.

## Retirements

N/A — this change retires nothing.

## Arc42 implementation conformance

Independently derived from the completed tree and compared with `arc42.md`, the
durable chapters, `design.md` and `tasks.md`:

| Arc42 chapter or architectural fact | Durable-doc source | `arc42.md` claim | `design.md` treatment | `tasks.md` treatment | Completed implementation evidence | Match? / finding |
|---|---|---|---|---|---|---|
| 01 goal row names both floors | `01-introduction-and-goals.md:51` | affected | use-case traceability | T4 | two floor assertions in the tree | OK |
| 02 constraint: a package no channel carries | `02-architecture-constraints.md:14` | affected | Technology Decisions | T2 | `overlays/opencode/default.nix` | OK |
| 04 key decision 11 | `04-solution-strategy.md:66` | affected | Decisions D1 | T2.1 | the refreshed overlay | OK |
| 05 OpenCode Level-3 entry | `05-building-block-view.md:146-157` | affected | Architecture Impact | T2.2 | `opencode.nix` | OK — the argument row was corrected to "Required" |
| 07 both hosts' coding-agent rows | `07-deployment-view.md:114,139` | affected | Verification Binding | T1.4, T2.3 | the two assertions | OK |
| 08 fourth package source | `08-crosscutting-concepts.md:158-164` | affected | Technology Decisions | T2.1 | the overlay + `overlays/README.md` | OK |
| 09 NOT_QUALIFIED candidate row | `09-architecture-decisions.md:56` | affected | Decisions | — | register still holds one ADR | OK |
| 10 QS-014 for both agents | `10-quality-requirements.md:53` | affected | Verification Binding | T1, T2 | host assertions + booted check | OK |
| 11 R-022 | `11-risks-and-technical-debt.md:37` | affected | Blast Radius | — | the hand-pinned overlay | OK |
| 12 three glossary entries | `12-glossary.md:9,13,31` | affected | — | — | the entries name both agents | OK |

- [x] Every chapter marked affected by either assessment was opened and checked
      for stale, contradictory, or placeholder content (one stale sentence found
      and fixed: chapter 5's argument row said the argument defaults).
- [x] Every fact relevant to this change is represented in `design.md` and
      mapped to tasks in `tasks.md`.
- [x] The completed implementation follows those facts; the evidence names the
      built files, the assertions and the booted check.
- [x] Architecture changes discovered during implementation (the required
      argument) are recorded in the durable chapter and the change assessment.
- [x] No mismatch remains.

ARC42 CONFORMANCE: CLEAN

**Result:** CLEAN.

## Coverage (traceability coverage)

No archive receipt exists yet for this change — it is not archived. Classified
from the traceability run above plus static inspection.

```
givn-spec-trace: 17 scenario(s) across 4 feature file(s), 0 finding(s)
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
```

## Coverage gap classification

| Location (scenario / unreferenced check) | Traceability finding | Classification | Action taken |
|---|---|---|---|
| `integration-adlerkopf` | referenced by no scenario | **Bucket 1** (an `integration-*` check no in-scope scenario binds) | Pre-existing and untouched by this change; the standing operator decision of 2026-10-12 (`givn/archive/host-specific-ssh-identities/review.md`) is to keep it, bound by the change that specifies adlerkopf's service-stack capability. Recorded, not excused. |
| `integration-vm-minimal-ssh` | referenced by no scenario | **Bucket 1** (same) | Pre-existing; bound in `givn/artifacts/specs/spec.feature`, which the traceability script does not scan. Same standing decision: keep. |

No bucket-2 gap exists: every scenario of this change is bound to a target that
exists and failed before the change. No bucket-3 target and no invented fourth
category.

## Scenario execution evidence

```
unproven candidate — no archive receipt yet. The two gate runners were executed
on the working tree during this change:
  ./scripts/givn-verify.sh      → exit 0, "[givn-verify] OK" (5/5 stages, 256 python tests)
  ./scripts/givn-verify-e2e.sh  → exit 0, "[givn-verify-e2e] OK" (all five integration-* checks build)
The archive receipt is the single full-suite authority and is written at archive time.
```

**Receipt status:** not archived yet

## Overlap dispositions

| Scenario A | Scenario B | Disposition |
|---|---|---|
| The personal laptop carries a current OpenCode | The work MacBook carries the personal laptop's current OpenCode | boundary |

Disposition rationale: the two hosts carry the same package but are distinct
configurations with distinct assertions, and a scenario carries exactly one
binding tag, so they cannot be merged. `givn lint` reports the shape as an
advisory only.

## Split-or-keep

No scenario exceeds the lint length threshold.

## Sign-off

- [x] Fabrication audit: CLEAN.
- [x] Every `@e2e` scenario binds to `@check:integration-*` and actually boots.
- [x] `verify.e2e_command` is not identical to `verify.command`; the e2e scope
      count (4) is strictly smaller than the total (17).
- [x] No plaintext secrets; no `sops`/decrypt invocation; `stateVersion` and
      `hardware.nix` untouched.
- [x] Dangerous-area changes carry a Deployment & Rollback section (none
      touched; the section is present anyway).
- [x] Implementation matches `design.md` as reviewed; the one deviation (the
      required module argument) went through a `design.md` update and a
      design-review re-run.
- [x] Scenario execution evidence recorded per scope (not archived yet; the two
      gate runners recorded above).
- [x] Every coverage gap is classified and resolved.
- [x] No `@wip` tags remain in the delta spec.
- [x] The delta spec contains no implementation-layer detail.
- [x] No finding is excused with a classification outside the three buckets.

**REVIEW: PASS**
