# Review: quiet-configuration-evaluation

## Method

The change's five scenarios were implemented one RED→GREEN→REFACTOR→COMMIT cycle
at a time; every cycle's targeted command, evidence and commit hash are recorded
in `tasks.md`. This review re-derives the audit from the tree and the commits, not
from the task list's claims, and folds in an independent read-only review run in
a fresh context (`CompletionReview`, task tool, agent `reviewer`).

| Revision | Scenario / purpose | Configuration files touched |
|---|---|---|
| `4c5c088` | setup: wire the new `flake-output-contract` check (its own RED run is recorded there) | `flake.nix` |
| `8d58126` | The personal laptop states its compositor configuration format | `tests/assertions/thiniel-hm-invariants.nix`, `home/dan/thiniel.nix`, `home/dan/features/linux/hyprland.nix` |
| `5d147b8` | The personal laptop's browser profile lives under its XDG config directory and survives a root reset | `home/dan/features/productivity/browser.nix`, `tests/assertions/{thiniel-hm-invariants,thiniel-impermanence-invariants,J6G6Y9JK7L-invariants}.nix` |
| `f4e5b16` | The flake exposes only outputs the checker interprets | `flake.nix`, `flake.lock` |
| `aebcdd6` | A booted device reproduces its identity surface from a single release | `tests/integration/{default,ssh-identity-selection-test}.nix`, `flake.nix` |
| `d485719` | A booted device starts its coding agents from a single release | `tests/integration/agent-tooling-test.nix` |
| `12239b8` | task record and verification evidence | none (artifact record) |
| `a355e92` | planning artifacts and the arc42/plan-document updates | `docs/arc42/*.md`, `docs/plans/**` |

## Fabrication audit

| Requirement | Evidence | Clean? |
|---|---|---|
| No scenario's tags lost `@e2e` | The delta's two `@e2e` scenarios are declared `@givn.added @e2e @check:integration-…`; `git log -p` over the change's commits shows only `@wip` removals, never an `@e2e` removal | CLEAN |
| Every `@e2e` scenario binds to `@check:integration-*`, `@host:` or `@deploy:` | `quiet-configuration-evaluation.feature`: `@e2e @check:integration-ssh-identity-selection`, `@e2e @check:integration-agent-tooling` | CLEAN |
| Traceability | `python3 scripts/givn-spec-trace.py` → `givn-spec-trace: 22 scenario(s) across 4 feature file(s), 0 finding(s)`, exit 0 | CLEAN |

| Scenario | Binding tag | Target exists? |
|---|---|---|
| The personal laptop states its compositor configuration format | `@host:thiniel` | yes — `nixosConfigurations.thiniel` |
| The personal laptop's browser profile lives under its XDG config directory and survives a root reset | `@host:thiniel` | yes |
| A booted device reproduces its identity surface from a single release | `@e2e @check:integration-ssh-identity-selection` | yes — in `nix eval .#checks.x86_64-linux --apply builtins.attrNames` |
| A booted device starts its coding agents from a single release | `@e2e @check:integration-agent-tooling` | yes |
| The flake exposes only outputs the checker interprets | `@check:flake-output-contract` | yes — added by this change, fails before the withdrawal (setup task) |

| Scenario | Commit | Touches real configuration? |
|---|---|---|
| compositor configuration format | `8d58126` | yes — `home/dan/features/linux/hyprland.nix`, `tests/assertions/thiniel-hm-invariants.nix`, `home/dan/thiniel.nix` |
| browser profile relocation | `5d147b8` | yes — `home/dan/features/productivity/browser.nix`, three assertion modules |
| flake exposes only interpreted outputs | `f4e5b16` | yes — `flake.nix`, `flake.lock` |
| identity surface from a single release | `aebcdd6` | yes — `tests/integration/default.nix`, `tests/integration/ssh-identity-selection-test.nix`, `flake.nix` |
| coding agents from a single release | `d485719` | yes — `tests/integration/agent-tooling-test.nix` |

| Promised target (design.md) | Kind | Exists? | Path |
|---|---|---|---|
| Compositor format stated explicitly | configuration | yes | `home/dan/features/linux/hyprland.nix` (`configType = "hyprlang"`) |
| Browser profile location stated, guarded to Linux | configuration | yes | `home/dan/features/productivity/browser.nix` (`// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux`) |
| Browser persistence entry moved | configuration | yes | same file (`.config/mozilla`) |
| Superseded-default predicates | assertion (Home-Manager level) | yes | `tests/assertions/thiniel-hm-invariants.nix` |
| Fleet CLI and alias guards; Mac browser-path guard | assertions | yes | `tests/assertions/{thiniel-hm-invariants,J6G6Y9JK7L-invariants}.nix` |
| Rendered-profile and persistence assertions | assertion (NixOS level) | yes | `tests/assertions/thiniel-impermanence-invariants.nix` |
| Flake-output contract check | flake check | yes | `flake.nix` (`checks.<system>.flake-output-contract`) |
| Guest package set per Home-Manager-based check | wiring | yes | `tests/integration/default.nix`, `flake.nix` (`unstablePkgs`) |
| Fixture pairing assertions | assertions (VM nodes) | yes | both fixtures' `nodes.machine` |

| Scenario | Targeted command | RED non-zero for its own reason? | GREEN? |
|---|---|---|---|
| compositor configuration format | `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath` | yes — exit 1, `- dan profile: thiniel: the compositor configuration format must be stated by the device…` | yes — exit 0 |
| browser profile relocation | same | yes — exit 1 with all five of this scenario's assertions named (predicate, XDG file, legacy file, persistence present, persistence absent) | yes — exit 0 |
| flake exposes only interpreted outputs | `nix build --no-link .#checks.<system>.flake-output-contract` | yes — exit 1, `the flake declares outputs the checker does not interpret: colmenaHive` | yes — exit 0 |
| identity surface from a single release | `nix eval --raw '.#checks.x86_64-linux.integration-ssh-identity-selection.drvPath'` | yes — exit 1, `- the test profile's Home Manager release must equal the guest package set's release` | yes — exit 0, then the VM check builds |
| coding agents from a single release | `nix eval --raw '.#checks.x86_64-linux.integration-agent-tooling.drvPath'` | yes — exit 1, same assertion, against the fixture's pre-change pairing (temporarily restored for the RED, recorded in `tasks.md`) | yes — exit 0, then the VM check builds |

Each RED fails for the scenario's own assertion, not generically: the two host
evaluations name only that scenario's assertions, the check's failure names
`colmenaHive`, and the two fixture failures are the pairing assertion before its
wiring.

| @e2e Scenario | Target | Real interface? | Real observable assertion? | Downgraded? |
|---|---|---|---|---|
| identity surface from a single release | `checks.integration-ssh-identity-selection` (`pkgs.testers.runNixOSTest`) | yes — QEMU boot, `multi-user.target` and `home-manager-test.service` waited for | yes — `ssh -G github-personal` resolves to the declared key and the rendered config declares no foreign identity; plus the node's release-pairing assertion | no |
| coding agents from a single release | `checks.integration-agent-tooling` | yes — QEMU boot, activation waited for | yes — both agents start and report at or above their floors, and the guard is a regular file where the agent discovers hooks; plus the pairing assertion | no |

`verify.command` = `./scripts/givn-verify.sh`, `verify.e2e_command` =
`./scripts/givn-verify-e2e.sh`: not identical; the e2e command builds the
`integration-*` scope only (verified in `scripts/givn-verify-e2e.sh`). Scenario
counts: 22 total, 2 `@e2e` — strictly smaller, as required.

## Safety

- No plaintext secret is added; the diff touches no `secrets.yaml`, no `.sops.yaml`
  and no sops invocation. `scripts/private_data_hygiene.py` (the `private-data-hygiene` check) passed in the runner.
- `home.stateVersion` (`25.11`) and every `system.stateVersion` are unchanged —
  the superseded defaults are stated explicitly instead, which is the point of
  the change (`git diff` over the change's commits shows no `stateVersion` line).
- No `hardware.nix` is touched.
- Dangerous area: `home.persistence` is touched (the browser entry moves), so
  `design.md` carries a Deployment & Rollback section with the apply command, the
  on-host verification, the copy-before-delete move and the generation rollback
  (corrected during implementation to drop a non-existent separate Home-Manager
  generation step).

## Arc42 implementation conformance

| Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match? |
|---|---|---|---|---|---|---|
| Fleet deployment: the `colmena` input and empty hive are withdrawn, the CLI stays | `docs/arc42/04-solution-strategy.md`, `03-context-and-scope.md` (input list, diagram, fleet row), `06-runtime-view.md`, `07-deployment-view.md` | rows 3, 4, 6, 7 affected | Decisions D4 | scenario 3 + the guards | `flake.nix` (no `colmena` input, no `colmenaHive`, explanatory comment), `flake.lock` pruned, guards in `tests/assertions/thiniel-hm-invariants.nix` | MATCH |
| Browser profile lives under `~/.config/mozilla/firefox`, persisted as `.config/mozilla` | `docs/arc42/07-deployment-view.md` (`thiniel` property row), `08-crosscutting-concepts.md` | rows 7, 8 affected | Decisions D1, Technology Decisions | scenario 2 | `home/dan/features/productivity/browser.nix`, `tests/assertions/thiniel-impermanence-invariants.nix`; rendered keys observed | MATCH |
| Superseded defaults are stated explicitly, never by raising the state version | `docs/arc42/02-architecture-constraints.md`, `01-introduction-and-goals.md` R1 | rows 1, 2 affected | Decisions D1, D2 | scenarios 1, 2 | `home/dan/features/linux/hyprland.nix`, `browser.nix`; predicates in `thiniel-hm-invariants.nix` | MATCH |
| Flake declares only outputs the checker interprets | `docs/arc42/05-building-block-view.md` (flake box, tests rows) | rows 5, 10 (QS-001, QS-015) | Technology Decisions | scenario 3 | `flake-output-contract` check; `nix flake check` prints no unknown-output line | MATCH |
| Two Home-Manager-based checks build their guest from the pin those modules follow | `docs/arc42/05-building-block-view.md` (integration-tests row) | row 5 affected | Decisions D3 | scenarios 4, 5 | `tests/integration/default.nix`, `flake.nix`, fixtures' assertions | MATCH |
| Risks and debt of the change (unstable-pin evidence, live relocation, compositor format) | `docs/arc42/11-risks-and-technical-debt.md` | row 11 affected | Blast Radius, Deployment & Rollback | scenario 2, Task 6 | R-023, R-024, TD-015 rows present; TD-010 updated | MATCH |
| Glossary terms | `docs/arc42/12-glossary.md` | row 12 affected | decisions | all | `Superseded default` added, `Colmena hive` updated, `flake-output-contract` named in the `Check` enumeration | MATCH |

ARC42 CONFORMANCE: CLEAN

## Ubiquitous language conformance

The delta, design and implementation reuse the glossary's terms: `Superseded
default` (the two settings, in `thiniel-hm-invariants.nix` comments and the
assertion messages), `Colmena hive` (withdrawn, re-registered with the first
server), `Check (flake checks)` (the enumeration now names
`flake-output-contract`), `Persistence` (the relocated entry), `Flake`,
`Assertion`. No term used by the change is missing from the glossary, and no
existing term is reused inconsistently. CLEAN.

## Coverage gap classification

| Location | Traceability finding | Classification | Action |
|---|---|---|---|
| `integration-adlerkopf` | referenced by no scenario | Bucket 1 (an `integration-*` check no in-scope scenario binds) | Pre-existing and untouched by this change; kept under the standing operator decision recorded in `givn/archive/host-specific-ssh-identities/review.md` (bound by the change that specifies adlerkopf's service stack) |
| `integration-vm-minimal-ssh` | referenced by no scenario | Bucket 1 (same) | Pre-existing; bound in `givn/artifacts/specs/spec.feature`, which the traceability script does not scan; same standing decision |

No bucket-2 gap exists: every scenario of this change is bound to a target that
exists and failed before its implementation. No bucket-3 target. No invented
fourth bucket.

## Use-case and Persona conformance

Owning contract: `publish-infrastructure-configuration`, carried in the change as
`specs/publish-infrastructure-configuration/usecase.md` with the new capability
`quiet-configuration-evaluation` added to its capability list, its capability
interaction inventory and its rules (the superseded-default rule and the flow
clause about reporting no diagnostic to triage). Goal, guarantees, actors and
typed relationships are preserved; no summary goal is introduced; the new
capability is placed in the use case whose flow already requires a checkout that
evaluates and passes its checks.

Personas: `owner--operator` (confirmed 2026-10-11) — the operator runs the
evaluations and owns the browsing data; relevance recorded per scenario in the
design's traceability table. `family--application-user` is recorded as not
affected (no hosted application, shared resource or access path changes), with
the reason. No Persona was invented or silently promoted; actors in the scenarios
are interaction roles (`the personal laptop`, `a device`), never Persona
biographies.

## Deferrals

No mandatory check is deferred. `verify.command` and `verify.e2e_command` are
configured and were both run. The live browser relocation is an operator
procedure carried by the change (recorded in `tasks.md`, its rollback recorded in
`design.md`), not a verification deferral: the scenario's observable is asserted
at evaluation time without it.

## Independent review findings

A fresh-context read-only review (`CompletionReview`, task tool, agent
`reviewer`) audited items 0–11 against the tree and the commits. It passed the
`@e2e` integrity, traceability, promised-target, RED-specificity, e2e-reality,
e2e-isolation, safety, dangerous-area, design-conformance and language items, and
raised three findings, all remediated before sign-off:

| # | Severity | Finding | Disposition |
|---|---|---|---|
| 1 | P2 | The arc42 chapter-11 edit had silently replaced the pre-existing risk `R-021` with the two new rows, leaving the live cross-reference at `docs/arc42/08-crosscutting-concepts.md:198` dangling. | **Fixed**: `R-021` restored verbatim in its numeric position, with `R-023`/`R-024` after it; the chapter-8 cross-reference resolves again. |
| 2 | P3 | `tasks.md` recorded a COMMIT hash for the flake-output scenario that does not exist (`bb29d64`). | **Fixed**: replaced with the real commit `f4e5b16`; all five recorded hashes now resolve (`git cat-file -t` on each). |
| 3 | P3 | The arc42 chapter-5 assertion-module count said 18 where the tree has 20 (`*-invariants.nix`). | **Fixed**: the row now states 20 — the 17 aggregated NixOS-level modules plus the three Home-Manager-level ones (`thiniel-hm-invariants.nix` and the Mac's two). |

The reviewer also read the unreferenced `integration-vm-minimal-ssh` warning as a
bucket-2 gap, because the `@e2e` scenario that binds it lives in the unscanned
reference template `givn/artifacts/specs/spec.feature`, not in an active
feature file. That is pre-existing and is kept under the standing operator
decision recorded in `givn/archive/host-specific-ssh-identities/review.md`
(classified bucket 1 there and in every later review); the disposition is
recorded, not an excuse. It is not this change's gap.

## Sign-off

- [x] Traceability: `scripts/givn-spec-trace.py` exits 0, every scenario bound to
      exactly one existing target, no `@e2e` bound to a unit/lint check.
- [x] Every scenario's RED run failed before its implementation for its own
      reason, and passes after (evidence in `tasks.md`).
- [x] Promised targets all exist in the tree; no module, option, check or
      assertion promised by `design.md` is missing.
- [x] Safety: no secret, no `stateVersion` change, no `hardware.nix` change; the
      dangerous area carries Deployment & Rollback.
- [x] Both runners green: `./scripts/givn-verify.sh` → `[givn-verify] OK`,
      `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK`; `nix flake check`
      prints none of the change's four warnings.
- [x] Arc42 conformance clean; ubiquitous language clean; gaps classified.
- [x] Fabrication audit clean: 0 fabricated scenarios/targets found.

README-IMPACT: none. The `readme` addon is disabled in `givn/config.yaml`
(`readme: false`, disabled because the project README is hand-maintained), and
this change touches no consumer-visible command, flag, configuration or output
of the repository: it changes which values the laptop's profile states, the
guest package set of two checks, and the flake's declared output set. The
`README.md` mentions no flake output or check by name that this change alters.

REVIEW: PASS
