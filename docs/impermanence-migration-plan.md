# Impermanence Colocation Migration Plan

## 1. Goal

Migrate all impermanence persistence path declarations from the central [`home/dan/features/linux/impermanence.nix`](../home/dan/features/linux/impermanence.nix) into the respective tool feature modules. Each tool module declares its own persistence paths, guarded by `myHome.persistence.enable`. System-level persistence paths in [`hosts/thiniel/default.nix`](../hosts/thiniel/default.nix) are similarly colocated into service-specific modules, guarded by `mySystem.persistence.enable`.

After migration, the central `impermanence.nix` is either removed or reduced to a minimal stub. Unclassified paths (no owning tool module) remain in a dedicated base persistence module.

## 2. Context

### Current State

All Home Manager persistence paths are declared in a single file [`home/dan/features/linux/impermanence.nix`](../home/dan/features/linux/impermanence.nix) (26 directories, 1 file). System-level paths are inline in [`hosts/thiniel/default.nix`](../hosts/thiniel/default.nix) (lines 128–158).

This violates the Single Responsibility Principle: adding a new tool requires editing a central file unrelated to the tool itself.

### Architecture Decision

- **Colocation via module options** — each feature module conditionally declares its persistence paths using `lib.mkIf config.myHome.persistence.enable`
- **No conditional imports** — all modules are always imported; persistence declarations are guarded by `mkIf`, not by import presence
- **Custom option namespaces** — `myHome.persistence.{enable, root}` (HM) and `mySystem.persistence.{enable, root}` (NixOS) provide the toggle mechanism
- **Base module** — unclassified paths (not owned by any tool) live in `modules/home-manager/persistence/default.nix` and `modules/nixos/persistence/default.nix`

### Flake Integration

- No `homeManagerModules` or `nixosModules` flake outputs exist yet
- `modules/home-manager/` contains only `.gitkeep`
- `modules/nixos/` contains only `systemd-sleep-settings.nix`
- The impermanence flake input (`inputs.impermanence.nixosModules.impermanence`) is imported per host and activates the HM impermanence module via `home-manager.sharedModules`

## 3. Technical Analysis

### 3.1 Home Manager Persistence Paths (current)

Source: [`home/dan/features/linux/impermanence.nix`](../home/dan/features/linux/impermanence.nix)

| # | Path | Type |
|---|------|------|
| 1 | `.cache/mesa_shader_cache` | directory |
| 2 | `.cache/mesa_shader_cache_db` | directory |
| 3 | `.cache/mozilla` | directory |
| 4 | `.claude` | directory |
| 5 | `.mozilla` | directory |
| 6 | `.ssh` | directory |
| 7 | `.vscode/extensions` | directory |
| 8 | `.roo` | directory |
| 9 | `dev` | directory |
| 10 | `Projects` | directory |
| 11 | `.config/sops/age` | directory |
| 12 | `.config/Code` | directory |
| 13 | `.config/libreoffice` | directory |
| 14 | `.config/ownCloud` | directory |
| 15 | `.config/netcup-scp` | directory |
| 16 | `.local/share/netcup-scp` | directory |
| 17 | `.local/share/ownCloud` | directory |
| 18 | `Dropbox` | directory |
| 19 | `.config/maestral` | directory |
| 20 | `.local/share/maestral` | directory |
| 21 | `.local/share/keyrings` | directory |
| 22 | `.local/share/containers` | directory |
| 23 | `.eteks` | directory |
| 24 | `.config/Signal` | directory |
| 25 | `.config/Threema` | directory |
| 26 | `Videos` | directory |
| 27 | `.bash_history` | file |

### 3.2 System-Level Persistence Paths (current)

Source: [`hosts/thiniel/default.nix`](../hosts/thiniel/default.nix) lines 128–158

| # | Path | Type |
|---|------|------|
| 1 | `/etc/nixos` | directory |
| 2 | `/var/log` | directory |
| 3 | `/var/lib/bluetooth` | directory |
| 4 | `/var/lib/cups` | directory |
| 5 | `/var/lib/nixos` | directory |
| 6 | `/var/lib/containers` | directory |
| 7 | `/var/lib/systemd/coredump` | directory |
| 8 | `/etc/NetworkManager/system-connections` | directory |
| 9 | `/var/lib/fwupd` | directory |
| 10 | `/var/lib/ModemManager` | directory |
| 11 | `/var/cache/tuigreet` | directory |
| 12 | `/etc/machine-id` | file |
| 13 | `/var/lib/sops-nix/key.txt` | file |

### 3.3 HM Path → Tool Module Mapping

| Persistenzpfad | Tool | Zielmodul | Kategorie |
|---|---|---|---|
| `.cache/mesa_shader_cache` | GPU/Mesa | base persistence module | unclassified |
| `.cache/mesa_shader_cache_db` | GPU/Mesa | base persistence module | unclassified |
| `.cache/mozilla` | Firefox | [`home/dan/features/productivity/browser.nix`](../home/dan/features/productivity/browser.nix) | tool |
| `.claude` | Claude Code | [`home/dan/features/development/claude-code.nix`](../home/dan/features/development/claude-code.nix) | tool |
| `.mozilla` | Firefox | [`home/dan/features/productivity/browser.nix`](../home/dan/features/productivity/browser.nix) | tool |
| `.ssh` | SSH | [`home/dan/features/cli/ssh.nix`](../home/dan/features/cli/ssh.nix) | tool |
| `.vscode/extensions` | VSCode | [`home/dan/features/productivity/vscode-fhs.nix`](../home/dan/features/productivity/vscode-fhs.nix) | tool |
| `.roo` | Roo Code | [`home/dan/features/productivity/vscode-fhs.nix`](../home/dan/features/productivity/vscode-fhs.nix) | tool |
| `dev` | Arbeitsverzeichnis | base persistence module | unclassified |
| `Projects` | Arbeitsverzeichnis | base persistence module | unclassified |
| `.config/sops/age` | SOPS age keys | base persistence module | unclassified |
| `.config/Code` | VSCode | [`home/dan/features/productivity/vscode-fhs.nix`](../home/dan/features/productivity/vscode-fhs.nix) | tool |
| `.config/libreoffice` | LibreOffice | [`home/dan/features/productivity/libreoffice.nix`](../home/dan/features/productivity/libreoffice.nix) | tool |
| `.config/ownCloud` | ownCloud | [`home/dan/features/productivity/owncloud.nix`](../home/dan/features/productivity/owncloud.nix) | tool |
| `.config/netcup-scp` | netcup-scp | base persistence module | unclassified |
| `.local/share/netcup-scp` | netcup-scp | base persistence module | unclassified |
| `.local/share/ownCloud` | ownCloud | [`home/dan/features/productivity/owncloud.nix`](../home/dan/features/productivity/owncloud.nix) | tool |
| `Dropbox` | Maestral | [`home/dan/features/productivity/maestral.nix`](../home/dan/features/productivity/maestral.nix) | tool |
| `.config/maestral` | Maestral | [`home/dan/features/productivity/maestral.nix`](../home/dan/features/productivity/maestral.nix) | tool |
| `.local/share/maestral` | Maestral | [`home/dan/features/productivity/maestral.nix`](../home/dan/features/productivity/maestral.nix) | tool |
| `.local/share/keyrings` | gnome-keyring | [`home/dan/features/linux/gnome-keyring.nix`](../home/dan/features/linux/gnome-keyring.nix) | tool |
| `.local/share/containers` | Podman | [`home/dan/features/development/containers-podman.nix`](../home/dan/features/development/containers-podman.nix) | tool |
| `.eteks` | SweetHome3D | [`home/dan/features/productivity/sweethome3d.nix`](../home/dan/features/productivity/sweethome3d.nix) | tool |
| `.config/Signal` | Signal | [`home/dan/features/productivity/messaging.nix`](../home/dan/features/productivity/messaging.nix) | tool |
| `.config/Threema` | Threema | [`home/dan/features/productivity/messaging.nix`](../home/dan/features/productivity/messaging.nix) | tool |
| `Videos` | wf-recorder | [`home/dan/features/linux/hyprland.nix`](../home/dan/features/linux/hyprland.nix) | tool |
| `.bash_history` (file) | Bash | base persistence module | unclassified |

### 3.4 Unclassified Paths — Rationale

| Path | Reason |
|---|---|
| `.cache/mesa_shader_cache` | GPU driver cache; activated implicitly by nixos-hardware; no HM feature module owns GPU |
| `.cache/mesa_shader_cache_db` | Same as above |
| `dev` | User work directory; no tool module |
| `Projects` | User work directory; no tool module |
| `.config/sops/age` | SOPS age key; managed via `home-manager.sharedModules`; no dedicated HM feature module |
| `.config/netcup-scp` | Python CLI script in `scripts/`; no HM feature module |
| `.local/share/netcup-scp` | Same as above |
| `.bash_history` (file) | No `programs.bash` feature module exists |

### 3.5 System Path → Service Mapping

| Persistenzpfad | Dienst | Zuordnung |
|---|---|---|
| `/etc/nixos` | NixOS config | base persistence |
| `/var/log` | System logs | base persistence |
| `/var/lib/nixos` | NixOS state | base persistence |
| `/var/lib/systemd/coredump` | Systemd | base persistence |
| `/etc/machine-id` (file) | Systemd | base persistence |
| `/var/lib/sops-nix/key.txt` (file) | SOPS | base persistence |
| `/var/lib/bluetooth` | Bluetooth | host-specific (thiniel) |
| `/var/lib/cups` | CUPS | host-specific (thiniel) |
| `/var/lib/containers` | Podman system | `hosts/common/optional/virtualisation.nix` or host |
| `/etc/NetworkManager/system-connections` | NetworkManager | `hosts/common/optional/networkmanager.nix` |
| `/var/lib/fwupd` | fwupd | host-specific (nixos-hardware implicit) |
| `/var/lib/ModemManager` | ModemManager | host-specific (nixos-hardware implicit) |
| `/var/cache/tuigreet` | greetd/tuigreet | host-specific (thiniel) |

### 3.6 Host Matrix

| Host | HM Impermanence | System Impermanence | Platform |
|---|---|---|---|
| thiniel | ✅ active | ✅ active | NixOS x86_64 |
| cupix001 | ❌ | ⚠️ module imported, no `environment.persistence` block | NixOS x86_64 |
| nixos-vm-minimal | ❌ | ❌ | NixOS aarch64 |
| J6G6Y9JK7L | ❌ | ❌ | macOS nix-darwin |

## 4. Implementation Phases

### Phase 0: Validation Strategy

**Syntax validation:**

```bash
nix flake check
```

**Build validation:**

```bash
nixos-rebuild build --flake .#thiniel
```

**Eval-time path set comparison** (before/after each phase):

```bash
# HM paths
nix eval .#nixosConfigurations.thiniel.config.home-manager.users.dan.home.persistence.\"/persist\".directories --json | jq 'sort'
nix eval .#nixosConfigurations.thiniel.config.home-manager.users.dan.home.persistence.\"/persist\".files --json | jq 'sort'

# System paths
nix eval .#nixosConfigurations.thiniel.config.environment.persistence.\"/persist/system\".directories --json | jq 'sort'
nix eval .#nixosConfigurations.thiniel.config.environment.persistence.\"/persist/system\".files --json | jq 'sort'
```

**Hosts without impermanence:**

```bash
# Must produce empty list or error (no persistence block)
nix eval .#nixosConfigurations.cupix001.config.home-manager.users.dan.home.persistence --json
```

**Rollback:**

```bash
# Revert commits; nixos-rebuild switch to previous generation
sudo nixos-rebuild switch --rollback
```

**Dangerous change categories:** None — this migration restructures where paths are declared, not what paths exist. No boot, network, filesystem, or auth changes.

### Phase 1: Snapshot Current State

- [ ] Record current HM persistence path set via `nix eval` (directories + files) for thiniel
- [ ] Record current system persistence path set via `nix eval` for thiniel
- [ ] Save both as reference files in `tests/` or local notes for comparison
- [ ] Verify `nix flake check` passes on current state

### Phase 2: Introduce Base Persistence Modules

#### 2.1 HM Options Module

- [ ] Create `modules/home-manager/persistence/options.nix`
  - Define `myHome.persistence.enable` (`mkEnableOption`)
  - Define `myHome.persistence.root` (`mkOption`, type `types.str`, default `"/persist"`)

#### 2.2 HM Base Persistence Module

- [ ] Create `modules/home-manager/persistence/default.nix`
  - Import `./options.nix`
  - Guard with `lib.mkIf config.myHome.persistence.enable`
  - Declare unclassified HM directories:
    - `.cache/mesa_shader_cache`
    - `.cache/mesa_shader_cache_db`
    - `dev`
    - `Projects`
    - `.config/sops/age`
    - `.config/netcup-scp`
    - `.local/share/netcup-scp`
  - Declare unclassified HM files:
    - `.bash_history`

#### 2.3 NixOS Options Module

- [ ] Create `modules/nixos/persistence/options.nix`
  - Define `mySystem.persistence.enable` (`mkEnableOption`)
  - Define `mySystem.persistence.root` (`mkOption`, type `types.str`, default `"/persist/system"`)

#### 2.4 NixOS Base Persistence Module

- [ ] Create `modules/nixos/persistence/default.nix`
  - Import `./options.nix`
  - Guard with `lib.mkIf config.mySystem.persistence.enable`
  - Declare base system directories:
    - `/etc/nixos`
    - `/var/log`
    - `/var/lib/nixos`
    - `/var/lib/systemd/coredump`
  - Declare base system files:
    - `/etc/machine-id`
    - `/var/lib/sops-nix/key.txt`
  - Set `hideMounts = true`

#### 2.5 Flake Integration

- [ ] Add HM persistence module to `home-manager.sharedModules` in `flake.nix`
- [ ] Add NixOS persistence module to host imports or a common module path
- [ ] Set `myHome.persistence.enable = true` in `home/dan/thiniel.nix`
- [ ] Set `mySystem.persistence.enable = true` in `hosts/thiniel/default.nix`
- [ ] Remove unclassified paths from central `impermanence.nix` (paths now in base module)
- [ ] Remove base system paths from `hosts/thiniel/default.nix` inline block (paths now in NixOS base module)

#### 2.6 Validation

- [ ] `nix flake check` passes
- [ ] `nixos-rebuild build --flake .#thiniel` succeeds
- [ ] HM path set identical to Phase 1 snapshot
- [ ] System path set identical to Phase 1 snapshot
- [ ] Hosts without impermanence unaffected (`myHome.persistence.enable` defaults to `false`)

### Phase 3: Per-Tool Migration (iterative)

Each tool migration follows this pattern:

1. Add `home.persistence.${cfg.root}.directories` (or `.files`) block to the tool module, guarded by `lib.mkIf config.myHome.persistence.enable`
2. Remove the corresponding path(s) from central `impermanence.nix`
3. Validate: `nix flake check`, path set comparison

#### Migration Order

| # | Tool | Paths | Target Module | Complexity |
|---|------|-------|--------------|------------|
| 1 | LibreOffice | `.config/libreoffice` | `home/dan/features/productivity/libreoffice.nix` | 1 dir |
| 2 | SweetHome3D | `.eteks` | `home/dan/features/productivity/sweethome3d.nix` | 1 dir |
| 3 | ownCloud | `.config/ownCloud`, `.local/share/ownCloud` | `home/dan/features/productivity/owncloud.nix` | 2 dirs |
| 4 | Maestral | `Dropbox`, `.config/maestral`, `.local/share/maestral` | `home/dan/features/productivity/maestral.nix` | 3 dirs |
| 5 | gnome-keyring | `.local/share/keyrings` | `home/dan/features/linux/gnome-keyring.nix` | 1 dir |
| 6 | SSH | `.ssh` | `home/dan/features/cli/ssh.nix` | 1 dir |
| 7 | Claude Code | `.claude` | `home/dan/features/development/claude-code.nix` | 1 dir |
| 8 | Firefox | `.cache/mozilla`, `.mozilla` | `home/dan/features/productivity/browser.nix` | 2 dirs |
| 9 | VSCode + Roo | `.config/Code`, `.vscode/extensions`, `.roo` | `home/dan/features/productivity/vscode-fhs.nix` | 3 dirs |
| 10 | Messaging | `.config/Signal`, `.config/Threema` | `home/dan/features/productivity/messaging.nix` | 2 dirs |
| 11 | Podman | `.local/share/containers` (HM) | `home/dan/features/development/containers-podman.nix` | 1 dir |
| 12 | Hyprland/Videos | `Videos` | `home/dan/features/linux/hyprland.nix` | 1 dir |

#### Per-Tool Checklist Template

For each tool above:

- [ ] Add persistence block to target module with `lib.mkIf config.myHome.persistence.enable`
- [ ] Remove path(s) from central `impermanence.nix`
- [ ] `nix flake check` passes
- [ ] Path set unchanged (eval comparison)

#### System-Level Per-Service Migration

| # | Service | Paths | Target | Complexity |
|---|---------|-------|--------|------------|
| S1 | Bluetooth | `/var/lib/bluetooth` | `hosts/thiniel/default.nix` (host-specific block) | 1 dir |
| S2 | CUPS | `/var/lib/cups` | `hosts/thiniel/default.nix` (host-specific block) | 1 dir |
| S3 | NetworkManager | `/etc/NetworkManager/system-connections` | `hosts/common/optional/networkmanager.nix` or host | 1 dir |
| S4 | Podman system | `/var/lib/containers` | virtualisation module or host | 1 dir |
| S5 | fwupd | `/var/lib/fwupd` | host-specific (hardware-dependent) | 1 dir |
| S6 | ModemManager | `/var/lib/ModemManager` | host-specific (hardware-dependent) | 1 dir |
| S7 | tuigreet | `/var/cache/tuigreet` | host-specific (thiniel greetd config) | 1 dir |

For each system service:

- [ ] Add persistence block guarded by `lib.mkIf config.mySystem.persistence.enable`
- [ ] Remove path from inline `environment.persistence` block in `hosts/thiniel/default.nix`
- [ ] `nix flake check` passes
- [ ] System path set unchanged (eval comparison)

### Phase 4: Cleanup

- [ ] Remove or reduce central `impermanence.nix` to empty/stub (all paths migrated)
- [ ] Remove inline `environment.persistence` block from `hosts/thiniel/default.nix` (all paths migrated)
- [ ] Add NixOS assertion: if `mySystem.persistence.enable` is true, `environment.persistence` must be non-empty
- [ ] Update `home/dan/thiniel.nix` imports if `impermanence.nix` is removed
- [ ] `nix flake check` passes
- [ ] `nixos-rebuild build --flake .#thiniel` succeeds
- [ ] Full path set comparison: HM + system identical to Phase 1 snapshot
- [ ] Hosts without impermanence build cleanly
- [ ] Documentation update: note colocation pattern in project docs

## 5. Validation Strategy

### Per-Change Validation

Every change runs:

```bash
nix flake check
```

### Per-Phase Validation

After each phase, compare path sets:

```bash
# Compare HM directories
diff <(nix eval .#nixosConfigurations.thiniel.config.home-manager.users.dan.home.persistence.\"/persist\".directories --json | jq 'sort') reference-hm-dirs.json

# Compare HM files
diff <(nix eval .#nixosConfigurations.thiniel.config.home-manager.users.dan.home.persistence.\"/persist\".files --json | jq 'sort') reference-hm-files.json

# Compare system directories
diff <(nix eval .#nixosConfigurations.thiniel.config.environment.persistence.\"/persist/system\".directories --json | jq 'sort') reference-sys-dirs.json

# Compare system files
diff <(nix eval .#nixosConfigurations.thiniel.config.environment.persistence.\"/persist/system\".files --json | jq 'sort') reference-sys-files.json
```

### Non-Impermanence Hosts

Hosts without impermanence must not gain any `home.persistence` or `environment.persistence` entries:

```bash
# Must be empty or absent
nix eval .#nixosConfigurations.cupix001.config.home-manager.users.dan.home.persistence --json
nix eval .#nixosConfigurations.nixos-vm-minimal.config.home-manager.users.dan.home.persistence --json
```

### Final Validation

- `nix flake check` green
- `nixos-rebuild build --flake .#thiniel` succeeds
- All path sets identical to pre-migration snapshot
- No `home.persistence` on hosts without `myHome.persistence.enable = true`
- No `environment.persistence` on hosts without `mySystem.persistence.enable = true`

## 6. Acceptance Criteria

- [ ] `myHome.persistence.enable` option exists and defaults to `false`
- [ ] `mySystem.persistence.enable` option exists and defaults to `false`
- [ ] All 27 HM paths (26 directories + 1 file) are declared in their respective tool modules or the base persistence module
- [ ] All 13 system paths (11 directories + 2 files) are declared in their respective service modules or the base persistence module
- [ ] Central `impermanence.nix` is removed or empty
- [ ] Inline `environment.persistence` block in `hosts/thiniel/default.nix` is removed
- [ ] `nix flake check` passes
- [ ] `nixos-rebuild build --flake .#thiniel` succeeds
- [ ] Hosts without impermanence are unaffected (no persistence paths, builds succeed)
- [ ] Path sets are identical before and after migration

## 7. Current Status

- **Phase 0**: ✅ Complete
- **Phase 1**: ✅ Complete
- **Phase 2**: ✅ Complete — base persistence modules introduced
- **Phase 3**: ✅ Complete — all 12 HM tool migrations done
- **Phase 4**: ✅ Complete — central impermanence.nix removed
