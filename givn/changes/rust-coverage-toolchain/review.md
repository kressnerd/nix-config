# Review — rust-coverage-toolchain

- Date: 2026-10-27
- Scope: `proposal.md`, `specs/reproduce-working-environment/*`, `design.md`,
  `design-review.md`, `arc42.md`, `tasks.md`, and the implementation commits
  `a32a4e8` and `98a6861`.
- Method: fabrication audit against the tree and the two commits, then the
  arc42 implementation-conformance comparison, then traceability
  classification.

## Step 0 — fabrication audit

0. **@e2e tag integrity.** Both delta scenarios carry `@e2e`; no tag was
   removed or downgraded. `scripts/givn-spec-trace.py` accepts both as
   `@check:integration-rust-toolchain`, a `pkgs.testers.runNixOSTest` VM check.
1. **Traceability.** Repository-wide the script reports 21 findings, all owned
   by the two other active changes (`provision-storage-host`,
   `security-key-remote-identity`); none names this change's files or targets.
   With those two change directories temporarily aside (restored afterwards),
   the same script over the permanent specs plus this change reports:
   ```
   $ python3 scripts/givn-spec-trace.py
   givn-spec-trace: 37 scenario(s) across 9 feature file(s), 0 finding(s)
   exit 0
   ```
   Both scenarios are bound to exactly one resolving target; no scenario is
   unbound; no `@e2e` scenario binds to a plain unit/lint check.
2. **Commit cross-check.** `a32a4e8` touches `flake.nix`, `flake.lock`,
   `lib/helpers.nix`, `home/dan/features/development/rust.nix`,
   `formatters.nix`, `home/dan/J6G6Y9JK7L.nix`, the assertion and VM test, and
   the arc42 chapters; `98a6861` touches `lib/helpers.nix`, `rust.nix`,
   `flake.nix`, the VM test and the arc42 chapters. Both carry real
   configuration and test changes, not only spec or artifact files.
3. **Promised-target existence.** Present: input `rust-overlay` and
   `rustToolchainFor`/`cargoLlvmCovFor` in `flake.nix`; `mkRustToolchain` in
   `lib/helpers.nix`; `rustToolchain`/`cargoLlvmCov` arguments in `rust.nix`,
   the thiniel Home Manager arguments, `tests/integration/default.nix` and the
   VM test; the sysroot, formatter and coverage steps in the VM test; the
   toolchain assertion in `thiniel-hm-invariants.nix`.
4. **RED evidence.** Scenario 1: host evaluation exit 1 on the new assertion and
   the VM check exit 1 on
   `test -x /nix/store/…-rustc-1.99.0/bin/rustfmt` (pasted in tasks.md). Scenario
   2: VM check exit 1 on `error: no such command: 'llvm-cov'` (pasted). Both
   scenarios passed after their own GREEN. `verify.command` is
   `./scripts/givn-verify.sh`; `verify.e2e_command` is
   `./scripts/givn-verify-e2e.sh` — distinct strings.
5. **E2E reality.** Both scenarios bind to the VM check, which boots a NixOS
   machine, builds a project in that machine, and reads the produced coverage
   report; the check is not an evaluation standing in for a boot.
6. **E2E isolation.** `verify.e2e_command` builds only `integration-*` checks.
   Repository-wide counts: 20 `@e2e` scenarios against 64 total, so the scope
   is strictly smaller.
7. **Safety.** No new secret, no `sops`/decrypt invocation; `stateVersion`
   values and `hosts/*/hardware.nix` are unchanged (the two commits touch no
   host file).
8. **Dangerous areas.** The change touches no boot, networking, filesystem,
   kernel or secret wiring; the existing `.cargo` persistence entry is
   unchanged. `design.md` nevertheless records the apply, on-host verification,
   shim quarantine and generation rollback.
9. **Design conformance.** One deviation was found and remediated before
   review: the reviewed design named `cargo-llvm-cov` from `nixpkgs-unstable`
   (0.9.0), which does not build at the pin (its own test suite segfaults);
   the implementation takes 0.8.7 from stable and passes it as `cargoLlvmCov`.
   `design.md` was updated and `design-review.md` re-run (finding F14), rather
   than keeping the deviation silently.
10. **Result.** 0 fabricated scenarios/targets found across 2 scenarios.

## Arc42 implementation conformance

| Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match? |
|---|---|---|---|---|---|---|
| Toolchain-source constraint | `02-architecture-constraints.md` row 15 | Affected | Tech table, D1 | Task 1 GREEN | `flake.nix` input + `rustToolchainFor`; `lib/helpers.nix` `mkRustToolchain` | Yes |
| Flake-input interface | `03-context-and-scope.md` flake-input row | Affected | Tech table | Setup | `flake.lock` node `rust-overlay` at `c7e9d51…`, `nixpkgs` followed | Yes |
| Technology choice | `04-solution-strategy.md` Rust row | Affected | Tech table | Task 1 | Same row names the release distribution and the pairing reason | Yes |
| Helpers and Rust module | `05-building-block-view.md` helpers row, `rust.nix` entry, integration inventory | Affected | Architecture Impact | Tasks 1–2 | `mkRustToolchain`; module packages `rustToolchain`, `cargoLlvmCov`, `gcc`, `pkg-config`; inventory says “measures the coverage” | Yes |
| Laptop property | `07-deployment-view.md` thiniel Rust row | Affected | Deployment | Tasks 1–2 | Row names the release toolchain, coverage tools and the measurement check | Yes |
| Package-source concept | `08-crosscutting-concepts.md` fifth-source paragraph | Affected | Tech table, D1 | Task 2 evidence | Paragraph names the pinned overlay, the shared derivation and no floor | Yes |
| Risks | `11-risks-and-technical-debt.md` R-030, R-035 | Affected | Deployment; risk referenced | Setup evidence; Task 2 | R-030 observed + quarantine; R-035 coverage-command/release skew with the VM check as detection | Yes |
| Glossary term | `12-glossary.md` Rust build toolchain | Affected | Tech table | Tasks 1–2 | Term names the release identity, coverage tools, `cargo-llvm-cov` and the measurement check | Yes |
| Non-affected chapters | 01, 06, 09, 10 | No | — | — | No goal, flow, ADR or quality-requirement change in the commits | Yes |

ARC42 CONFORMANCE: CLEAN

## Use-case and Persona conformance

- Owning use case `reproduce-working-environment`; capability
  `rust-build-toolchain` extended. The delta updates the capability's rule
  (formatter and lint driver of the release, coverage tools of the release) and
  adds the measurement interaction row. The base rule's stability is preserved:
  one default toolchain, not a project pin.
- `owner--operator` is the confirmed Persona; the measurement scenario is the
  operator's task. `family--application-user` remains unaffected and is not
  named as an actor.
- No migration ledger applies: no stored state, credential or access changes.

## Deterministic gate dispositions

### Overlap dispositions

No shape-match or subset finding involves this change's scenarios; the gate
advisories reported by `givn lint` are pairs within other capabilities.

### Split-or-keep

No scenario in this change exceeds the gate threshold; both keep their single
outcome.

## Coverage classification

- No dead configuration: both new arguments are consumed (module, VM test,
  assertions), and both extensions are exercised by the VM check.
- No missing scenario: both use-case interactions for `rust-build-toolchain`
  have a bound `@e2e` scenario with a real boot.
- No hard-to-test gap.
- Unreferenced `integration-*` checks (`integration-adlerkopf`,
  `integration-vm-minimal-ssh`) are pre-existing advisories belonging to other
  capabilities, not to this change.

## External gate blocker (not this change)

The repository-wide `scripts/givn-verify.sh` stops at its first step because
the two other active changes declare targets that do not exist yet (21
findings, all attributed to `provision-storage-host` and
`security-key-remote-identity`). The same script's remaining steps were run
individually and pass for this change:

- `nix flake check --no-build --no-write-lock-file` — all checks evaluated
  (“all checks passed!”).
- Non-VM checks built: `flake-output-contract`, `lint-deadnix`,
  `lint-nixfmt`, `lint-statix`, `private-data-defaults`,
  `private-data-hygiene`, `unit-agent-secret-guard`, `unit-helpers` — exit 0.
- Host assertions for `adlerkopf`, `cupix001`, `nixos-vm-minimal`, `thiniel`,
  `J6G6Y9JK7L` — no failed assertion.
- `nix develop --command python3 -m pytest scripts/tests -q` — 256 passed.
- `integration-rust-toolchain` — built and booted (RED and GREEN evidence in
  `tasks.md`).

`givn archive` remains deferred until those two changes resolve their
bindings; nothing in this change needs to change for the gate to pass.

## Sign-off checklist

- [x] Fabrication audit clean (0 fabricated scenarios/targets across 2).
- [x] Traceability: this change's scenarios bound to exactly one existing
      target (scoped run exits 0); repository-wide findings belong to other
      active changes.
- [x] Every checked task has a verified commit touching configuration/tests.
- [x] Every promised module/argument/check/test exists.
- [x] Targeted RED evidence present for both scenarios.
- [x] Both `@e2e` scenarios bind to the VM check and actually boot; no tag
      removed.
- [x] `verify.e2e_command` differs from `verify.command`; e2e scope is the
      `integration-*` subset (20 of 64 scenarios).
- [x] No plaintext secrets; no decrypt invocation; `stateVersion` and
      `hardware.nix` untouched.
- [x] No dangerous area; Deployment & Rollback present anyway.
- [x] Implementation matches design.md as re-reviewed after F14.
- [x] Coverage evidence is the latest scoped traceability run.
- [x] Every gap classified; none excused by an invented bucket.
- [x] No `@wip` tags remain; no implementation detail in the spec.
- [x] Scenario execution evidence recorded per scope in tasks.md and in the
      archive receipt when the gate runs.
- [x] No finding excused outside the three buckets.

REVIEW: PASS
