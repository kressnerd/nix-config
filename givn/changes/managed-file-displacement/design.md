# Design: managed-file-displacement

## Scope

The device's Home Manager activation must complete when a program on the device
has rewritten a file the home profile manages — on the first rewrite *and* on
every later one — keeping each rewritten version beside the rendered file instead
of aborting. One helper, one setting in two declaration sites, one new booted
check, two host assertions.

Runners unchanged: `verify.command` = `./scripts/givn-verify.sh`,
`verify.e2e_command` = `./scripts/givn-verify-e2e.sh`.

## Use-Case Traceability

Owning contract: `reproduce-working-environment` (permanent, carried in this
change with the new capability, its rule and its interaction row). New capability:
`managed-file-displacement`.

| Use-case contract element | Technical decision | Bound verification target |
|---|---|---|
| Rule: applying the configuration preserves already available working data unless a replacement is authorised | Every rewrite is renamed to the first free `<name>.<n>`; nothing is deleted, so each version a program wrote stays | `@e2e @check:integration-managed-file-displacement` |
| Rule (new): applying the device's configuration completes even when a program rewrote a managed file, each time it is rewritten | `home-manager.backupCommand` runs a small renaming script; Home Manager's own extension mechanism covers only the first conflict per path | `@host:thiniel` (shared-module invariant covering the four NixOS hosts), `@host:J6G6Y9JK7L`, and the booted check |
| Flow step 3: the owner authorises assembly of the intended context; the system applies the selected configuration | The activation applies it; it no longer depends on a manual file move | `@e2e @check:integration-managed-file-displacement` |
| Success guarantee: the owner can resume the specified usual work on the selected device | The configuration stays appliable, so the environment can be kept current | all three scenarios |

Personas: `owner--operator` (confirmed 2026-10-11) applies the configuration and
sees a failed activation. `family--application-user` is not affected. Scenario
actors stay interaction roles (`a device`, `the personal laptop`).

## Decisions

- **Decides D1 (proposal)**: the displacement mechanism is a backup command that
  renames the conflicting file to the first free `<name>.<n>` — realized as
  `mkManagedFileDisplacement` in `lib/helpers.nix`, used by
  `hosts/common/global/default.nix` (four NixOS hosts) and
  `hosts/J6G6Y9JK7L/default.nix` (the MacBook) as
  `home-manager.backupCommand`. Rejected: the backup extension alone (Home
  Manager aborts on a second conflict on the same path — verified in
  `modules/files/check-link-targets.sh:39-40`), the extension with
  `overwriteBackup` (Home Manager deletes the previous displaced copy before
  moving the new one — `modules/files.nix:204-207`), and `trash-cli` (moves the
  file out of the tree and adds a package for a rename).
- **Decides D2 (proposal)**: the configuration moves the file; no manual step.
  The operator loses the loud abort and the displaced copies accumulate, which is
  recorded as risk R-025.
- **Carried to tasks**: the fixture's wiring — the flake passes the *declared*
  value, so the boot proves the device's setting rather than a test-local one.

## Technology Decisions

| Decision | Choice | Channel / source | Why |
|---|---|---|---|
| Displacement mechanism | `home-manager.backupCommand` set to a `writeShellScript` that renames the conflicting file to the first free `<name>.<n>` | Home Manager's system-level module option (`nixosModules` / `darwinModules`); the command runs in the activation | Home Manager runs the command with the conflicting path as its **final argument** (`modules/files.nix:198-200`), so the behaviour is entirely ours: every rewrite is displaced, nothing is deleted, and no second-conflict case exists. The extension alone cannot do this (see Decisions). |
| Where the script lives | `lib/helpers.nix`: `mkManagedFileDisplacement = pkgs: pkgs.writeShellScript "hm-displace-managed-file" ''…''` | this repository | One definition, two call sites (`hosts/common/global`, `hosts/J6G6Y9JK7L`), following the existing `mkPkgsUnstable` / `mkFirefoxExtensions` pattern instead of two drifting copies. |
| Where the value is declared | `hosts/common/global/default.nix` (adlerkopf, cupix001, nixos-vm-minimal, thiniel) plus `hosts/J6G6Y9JK7L/default.nix` (the MacBook, which does not import the NixOS shared module) | this repository | One value everywhere, two sites instead of five per-host copies. `hosts/common/global` is NixOS-only, so the darwin host states it itself. |
| Name of a displaced file | `<name>.<n>`, first free number | this repository | Says what happened (the file was displaced) without colliding with anything else, and needs no timestamp dependency — the operator chose the numbered rename (proposal D1). |
| Guest package set of the new check | `nixpkgs-unstable` pin, like the other two Home-Manager-based checks | `nixpkgs-unstable` (release `26.11`) | The check loads Home Manager modules, so their release must match the guest's; the release check stays enabled (design D3 of `quiet-configuration-evaluation`, still in force). |

No new overlay, package, or flake input.

## Verification Binding

| Scenario title | Binding tag | Bound target | Targeted run command | Expected RED failure mode |
|---|---|---|---|---|
| A booted device activates although a program rewrote a managed file | `@e2e @check:integration-managed-file-displacement` | `tests/integration/managed-file-displacement-test.nix` (wired by `tests/integration/default.nix` and the flake's linux checks block, which passes the declared command) | `nix build .#checks.x86_64-linux.integration-managed-file-displacement` | the guest's `home-manager-test.service` fails: with `null` declared there is no displacement mechanism, so Home Manager refuses the rewritten file (`Existing file '…/settings.conf' would be clobbered`) and the activation aborts |
| The personal laptop displaces a rewritten managed file | `@host:thiniel` | `tests/assertions/common-global-invariants.nix` (universal NixOS-host invariant, fired by host evaluation) | `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath` | the new assertion fails: `home-manager.backupCommand` is `null`, not a displacement command |
| The work MacBook displaces a rewritten managed file | `@host:J6G6Y9JK7L` | `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` (darwin system level — the HM-level file cannot see system options) | `nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath` | the new assertion fails for the same reason |

Assertion mechanics:

- Both host assertions assert that the device declares a displacement command
  (`config.home-manager.backupCommand != null`, and that its store path comes from
  the repository helper) — the declared state the activation consumes. The
  shared-module assertion covers all four NixOS hosts, so `@host:thiniel` proves
  the invariant for the host that reported the failure while the others are
  covered by the same assertion and by `nix flake check`.
- The booted check asserts the *behaviour*, with the expected names built
  independently of the declared value (`.1`, `.2`), so the fixture never
  interpolates the option and a `null` declaration cannot turn into an evaluation
  error — it turns into the intended abort.

## Test Targets Added/Changed

| Target file | Kind | Wired in by | Covers scenarios |
|---|---|---|---|
| `tests/integration/managed-file-displacement-test.nix` | VM (`pkgs.testers.runNixOSTest`) | registered in `tests/integration/default.nix`; the flake's linux checks block passes `backupCommand = self.nixosConfigurations.thiniel.config.home-manager.backupCommand` and the `unstablePkgs`/`home-manager-unstable` pair | the `@e2e` scenario |
| `tests/integration/default.nix`, flake linux checks block | wiring | — | the `@e2e` scenario |
| `tests/assertions/common-global-invariants.nix` | assertion (NixOS level, extended) | already imported by `tests/assertions/default.nix` | `@host:thiniel` (and the other three NixOS hosts) |
| `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` | assertion (darwin level, extended) | imported by `hosts/J6G6Y9JK7L/default.nix` | `@host:J6G6Y9JK7L` |

The fixture's shape (this is what makes RED real and repeat-safety visible):

```nix
{ pkgs, home-manager, backupCommand, ... }:
pkgs.testers.runNixOSTest {
  name = "managed-file-displacement";
  nodes.machine = { lib, ... }: {
    imports = [ home-manager.nixosModules.home-manager ];
    users.users.test = { isNormalUser = true; password = "testpass"; };

    # What a program on the device produced: it rewrote the managed file, and an
    # earlier rewrite was displaced before that, so the first free number is 2.
    system.activationScripts.seedRewrittenManagedFile = {
      deps = [ "users" ];
      text = ''
        install -d -o test -g users /home/test/.config/example
        install -o test -g users -m 0644 /dev/stdin /home/test/.config/example/settings.conf <<< "written by a program"
        install -o test -g users -m 0644 /dev/stdin /home/test/.config/example/settings.conf.1 <<< "written even earlier"
      '';
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      inherit backupCommand;                       # the value the device declares
      users.test = {
        home = { username = "test"; homeDirectory = "/home/test"; stateVersion = "25.11"; };
        home.file.".config/example/settings.conf".text = "rendered by the configuration\n";
      };
    };

    # The Home Manager modules the guest loads and its package set come from the
    # same release (the invariant the two sibling checks assert).
    assertions = [ { assertion = /* …release pairing… */; message = "…"; } ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    machine.succeed("test -L /home/test/.config/example/settings.conf")
    assert "rendered by the configuration" in machine.succeed("cat /home/test/.config/example/settings.conf")
    # the earlier displaced copy is untouched, the new rewrite landed beside it
    assert "written even earlier" in machine.succeed("cat /home/test/.config/example/settings.conf.1")
    assert "written by a program" in machine.succeed("cat /home/test/.config/example/settings.conf.2")
  '';
}
```

Ordering and ownership are deliberate: `system.activationScripts` runs as part of
stage 2, before systemd starts, so the seed always precedes
`home-manager-<user>.service`; `deps = [ "users" ]` puts the seed after the `users`
activation script, and the seed creates the directory and files owned by the test
user so a late or root-owned seed cannot masquerade as the clobber failure. A seed
that ran *after* activation would produce a false GREEN rather than a loud error —
which is why the assertion side checks the displaced contents, not only the
service state.

## Architecture Impact

- `lib/helpers.nix` — new `mkManagedFileDisplacement` (a `writeShellScript`).
- `hosts/common/global/default.nix` — `home-manager.backupCommand` for the four NixOS hosts.
- `hosts/J6G6Y9JK7L/default.nix` — the same for the darwin host.
- `tests/integration/managed-file-displacement-test.nix` — new VM check.
- `tests/integration/default.nix`, `flake.nix` — wiring and the declared value.
- `tests/assertions/{common-global-invariants,J6G6Y9JK7L-darwin-invariants}.nix` — the two assertions.
- `docs/arc42/` — chapters 01, 02, 05, 06, 07, 08, 09, 10, 11, 12 (see the impact assessment).

No `modules/` option surface, no service, no secret, no network change.

## Secrets & Safety

- **sops targets**: none.
- **`stateVersion` invariants**: unchanged (`25.11` on every host).
- **`hardware.nix`**: untouched.
- No plaintext secret; the private-data guard is unaffected.
- The script only renames a file in the same directory; it never deletes and never
  writes outside the profile's own directory.

## Blast Radius

- Every device that runs Home Manager: a file the operator hand-edited at a
  managed path is renamed aside instead of blocking the activation, so the failure
  no longer *tells* them about the edit; the displaced copy is visible as
  `<name>.<n>`. Recorded as risk R-025.
- `thiniel`: the immediate beneficiary — the browser-rewritten `profiles.ini` and
  both `search.json.mozlz4` are displaced on every rewrite, so a switch completes
  unattended.
- The script is the only custom code; a bug in it would show up as a failed
  activation (Home Manager logs the command's failure), not as data loss.
- No networking, boot-loader, secret, or service surface: no lockout risk.

## Deployment & Rollback

Not a dangerous area (no `boot.loader`, `networking`, `fileSystems`/disko,
persistence or secret wiring). Apply with
`sudo nixos-rebuild switch --flake .#thiniel`; rollback is the previous
system generation (`sudo nixos-rebuild switch --rollback`), which restores the
abort-on-conflict behaviour; displaced files already created stay where they are
and harm nothing.

## arc42 chapter impact

- `01-introduction-and-goals.md` — R1's evidence (the appliable configuration) and the quality-scenario pointer.
- `02-architecture-constraints.md` — the activation rule for a rewritten managed file.
- `05-building-block-view.md` — the helper, the two declaration sites, the sixth integration check.
- `06-runtime-view.md` — the "repository validation" list of integration checks.
- `07-deployment-view.md` — `thiniel`'s record of the failure mode and its removal.
- `08-crosscutting-concepts.md` — file rendering gains the displacement behaviour and the naming.
- `09-architecture-decisions.md` — the assessed candidate (NOT_QUALIFIED) row.
- `10-quality-requirements.md` — a quality scenario for an appliable configuration.
- `11-risks-and-technical-debt.md` — R-025.
- `12-glossary.md` — `Managed file`, `Displaced file`, and the check enumeration.

## Local runnability

- Host evaluation: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
  and `nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath`.
- Booted check: `nix build .#checks.x86_64-linux.integration-managed-file-displacement`
  (needs KVM; the `@e2e` runner builds all `integration-*` checks).
- The ordering risk is handled by the seed's `deps`/ownership and verified by the
  displaced-file assertions, not by the service wait alone.

## Open Technical Questions

None.
