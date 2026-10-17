# arc42 Impact Assessment — rust-build-toolchain

Assessment of the change against all twelve arc42 chapters, in order. A "No" is
a checked result, not an omission.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | No | The change supplies one already-open inventory item (the device owner's intended tools) and changes no goal, quality goal or stakeholder. |
| 2 | 02 architecture-constraints | **Yes** | The factual import count for `thiniel` in the feature-module convention row changes from 41 to 42. No constraint is added or removed. |
| 3 | 03 context-and-scope | No | No new external interface or source: the packages come from the existing `nixpkgs-unstable` input the host already uses. |
| 4 | 04 solution-strategy | No | The change applies the existing feature-module and host-package-set conventions; it adds no new solution strategy. |
| 5 | 05 building-block-view | **Yes** | New Level-3 entry for `home/dan/features/development/rust.nix`; the `development/` inventory grows to 17 modules and the repository to 60 feature modules; `thiniel`'s import count becomes 42; the integration-test inventory gains `integration-rust-toolchain` and names the fourth Home Manager-loading check. |
| 6 | 06 runtime-view | No | No new runtime flow: activation renders packages and one persistence bind, which is the existing Home Manager/impermanence activation. |
| 7 | 07 deployment-view | **Yes** | `thiniel`'s property table gains a Rust build toolchain row. The persistence entry generates a system mount unit, so the host's state model is touched, but no topology, disk, boot-loader or service change. |
| 8 | 08 crosscutting-concepts | No | The package-source concept is unchanged: the toolchain comes from the host's existing package set, and persistence uses the existing `myHome.persistence` concept without modifying it. |
| 9 | 09 architecture-decisions | No | No ADR candidate: the decision is a package choice realized inside one feature module and does not pass the architecture-significance qualification; D1 is recorded in `design.md`. |
| 10 | 10 quality-requirements | No | No quality goal changes. The booted check strengthens the existing testability discipline but introduces no new quality scenario. |
| 11 | 11 risks-and-technical-debt | **Yes** | New risk R-030: a persisted `~/.cargo/bin` can carry manual or `rustup` shims that shadow the declared toolchain. |
| 12 | 12 glossary | **Yes** | New term "Rust build toolchain"; the check inventory gains `integration-rust-toolchain` and its provenance (and the previously omitted `integration-github-fetch-credential`). |

## ADR qualification outcome

No candidate was assessed: the change selects packages from the host's existing
package set for one feature module, follows the repository's existing
package-source convention, and is reversible by removing one import. It
introduces no architectural constraint, building-block responsibility or
cross-cutting concept.

## Files touched in this assessment

| File | Change |
|---|---|
| `docs/arc42/02-architecture-constraints.md` | thiniel import count |
| `docs/arc42/05-building-block-view.md` | Module counts, thiniel import count, new Rust Level-3 entry, integration-test inventory |
| `docs/arc42/07-deployment-view.md` | thiniel Rust build toolchain row |
| `docs/arc42/11-risks-and-technical-debt.md` | R-030 persisted Cargo bin |
| `docs/arc42/12-glossary.md` | "Rust build toolchain" term; check inventory |

## Status

STATUS: DONE
