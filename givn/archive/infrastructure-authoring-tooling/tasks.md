# Tasks: infrastructure-authoring-tooling

Owning use case: `reproduce-working-environment`. Domain constraints carried
into every scenario: the tools are available to the owner's ordinary account on
a booted device; their presence creates no authentication session, credential,
or git credential-helper registration; `system.stateVersion` and
`home.stateVersion` do not change; `hosts/thiniel/hardware.nix` is read-only;
no secret is read or written.

## Setup

- [x] Read `givn/specs/reproduce-working-environment/usecase.md`, the
      `infrastructure-authoring-tooling` delta, and the proposal/design.
- [x] Wire the new `@e2e` target before RED: `tests/integration/infrastructure-tooling-test.nix`
      is registered in `tests/integration/default.nix`. The test imports the
      new feature module and runs `tofu version` / `gh --version` as the
      ordinary test user.
- [x] Prove the e2e target's RED (module not yet created):
      `nix build --no-link .#checks.x86_64-linux.integration-infrastructure-tooling`
      → exit 1:
      ```
      error: Path 'home/dan/features/cli/infrastructure-tooling.nix' does not exist in Git repository "/home/dan/dev/PRIVATE/nix-config".
      ```
- [x] E2e scope counts from `scripts/givn-scenario-count.py`:
      regular = 25, e2e = 10, total = 35. The e2e scope is strictly smaller.
      `verify.e2e_command` (`./scripts/givn-verify-e2e.sh`) is not identical to
      `verify.command` (`./scripts/givn-verify.sh`); both are declared in
      `givn/commands.yaml`.
- [x] Linux/KVM builder available: `/dev/kvm` exists
      (`crw-rw-rw- 1 root kvm 10, 232`).

## Scenario 1 — The personal laptop provides an OpenTofu engine

- [x] **RED** — add `hmHasPkg "opentofu"` to
      `tests/assertions/thiniel-invariants.nix`. Run:
      `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
      → exit 1:
      ```
      error:
      Failed assertions:
      - thiniel: the OpenTofu engine (opentofu) must be installed for infrastructure authoring
      ```
- [x] **GREEN** — create
      `home/dan/features/cli/infrastructure-tooling.nix` with `pkgs.opentofu`
      and import it from `home/dan/thiniel.nix`. Re-run the targeted command →
      exit 0:
      ```
      /nix/store/q0lp0ngbnlv0z3i5fgfn2wgsvfdifxiy-nixos-system-thiniel-26.11.20261016.f20cd90.drv
      ```
- [x] **REFACTOR** — no refactor needed; the module contains only the package
      declaration. Re-run the targeted command → exit 0:
      ```
      /nix/store/q0lp0ngbnlv0z3i5fgfn2wgsvfdifxiy-nixos-system-thiniel-26.11.20261016.f20cd90.drv
      ```
- [x] COMMIT: `2966631`

## Scenario 2 — The personal laptop provides a GitHub command-line client

- [x] **RED** — add the `gh` presence assertion and the credential-helper guard
      to `tests/assertions/thiniel-invariants.nix`. Run:
      `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
      → exit 1:
      ```
      error:
      Failed assertions:
      - thiniel: the GitHub CLI (gh) must be installed without registering a git credential helper for GitHub hosts
      ```
- [x] **GREEN** — add `pkgs.gh` to
      `home/dan/features/cli/infrastructure-tooling.nix`. Re-run the targeted
      command → exit 0:
      ```
      /nix/store/4jz04wjg735avaprl3qz8j4ik443zfd4-nixos-system-thiniel-26.11.20261016.f20cd90.drv
      ```
- [x] **REFACTOR** — no refactor needed; the module stays package-only (no
      `programs.gh`, so no credential helper). Re-run the targeted command →
      exit 0:
      ```
      /nix/store/4jz04wjg735avaprl3qz8j4ik443zfd4-nixos-system-thiniel-26.11.20261016.f20cd90.drv
      ```
- [x] COMMIT: `f784a92`

## Scenario 3 — A booted device runs its infrastructure and GitHub client tools

- [x] **RED** — the target was wired in Setup; before the feature module
      existed it failed to evaluate:
      ```
      error: Path 'home/dan/features/cli/infrastructure-tooling.nix' does not exist in Git repository "/home/dan/dev/PRIVATE/nix-config".
      ```
      (exit 1, command above).
- [x] **GREEN** — after both packages are in the module, run
      `nix build --no-link .#checks.x86_64-linux.integration-infrastructure-tooling`
      → exit 0. The guest booted, `home-manager-test.service` started, and
      `tofu version` and `gh --version` both succeeded from
      `/etc/profiles/per-user/test/bin`:
      ```
      these 2 paths will be fetched (45.7 MiB download, 152.9 MiB unpacked):
        /nix/store/x6kcq7g4cwysbwjiyz152rbl6fv7l55w-gh-2.102.0
        /nix/store/h9hbmcr2zjbd7hggkkng83c709i88302-opentofu-1.13.1
      building '/nix/store/48gj1g82znysgyjmpyhv4riamwbqcqvi-vm-test-run-infrastructure-tooling.drv'...
      exit=0
      ```
- [x] **REFACTOR** — no refactor needed; the test imports the same module the
      host imports. Re-run the targeted command → exit 0 (same output).
- [x] COMMIT: `003403c`
