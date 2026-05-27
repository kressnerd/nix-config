# Implementation Plan: Node.js (fnm) and Podman on thiniel

## Business Context

The thiniel dev machine needs Node.js (via fnm — Fast Node Manager) and Podman for containerized development workflows. The fnm module already exists and is tested; the container modules (~1800 lines across 6 files) exist but have a **duplicate alias bug** and are missing the required **system-level Podman enablement**.

## Acceptance Criteria

- [ ] `fnm` is available in the user shell on thiniel and auto-switches Node versions via `.nvmrc`/`.node-version`
- [ ] `podman` runs rootless containers on thiniel
- [ ] Container data survives reboots (impermanence persistence)
- [ ] No Home Manager merge conflicts from duplicate aliases
- [ ] All existing tests continue to pass
- [ ] New assertions and tests cover each change
- [ ] `nix flake check` passes after every phase

## Technical Analysis

### Node.js via fnm

- Module: [`fnm.nix`](../../home/dan/features/development/fnm.nix) — installs `pkgs.fnm` + fish shell integration
- Unit tests exist: [`hm-dev-modules-test.nix`](../../tests/unit/hm-dev-modules-test.nix:83) lines 83–93
- Action: Single import line in [`thiniel.nix`](../../home/dan/thiniel.nix)

### Podman

#### System level (NixOS)

- [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix) — no `virtualisation.podman` configured
- [`hosts/common/optional/virtualisation.nix`](../../hosts/common/optional/virtualisation.nix) — only libvirtd/QEMU
- [`hosts/common/users/dan.nix`](../../hosts/common/users/dan.nix) — user `dan` not in `podman` group
- Required NixOS options: `virtualisation.podman.enable`, `virtualisation.podman.dockerCompat`, `virtualisation.podman.defaultNetwork.settings`

#### Home Manager level

- [`containers.nix`](../../home/dan/features/development/containers.nix) — entry point, imports all sub-modules
- [`containers-common.nix`](../../home/dan/features/development/containers-common.nix) — shared tooling, packages, aliases
- [`containers-podman.nix`](../../home/dan/features/development/containers-podman.nix) — Podman config files, **duplicate aliases**
- [`containers-networking.nix`](../../home/dan/features/development/containers-networking.nix) — network/volume definitions
- [`containers-nix-tools.nix`](../../home/dan/features/development/containers-nix-tools.nix) — Nix container templates
- [`containers-vscode.nix`](../../home/dan/features/development/containers-vscode.nix) — VS Code devcontainer integration

#### Alias Duplication Bug

Both [`containers-common.nix`](../../home/dan/features/development/containers-common.nix:79) and [`containers-podman.nix`](../../home/dan/features/development/containers-podman.nix:127) define identical `programs.fish.shellAliases` for:
- `docker`, `docker-compose`, `prun`, `pexec`, `plogs`, `container-cleanup`, `container-reset`

Home Manager merges attribute sets; identical keys in two imported modules cause a **merge conflict** error. This MUST be fixed before importing `containers.nix`.

**Fix**: Remove all duplicate aliases from `containers-podman.nix` lines 128–145 (keep only the dev-distro aliases `dev-ubuntu`, `dev-fedora`, `dev-arch` which are unique to that module).

#### Impermanence

- System level: [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix:126) — `environment.persistence."/persist/system".directories` needs `/var/lib/containers`
- User level: [`impermanence.nix`](../../home/dan/features/linux/impermanence.nix) — `home.persistence."/persist".directories` needs `.local/share/containers`

### Risk Assessment

| Category | Risk | Mitigation |
|----------|------|------------|
| Alias merge conflict | HM build failure | Fix duplication before import — Phase 2 |
| Missing system Podman | Rootless Podman broken - no subuid/subgid, no cgroup delegation | Enable `virtualisation.podman.enable` — Phase 3 |
| Impermanence data loss | Container images/volumes wiped on reboot | Persist directories — Phase 4 |
| Boot/Network | None — no bootloader, firewall, or SSH changes | N/A |

## Phase 0: Validation Strategy

### Validation Commands

| Command | Purpose |
|---------|---------|
| `nix flake check` | Evaluate all configs + run all checks |
| `nix flake check --no-build` | Eval-only — assertions fire, no VM tests |
| `nixos-rebuild build --flake .#thiniel` | Build thiniel closure |
| `nixos-rebuild test --flake .#thiniel` | Apply to running system without boot entry |
| `nixos-rebuild switch --flake .#thiniel` | Full apply |

### Rollback Path

- `nixos-rebuild switch --rollback` reverts to previous generation
- All changes are in version control; `git revert` provides file-level rollback
- No dangerous changes (boot/network/auth/filesystem) in this plan

### Affected Hosts

Only `thiniel` (x86_64-linux)

---

## Phase 1: Node.js — Import fnm.nix

The fnm module is complete and already tested. This phase is a single-import change.

### Step 1.1 — RED: Assertion that fnm package exists in thiniel HM config

- **File**: `tests/assertions/thiniel-invariants.nix`
- **Change**: Add assertion that `home-manager.users.dan.home.packages` contains a package with pname matching `fnm`
- **Verify**: `nix flake check --no-build` → FAIL (fnm not yet imported)

### Step 1.2 — GREEN: Import fnm.nix in thiniel profile

- **File**: `home/dan/thiniel.nix`
- **Change**: Add `./features/development/fnm.nix` to imports list (after existing development imports)
- **Verify**: `nix flake check` → PASS

---

## Phase 2: Fix Alias Duplication Bug

This phase must complete before Phase 3 (which imports `containers.nix`).

### Step 2.1 — RED: Unit test that containers-podman.nix has no fish aliases matching containers-common.nix

- **File**: `tests/unit/hm-dev-modules-test.nix`
- **Change**: Add test verifying that `containers-podman.nix` does NOT define fish aliases `docker`, `docker-compose`, `prun`, `pexec`, `plogs`, `container-cleanup`, `container-reset`
- **Note**: This test cannot use simple `import` for `containers-podman.nix` because it uses `config.home.homeDirectory`. Evaluate the module in a minimal HM eval context, OR test the presence/absence of the known-duplicate alias keys by importing and checking `programs.fish.shellAliases` attribute names. If direct import is infeasible, use a `builtins.readFile` + `hasInfix` check on the raw file to verify the aliases were removed.
- **Verify**: `nix flake check` → FAIL (duplicates still present)

### Step 2.2 — GREEN: Remove duplicate aliases from containers-podman.nix

- **File**: `home/dan/features/development/containers-podman.nix`
- **Change**: Remove lines 128–145 (`programs.fish.shellAliases` block). Keep only:
  - `dev-ubuntu`, `dev-fedora`, `dev-arch` aliases → move them to `programs.fish.shellAliases` in the same file (these are unique)
  - `interactiveShellInit` (podman completion) — keep as-is
  - `functions` (dev-enter, dev-create) — keep as-is
- **Verify**: `nix flake check` → PASS

---

## Phase 3: System-Level Podman Configuration

### Step 3.1 — RED: Assertion that Podman is enabled on thiniel

- **File**: `tests/assertions/thiniel-services-invariants.nix`
- **Change**: Add assertion `config.virtualisation.podman.enable == true`
- **Verify**: `nix flake check --no-build` → FAIL

### Step 3.2 — GREEN: Enable Podman in thiniel host config

- **File**: `hosts/thiniel/default.nix`
- **Change**: Add `virtualisation.podman` block:
  ```nix
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;  # HM aliases handle docker → podman mapping
    defaultNetwork.settings.dns_enabled = true;
  };
  ```
- **Verify**: `nix flake check` → PASS

### Step 3.3 — RED: Assertion that user dan is in podman group

- **File**: `tests/assertions/thiniel-invariants.nix`
- **Change**: Add assertion that `builtins.elem "podman" config.users.users.dan.extraGroups`
- **Note**: NixOS `virtualisation.podman.enable` does NOT auto-add users to the `podman` group. The `podman` group is only needed for `dockerSocket.enable` (API socket access). For standard rootless Podman, group membership is optional. Evaluate whether `dockerSocket.enable` is needed — if not, skip this step.
- **Decision**: Skip this step unless `virtualisation.podman.dockerSocket.enable = true` is set. Rootless Podman works without group membership via user-level socket at `/run/user/1000/podman/podman.sock`.

---

## Phase 4: Impermanence — Persist Container Data

### Step 4.1 — RED: Assertion that /var/lib/containers is persisted (system level)

- **File**: `tests/assertions/thiniel-impermanence-invariants.nix`
- **Change**: Add assertion using existing `hasDir` helper: `hasDir "/var/lib/containers"`
- **Verify**: `nix flake check --no-build` → FAIL

### Step 4.2 — GREEN: Add /var/lib/containers to system persistence

- **File**: `hosts/thiniel/default.nix`
- **Change**: Add `"/var/lib/containers"` to `environment.persistence."/persist/system".directories` list
- **Verify**: `nix flake check` → PASS

### Step 4.3 — RED: Assertion that ~/.local/share/containers is persisted (HM level)

- **File**: `tests/assertions/thiniel-impermanence-invariants.nix`
- **Change**: Add assertion using existing `hmHasDir` helper: `hmHasDir ".local/share/containers"`
- **Verify**: `nix flake check --no-build` → FAIL

### Step 4.4 — GREEN: Add .local/share/containers to HM persistence

- **File**: `home/dan/features/linux/impermanence.nix`
- **Change**: Add `".local/share/containers"` to `home.persistence."/persist".directories` list
- **Verify**: `nix flake check` → PASS

---

## Phase 5: Import Container Modules in thiniel Profile

### Step 5.1 — RED: Assertion that Podman package exists in thiniel HM config

- **File**: `tests/assertions/thiniel-invariants.nix`
- **Change**: Add assertion that `home-manager.users.dan.home.packages` contains a package with pname `podman`
- **Verify**: `nix flake check --no-build` → FAIL

### Step 5.2 — GREEN: Import containers.nix in thiniel profile

- **File**: `home/dan/thiniel.nix`
- **Change**: Add `./features/development/containers.nix` to imports list
- **Verify**: `nix flake check` → PASS

---

## Phase 6: Full Build and Apply

### Step 6.1 — Build validation

- **Command**: `nixos-rebuild build --flake .#thiniel`
- **Purpose**: Full closure build without applying

### Step 6.2 — Test application

- **Command**: `sudo nixos-rebuild test --flake .#thiniel`
- **Purpose**: Apply without creating boot entry; verify services start

### Step 6.3 — Smoke test (manual)

- Verify `fnm --version` works in fish shell
- Verify `fnm install 22` installs Node.js
- Verify `podman run --rm hello-world` succeeds
- Verify `podman info` shows rootless mode, overlay storage driver

### Step 6.4 — Switch

- **Command**: `sudo nixos-rebuild switch --flake .#thiniel`
- **Purpose**: Create boot entry and apply permanently

---

## Current Status

- [ ] Phase 0: Validation strategy defined
- [ ] Phase 1: Node.js — Import fnm.nix
  - [ ] Step 1.1: RED — fnm assertion
  - [ ] Step 1.2: GREEN — Import fnm.nix
- [ ] Phase 2: Fix alias duplication bug
  - [ ] Step 2.1: RED — Alias duplication test
  - [ ] Step 2.2: GREEN — Remove duplicate aliases
- [ ] Phase 3: System-level Podman
  - [ ] Step 3.1: RED — Podman enable assertion
  - [ ] Step 3.2: GREEN — Enable Podman
- [ ] Phase 4: Impermanence persistence
  - [ ] Step 4.1: RED — System persistence assertion
  - [ ] Step 4.2: GREEN — Persist /var/lib/containers
  - [ ] Step 4.3: RED — HM persistence assertion
  - [ ] Step 4.4: GREEN — Persist ~/.local/share/containers
- [ ] Phase 5: Import container modules
  - [ ] Step 5.1: RED — Podman HM package assertion
  - [ ] Step 5.2: GREEN — Import containers.nix
- [ ] Phase 6: Build and apply
  - [ ] Step 6.1: Build validation
  - [ ] Step 6.2: Test application
  - [ ] Step 6.3: Smoke test
  - [ ] Step 6.4: Switch

## Files Modified (Summary)

| File | Phase | Change |
|------|-------|--------|
| `tests/assertions/thiniel-invariants.nix` | 1, 5 | Add fnm + podman package assertions |
| `home/dan/thiniel.nix` | 1, 5 | Import `fnm.nix`, `containers.nix` |
| `tests/unit/hm-dev-modules-test.nix` | 2 | Add alias duplication test |
| `home/dan/features/development/containers-podman.nix` | 2 | Remove duplicate aliases |
| `tests/assertions/thiniel-services-invariants.nix` | 3 | Add Podman enable assertion |
| `hosts/thiniel/default.nix` | 3, 4 | Enable Podman + persist /var/lib/containers |
| `tests/assertions/thiniel-impermanence-invariants.nix` | 4 | Add persistence assertions |
| `home/dan/features/linux/impermanence.nix` | 4 | Persist ~/.local/share/containers |
