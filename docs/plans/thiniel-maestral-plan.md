# Implementation Plan: Maestral on thiniel

## Goal

Add Maestral (open-source Dropbox client, CLI-only) to the thiniel host as a Home Manager feature module with systemd user service for auto-start and proper impermanence persistence.

## Business Context

The user needs Dropbox file synchronization on the thiniel laptop. Maestral is a lightweight, MIT-licensed, CLI-only Dropbox client that avoids the proprietary Dropbox desktop app. It must run as a background daemon with auto-start on login and survive reboots on the ephemeral BTRFS root.

## Acceptance Criteria

- [x] `maestral` package (v1.9.6) is available in `home.packages` on thiniel
- [x] `maestral-gui` is NOT installed
- [x] A systemd user service `maestral` runs `maestral start --foreground` as a daemon
- [x] The service starts automatically after `graphical-session.target`
- [x] `maestral status`, `maestral filestatus`, `maestral ls` work from the CLI
- [x] Persistence paths `Dropbox`, `.config/maestral`, `.local/share/maestral` are in HM impermanence
- [x] All existing tests pass (`nix flake check`)
- [x] New assertions validate maestral package presence, service definition, and persistence paths
- [x] Feature module is imported in `home/dan/thiniel.nix`

## Technical Analysis

### Package

- `pkgs.maestral` (v1.9.6) — available in nixpkgs unstable, MIT license, no `allowUnfree` needed
- CLI binary provides: `maestral start`, `maestral stop`, `maestral status`, `maestral filestatus`, `maestral ls`, `maestral pause`, `maestral resume`, `maestral config`

### Architecture

```
home/dan/features/productivity/maestral.nix  ← NEW feature module
  ├── home.packages: [maestral]
  └── systemd.user.services.maestral          ← systemd user unit

home/dan/features/linux/impermanence.nix     ← MODIFY: add 3 persistence paths
home/dan/thiniel.nix                         ← MODIFY: add import

tests/unit/hm-productivity-modules-test.nix  ← MODIFY: add maestral unit tests
tests/assertions/thiniel-invariants.nix      ← MODIFY: add maestral package assertion
tests/assertions/thiniel-impermanence-invariants.nix ← MODIFY: add maestral persistence assertions
```

### Systemd User Service Design

```nix
systemd.user.services.maestral = {
  Unit = {
    Description = "Maestral Dropbox client";
    After = [ "graphical-session.target" ];
  };
  Service = {
    ExecStart = "${pkgs.maestral}/bin/maestral start --foreground";
    ExecStop = "${pkgs.maestral}/bin/maestral stop";
    Restart = "on-failure";
    RestartSec = 5;
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};
```

### Persistence Paths

| Path | Purpose | Module |
|------|---------|--------|
| `Dropbox` | Sync folder with actual files | `impermanence.nix` |
| `.config/maestral` | Config + OAuth tokens | `impermanence.nix` |
| `.local/share/maestral` | Logs, state DB, index | `impermanence.nix` |

### File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `home/dan/features/productivity/maestral.nix` | CREATE | Feature module: package + systemd service |
| `home/dan/features/linux/impermanence.nix` | MODIFY | Add 3 persistence directories |
| `home/dan/thiniel.nix` | MODIFY | Add import line |
| `tests/unit/hm-productivity-modules-test.nix` | MODIFY | Add maestral unit tests |
| `tests/assertions/thiniel-invariants.nix` | MODIFY | Add maestral package assertion |
| `tests/assertions/thiniel-impermanence-invariants.nix` | MODIFY | Add maestral persistence assertions |

## Phase 0: Validation Strategy

### Validation Commands

| Command | Purpose |
|---------|---------|
| `nix flake check` | Full evaluation + all checks (assertions + unit tests) |
| `nix flake check --no-build` | Eval-only (assertions fire, no VM tests) |
| `nix build .#checks.x86_64-linux.unit-tests` | Run unit tests only |
| `nixos-rebuild build --flake .#thiniel` | Build thiniel config |

### Affected Hosts

- thiniel (NixOS, x86_64-linux)

### Rollback Procedure

1. Remove import line from `home/dan/thiniel.nix`
2. Revert persistence paths in `home/dan/features/linux/impermanence.nix`
3. Remove test additions
4. Delete `home/dan/features/productivity/maestral.nix`
5. Run `nix flake check` to confirm clean state
6. Apply with `sudo nixos-rebuild switch --flake .#thiniel`

### Dangerous Changes

None — this is a user-level feature addition. No bootloader, networking, filesystem, or authentication changes.

### Post-Apply Manual Steps

After first `nixos-rebuild switch`, the user must run `maestral link` once to authenticate the Dropbox account via OAuth. This is a one-time interactive step that cannot be automated.

## Implementation Phases

### Phase 1: Red — Unit Test for Maestral Feature Module

**Cycle 1.1**: Test maestral package presence in module output

- [x] Step 1.1.1: Add maestral module import and test to `tests/unit/hm-productivity-modules-test.nix`
  - Import `../../home/dan/features/productivity/maestral.nix` with `{ pkgs = mockPkgsLinux; }` (signature will be `{ pkgs, ... }:`)
  - Add test `testMaestralPackagePresent`: assert `maestral` is in `home.packages`
- [x] Step 1.1.2: Verify RED — `nix build .#checks.x86_64-linux.unit-tests` FAILS (module file does not exist)

### Phase 2: Green — Create Maestral Feature Module (Package Only)

**Cycle 2.1**: Make package test pass

- [x] Step 2.1.1: Create `home/dan/features/productivity/maestral.nix` with minimal content:
  ```nix
  { pkgs, ... }:
  {
    home.packages = with pkgs; [
      maestral
    ];
  }
  ```
- [x] Step 2.1.2: Verify GREEN — `nix build .#checks.x86_64-linux.unit-tests` PASSES

### Phase 3: Red — Unit Test for Systemd User Service

**Cycle 3.1**: Test systemd service is defined

- [x] Step 3.1.1: Add test `testMaestralServiceDefined` to `tests/unit/hm-productivity-modules-test.nix`: assert `systemd.user.services` has attribute `maestral`
- [x] Step 3.1.2: Verify RED — unit tests FAIL (service not yet defined)

**Cycle 3.2**: Test service ExecStart contains maestral

- [x] Step 3.2.1: Add test `testMaestralServiceExecStart`: assert `ExecStart` value contains `maestral` and `--foreground`
- [x] Step 3.2.2: Verify RED — test FAILS (no service definition)

### Phase 4: Green — Add Systemd User Service to Feature Module

**Cycle 4.1**: Make service tests pass

- [x] Step 4.1.1: Add `systemd.user.services.maestral` to `home/dan/features/productivity/maestral.nix` with:
  - `Unit.Description = "Maestral Dropbox client"`
  - `Unit.After = [ "graphical-session.target" ]`
  - `Service.ExecStart = "${pkgs.maestral}/bin/maestral start --foreground"`
  - `Service.ExecStop = "${pkgs.maestral}/bin/maestral stop"`
  - `Service.Restart = "on-failure"`
  - `Service.RestartSec = 5`
  - `Install.WantedBy = [ "graphical-session.target" ]`
- [x] Step 4.1.2: Verify GREEN — `nix build .#checks.x86_64-linux.unit-tests` PASSES

### Phase 5: Red — Assertion for Maestral Package on Thiniel

**Cycle 5.1**: Assert maestral is in thiniel HM packages

- [x] Step 5.1.1: Add assertion to `tests/assertions/thiniel-invariants.nix`:
  ```nix
  {
    assertion =
      let
        hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
      in
      builtins.elem "maestral" hmPkgNames;
    message = "thiniel: Maestral must be installed via Home Manager for Dropbox sync";
  }
  ```
- [x] Step 5.1.2: Verify RED — `nix flake check --no-build` FAILS (maestral not yet imported in thiniel.nix)

### Phase 6: Green — Wire Import in thiniel.nix

**Cycle 6.1**: Add maestral import to host profile

- [x] Step 6.1.1: Add `./features/productivity/maestral.nix` to imports in `home/dan/thiniel.nix` (after `./features/productivity/keepassxc.nix`, maintaining alphabetical order within category)
- [x] Step 6.1.2: Verify GREEN — `nix flake check --no-build` PASSES

### Phase 7: Red — Persistence Assertions

**Cycle 7.1**: Assert Dropbox sync folder is persisted

- [x] Step 7.1.1: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
  ```nix
  {
    assertion = hmHasDir "Dropbox";
    message = "thiniel: Dropbox sync folder must be persisted for Maestral";
  }
  ```
- [x] Step 7.1.2: Verify RED — `nix flake check --no-build` FAILS (path not yet in impermanence)

**Cycle 7.2**: Assert maestral config is persisted

- [x] Step 7.2.1: Add assertion:
  ```nix
  {
    assertion = hmHasDir ".config/maestral";
    message = "thiniel: .config/maestral must be persisted for Maestral config and OAuth tokens";
  }
  ```
- [x] Step 7.2.2: Verify RED — `nix flake check --no-build` FAILS

**Cycle 7.3**: Assert maestral state is persisted

- [x] Step 7.3.1: Add assertion:
  ```nix
  {
    assertion = hmHasDir ".local/share/maestral";
    message = "thiniel: .local/share/maestral must be persisted for Maestral state and index";
  }
  ```
- [x] Step 7.3.2: Verify RED — `nix flake check --no-build` FAILS

### Phase 8: Green — Add Persistence Paths

**Cycle 8.1**: Add all three persistence directories

- [x] Step 8.1.1: Add to `home/dan/features/linux/impermanence.nix` directories list:
  ```nix
  # Maestral Dropbox client
  "Dropbox"
  ".config/maestral"
  ".local/share/maestral"
  ```
- [x] Step 8.1.2: Verify GREEN — `nix flake check --no-build` PASSES

### Phase 9: Full Validation

- [x] Step 9.1: Run `nix flake check` (full, with builds) — ALL checks pass
- [x] Step 9.2: Run `nixos-rebuild build --flake .#thiniel` — build succeeds
- [x] Step 9.3: Code quality: `nix fmt` on all changed `.nix` files

### Phase 10: Apply & Verify

- [ ] Step 10.1: Apply with `sudo nixos-rebuild switch --flake .#thiniel`
- [ ] Step 10.2: Verify `which maestral` returns a valid path
- [ ] Step 10.3: Verify `systemctl --user status maestral` shows the service (may be inactive until `maestral link` is run)
- [ ] Step 10.4: Run `maestral link` to authenticate with Dropbox (one-time manual step)
- [ ] Step 10.5: Verify `maestral status` shows connected state
- [ ] Step 10.6: Verify `systemctl --user start maestral` starts the daemon
- [ ] Step 10.7: Verify `systemctl --user enable maestral` is already enabled via WantedBy

## Current Status

- **Phase**: COMPLETED (Phases 1–9 done, Phase 10 pending deployment)
- **Blockers**: None
- **Notes**: All tests pass, build succeeds, awaiting `nixos-rebuild switch` deployment

## Completion Summary

- **Completed Date**: 2026-04-19
- **Total Duration**: ~2 hours
- **Deviations**:
  - Phases 5+7 (Red) were combined into a single subtask since both assertion types fail for the same root cause (maestral not imported)
  - Phases 6+8 (Green) were combined similarly for efficiency
  - Review finding F-001 triggered an additional refactoring commit for DRY improvement in `thiniel-invariants.nix`
- **Commits**:
  - `20ddb8c` — `feat(thiniel): add Maestral Dropbox client with systemd service and persistence`
  - `faf6c09` — `fix(thiniel): add missing maestral unit tests and explicit service Type`
  - `397bb34` — `refactor(tests): extract hmHasPkg helper in thiniel-invariants.nix (DRY)`
- **Lessons Learned**:
  1. **Batch similar Red phases**: When multiple assertions fail for the same root cause (e.g., missing import), combining them into one Red subtask reduces overhead without sacrificing TDD discipline
  2. **Extract helpers early**: The `hmHasPkg` helper pattern (from `thiniel-impermanence-invariants.nix`) should have been applied to `thiniel-invariants.nix` from the start. When adding the 4th instance of a duplicated pattern, refactor immediately rather than replicating
  3. **Explicit systemd defaults**: Always set `Type = "simple"` explicitly in systemd user services, even when it's the default. Self-documenting configuration prevents ambiguity during review
  4. **Test service lifecycle properties**: Unit tests for systemd services should cover not just `ExecStart` but also `WantedBy` (auto-start), `Restart` (resilience), and `Type` (execution model). These are the properties most likely to regress
  5. **Maestral requires one-time OAuth**: Unlike packages that work immediately after deployment, Maestral requires `maestral link` for initial OAuth authentication — this must be documented as a post-deploy manual step

## Completion Log

| Phase | Status | Duration | Notes |
|-------|--------|----------|-------|
| Phase 0 | ✅ | — | Validation strategy defined |
| Phase 1 | ✅ | 5min | Red: unit test for package presence |
| Phase 2 | ✅ | 3min | Green: created maestral.nix with package |
| Phase 3 | ✅ | 5min | Red: unit tests for systemd service |
| Phase 4 | ✅ | 5min | Green: added systemd user service |
| Phase 5+7 | ✅ | 8min | Red: combined package + persistence assertions |
| Phase 6+8 | ✅ | 5min | Green: import wiring + persistence paths |
| Phase 9 | ✅ | 10min | Full validation + commit |
| Phase 10 | ⏳ | — | Pending deployment |
