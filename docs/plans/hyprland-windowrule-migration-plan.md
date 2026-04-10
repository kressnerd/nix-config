# Hyprland windowrulev2 → windowrule Migration Plan

**Status**: READY FOR IMPLEMENTATION

## Goal

Replace the deprecated `windowrulev2` key in [`hyprland.nix`](../../home/dan/features/linux/hyprland.nix:91) with the new `windowrule` list-of-attrsets syntax required by Hyprland ≥ 0.53. Eliminate 8 startup deprecation warnings on thiniel.

## Context

- Hyprland 0.53 (Dec 2025) removed `windowrulev2`; nixpkgs-unstable ships 0.54.3
- Home Manager's `toHyprconf` serializer converts list-of-attrsets into named `windowrule { ... }` blocks — exactly the syntax Hyprland 0.53+ expects
- Only [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix) is affected (lines 91–100)
- No other deprecated syntax in `hypridle.nix`, `hyprlock.nix`, or `thiniel.nix`

## Acceptance Criteria

1. `windowrulev2` key absent from `hyprSettings`
2. `windowrule` key present in `hyprSettings` with exactly 8 entries
3. Each entry is an attrset (not a string) — verified by checking `name` attribute presence
4. `nix flake check` passes on both `x86_64-linux` and `aarch64-darwin`
5. No Hyprland startup warnings about `windowrulev2` on thiniel

## Technical Analysis

### Current (deprecated)

```nix
# home/dan/features/linux/hyprland.nix lines 91–100
windowrulev2 = [
  "float, class:^(dialog)$"
  "float, title:^(Open File)(.*)$"
  # ... 6 more string entries
];
```

Home Manager serializes this as `windowrulev2 = <value>` in the Hyprland config, which Hyprland 0.53+ rejects.

### Target (new syntax)

```nix
windowrule = [
  { name = "float-dialog";      float = true; "match:class" = "^(dialog)$"; }
  { name = "float-open-file";   float = true; "match:title" = "^(Open File)(.*)$"; }
  { name = "float-select-file"; float = true; "match:title" = "^(Select a File)(.*)$"; }
  { name = "float-wallpaper";   float = true; "match:title" = "^(Choose wallpaper)(.*)$"; }
  { name = "float-open-folder"; float = true; "match:title" = "^(Open Folder)(.*)$"; }
  { name = "float-save-as";     float = true; "match:title" = "^(Save As)(.*)$"; }
  { name = "pin-pip";           pin  = true;  "match:title" = "^(Picture-in-Picture)$"; }
  { name = "idleinhibit-full";  idleinhibit = "fullscreen"; "match:class" = ".*"; }
];
```

Home Manager's `toHyprconf` serializes each attrset as a named `windowrule { ... }` block — exactly what Hyprland 0.53+ expects.

### Test infrastructure

[`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix) already imports `hyprland.nix` and evaluates `hyprSettings` (line 37). Tests for `bind`, `workspace`, `monitor` counts exist. No test covers `windowrulev2` or `windowrule`.

## Implementation Phases

### Phase 0: Validation Strategy

- **Syntax validation**: `nix flake check`
- **Build validation**: `nix flake check` (runs `checks.x86_64-linux.*` unit tests)
- **Apply validation**: `darwin-rebuild build --flake .#J6G6Y9JK7L` (local macOS build); `nixos-rebuild build --flake .#thiniel` on thiniel
- **Rollback path**: Revert the two changed files (git checkout). No bootloader/network/filesystem risk.

### Phase 1 — Red: Add failing tests

**File**: [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix)

Add two tests after [`testHyprlandBindeCount`](../../tests/unit/hm-linux-modules-test.nix:70) (line 73):

```nix
testHyprlandNoWindowrulev2 = {
  expr = hyprSettings ? windowrulev2;
  expected = false;
};

testHyprlandWindowruleCount = {
  expr = builtins.length hyprSettings.windowrule;
  expected = 8;
};
```

**Verify**: `nix flake check` → FAIL (currently `windowrulev2` exists and `windowrule` is absent).

### Phase 2 — Green: Replace windowrulev2 with windowrule

**File**: [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix)

Replace lines 91–100 (`windowrulev2 = [ ... ];`) with:

```nix
windowrule = [
  { name = "float-dialog";      float = true; "match:class" = "^(dialog)$"; }
  { name = "float-open-file";   float = true; "match:title" = "^(Open File)(.*)$"; }
  { name = "float-select-file"; float = true; "match:title" = "^(Select a File)(.*)$"; }
  { name = "float-wallpaper";   float = true; "match:title" = "^(Choose wallpaper)(.*)$"; }
  { name = "float-open-folder"; float = true; "match:title" = "^(Open Folder)(.*)$"; }
  { name = "float-save-as";     float = true; "match:title" = "^(Save As)(.*)$"; }
  { name = "pin-pip";           pin  = true;  "match:title" = "^(Picture-in-Picture)$"; }
  { name = "idleinhibit-full";  idleinhibit = "fullscreen"; "match:class" = ".*"; }
];
```

**Verify**: `nix flake check` → PASS.

### Phase 3 — Quality & Format

- Run `nix fmt` on both changed files
- Run `statix check` and `deadnix` on both changed files
- Commit: `fix(hyprland): migrate windowrulev2 to windowrule block syntax`

## Files Changed

| File | Action |
|------|--------|
| [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix) | Replace `windowrulev2` with `windowrule` (lines 91–100) |
| [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix) | Add 2 tests after line 73 |

## Current Status

- [x] Phase 1 — Red: Add failing tests
- [x] Phase 2 — Green: Replace windowrulev2 with windowrule
- [x] Phase 3 — Quality & Format
