# Implementation Plan: Add LibreOffice to Thiniel

## Status: COMPLETED

## Goal

Add LibreOffice as a productivity application on the thiniel host, following established patterns for Home Manager feature modules, impermanence persistence, and assertion-based testing.

## Business Context

Thiniel is a Linux desktop workstation (ThinkPad X270, Hyprland/Wayland). LibreOffice provides office document editing (`.odt`, `.docx`, `.ods`, `.xlsx`, etc.). No office suite is currently configured in the repository.

## Acceptance Criteria

- [x] LibreOffice is installed via `home.packages` in a dedicated feature module
- [x] `.config/libreoffice` is persisted across reboots via impermanence
- [x] `thiniel.nix` imports the new feature module
- [x] Assertion test: LibreOffice package present in thiniel HM packages (eval-time)
- [x] Assertion test: `.config/libreoffice` in HM persistence directories (eval-time)
- [x] `nix flake check` passes

## Technical Analysis

### Existing Patterns

| Concern | Pattern Source | Convention |
|---------|--------------|------------|
| Simple app module | [`sweethome3d.nix`](../../home/dan/features/productivity/sweethome3d.nix) | `{ pkgs, ... }: { home.packages = [ ... ]; }` |
| Impermanence paths | [`impermanence.nix`](../../home/dan/features/linux/impermanence.nix:1) | `_: { home.persistence."/persist".directories = [ ... ]; }` with inline comment |
| Package assertions | [`thiniel-desktop-invariants.nix`](../../tests/assertions/thiniel-desktop-invariants.nix:84) | `builtins.any (p: (p.pname or p.name or "") == "<name>") config.home-manager.users.dan.home.packages` |
| Persistence assertions | [`thiniel-impermanence-invariants.nix`](../../tests/assertions/thiniel-impermanence-invariants.nix:17) | `hmHasDir` helper checks `home.persistence."/persist".directories` |
| Import wiring | [`thiniel.nix`](../../home/dan/thiniel.nix:31) | Alphabetical within `features/productivity/` section |

### Files to Modify

| File | Action | Purpose |
|------|--------|---------|
| `home/dan/features/productivity/libreoffice.nix` | **Create** | Feature module with `home.packages = [ pkgs.libreoffice ]` |
| `home/dan/features/linux/impermanence.nix` | **Modify** | Add `.config/libreoffice` to persisted directories |
| `home/dan/thiniel.nix` | **Modify** | Add import of `./features/productivity/libreoffice.nix` |
| `tests/assertions/thiniel-desktop-invariants.nix` | **Modify** | Add LibreOffice package presence assertion |
| `tests/assertions/thiniel-impermanence-invariants.nix` | **Modify** | Add `.config/libreoffice` persistence assertion |

### Risk Assessment

| Category | Risk | Mitigation |
|----------|------|------------|
| Build | Low — adding a package, no system-level changes | `nix flake check` validates |
| Data | None — no existing LibreOffice data to preserve | Fresh install |
| Rollback | Trivial — revert the 3 file changes | `git revert` |

## Phase 0: Validation Strategy

### Validation Commands

- **Syntax validation**: `nix flake check --no-build` (eval-time assertions fire)
- **Full build validation**: `nix flake check` (all checks including VM tests)
- **Host build**: `nixos-rebuild build --flake .#thiniel` (optional, confirms full config builds)

### Rollback Path

Revert the commit. No system-level services, no bootloader, no networking changes — rollback is a simple `git revert`.

### Dangerous Changes

None. This change adds a user-level package and a persistence path. No boot, network, filesystem, authentication, or secrets changes.

## Implementation Phases

### Phase 1: LibreOffice Package — Red-Green-Refactor

#### Cycle 1.1: Red — LibreOffice package assertion

1. Add assertion to [`tests/assertions/thiniel-desktop-invariants.nix`](../../tests/assertions/thiniel-desktop-invariants.nix) — assert `libreoffice` is in thiniel HM packages
2. Run `nix flake check --no-build` → **FAIL** (LibreOffice not yet installed)

#### Cycle 1.2: Green — Create LibreOffice feature module

1. Create `home/dan/features/productivity/libreoffice.nix` following [`sweethome3d.nix`](../../home/dan/features/productivity/sweethome3d.nix) pattern:
   ```
   { pkgs, ... }:
   {
     home.packages = with pkgs; [
       libreoffice
     ];
   }
   ```
2. Add import `./features/productivity/libreoffice.nix` to [`home/dan/thiniel.nix`](../../home/dan/thiniel.nix:31) — insert alphabetically after `keepassxc.nix`
3. Run `nix flake check --no-build` → **PASS**

### Phase 2: Impermanence — Red-Green-Refactor

#### Cycle 2.1: Red — Impermanence assertion

1. Add assertion to [`tests/assertions/thiniel-impermanence-invariants.nix`](../../tests/assertions/thiniel-impermanence-invariants.nix) — assert `hmHasDir ".config/libreoffice"` is true
2. Run `nix flake check --no-build` → **FAIL** (path not yet persisted)

#### Cycle 2.2: Green — Add persistence path

1. Add `".config/libreoffice"` to [`home/dan/features/linux/impermanence.nix`](../../home/dan/features/linux/impermanence.nix:3) directories list, with a `# LibreOffice user config` comment
2. Run `nix flake check --no-build` → **PASS**

### Phase 3: Final Validation

1. Run `nix flake check` (full validation including all checks)
2. Run `nix fmt` on all changed files
3. Run `statix check` and `deadnix` on all changed files
4. Commit with message: `feat(thiniel): add LibreOffice productivity suite`

## Current Status

Plan created — awaiting approval.

## Completion Log

### Completion Summary

- **Completed Date**: 2026-04-23
- **Commits**: `77c4312` (initial), fix commit (wrapped package fix)
- **Deviations**:
  - Created separate `thiniel-libreoffice-invariants.nix` instead of adding assertions to existing files
  - Initial implementation used `pkgs.libreoffice.unwrapped` due to assertion limitations; fixed in follow-up commit to use `pkgs.libreoffice` with `lib.hasPrefix` pattern for wrapped package name matching
- **Lessons Learned**: LibreOffice's nixpkgs wrapper derivation lacks `pname` — assertions matching wrapped packages should use `lib.hasPrefix` instead of exact `pname` match
