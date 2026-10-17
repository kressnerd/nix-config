# Design: infrastructure-authoring-tooling

## Use-Case Traceability

| Use-case contract element | Technical decision | Bound verification target |
|---|---|---|
| `reproduce-working-environment` rule "A device that authors infrastructure provides an OpenTofu engine and a GitHub command-line client" | Both packages are declared once in a Home Manager feature module and imported by the personal laptop | `@host:thiniel` (`tests/assertions/thiniel-invariants.nix`) |
| Capability `infrastructure-authoring-tooling`, scenario "The personal laptop provides an OpenTofu engine" | `pkgs.opentofu` in `home.packages` | `@host:thiniel` |
| Capability `infrastructure-authoring-tooling`, scenario "The personal laptop provides a GitHub command-line client" | `pkgs.gh` in `home.packages` | `@host:thiniel` |
| Capability interaction "a device authors infrastructure and repository work" | A booted guest imports the same feature module and invokes both tools from the ordinary account | `@check:integration-infrastructure-tooling` |
| Proposal boundary D1 (client only) | No `programs.gh` module and no git credential-helper registration; `home.packages` only | `@host:thiniel` (absence of helper configuration is preserved by not enabling the module) |

Persona impact: `owner--operator` gains the ability to author infrastructure
and operate repository workflows from the laptop. The interface is host
configuration, not a rendered screen, so the recording is otherwise `none`.

## Technology Decisions

| Decision | Choice | Channel / source | Why |
|---|---|---|---|
| Where the tools live | New Home Manager feature module `home/dan/features/cli/infrastructure-tooling.nix`, imported by `home/dan/thiniel.nix` | repository structure | Keeps the two tools in one host-scoped unit, importable by the integration test without loading the whole host profile. Alternatives: packages inline in `home/dan/thiniel.nix` (not importable as a test target), or `cloud-tools.nix` (imported by the macOS workstation, which the request does not cover). |
| OpenTofu package | `pkgs.opentofu` | `nixpkgs-unstable` (the host's package set); pinned `1.13.1` (verified by evaluating `inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.opentofu.version` at design time, 2026-10-17) | No Home Manager module exists; the package is the engine itself. `tenv`, which manages engine versions on the macOS workstation, is deliberately not used: it would add a version-manager state directory and an imperative `tenv tofu install` step, whereas the request is a ready-to-invoke tool. |
| GitHub CLI package | `pkgs.gh` | `nixpkgs-unstable`; pinned `2.102.0` (same evaluation, 2026-10-17) | `programs.gh` exists in Home Manager, but enabling it also enables the git credential helper by default, which would register `gh` for GitHub hosts and change the device's established identity selection (proposal D1). `home.packages` installs the client without touching git configuration. |
| Version-manager layering | None | — | Both packages come from the host's pinned nixpkgs input, so their versions move only with `flake.lock`. |

## Decisions

Decides D1: the GitHub client is installed as a package only; the git
credential helper stays unregistered — realized in
`home/dan/features/cli/infrastructure-tooling.nix` (`home.packages`, no
`programs.gh`), and preserved by `tests/assertions/thiniel-invariants.nix`
asserting the tools are present without asserting any helper configuration.

## Verification Binding

| Scenario title | Binding tag | Bound target (file / check / host) | Targeted run command | Expected RED failure mode |
|---|---|---|---|---|
| The personal laptop provides an OpenTofu engine | `@host:thiniel` | `tests/assertions/thiniel-invariants.nix` (imported by `tests/assertions/default.nix`, fired on host evaluation) | `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath` | Assertion failure: the host's package list does not contain `opentofu` |
| The personal laptop provides a GitHub command-line client | `@host:thiniel` | `tests/assertions/thiniel-invariants.nix` | `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath` | Assertion failure: the host's package list does not contain `gh` (the credential-helper guard holds before and after and is enforced by the same assertion) |
| A booted device runs its infrastructure and GitHub client tools | `@check:integration-infrastructure-tooling` | `tests/integration/infrastructure-tooling-test.nix` wired into `tests/integration/default.nix` | `nix build .#checks.x86_64-linux.integration-infrastructure-tooling` | Evaluation failure: the feature module imported by the guest does not exist yet (target wired before RED) |

## Test Targets Added/Changed

| Target file | Kind | Wired in by | Covers scenarios |
|---|---|---|---|
| `tests/assertions/thiniel-invariants.nix` (extend) | assertion | already imported by `tests/assertions/default.nix`; fired on `nixosConfigurations.thiniel` evaluation | The two `@host:thiniel` scenarios |
| `tests/integration/infrastructure-tooling-test.nix` (new) | VM (`pkgs.testers.runNixOSTest`) | `tests/integration/default.nix` → flake `checks.x86_64-linux.integration-infrastructure-tooling` | The `@e2e` scenario |

The integration guest imports the same feature module the host imports, uses
`home-manager-unstable` and the `unstablePkgs` package set already passed by
`tests/integration/default.nix`, and resolves the tools from the test user's
profile (`/etc/profiles/per-user/test/bin`). The test runs `tofu version` and
`gh --version` as the ordinary user.

## Architecture Impact

New:

- `home/dan/features/cli/infrastructure-tooling.nix` — `home.packages = [ pkgs.opentofu pkgs.gh ];`
- `tests/integration/infrastructure-tooling-test.nix` — VM check.

Changed:

- `home/dan/thiniel.nix` — imports the new feature module.
- `tests/assertions/thiniel-invariants.nix` — two package-presence assertions.
- `tests/integration/default.nix` — registers the new VM check.
- `docs/arc42/05-building-block-view.md` — adds the module to the `cli/` inventory.

No Option is introduced; the feature module carries only package declarations.

## Secrets & Safety

- **sops targets**: none. The change adds no secret, reads no secret, and
  creates no authentication session.
- **Identity boundary**: no `programs.gh` and no `gitCredentialHelper`
  configuration; the device's existing git identity selection is untouched
  (proposal D1).
- **`stateVersion` invariants**: neither `system.stateVersion` nor
  `home.stateVersion` is changed.
- **`hardware.nix` untouched**: `hosts/thiniel/hardware.nix` is not modified.
- The integration guest is disposable; no real host credential is used.

## Deployment & Rollback

Not a dangerous area (no boot loader, networking, filesystem, impermanence,
kernel, or secret change). The additive apply command for completeness:

- **Apply command**: `sudo nixos-rebuild switch --flake .#thiniel`
- **On-host verification**: as the owner, `tofu version` and `gh --version`
  print their versions; `command -v tofu gh` finds both in the profile.
- **Rollback**: `sudo nixos-rebuild switch --rollback` returns to the previous
  generation; the tools disappear from the profile. No data migration exists.

## Blast Radius

`thiniel` only. The change is additive to the owner's package profile; no
system service, network path, or credential path changes. A bad apply is
recoverable in the running system through `nixos-rebuild --rollback`; no SSH
or network surface is affected.

## arc42 chapter impact

- `docs/arc42/05-building-block-view.md` — the `cli/` feature inventory gains
  `infrastructure-tooling`.

No other chapter changes: no new service, interface, or deployment topology.

## Open Technical Questions

None.
