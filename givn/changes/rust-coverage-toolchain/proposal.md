# Proposal: rust-coverage-toolchain

## Release note

The personal laptop's Rust toolchain carries coverage tools built from the
same compiler release, so a Rust project's test coverage can be measured on the
device.

## Use-Case Context

- Use-case ID: `reproduce-working-environment` — the permanent contract for a
  device reproducing the owner's usable working environment.
- Ideation topic: none. This change has no ideation change seed; the use case's
  originating topic was `infrastructure-growth`, which is not re-opened here.
- Seed path: none.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the operator
  builds and measures Rust projects on `thiniel` and judges whether the device
  can do so. `family--application-user` is not affected: measuring a build is
  not part of an application user's task.

Vocabulary: the *Rust build toolchain* is the device's default compiler,
package manager, lint driver, formatter, C linker and pkg-config. Its *coverage
tools* are the profiler-merge and coverage-report programs that belong to that
same compiler release; they read the raw profile the compiler emits.

## Problem / Opportunity

The personal laptop `thiniel` builds and lints Rust projects, but the owner
cannot measure their test coverage there. The compiler and the separately
packaged LLVM tools come from different builds, so the raw coverage profile the
compiler writes is not accepted by any tool available on the device: the
installed LLVM tools reject it as an unknown profile version, and the newest one
reports zero counters instead of an error. The device's toolchain does not ship
coverage tools of its own.

Operator impact: the coverage gate of a Rust project that the owner develops on
the laptop cannot be satisfied locally, so the owner cannot tell which lines a
test run executed without leaving the device. The failure looks like corrupt
measurement data, which it is not.

Observed on `thiniel` on 2026-10-27 with the device's Rust compiler 1.99.0: the
compiler wrote raw profile format version 11, the device's LLVM 21.1.8 and
22.1.8 tools expected version 10, and LLVM 23.1.3 reported "number of counters
is zero". A separately installed compiler 1.99.1 produced the same version 11
and its own merged profile was likewise unreadable by the other build's tools.

## Proposed Solution

Observable device state on `thiniel`:

1. The device's one default Rust toolchain carries its own coverage tools, built
   from the same release as the compiler, so a Rust project built on the device
   is measured by programs that accept the profile the compiler writes.
2. A booted device builds a Rust project with coverage instrumentation, merges
   the profile and reports the measured lines, with a non-zero count for code
   the project's tests exercised.
3. The compiler, Cargo, the lint driver and the formatter the device provides
   are the same release, so the tools that read and produce Rust build data do
   not disagree.
4. Import-scope fact: no other device's configuration imports this toolchain;
   `thiniel` is the only device whose profile is changed.

Verification binding (each point bound to exactly one native target; see
`docs/GIVN-VERIFICATION.md`):

| Point | Native target |
|---|---|
| 1 and 3 as configuration facts, and 2 as behaviour of a running system | `@check:integration-rust-toolchain` — a booted Linux VM builds a covered Rust project, reports the measured lines, and reports the formatter and lint driver release |
| 4 | not separately bound; it is an import-scope fact (the module is imported only by `home/dan/thiniel.nix`), recorded in the design's Blast Radius |

## Capability Routing

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| `rust-build-toolchain` | EXTEND `quiet-configuration-evaluation` (score 13.00, signal) | EXTEND `rust-build-toolchain` (existing capability in `reproduce-working-environment`) | Route matched goal words and the literal "none" in the proposal template, not the capability. The existing capability already owns the device's Rust build toolchain; this change adds the coverage tools that belong to that same toolchain, so it extends that capability rather than a capability about evaluation warnings. |

## Out of Scope

- Project-specific Rust toolchain pins and a `rustup`-managed toolchain — the
  device provides one default toolchain; a project needing another compiler
  release is not served by this change.
- Coverage measurement of a project's browser or end-to-end suite; this change
  covers the device's ability to measure instrumented code, not a project's
  suite design.
- Rust language servers, editor extensions or Rust tooling on other devices.
  The work MacBook's `rustfmt` keeps its current presence: it is declared
  directly on that host instead of through the shared formatter module, so no
  device gains or loses a Rust tool.
- Changes to Go, Node.js or Python tooling.

## Open Questions

### D1 — Which toolchain does the device provide now that its coverage tools must match the compiler?

- Question: The device's compiler and its separately packaged LLVM tools
  disagree about the coverage profile format. Should the device take a released
  Rust toolchain that ships its own coverage tools, pair the device's own
  compiler with the LLVM tools of the same package set, or let a `rustup`-managed
  toolchain follow each project's pin?
- Options:
  1. **Released Rust toolchain with its own coverage tools** — the device
     installs one released Rust distribution that includes the coverage tools
     built for it. Gain: compiler, Cargo, lint driver, formatter and coverage
     tools are one release, so profiles always match the programs that read
     them; cost: the device gains one flake input and its Rust version advances
     with that input rather than with the host package set; in practice:
     `cargo llvm-cov` reports measured lines for a project's tests instead of
     "profile version mismatch".
  2. **Device package set, compiler and LLVM tools together** — the device keeps
     its host package set's compiler and adds that set's LLVM tools. Gain: no
     new input. Cost: measured on 2026-10-27, the compiler's coverage runtime
     writes raw profile format 11 while the host set's LLVM 21.1.8 and 22.1.8
     expect 10 and 23.1.3 reports zero counters, so this option does not
     restore measurement; in practice: `cargo llvm-cov` still fails to merge.
  3. **`rustup`-managed toolchain** — each project's pin selects and downloads
     its compiler. Gain: exact per-project releases. Cost: downloaded
     toolchains are unpatched for the NixOS loader and need hand-written
     wrappers for the compiler, Cargo and every tool it spawns, and the device's
     build becomes network-dependent; in practice: a downloaded `llvm-cov`
     cannot start on the device.
- Disposition: answered — the operator's decision note of 2026-10-27 rejects
  mixing a compiler with LLVM tools from another build and prefers the released
  toolchain with its own `llvm-tools-preview`; design D1 adopts option 1 and
  records option 2's measured failure and option 3's loader failure.
