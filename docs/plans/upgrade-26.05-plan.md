# Upgrade 25.11 → 26.05 (ausgeführt)

Status: **durchgeführt** (2026-09-29). Alle non-adlerkopf-Hosts evaluieren auf 26.05.

## Channel-Bump

| Input | von | nach |
|---|---|---|
| nixpkgs | `nixos-25.11` | `nixos-26.05` |
| nixpkgs-darwin | `nixpkgs-25.11-darwin` | `nixpkgs-26.05-darwin` |
| darwin | `nix-darwin-25.11` | `nix-darwin-26.05` |
| home-manager | `release-25.11` | `release-26.05` |
| stylix | `release-25.11` | `release-26.05` |

`system.stateVersion` / `home.stateVersion` **unverändert** (`"25.11"` bzw. darwin `6`).

## Cycles

1. `chore(flake): upgrade to nixpkgs 26.05`
   - Unit-Test `tests/unit/flake-channel-test.nix` (Red: `release = 25.11`).
   - `nodePackages.*` entfernt (26.05) → Top-Level-Attribute `prettier`, `typescript-language-server`, `bash-language-server`, `yaml-language-server`, `js-beautify`.
   - `modules/nixos/systemd-sleep-settings.nix` gelöscht: 26.05 bringt `systemd.sleep.settings.Sleep` nativ (freeform `attrsOf unitOption`) → doppelte Deklaration. `tests/assertions/thiniel-sleep-invariants.nix` sichert die OPAL-Invarianten weiter.
   - 26.05 macht systemd-Stage-1 zum Default → `boot.initrd.postDeviceCommands` bricht.
     - thiniel: `boot.initrd.systemd.enable = false` (Opt-out, boot-kritisch/OPAL-FDE). Assertion `tests/assertions/thiniel-boot-invariants.nix`.
     - nixos-vm-minimal: obsoleten Device-Wait-Loop aus `hosts/nixos-vm-minimal/disko.nix` entfernt.
2. `chore(flake): unpin sops-nix` — 26.05 liefert go 1.26.7; `sops-install-secrets` baut verifiziert.
3. `fix(J6G6Y9JK7L): drop homebrew cleanup workaround` — nix-darwin 26.05 emittiert `brew bundle … --zap --force-cleanup` selbst. Assertion `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` (darwin-Level; das HM-Level-File sieht `homebrew.*` nicht).
4. `refactor(nix): replace nixfmt-rfc-style alias with nixfmt` — `warnAlias` in 26.05. Unit-Test `tests/unit/nixfmt-alias-test.nix`.

## Offen

**adlerkopf: vorbestehend kaputt** (auch auf 25.11, im Worktree verifiziert):
`boot.initrd.luks.devices.cryptroot.device` — disko generiert `/dev/disk/by-partlabel/disk-nvme0n1-cryptroot`, `hosts/adlerkopf/tpm2.nix` setzt `/dev/disk/by-partlabel/cryptroot`. Nicht Teil des Upgrades.

**HM-Deprecation-Warnungen** (funktionieren noch, Entfernung späterer Release):
- `programs.aerospace.userSettings` → `programs.aerospace.settings`
- `programs.ssh.matchBlocks` (+ `.*.extraOptions`) → `programs.ssh.settings`
- `programs.firefox.configPath` Legacy-Default — bleibt wegen `home.stateVersion < 26.05` bewusst so

**26.11-Pflicht:** Scripted Initrd wird entfernt → thiniels Root-Wipe muss auf `boot.initrd.systemd.services.<name>` (`before = [ "sysroot.mount" ]`) migriert werden.

## Verifikation

```bash
nix flake check --no-build
nix build .#checks.aarch64-darwin.unit-helpers
nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.cupix001.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.nixos-vm-minimal.config.system.build.toplevel.drvPath
nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath
sudo darwin-rebuild switch --flake .#J6G6Y9JK7L     # Homebrew-Aktivierung prüfen
sudo nixos-rebuild test --flake .#thiniel           # vor switch; Boot-Pfad geändert
```

Rollback: `sudo darwin-rebuild rollback` / vorherige NixOS-Generation; Repo: `git revert`.
