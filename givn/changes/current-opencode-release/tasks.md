# Tasks — current-opencode-release

Release note (carried as every commit's message subject):
**Both personal devices run a current OpenCode coding agent from a freshly
refreshed package, and each device refuses an OpenCode older than 2.0.28.**

Native targets this change adds or extends:

| Target | Kind | Wiring |
|---|---|---|
| `tests/assertions/thiniel-invariants.nix` | assertion (NixOS) | aggregated by `tests/assertions/default.nix`, imported by `hosts/thiniel/default.nix`, fired by `@host:thiniel` |
| `tests/assertions/J6G6Y9JK7L-invariants.nix` | assertion (home-manager) | imported by `home/dan/J6G6Y9JK7L.nix`, fired by `@host:J6G6Y9JK7L` |
| `checks.integration-agent-tooling` | `runNixOSTest`, Linux | `tests/integration/agent-tooling-test.nix` + `tests/integration/default.nix` + the flake's linux-systems block |
| `checks.unit-helpers` | unit (`lib.debug.runTests`) | `tests/unit/hm-dev-modules-test.nix` (the module instantiation gains the package argument) |

Use-case constraints that apply to every scenario below (from the change-side
`specs/reproduce-working-environment/usecase.md`, use case
`reproduce-working-environment`):

- "Each coding agent the device carries is at or above its accepted version
  floor, and currency is a floor rather than a schedule: refreshing an agent's
  source is the owner's deliberate action, not an automatic promise."
- "A device that carries the guarded coding agent also carries its guardrails
  … The rule is scoped to the agent with a user-level secret-access guard
  (today Oh My Pi (omp)); a second agent's guardrails are a separate concern and
  are not claimed by this contract." — OpenCode's guardrails are out of scope.
- "Check actual usable work context; a successful evaluation, launcher,
  directory creation or green transfer job is not alone work readiness." — for
  this change the *launch on a booted system* is the real-interface evidence.

**One RED/GREEN cycle covers all three scenarios.** The implementation is a
single step — refreshing the package pin — and it turns all three targets green
at once. A second cycle is impossible: once the pin carries `2.0.28`, neither
host floor can fail and the booted check cannot report below the floor, so a
later scenario could not go RED. The three scenarios therefore share one RED
observation and one GREEN, and the commit carries all three scenario titles.

---

## T1 — Setup: wire the targets and prove RED for all three scenarios [x]

- [x] T1.1 Use-case rules quoted verbatim at the top of this file; each scenario
      below names the rule it realises (floor; guardrails not extended).
      Evidence: the two rule quotations above.
- [x] T1.2 Runners differ: `verify.command = ./scripts/givn-verify.sh`,
      `verify.e2e_command = ./scripts/givn-verify-e2e.sh` (`givn/commands.yaml`).
      Evidence: both keys present and distinct.
- [x] T1.3 Delta bindings resolve: `python3 scripts/givn-spec-trace.py`.
      Evidence: exit 0 — `givn-spec-trace: 17 scenario(s) across 4 feature
      file(s), 0 finding(s)`; the only other output is two pre-existing
      `[warn]` lines for unreferenced integration checks
      (`integration-adlerkopf`, `integration-vm-minimal-ssh`).
- [x] T1.4 Floors raised in both assertion modules (`"2"` → `"2.0.28"`, messages
      updated).
      Evidence: `tests/assertions/thiniel-invariants.nix:21-23`,
      `tests/assertions/J6G6Y9JK7L-invariants.nix:214-216`.
- [x] T1.5 Booted check extended (optional `opencodePackage`, guest imports the
      module, three-component floor), forwarded by
      `tests/integration/default.nix`, passed by the flake's linux-systems block
      only where the overlay supports the system.
      Evidence: `tests/integration/agent-tooling-test.nix`,
      `tests/integration/default.nix`, `flake.nix` (linux block).
- [x] T1.6 RED for scenarios 1 and 2 (both targeted host evaluations, package
      still `2.0.22`).
      Evidence: exit 1 both —
      `- thiniel: OpenCode must be at version 2.0.28 or newer`;
      `- daniel.kressner profile: opencode: OpenCode must be at version 2.0.28 or newer`.
- [x] T1.7 RED for scenario 3: `nix build .#checks.x86_64-linux.integration-agent-tooling`.
      Evidence: exit 1 after a real boot —
      `AssertionError: OpenCode reports 'opencode v2.0.22', below the floor 2.0.28`
      (the guest ran `${opencodePackage}/bin/opencode --version` and the binary
      started, so the RED is behavioural, not an evaluation error).
- [x] T1.8 Unsupported system still evaluable:
      `nix eval --raw .#checks.aarch64-linux.integration-agent-tooling.drvPath`.
      Evidence: exit 0 — `/nix/store/bq72h3…-vm-test-run-agent-tooling.drv`.

## T2 — GREEN: refresh the package pin [x]

- [x] T2.1 `overlays/opencode/default.nix`: `version` `2.0.28`; both platform
      hashes replaced.
      Evidence: hashes measured with
      `nix store prefetch-file --json --hash-type sha512 <tarball>`; the method
      was validated by re-deriving the recorded `2.0.22` linux hash, which
      matched the overlay's literal exactly.
- [x] T2.2 Module takes the package:
      `home/dan/features/development/opencode.nix` now `{ pkgs, opencodePackage, ... }`
      and installs `opencodePackage`; both hosts pass `pkgs.opencode` through
      their `{ pkgs, ... }` module arguments, and
      `tests/unit/hm-dev-modules-test.nix` passes it in the instantiation.
      Deviation from the design as first written: a Home Manager module argument
      cannot default to another argument (both `? pkgs.opencode` and `? null`
      fail with "attribute `opencodePackage` missing"), so the argument is
      required. The design records the corrected decision.
- [x] T2.3 GREEN for scenarios 1 and 2: both targeted host evaluations.
      Evidence: exit 0 both; thiniel's declared package reports version `2.0.28`.
- [x] T2.4 GREEN for scenario 3: `nix build .#checks.x86_64-linux.integration-agent-tooling`.
      Evidence: exit 0 — the log shows `opencode-2.0.28.drv` built and the VM
      test passing (the guest started OpenCode 2.0.28 and the omp assertions of
      the same node stayed green).

## T3 — REFACTOR, lint, and commit [x]

- [x] T3.1 Format and lint without behaviour change.
      Evidence: `nixfmt` formatted `flake.nix` and
      `tests/integration/agent-tooling-test.nix`; `lint-nixfmt`, `lint-deadnix`,
      `lint-statix` and `unit-helpers` all exit 0; `./scripts/givn-verify.sh`
      re-evaluated every host configuration with its assertions (exit 0).
- [x] T3.2 `@wip` removed from all three delta scenarios.
      Evidence: the delta feature carries only `@givn.added` and binding tags.
- [x] T3.3 COMMIT: one revision for T1–T3, shared by all three scenarios (the
      shared cycle above).
      Evidence: 26 files, including the change artifacts and the arc42 updates.
  - [x] COMMIT: `006a49f` — `feat(current-agent-tooling): Both personal devices run a current OpenCode coding agent from a freshly refreshed package, and each device refuses an OpenCode older than 2.0.28.` (one commit for RED+GREEN+REFACTOR; scenario "The personal laptop carries a current OpenCode").
  - [x] COMMIT: `006a49f` — `feat(current-agent-tooling): <release note>` (same commit; scenario "The work MacBook carries the personal laptop's current OpenCode" — the pin refresh turns this floor green in the same step, so no separate cycle can go RED).
  - [x] COMMIT: `006a49f` — `feat(current-agent-tooling): <release note>` (same commit; scenario "A booted device starts its OpenCode" — the same refresh supplies the package the guest runs).

## T4 — Full verification and operator hand-off [x]

- [x] T4.1 `python3 scripts/givn-spec-trace.py` exits 0.
      Evidence: `17 scenario(s) across 4 feature file(s), 0 finding(s)`.
- [x] T4.2 `givn lint --change current-opencode-release` reports no `@wip`.
      Evidence: exit 0 — `1 file(s) checked — clean`; one `[SHAPE]` advisory
      noting the two host scenarios share a shape, which is inherent (a scenario
      carries exactly one binding tag, so the two hosts cannot be merged).
- [x] T4.3 `./scripts/givn-verify.sh` passes.
      Evidence: exit 0 — `[givn-verify] OK`; spec traceability, flake
      evaluation, the non-VM checks, every host configuration's assertions
      (`adlerkopf`, `cupix001`, `nixos-vm-minimal`, `thiniel`, `J6G6Y9JK7L`) and
      `256 passed in 6.83s` for the Python suite.
- [x] T4.4 `./scripts/givn-verify-e2e.sh` passes.
      Evidence: exit 0 — `[givn-verify-e2e] OK`; all five `integration-*` checks
      build for this system, `integration-agent-tooling` among them.
- [x] T4.5 Operator: apply on the laptop
      (`sudo nixos-rebuild switch --flake .#thiniel`) and confirm
      `opencode --version` reports at least `2.0.28`.
      Evidence (operator-reported, 2026-10-13): the switch succeeded on both
      machines. The floor is an evaluation-time assertion on the declared
      package, so a switch that builds and activates is the floor met on
      hardware — a below-floor OpenCode fails the evaluation before any
      activation. No separate `opencode --version` output was reported.
- [x] T4.6 Operator: apply on the Mac
      (`sudo darwin-rebuild switch --flake .#J6G6Y9JK7L`), confirm
      `opencode --version` reports at least `2.0.28`, and record
      `command -v opencode` resolving under the Nix store (D2's confirmation on
      the machine the repository cannot observe).
      Evidence (operator-reported, 2026-10-13): the switch succeeded on both
      machines (same evaluation-time floor reasoning as T4.5). D2 stands on the
      operator's answer of 2026-10-13 — no OpenCode exists on the Mac outside
      this configuration — and no separate `command -v opencode` output was
      reported.
- [x] T4.7 Operator: record the rollback path if either activation is rejected
      (`nixos-rebuild switch --rollback` / `darwin-rebuild rollback`).
      Evidence: not required — both activations succeeded. The rollback path
      stays as designed: `sudo nixos-rebuild switch --rollback` on thiniel,
      `sudo darwin-rebuild rollback` on the Mac. The package is not stateful, so
      nothing beyond the generation selection must be undone.
