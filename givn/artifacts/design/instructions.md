# Instruction: design

Write the technical design (the HOW layer). Implementation detail belongs here.

Read `docs/GIVN-VERIFICATION.md` before designing. It is the canonical
verification model for this repository: every scenario carries exactly one
binding tag (`@check:<name>`, `@host:<name>`, or `@deploy:<name>`), no
in-process scenario runner exists, and RED/GREEN is proven against native Nix
targets. This instruction does not restate the binding semantics, the runner
commands, or the targeted-run commands — it references them.

## Scope

- **Technology decisions**: Nix modules, option paths, channel pins, package
  choices, helper functions, and the shape of the configuration change.
- **Architecture impact**: modules, options, and host definitions affected, and
  what is new. Any diagram (component, sequence, flow, tree) MUST be Mermaid
  (```` ```mermaid ```` fenced code block), never ASCII art. A plain
  directory/file-tree listing is not a diagram and may stay as plain text.
- **Verification binding**: the native target that proves each scenario, and the
  test targets this change adds or changes.
- **Secrets & safety**: sops targets and the invariants this change must not
  violate.
- **Deployment & rollback**: mandatory for a change that touches a dangerous
  area (see below).
- Any other technical decision the implementer needs before writing tasks.

## Use-Case Traceability

Read the selected `usecase.md` and the relevant ideation change seed. Add a
table mapping use-case guarantees, rules, events, and capability ownership to
technical decisions and their bound verification target.

Actors in Gherkin are interaction roles and remain distinct from Personas,
which are stakeholder review lenses. Record the Persona impact for every
user-visible outcome. This repository's interface is host configuration, not a
rendered screen, so almost every change records `none` with the reason.

| Use-case contract element | Technical decision | Bound verification target |
|---|---|---|
| | | |

## Technology Decisions

Nix-relevant decisions: which nixpkgs channel a package or module comes from,
which module or option to use, and why over the alternatives.

- **Channel pinning**: state the channel for every decision that depends on
  package freshness — `nixpkgs-26.05` (stable) or `unstable` (rolling). Prefer
  stable; when a package, module, or option exists only on `unstable`, name it
  and give the reason. The flake's nixpkgs inputs resolve the exact version.
- **Module / option choice**: name the NixOS / home-manager / nix-darwin module
  and the option path; if two modules, an option, or an overlay could achieve
  the result, say why this one.
- **Overlays / custom derivations**: name the overlay (or `pkgs` override) if
  one is introduced, and its file under `overlays/`.

**Version freshness (mandatory).** Never write a specific version number for a
package, kernel, module, or channel from memory. Training data is a snapshot
with an unknown cutoff — a remembered "current" version can now be old,
superseded, or end-of-life. For every version-bearing decision do ONE of:

- **State the channel as the resolution strategy**, e.g. "`nginx`: from
  `nixpkgs-26.05`", "`headscale`: `unstable`, because the required option does
  not exist in stable" — the flake's nixpkgs pin resolves the exact version.
- **Look the version up** (the repo's own `flake.lock`, the NixOS package
  search, or the upstream release page) and record the version AND how/when it
  was verified, e.g. "`foo` 1.2.x (checked nixos.org search and this repo's
  `flake.lock` at design time)".

A version number with no channel and no lookup note is an unverified guess.

| Decision | Choice | Channel / source | Why |
|---|---|---|---|
| (e.g. reverse proxy) | (e.g. nginx module) | (e.g. nixpkgs-26.05) | (e.g. already used on cupix001; no new module) |

## Decisions ledger (mandatory)

Add a `## Decisions` section resolving the proposal's open questions. Every
`D<n>` either appears there as `Decides D<n>: <decision> — <where it is
realized>`, or is explicitly carried with a named owner. A question that
originated in an ideation seed records the seed reference beside the ledger ID
(`Decides D2 (seed Q5): …`), so the question-to-decision link is readable from
the proposal and the design alone. An unresolved, unrecorded `D<n>` is a
design-review finding.

## Verification Binding (mandatory)

Read `docs/GIVN-VERIFICATION.md` first — it owns the binding-tag semantics, the
runner commands, and the targeted-run commands. This section records the
per-scenario mapping; it does not restate the policy.

One row per scenario in the change's `specs/**/*.feature`:

| Scenario title | Binding tag | Bound target (file / check / host) | Targeted run command | Expected RED failure mode |
|---|---|---|---|---|
| (the `Scenario:` title) | (`@check:<name>` / `@host:<name>` / `@deploy:<name>`) | (e.g. `tests/unit/default.nix` → check `unit-helpers`, or `tests/assertions/network.nix` → `@host:cupix001`) | (the exact command from the targeted-run table in `docs/GIVN-VERIFICATION.md`) | (how it must fail before the fix — a named assertion or a build/parse error) |

Rules:

- Every scenario carries exactly one binding tag. `@e2e` scenarios MUST bind to
  `@check:integration-*` (a `pkgs.testers.runNixOSTest` VM test), `@host:<name>`,
  or `@deploy:<name>`.
- Every `@check:` / `@host:` name must resolve in the flake; every `@deploy:`
  name must have a matching `tests/deploy/test_<name>.py`.
- **RED is proven by a non-zero targeted run.** The targeted command must exit
  non-zero before the fix, for the stated reason — a named assertion failure, a
  failed unit test, or an evaluation/build error. A target that already passes
  is not RED: split the scenario, extend the target, or fix the scenario until
  it fails for the expected reason. There is no in-process runner that could
  silently pass for an unimplemented target.
- If the expected RED failure is an evaluation/build error, name it (missing
  option, failed assertion, failed `runTests` case).

## Test Targets Added/Changed (mandatory)

Name every test target the change adds or extends and the wiring that makes it
run. A target that is not wired in is never executed, so RED/GREEN evidence is
meaningless.

| Target file | Kind | Wired in by | Covers scenarios |
|---|---|---|---|
| (e.g. `tests/unit/default.nix`) | unit (`lib.debug.runTests`) | flake `checks.unit-helpers` | |
| (e.g. `tests/assertions/foo.nix`) | assertion | imported by `tests/assertions/default.nix`, fired on host evaluation | |
| (e.g. `tests/integration/foo.nix`) | VM (`pkgs.testers.runNixOSTest`) | flake `checks.integration-foo` | |
| (e.g. `tests/deploy/test_foo.py`) | deploy (pytest-testinfra) | `@deploy:foo` binding | |

State which flake `checks` entry or host import wires each target. New unit
tests go into `tests/unit/default.nix` and `flake.nix`; new assertions into
`tests/assertions/default.nix`; new VM tests into `tests/integration/default.nix`.

## Architecture Impact

What existing modules, options, and host definitions are affected? What is new?
Name the files under `modules/nixos`, `modules/home-manager`, `hosts/<host>/`,
`hosts/common/`, and `lib/` as applicable.

## Secrets & Safety

- **sops targets**: for every secret this change wires, the declared path, the
  sops key name, and the target owner/mode. Never a plaintext secret.
- **`stateVersion` invariants**: `system.stateVersion` and
  `home.stateVersion` are never changed.
- **`hardware.nix` untouched**: `hosts/<host>/hardware.nix` is generated and
  read-only — this change must not modify it.
- Any other invariant this change must preserve.

## Deployment & Rollback (mandatory for dangerous areas)

Required whenever the change touches `boot.loader`, `networking`,
`fileSystems`/disko, `environment.persistence`/impermanence, kernel, or
secrets. Record:

- **Apply command**: the exact command to deploy, e.g.
  `nixos-rebuild switch --flake .#<host>` (or the repository's deploy tool if it
  uses one) — state which.
- **On-host verification**: how to confirm the change on the real host after
  apply — a service status, a listening port, a firewall rule, a materialised
  secret.
- **Rollback**: the exact rollback — rebooting into the previous boot
  generation, `nixos-rebuild switch --rollback`, or restoring the pre-change
  generation. Name the mechanism, never just "revert the commit".

A dangerous-area change without this section is a design-review finding.

## Blast Radius

What can break, on which hosts, and how detectable it is. Name the hosts
affected and whether a bad apply is recoverable remotely (for example, whether
a networking change can lock out SSH).

## arc42 chapter impact

Which arc42 chapters (`docs/arc42/`) does this change affect? Relevant only
when the arc42 addon is enabled (`addons.arc42` in `givn/config.yaml`).

## Open Technical Questions

List unresolved HOW decisions before moving to tasks.
