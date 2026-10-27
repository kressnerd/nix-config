# Design Review — rust-coverage-toolchain

- Date: 2026-10-27
- Reviewed artifacts: `proposal.md`, `specs/reproduce-working-environment/*`,
  `design.md`, `arc42.md` and the wiring they name
- Method: one read-only grilling subagent in a fresh context
  (`GrillRustCoverage`) read the plan, `docs/GIVN-VERIFICATION.md`, the flake
  wiring, the assertions, the test harness and the arc42 chapters, and returned
  ranked findings. Each finding was re-checked against the tree before being
  accepted; the dispositions below name the artifact that changed.

## Phase 1 — grilling findings and dispositions

| # | Finding | Severity | Disposition |
|---|---|---|---|
| F1 | The two `@host:thiniel` assertions match package names containing `rustc`/`cargo`; the rust-overlay aggregated derivation is `rust-minimal-<ver>` (`pname = "rust-minimal"`, verified by evaluation), so the host evaluation and `verify.command` would fail while the booted check stayed green. The design had claimed no assertion change. | BLOCKER | **Fixed.** `design.md` now asserts the declared `rustToolchain` is in `config.home.packages` (the argument reaches the imported assertion module through `extraSpecialArgs`) and removes the name-substring assertions. The changed target is listed in "Test Targets Added/Changed" and in the use-case traceability table. |
| F2 | The build scenario said the formatter and lint driver "report the compiler's release", but the planned assertion was a sysroot path check — a packaging fact, not a release report. | MAJOR | **Fixed.** The scenario now says the device formats the project without changes and that the formatter and lint driver are the compiler's own components; the VM check runs `cargo fmt --check` and asserts the sysroot paths. |
| F3 | The measurement scenario's RED was unreachable: one toolchain definition with `llvm-tools-preview` would already satisfy the coverage tools' presence before the scenario's implementation. | MAJOR | **Fixed.** `design.md` sequences the extensions: the build scenario lands `rustfmt-preview`/`clippy-preview`; the measurement scenario lands `llvm-tools-preview` and `cargo-llvm-cov`, and its RED is the missing `cargo llvm-cov` and profiler. |
| F4 | The repository gate runs `nix flake check --no-build --no-write-lock-file`, and the new input was absent from the lock; the design also cited a revision the lock did not contain. | MAJOR | **Fixed.** The input URL pins `c7e9d512653a35ef4d5879c3df4d44d7b78d0e6d` (the revision used for the design-time evidence); the deployment section makes `nix flake lock` the first step, and the setup task stages the lock before any RED. |
| F5 | The apply command omitted thiniel's `givn` input override, and the macOS host (which loses `rustfmt` from the shared module) was unnamed. | MAJOR | **Fixed.** The deployment section names `nrs` with its `--override-input givn …` and requires `dars` on the MacBook, with the lagging state described. |
| F6 | Applying the overlay to thiniel's package set created a second package-set instance and left "the check uses exactly the device's toolchain" unproven; `fenix` was unrecorded. | MAJOR | **Fixed.** The toolchain is one derivation built in `flake.nix` from `import nixpkgs-unstable { overlays = [ inputs.rust-overlay.overlays.default ]; }` and passed to both the host and the check; no host carries the overlay. `fenix` and the other unrecorded choices are in the technology table. |
| F7 | The stale-shim step was shim-blind, ambiguous, and "removes" would delete `cargo install` binaries. | MINOR | **Fixed.** The deployment section quarantines the shims into `~/.cargo/bin.pre-toolchain/` and proves resolution with `command -v rustc` and the sysroot contents; the limitation that the VM cannot model the session PATH is recorded in Local Runnability. |
| F8 | `arc42.md` misclassified chapters: chapter 1's reason was unsupported, chapter 3's row belongs to the technical context, chapter 4 claimed a replacement that does not exist, chapter 5 omitted the helpers row and kept the old formatter sentence, chapter 12 overstated a check-description change. | MINOR | **Fixed.** `arc42.md` and `design.md`'s chapter list now reflect the independent derivation; the affected sentences in chapters 4, 5, 7, 8, 11 and 12 are the implementation targets. |
| F9 | Unrecorded decisions: `fenix` alternative, revision pinning, no version floor, single shared derivation. | MINOR | **Fixed.** All four are rows in `design.md`'s technology table; the Decisions ledger records them as decided, not carried. |
| F10 | Wording inaccuracies: format-version framing, `import inputs.rust-overlay` vs `.overlays.default`, the `nixpkgs.follows` rationale, the all-systems claim, a placeholder local command, chapter 2 lacking the no-floor reason. | MINOR | **Fixed.** The design now cites the 1.99.0/1.99.1 cross-test as the decisive evidence, uses `inputs.rust-overlay.overlays.default`, describes `follows` as avoiding an unused input evaluation, scopes `nix flake check` to the current system, carries a concrete local command, and records the no-floor reason. |
| F11 | The VM test shape was under-specified: template reliance, no formatter invocation, report capture unstated, no offline belt-and-braces. | MINOR | **Fixed.** Local Runnability names the explicit `--lib` source with a test that calls the covered function, `CARGO_NET_OFFLINE=true`, the Cobertura output file, and host-side parsing of `lines-covered` plus the file's own hits. |
| F12 | "Out of scope: Rust tooling on other devices" read as contradicting the macOS `rustfmt` relocation. | MINOR | **Fixed.** The proposal states the Mac keeps the same presence, declared directly instead of through the shared module. |
| F13 | The aggregated profile propagates `stdenv.cc`; a differing `pkgs.gcc` could collide in the Home Manager profile. | MINOR (watch) | **Recorded as a watch item in tasks.** The first profile build proved it: no collision occurred with `pkgs.gcc` in the same profile. |

### Re-review after implementation (2026-10-27)

| # | Finding | Severity | Disposition |
|---|---|---|---|
| F14 | The reviewed design named `cargo-llvm-cov` from the host package set (`nixpkgs-unstable`, 0.9.0). During GREEN that package failed to build: its own test suite segfaults in the sandbox at the pin (observed building `c5c558jc…-cargo-llvm-cov-0.9.0.drv`). The implementation instead takes 0.8.7 from the stable channel and passes it as `cargoLlvmCov`, and the VM test receives it the same way as the toolchain. | MAJOR | **Fixed by updating the design, not silently.** `design.md` now records the stable release, the build failure and why the command's own version is not the pairing that matters; `arc42.md`'s affected-chapter list was unchanged (chapter 5/11 wording updated to the new argument and channel). The alternative was rejected because pinning a `doCheck = false` override would hide a genuine package failure. |

## Phase 2 — branch verdicts

- **Scope** — the spec matches the proposal; hosts and observable end state are
  named; the import-scope fact is true. The macOS relocation is now explicit.
- **Tech choices** — same-release pairing is the invariant; the host-set
  compiler plus LLVM-tools option is dead by measurement; `rustup` is rejected
  for the NixOS loader; `fenix`, the pin, the floor and the derivation identity
  are recorded.
- **Missing scenarios** — formatter usability is now a step; the offline
  boundary is stated; the `cargo-llvm-cov` release skew is R-035.
- **Testability** — both scenarios have reachable REDs after the extension
  sequencing; the host assertion failure is separate evidence.
- **Verification-binding completeness** — every scenario carries exactly one
  resolving tag; both `@e2e` scenarios bind to the VM check; `verify.command`
  and `verify.e2e_command` stay distinct.
- **Deployment & rollback** — not a dangerous-area change; the shim quarantine,
  `nrs`, `dars`, lock step and generation rollback are recorded.
- **Risk** — most likely implementation failure was F3 (already-green target),
  now removed by sequencing; most likely deployment failure is a stale shim
  shadowing the new toolchain, mitigated by the quarantine and the resolution
  proof.
- **Decision ledger** — D1 resolves to the release-toolchain option; the four
  secondary choices are recorded, none carried.
- **Use-case / Persona context** — capability `rust-build-toolchain` extended;
  `owner--operator` is the confirmed Persona and `family--application-user` is
  correctly excluded; the rule and interaction row are updated.
- **Deferrals** — none. The operator questions the grilling raised (revision
  pin, shim quarantine scope, version floor) were answered by adopting the
  recommended option, each recorded above and in the technology table.
- **arc42 completeness** — the independent twelve-chapter derivation agrees with
  the corrected `arc42.md`; chapters 1, 6, 9 and 10 are "No" for stated
  reasons.

## Status

STATUS: DONE

DESIGN-REVIEW: PASS
