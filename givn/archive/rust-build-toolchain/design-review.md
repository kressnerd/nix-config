# Design Review — rust-build-toolchain

- Date: 2026-10-17
- Reviewed artifacts: `proposal.md`, `specs/reproduce-working-environment/*`,
  `design.md`, `arc42.md` and the five affected `docs/arc42/` chapters
- Method: one grilling subagent in a fresh read-only context (`GrillRustPlan`)
  read the plan, `docs/GIVN-VERIFICATION.md`, the changed chapters and the
  relevant Nix wiring. Its findings are recorded below with their dispositions;
  each was re-checked against the tree before being accepted.

## Phase 1 — grilling findings and dispositions

| # | Finding | Severity | Disposition |
|---|---|---|---|
| F1 | The design claimed a stable-channel toolchain resolved to Rust 1.95.0, but `thiniel` is built from `nixpkgs-unstable` (`flake.nix:197`, `useGlobalPkgs = true`) and `nix eval --raw .#nixosConfigurations.thiniel.pkgs.cargo.version` returns `1.98.1`; the prose would have contradicted the evaluated configuration and the existing `rustfmt`. | BLOCKER | **Fixed.** The design, proposal D1, use-case rule, arc42 chapters and glossary now state the host's package set (`nixpkgs-unstable`, Rust 1.98.1 observed at review time). No separate stable pin is introduced. |
| F2 | Scenario 2's expected RED was a missing flake check, which is a wiring error, not a behavioural RED. The planned persistence guard used `lib.mkIf` on `home.persistence`; a disabled `mkIf` does not prevent an undeclared-option error, and the bare Home Manager VM had no `myHome` options. Test-user command resolution was unspecified. | BLOCKER | **Fixed.** The setup task wires the VM check and a package-less `rust.nix` first, so RED is `cargo` absent at runtime. `rust.nix` uses `lib.optionalAttrs config.myHome.persistence.enable` (the `ssh.nix` pattern); the guest imports `modules/home-manager/persistence/options.nix`; the test invokes the per-user profile by absolute path (`/etc/profiles/per-user/test/bin`) and builds with `--offline --vcs none`. |
| F3 | "Keeps the Cargo home across boots" was bound to an evaluation-only host target and could not observe a mount or a reboot; scenario 1 also bundled three behaviours. | MAJOR | **Fixed.** The persistence claim is now its own `@host:thiniel` scenario asserting the declared persistence entry, the same evidence level as the repository's other persistence assertions (e.g. `thiniel-yazi-invariants`); the design records the evidence limitation explicitly. The package chain and persistence are separate scenarios. |
| F4 | The deployment/rollback section named `/persist/.cargo`; the user layer's source is `/persist/home/dan/.cargo`. | MAJOR | **Fixed.** All paths corrected; the on-host check is `findmnt /home/dan/.cargo`, and the apply-order note (switch before boot) is recorded. |
| F5 | The blast radius claimed the assertion was host-name guarded and that no boot path changes; the assertion is scoped by import only, and the persistence entry generates a system mount unit and activation entry. | MAJOR | **Fixed.** Blast Radius now states the import scope, the generated system-level mount, and the previous-generation rollback. |
| F6 | Proposal point 4 ("no other device gains the toolchain") was bound to `@host:thiniel`, which cannot prove anything about the other hosts. | MAJOR | **Fixed.** Recorded as an import-scope fact and moved out of the verified binding table; the design's Blast Radius owns it. |
| F7 | arc42 counts were stale: chapter 2 still said 41 thiniel imports, chapter 5 said 59 modules and 41 imports. | MAJOR | **Fixed.** 42 imports in chapters 2 and 5; 60 feature modules in chapter 5; `arc42.md` marks chapter 2 affected and lists it. |
| F8 | arc42 chapters repeated the false stable-channel claim, and chapter 8's "No" rested on that premise. | MAJOR | **Fixed.** Chapters 5, 7 and 12 now name the host's package set; chapter 8's "No" is correct under host-set resolution (the package-source concept is unchanged). |
| F9 | The glossary check inventory omitted the pre-existing `integration-github-fetch-credential`. | MINOR | **Fixed** while editing the line, with its provenance. |
| F10 | The use-case delta recorded a stale base hash. | MINOR | **Fixed.** The header now records the current baseline hash `2ffa4aa…`. |
| F11 | Clippy and pkg-config were named by the contract but never exercised. | MINOR | **Fixed.** The booted check runs `cargo clippy` and `pkg-config --version`; Clippy is the staged GREEN for the e2e scenario (absent at its RED). |
| F12 | Architecture Impact omitted the new integration test file; chapter 11 lacked the persisted `~/.cargo/bin` risk. | MINOR | **Fixed.** The test file is listed; risk R-030 records the persisted-bin conflict and its mitigation. |

## Branch verdicts

- **Scope** — no issue found beyond F6.
- **Tech choices** — F1, F2.
- **Missing scenarios** — F3, F6, F11.
- **Testability** — F2, F3; the host assertions can genuinely fail, and the VM check now fails behaviourally at RED.
- **Verification-binding completeness** — F2, F6; otherwise every scenario carries exactly one resolving binding and `@e2e` binds to `integration-*`.
- **Deployment & rollback** — F4, F5.
- **Risk** — F5, F12.
- **Decision ledger** — F1; D1 is now consistent with the host package set and has no competing stable-pin claim.
- **Use-case / Persona context** — no Persona issue found; `owner--operator` is confirmed and `family--application-user` is correctly excluded.
- **Deferrals** — no issue found; rustup, project pins, language servers and other devices are explicit.
- **arc42 completeness** — F5, F7, F8, F9, F12; the independent twelve-chapter derivation matched `arc42.md` after the fixes.

## Status

STATUS: DONE

DESIGN-REVIEW: PASS
