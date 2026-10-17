# Proposal: rust-build-toolchain

## Release note

The personal laptop `thiniel` provides a Rust build toolchain — the compiler,
Cargo, Clippy, a C linker and pkg-config — and keeps Cargo's home across boots,
so Rust projects can be built and run there.

## Use-Case Context

- Use-case ID: `reproduce-working-environment` — the permanent contract for a
  device reproducing the owner's usable working environment (intended tools and
  settings, required working state, permitted identity access).
- Ideation topic: none. This change has no ideation change seed; the use case's
  originating topic was `infrastructure-growth`, which is not re-opened here.
- Seed path: none.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the operator
  builds Rust projects on `thiniel` and judges whether the device can do so.
  `family--application-user` is not affected: compiling a Rust project is not
  part of an application user's task.

Vocabulary: a *Rust build toolchain* is the device's default compiler, package
manager, lint driver, C linker and pkg-config used to build and run Rust
projects. It is distinct from a *toolchain pin* that an individual project may
carry; project-specific pins are not part of this change (see Out of Scope).

## Problem / Opportunity

The personal laptop `thiniel` is the device on which the operator develops.
Its configuration provides editors, shells, Node.js, Go and Python, but no Rust
compiler or Cargo. A Rust project checked out on the laptop therefore cannot be
built or run there, even though the device already reserves
`$HOME/.cargo/bin` on the session path and already installs the Rust formatter
through the shared formatter module.

Because the laptop's root filesystem is wiped on every boot (impermanence),
installing a toolchain by hand would also lose the Cargo home — registry cache
and installed binaries — at the next boot.

Operator impact: Rust work started on the laptop cannot be compiled locally
without an ad-hoc shell, and anything installed by hand disappears on reboot.

## Proposed Solution

Observable device state on `thiniel`:

1. The device provides the Rust compiler and Cargo, and a C linker plus
   pkg-config so that building a Rust project succeeds.
2. A newly created Rust project builds and its produced program runs on the
   device; the device also lints it with Clippy.
3. The device declares the Cargo home (`$HOME/.cargo`) persistent, so cached
   dependencies and binaries installed with Cargo remain available across boots.
4. Import-scope fact: no other device's configuration imports the toolchain;
   `thiniel` is the only device whose profile is changed.

Verification binding (each point bound to exactly one native target; see
`docs/GIVN-VERIFICATION.md`):

| Point | Native target |
|---|---|
| 1 as a configuration fact | `@host:thiniel` — the device evaluation asserts the declared packages |
| 3 as a persistence declaration | `@host:thiniel` — the device evaluation asserts the Cargo home in the persistent set; the repository's other persistence entries are verified the same way, by declaration |
| 2 as behaviour of a running system | `@check:integration-rust-toolchain` — a booted Linux VM creates, builds and runs a Rust project, and lints it |
| 4 | not separately bound; it is an import-scope fact (the module is imported only by `home/dan/thiniel.nix`), recorded in the design's Blast Radius |

## Capability Routing

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| `rust-build-toolchain` | EXTEND `quiet-configuration-evaluation` (score 13.00, signal) | NEW in `reproduce-working-environment` | Route matched goal words and the literal "none" in the proposal template, not the capability: quiet configuration evaluation concerns evaluation warnings, whereas a Rust build toolchain is part of the device owner's reproducible working environment (capability list of `reproduce-working-environment`). The other ranked candidates (`current-agent-tooling`, `operational-data-separation`, the credential/identity capabilities) cover coding agents, data separation or identity access, none of which a compiler belongs to. |

## Out of Scope

- Project-specific Rust toolchain pins and a `rustup`-managed toolchain — the
  device provides one default toolchain from its own package set (the
  `nixpkgs-unstable` pin on `thiniel`); a project needing a different compiler
  version is not served by this change.
- Rust language servers, editor extensions or Rust tooling for other devices.
- C/C++ build systems beyond the linker and pkg-config that a plain Rust
  project needs (for example CMake-based `-sys` crates with their own system
  libraries).
- Changes to Go, Node.js or Python tooling.

## Open Questions

### D1 — Which toolchain does the device provide?

- Question: Should the device build Rust projects with a toolchain resolved
  from the device's own package set, or with a `rustup`-managed toolchain that
  follows each project's pin?
- Options:
  1. **Device-package-set toolchain** — the device installs the compiler,
     Cargo and the C prerequisites from the same package set it already uses for
     Go, Node.js and Python. Gain: reproducible, no unpatched binaries, one
     declaration for the device; cost: a project pinning another compiler
     version builds with the device's compiler or needs an explicit shell; in
     practice: `cargo build` in any project uses the device's Rust toolchain.
  2. **`rustup`-managed toolchain** — a project's `rust-toolchain.toml` selects
     and downloads its own compiler. Gain: exact per-project versions; cost:
     downloaded toolchains are unpatched for the NixOS loader and need an extra
     loader configuration, and the device's build becomes network-dependent and
     not fully declarative; in practice: entering a project downloads its pinned
     toolchain before the first build.
- Disposition: answered — the operator asked for Rust on `thiniel`; the
  repository's convention is a feature module fed by the host's package set (Go,
  Node.js, Python), and this change follows it (design D1). `thiniel` runs the
  `nixpkgs-unstable` pin. A project-specific pin stays the project's concern and
  is recorded as out of scope.
