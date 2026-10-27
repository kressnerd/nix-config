# arc42 Impact Assessment — rust-coverage-toolchain

Assessment of the change against all twelve arc42 chapters, in order. A "No" is
a checked result, not an omission.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | No | No goal, quality goal or stakeholder changes. The new rule lives in the use case; chapter 1 records no Rust inventory item and the open inventory question (Q16) names no such item, so nothing there is falsely completed. |
| 2 | 02 architecture-constraints | **Yes** | New constraint row: a toolchain whose components must be same-release is taken whole from a distribution input (`rust-overlay`) instead of being assembled from the channel's separately packaged tools; no version floor, because a floor cannot detect a cross-release mismatch. The existing stable/unstable channel rules are unchanged. |
| 3 | 03 context-and-scope | **Yes** | The technical-context flake-input row gains `rust-overlay`. It is already present in `flake.lock` as lanzaboote's transitive node; this change adds the root input. The build-time component fetch from the Rust distribution server is hash-pinned. No new business-context partner, credential or interface. |
| 4 | 04 solution-strategy | **Yes** | The technology-choices table gains a row for the Rust build-and-coverage toolchain. (The previous description of the toolchain lived in chapters 7 and 12, not in chapter 4; there is no chapter-4 row to replace.) |
| 5 | 05 building-block-view | **Yes** | The `lib/helpers.nix` row gains `mkRustToolchain`; the Level-3 entry for `home/dan/features/development/rust.nix` changes its packages, gains the `rustToolchain` argument, and drops the "rustfmt stays in formatters.nix" sentence; the integration-test inventory states that `integration-rust-toolchain` now measures coverage. Module and import counts are unchanged. |
| 6 | 06 runtime-view | No | No new runtime flow or service: activation still renders packages and the existing persistence bind; coverage measurement is an operator-invoked build, not a runtime interaction of the host. |
| 7 | 07 deployment-view | **Yes** | `thiniel`'s Rust row names the release toolchain and its own coverage tools instead of the host package set's individual packages. |
| 8 | 08 crosscutting-concepts | **Yes** | The package-source concept gains a fifth source: `rust-overlay` supplies one device's whole Rust distribution, because the channel's compiler and its LLVM tools come from different builds and cannot read each other's coverage profiles. |
| 9 | 09 architecture-decisions | No | No ADR candidate passes the qualification gate: the decision is one module's package source, realised and reversible within this change, touching one component and constraining no future change or component. It is recorded in `design.md` D1. |
| 10 | 10 quality-requirements | No | No quality goal or scenario changes. The booted check now proves measurement in addition to build and lint, strengthening the existing testability approach without adding a quality requirement. |
| 11 | 11 risks-and-technical-debt | **Yes** | R-030 (persisted `~/.cargo/bin` shims shadowing the declared toolchain) moves from latent to observed and gains the reversible quarantine step; its mitigation text no longer says the earlier change accepted the state. New R-035 records the release skew between the device's coverage tool package (`cargo-llvm-cov` from `nixpkgs-unstable`), the `rust-overlay` pin, and a project's own pin. |
| 12 | 12 glossary | **Yes** | The "Rust build toolchain" term gains the release identity and the coverage tools. The check list already names `integration-rust-toolchain`; its wording needs no change. |

## ADR qualification outcome

No candidate was assessed in depth: the choice of a release-distributed
toolchain over the channel's separate packages is a package-source decision for
one feature module. It is fully implementable and reversible within this change
(revert the input and the module's package list), touches one component, and
constrains no other component or future change. That fails the
single-change-reversibility and no-multi-change-constraint tests, so the
rationale stays in `design.md` D1 and the cross-cutting package-source concept
in chapter 8.

## Files touched in this assessment

| File | Change |
|---|---|
| `docs/arc42/02-architecture-constraints.md` | New Rust toolchain-source constraint row (no floor, with reason) |
| `docs/arc42/03-context-and-scope.md` | Technical-context flake-input row names `rust-overlay` |
| `docs/arc42/04-solution-strategy.md` | Rust build-and-coverage toolchain technology row |
| `docs/arc42/05-building-block-view.md` | `lib/helpers.nix` row, `rust.nix` Level-3 entry, integration-test inventory |
| `docs/arc42/07-deployment-view.md` | `thiniel` Rust build toolchain row |
| `docs/arc42/08-crosscutting-concepts.md` | Fifth package source in the package-strategy concept |
| `docs/arc42/11-risks-and-technical-debt.md` | R-030 update; new R-035 |
| `docs/arc42/12-glossary.md` | Rust build toolchain term |

## Status

STATUS: DONE
