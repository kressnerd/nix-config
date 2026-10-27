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
- [x] GREEN: `home/dan/features/development/rust.nix` takes `rustToolchain`
      and installs `[ rustToolchain pkgs.gcc pkgs.pkg-config ]` (no standalone
      `cargo`, `rustc`, `clippy`); `formatters.nix` drops `rustfmt`;
      `home/dan/J6G6Y9JK7L.nix` declares `pkgs.rustfmt` directly. Re-run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/z4198i381w6bi36hxb1wzri75jibcr67-nixos-system-thiniel-26.11.20261024.d3b13ad.drv
      exit 0
      $ nix build --no-link .#checks.x86_64-linux.integration-rust-toolchain
      exit 0
      ```
      The VM log shows the toolchain's own components:
      ```
      machine: must succeed: rustc --print sysroot
      machine: must succeed: test -x /nix/store/b29gb961bmp0bjdyr8anm438zckpqvhc-rust-minimal-1.99.1/bin/rustfmt
      machine: must succeed: test -x /nix/store/b29gb961bmp0bjdyr8anm438zckpqvhc-rust-minimal-1.99.1/bin/clippy-driver
      machine: must succeed: cargo fmt --check --manifest-path /home/test/hello/Cargo.toml
      ```
      Watch item (design review F13): no profile collision occurred — the Home
      Manager profile built with both the toolchain and `pkgs.gcc`.
- [x] REFACTOR: `nix fmt` on every touched Nix file; the targeted host
      evaluation and booted check were re-run afterwards and both exit 0 with
      the same derivations (`z4198i38…-nixos-system-thiniel`,
      `iaj7ncja…-vm-test-run-rust-toolchain`).
- [x] COMMIT: `a32a4e8a5d18a6c8913feaaf9f89cfed835957bf` — release note as
      subject, scenario title in the body.

---

## Task 2 — Scenario: `A booted device measures coverage of a Rust project` (`@e2e @check:integration-rust-toolchain`)

- [x] RED: remove `@wip` from this scenario; extend the test script with the
      measurement steps: create a `--lib` project whose explicit `src/lib.rs`
      has a function and a `#[test]` that calls it, run
      `cargo llvm-cov --offline --cobertura --output-path <file>` with
      `CARGO_NET_OFFLINE=true`, and parse the report on the driver side
      (`lines-covered > 0`). Re-run and paste the non-zero output (missing
      `cargo llvm-cov` or missing sysroot `llvm-profdata`):
      ```
      $ nix build --no-link .#checks.x86_64-linux.integration-rust-toolchain
      machine: must succeed: … CARGO_NET_OFFLINE=true cargo llvm-cov --offline --cobertura --output-path /home/test/covered/coverage.xml --manifest-path /home/test/covered/Cargo.toml
      machine # error: no such command: `llvm-cov`
      machine # help: find a package to install `llvm-cov` with `cargo search cargo-llvm-cov`
      !!! RequestedAssertionFailed: command `… cargo llvm-cov …` failed (exit code 101)
      exit 1
      ```
      (A first RED run failed earlier at the fixture's ownership step —
      `chown: invalid group: 'test:test'` — while the test user's group is
      `users`; the fixture now changes only the file's owner and the RED is the
      missing coverage command.)
- [x] GREEN: added `"llvm-tools-preview"` to the toolchain extensions and passed
      the stable channel's `cargo-llvm-cov` (0.8.7, as `cargoLlvmCov`) into the
      module — the `nixpkgs-unstable` 0.9.0 package does not build at the pin
      (its own test suite segfaults in the sandbox, observed while building the
      first green). Re-run:
      ```
      $ nix build --no-link .#checks.x86_64-linux.integration-rust-toolchain
      exit 0
      /nix/store/ma4q0qgaj8qc4wl0zx0kj59bq51vns28-vm-test-run-rust-toolchain
      ```
      The VM log shows the instrumented run and the report:
      ```
      machine: must succeed: … CARGO_NET_OFFLINE=true cargo llvm-cov --offline --cobertura --output-path /home/test/covered/coverage.xml --manifest-path /home/test/covered/Cargo.toml
      machine # info: cargo-llvm-cov currently setting cfg(coverage); …
      machine #      Running unittests src/lib.rs (/home/test/covered/target/llvm-cov-target/debug/deps/covered-…)
      machine #     Finished report saved to /home/test/covered/coverage.xml
      machine: must succeed: cat /home/test/covered/coverage.xml
      ```
      The driver-side parse asserted `lines-covered > 0` and `src/lib.rs` in the
      report.
- [x] REFACTOR: `nix fmt` on the touched Nix files (no behaviour change); the
      booted check was re-run and exits 0 with the same output path
      `ma4q0qga…-vm-test-run-rust-toolchain`. The arc42 chapters named in
      `arc42.md` were updated (02, 03, 04, 05, 07, 08, 11, 12).
- [x] COMMIT: `98a686142396fe1844853870006e67d83304bbf9` — release note as
      subject, scenario title in the body.

---

## Verification close-out

- [ ] `./scripts/givn-verify.sh` (non-e2e scope) passes. **Blocked externally:**
      its first step fails on 21 unresolved bindings owned by the two other
      active changes (`provision-storage-host`, `security-key-remote-identity`).
      Its remaining steps were run individually and pass: `nix flake check
      --no-build` (all checks evaluated), the eight non-VM checks build
      (exit 0), every host's assertions pass, `pytest scripts/tests` →
      256 passed.
- [ ] `./scripts/givn-verify-e2e.sh` (e2e scope) passes. Not run as a whole:
      the receipt step needs the archive gate, which is externally blocked. The
      change's own `@e2e` target, `integration-rust-toolchain`, was built and
      booted at RED and GREEN.
- [ ] Local operator smoke on `thiniel` after applying the generation: the
      shim quarantine and the `cargo llvm-cov` report described in
      `design.md` "Deployment & Rollback"; and the same check on the project
      that reported the failure (`duty2cal`). Evidence gathered so far, using
      the exact toolchain and coverage command the profile declares (store
      paths, without switching the host):
      ```
      $ PATH=<rust-minimal-1.99.1>/bin:<cargo-llvm-cov-0.8.7>/bin:$PATH \
          cargo llvm-cov -p duty2cal --test golden --cobertura --output-path /tmp/duty2cal-golden-cov.xml
      test result: ok. 1 passed; 0 failed
      Finished report saved to /tmp/duty2cal-golden-cov.xml
      lines-covered="43"  line-rate="0.36134453781512604"
      ```
      The report is produced where the same project previously failed with
      "raw profile version mismatch"/"number of counters is zero". Switching the
      generation and quarantining `~/.cargo/bin` shims remain the operator's
      steps; they need `nrs` (sudo) and are not performed by this change.
