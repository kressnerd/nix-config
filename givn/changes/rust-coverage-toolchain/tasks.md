# Tasks: rust-coverage-toolchain

RED→GREEN→REFACTOR→COMMIT per scenario. Both scenarios are `@e2e`; each phase
runs the scenario's bound target (`@check:integration-rust-toolchain`) with the
targeted command from `docs/GIVN-VERIFICATION.md` ("Single-scenario
(targeted) run"), not the whole suite. Check each box as its evidence is
filled in.

---

## Domain Constraints

Owning use case: `reproduce-working-environment`. Capability: `rust-build-toolchain` (extended).

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| Both scenarios | Rule: the device's one default Rust toolchain carries a lint driver and a formatter of the same release, and the coverage tools of that release, so a profile the compiler writes is measured by the tools that accept it. The toolchain is the device's, not a project-specific pin. | `owner--operator` — the operator builds and measures Rust projects on `thiniel`. `family--application-user` is unaffected. |
| Build scenario | Flow step 4: the owner attempts the defined usual work and the system checks usable work context, not installation alone. | `owner--operator` |
| Measurement scenario | The interaction "a device measures a Rust project's test coverage" exists in the use-case interactions table. | `owner--operator` |

Not a dangerous-area change: no boot, networking, filesystem, kernel or secret
wiring. `hardware.nix` untouched; `stateVersion` untouched.

---

## Setup task (do first)

- [x] **Wire the new input, the shared toolchain derivation, the assertion and
      the build scenario's test steps; prove both REDs.**
  - `flake.nix`: added the pinned input
    `rust-overlay = { url = "github:oxalica/rust-overlay/c7e9d512653a35ef4d5879c3df4d44d7b78d0e6d"; inputs.nixpkgs.follows = "nixpkgs"; };`,
    `rustToolchainFor`, thiniel's `rustToolchain` Home Manager argument, and the
    checks' `rustToolchain` argument.
  - `lib/helpers.nix`: `mkRustToolchain` with `rustfmt-preview` and
    `clippy-preview` (the coverage extension is the measurement task's green).
  - `tests/integration/default.nix` and `tests/integration/rust-toolchain-test.nix`:
    `rustToolchain` passed through, guest `extraSpecialArgs`, plus the
    `cargo fmt --check` and sysroot `rustfmt`/`clippy-driver` steps.
  - `tests/assertions/thiniel-hm-invariants.nix`: the `rustc`/`cargo`
    name-substring assertions replaced with
    `builtins.elem rustToolchain config.home.packages`.
  - `nix flake lock`: added only the `rust-overlay` node and its followed
    `nixpkgs` (22 lines, no other input moved).
  - Evidence (RED), host — exit 1:
    ```
    $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
    error:
    Failed assertions:
    - dan profile: thiniel: the declared Rust toolchain (compiler, Cargo, formatter, lint driver and coverage tools of one release) must be installed
    exit 1
    ```
  - Evidence (RED), booted check — exit 1:
    ```
    $ nix build --no-link .#checks.x86_64-linux.integration-rust-toolchain
    machine: must succeed: test -x /nix/store/1qg7z7i461qsv0lczc40nyi8ps6snlca-rustc-1.99.0/bin/rustfmt
    !!! RequestedAssertionFailed: command `test -x /nix/store/…-rustc-1.99.0/bin/rustfmt` failed (exit code 1)
    exit 1
    ```
  - e2e scope: `--scope e2e` = 20 scenarios, `--scope regular` = 44;
    `verify.e2e_command` (`scripts/givn-verify-e2e.sh`) differs from
    `verify.command`.
  - `scripts/givn-spec-trace.py` resolves this change's two scenarios to the
    existing `integration-rust-toolchain` check; the reported findings are the
    repository's pre-existing ones from two other active changes.

---

## Task 1 — Scenario: `A booted device builds and runs a Rust project` (`@e2e @check:integration-rust-toolchain`)

- [x] RED: remove `@wip` from this scenario only (the measurement scenario keeps
      `@wip`). The setup task added the target's new assertions; the same
      targeted run proves RED and is pasted there:
      ```
      $ nix build .#checks.x86_64-linux.integration-rust-toolchain
      … RequestedAssertionFailed: command `test -x …-rustc-1.99.0/bin/rustfmt` failed (exit code 1)
      exit 1
      ```
      and the host target fails its new assertion (exit 1, pasted in the setup
      task).
- [ ] GREEN: `home/dan/features/development/rust.nix` takes `rustToolchain`
      and installs `[ rustToolchain pkgs.gcc pkgs.pkg-config ]` (no standalone
      `cargo`, `rustc`, `clippy`); `formatters.nix` drops `rustfmt`;
      `home/dan/J6G6Y9JK7L.nix` declares `pkgs.rustfmt` directly. Re-run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      $ nix build .#checks.x86_64-linux.integration-rust-toolchain
      ```
      Watch item (design review F13): if the Home Manager profile reports a
      `bin/gcc`/`bin/cc` collision because the toolchain propagates
      `stdenv.cc`, record the resolution here.
- [ ] REFACTOR: formatting/comment cleanup only; re-run the second command and
      confirm it still passes.
- [ ] COMMIT: `givn commit -m "<release note>" -m "<scenario title>"`; record
      the revision in this task.

---

## Task 2 — Scenario: `A booted device measures coverage of a Rust project` (`@e2e @check:integration-rust-toolchain`)

- [ ] RED: remove `@wip` from this scenario; extend the test script with the
      measurement steps: create a `--lib` project whose explicit `src/lib.rs`
      has a function and a `#[test]` that calls it, run
      `cargo llvm-cov --offline --cobertura --output-path <file>` with
      `CARGO_NET_OFFLINE=true`, and parse the report on the driver side
      (`lines-covered > 0`). Re-run and paste the non-zero output (missing
      `cargo llvm-cov` or missing sysroot `llvm-profdata`):
      ```
      $ nix build .#checks.x86_64-linux.integration-rust-toolchain
      ```
- [ ] GREEN: add `"llvm-tools-preview"` to the toolchain extensions and
      `pkgs.cargo-llvm-cov` to the module's packages. Re-run and paste the
      passing output:
      ```
      $ nix build .#checks.x86_64-linux.integration-rust-toolchain
      ```
- [ ] REFACTOR: no behaviour change; re-run the command.
- [ ] Update the arc42 chapters named in `arc42.md` (02, 03, 04, 05, 07, 08, 11,
      12) with the measured outcome.
- [ ] COMMIT: `givn commit -m "<release note>" -m "<scenario title>"`; record
      the revision in this task.

---

## Verification close-out

- [ ] `./scripts/givn-verify.sh` (non-e2e scope) passes.
- [ ] `./scripts/givn-verify-e2e.sh` (e2e scope) passes.
- [ ] Local operator smoke on `thiniel` after applying the generation: the
      shim quarantine and the `cargo llvm-cov` report described in
      `design.md` "Deployment & Rollback"; and the same check on the project
      that reported the failure (`duty2cal`).
