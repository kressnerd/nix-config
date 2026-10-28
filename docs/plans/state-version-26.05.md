# State-version epoch 25.11 → 26.05 (executed)

Status: **executed** (2026-10-28). Every host and Home Manager profile records
`26.05`; the work MacBook records nix-darwin `system.stateVersion = 7`.

The preceding channel upgrade ([`upgrade-26.05-plan.md`](upgrade-26.05-plan.md))
deliberately left both epochs at `25.11`. This record raises them. The operator
decision was: all hosts are near-fresh installs, the explicit workarounds below
should go, and losing GNU `man-db` on macOS is acceptable.

## Values

| Surface | Before | After |
|---|---|---|
| `system.stateVersion` on `thiniel`, `cupix001`, `adlerkopf`, `nixos-vm-minimal` | `"25.11"` | `"26.05"` |
| `home.stateVersion` in `home/dan/global/default.nix` (all profiles) | `"25.11"` | `"26.05"` |
| `home.stateVersion` in `home/dan/nixos-vm-minimal.nix` | `"25.11"` | `"26.05"` |
| nix-darwin `system.stateVersion` on `J6G6Y9JK7L` | `6` | `7` (`system.maxStateVersion`) |

`thiniel` keeps `26.05` although it builds from `nixpkgs-unstable` /
`home-manager-unstable` (both report `26.11`). The `26.11` gates are not
adopted: they would move the OpenCode/Claude Code directories, change zellij
escaping, adopt notmuch's new defaults and move Firefox's Darwin data
directory — none of which this change audited.

## Adopted release defaults

NixOS 26.05 gates, none of whose services is enabled on any host:
`dovecot`, `stalwart`, `seerr`, `tandoor-recipes`,
`taskchampion-sync-server`, `sabnzbd`, `lauti`, `netbox`, `nextcloud`,
`olivetin`.

Home Manager 26.05 gates and their disposition:

| Gate | Disposition |
|---|---|
| `programs.yazi.shellWrapperName` default `yy` → `y` | explicit pin removed; the wrapper is `y` |
| `wayland.windowManager.hyprland.configType` default `hyprlang` → `lua` | explicit pin removed; the generated file stays `hyprland.lua` |
| `programs.firefox.configPath` default `.mozilla/firefox` → relative XDG path | **pin kept, now absolute** — Home Manager exports `MOZ_APP_DATA` only when `configPath` differs from its resolved default, so the relative default would fall back to `~/.mozilla/firefox` while the `profiles.ini` is rendered under XDG; asserted in `tests/assertions/thiniel-hm-invariants.nix` |
| `programs.man.package` default `null` on Darwin | accepted: the Mac drops GNU `man-db` and uses the system `man` |
| `programs.zsh.dotDir` default XDG path | no effect: `xdg.enable = false` |
| `xdg.userDirs.setSessionVariables` default `false` | no effect: `xdg.userDirs.enable = false` |
| `gtk.gtk4.theme` no longer mirrors `gtk.theme` | no effect: `gtk.gtk4.theme` is unset and stylix does not set it |
| `programs.neovim.*`, `programs.mergiraf.*`, `programs.docker-cli`, `services.colima`, `services.home-manager-auto-upgrade` | not used by any profile |

nix-darwin epoch `7` changes only `programs.tmux` reversed split bindings; no
profile installs tmux.

## Removed workarounds

- `home/dan/features/cli/yazi.nix`: `shellWrapperName = "y"`.
- `home/dan/features/linux/hyprland.nix`: `configType = "lua"`.
- `tests/assertions/thiniel-yazi-invariants.nix` and
  `tests/assertions/J6G6Y9JK7L-invariants.nix`: the assertions that existed only
  to prove the pin was stated.
- `tests/assertions/thiniel-hm-invariants.nix`: the
  `mkStateVersionOptionDefault` guard and its two assertions; the browser
  location assertion is kept in direct form because that pin is still required.
- `tests/unit/hm-linux-modules-test.nix`: the `configType` wiring test.

## Guard

`checks.<system>.state-version-epoch` in `flake.nix` compares every host's
`system.stateVersion`, every Home Manager profile's `home.stateVersion`, and the
Darwin `system.stateVersion` (against `system.maxStateVersion`) with
`nixpkgs.lib.trivial.release`. A channel bump fails it until the epoch is raised
deliberately.

## Verification

- **RED**: the new check failed with 10 findings — four systems and four home
  profiles at `25.11`, Darwin home at `25.11`, Darwin system at `6`.
- **GREEN**: the check passes; the template check still passes.
- **Derivation identity on Linux**: system toplevel and Home Manager generation
  are unchanged from before the change for `thiniel`
  (`ynlljby…-nixos-system-thiniel-26.11.20261024.d3b13ad`,
  `1zs7aa6…-home-manager-generation`), `cupix001`, `adlerkopf` and
  `nixos-vm-minimal`. The epoch bump and the yazi/hyprland pin removals are
  behaviourally inert there.
- **Darwin**: the toplevel changes from `cvyb90i…` to `qrn5d7w…`; the only
  configuration delta is the removed `man-db` package. Epoch `7` alone does not
  change the derivation (the same `qrn5d7w…` results with system epoch `6`).
- `nix flake check --no-build` passes; the non-VM checks build; every host
  evaluates its assertions; the Python suite passes (256 tests).
- The seven integration fixtures were raised to `26.05`; all seven
  `integration-*` derivations are identical to `HEAD`, so their booted
  behaviour is unchanged.
- The `thiniel` system toplevel builds from the unchanged derivation.
- **Deployed** (2026-10-28 11:20:52, `sudo nixos-rebuild switch --flake .#thiniel
  --override-input givn github:kressnerd/givn`): the active system is
  `mx60abbj…` (deriver `ys66kfiv…`), the active Home Manager generation is
  `wv6r5rrl…`. Evaluating the working tree with the same `givn` override
  reproduces both paths exactly; without the override the evaluation lacks the
  `givn` package and differs. No systemd unit failed, and the deployed
  configuration's system and Home Manager assertions pass. The activation reused
  the existing generation 237 because the epoch bump leaves the store path
  unchanged.
- The givn spec-traceability step fails on the two in-progress changes
  (`provision-storage-host`, `security-key-remote-identity`) that bind checks
  and a host which do not exist yet; that failure predates this change.

## Rollback

Revert the commit and rebuild. No data migration was triggered: no gated service
is enabled, and the browser profile already lives at
`~/.config/mozilla/firefox`. Lowering an epoch again is itself an explicit
upgrade, not a routine action.
