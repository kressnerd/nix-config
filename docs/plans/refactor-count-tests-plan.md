# Refactor Count-Based Tests to Existence Checks

## Status: APPROVED — ready for implementation

## Business Context

17 count-based test assertions across 4 files use `builtins.length` to check collection sizes. These are fragile: adding a new entry (package, keybinding, directory) requires manually updating a hardcoded count. The refactoring replaces count checks with `builtins.elem`, `builtins.any`, or `builtins.hasAttr` checks for specific named entries.

**Scope**: Pure refactoring — only test files are modified, no production code changes.

## Acceptance Criteria

- All 17 `builtins.length` assertions are removed
- Replacement existence checks cover previously uncovered entries (identified per file below)
- `nix flake check` passes after each file is modified
- No production `.nix` files are touched

## Validation Strategy

| Step | Command | Purpose |
|------|---------|---------|
| After each file | `nix flake check` | Full eval + check suite |
| Final | `nix flake check` | Confirm no regressions |

**Rollback**: `git checkout -- tests/` reverts all changes.

No dangerous changes (boot, network, filesystem, auth, secrets) — test-only refactoring.

## Implementation Phases

### Phase 1: `tests/unit/helpers-test.nix` — 5 count tests

**DELETE** all 5 length checks (lines 119–142). **ADD** `builtins.elem` checks for entries not already covered by existing spot-checks:

| Deleted Test | Already Covered | New `builtins.elem` Checks to Add |
|---|---|---|
| `testCommonLength` (line 119) | `ublock-origin`, `keepassxc-browser`, `consent-o-matic` — all 3 covered | None |
| `testDevLength` (line 124) | `refined-github` | `octotree`, `wappalyzer` |
| `testPrivacyLength` (line 129) | `privacy-badger`, `noscript` | `decentraleyes`, `clearurls`, `temporary-containers` |
| `testProductivityLength` (line 134) | `tridactyl` | `tree-style-tab`, `languagetool`, `single-file` |
| `testConvenienceLength` (line 139) | `sponsorblock`, `old-reddit-redirect` | `return-youtube-dislikes`, `youtube-shorts-block`, `reddit-enhancement-suite` |

**Net change**: −5 count tests, +13 existence tests.

**Verify**: `nix flake check`

### Phase 2: `tests/unit/hm-cli-modules-test.nix` — 2 count tests

#### 2a: `testFishAliasCount` (line 72) — DELETE

Existing individual alias tests cover: `ll`, `lt`, `gs`, `ssh`, `..` (5 of 13).

**ADD** `builtins.hasAttr` checks for the 8 uncovered aliases:

- `la`, `l`, `g`, `v`, `vi`, `icat`, `...`, `....`

#### 2b: `testVimPluginCount` (line 218) — REPLACE

Replace `builtins.length ... == 1` with a `builtins.any` check for the Catppuccin plugin:

```nix
testVimHasCatppuccinPlugin = {
  expr = builtins.any (p: lib.strings.hasInfix "catppuccin" (p.pname or p.name or ""))
    vimModule.programs.vim.plugins;
  expected = true;
};
```

**Net change**: −2 count tests, +9 existence tests.

**Verify**: `nix flake check`

### Phase 3: `tests/unit/hm-linux-modules-test.nix` — 9 count tests

#### 3a: Hyprland section (inside `hyprlandTests` conditional block)

| Test | Action | Replacement |
|---|---|---|
| `testHyprlandMonitorCount` (line 61) | REPLACE | Two `builtins.any` checks: one for entry containing `eDP-1`, one for catch-all entry starting with `,` |
| `testHyprlandBindCount` (line 66) | DELETE | Add 3 representative `builtins.any` checks: workspace bind (`1, workspace, 1`), volume bind (`XF86AudioRaiseVolume`), screenshot bind (`Print`) |
| `testHyprlandBindeCount` (line 71) | REPLACE | Two `builtins.any` checks: one for volume `binde` entry (`XF86AudioRaiseVolume`), one for brightness `binde` entry (`XF86MonBrightnessUp`) |
| `testHyprlandWindowruleCount` (line 81) | DELETE | Add 2 representative `builtins.any` checks for key window rules (e.g., float rule, opacity rule) |

#### 3b: Hypridle section

| Test | Action | Replacement |
|---|---|---|
| `testHypridleListenerCount` (line 203) | REPLACE | Two `builtins.any` checks: one for listener with `on-timeout` containing `hyprlock`, one for listener with `on-timeout` containing `systemctl suspend` |

#### 3c: Impermanence section

| Test | Action | Replacement |
|---|---|---|
| `testImpermanenceDirCount` (line 353) | DELETE | Add `builtins.elem` checks for the 6 uncovered directories: `.config/netcup-scp`, `.local/share/netcup-scp`, `.local/share/containers`, `.config/Signal`, `.config/Threema`, `Videos` |
| `testImpermanenceFileCount` (line 365) | DELETE | None — fully redundant with `testImpermanenceHasBashHistory` |

#### 3d: Gnome-keyring and Fonts sections

| Test | Action | Replacement |
|---|---|---|
| `testGnomeKeyringComponentCount` (line 382) | DELETE | None — fully redundant with `testGnomeKeyringComponents` list equality check |
| `testFontsPackageCount` (line 404) | DELETE | None — fully redundant with `testFontsHasFontAwesome` + `testFontsHasSymbolsOnly` |

**Net change**: −9 count tests, +15 existence tests.

**Verify**: `nix flake check`

### Phase 4: `tests/assertions/thiniel-rice-invariants.nix` — 1 count assertion

**REPLACE** the monitor count assertion (line 48) with two existence assertions:

```nix
{
  assertion =
    builtins.any (m: builtins.match "eDP-1.*" m != null)
      config.home-manager.users.dan.wayland.windowManager.hyprland.settings.monitor;
  message = "thiniel: Hyprland monitor rules must include an eDP-1 entry";
}
{
  assertion =
    builtins.any (m: builtins.match ",.*" m != null)
      config.home-manager.users.dan.wayland.windowManager.hyprland.settings.monitor;
  message = "thiniel: Hyprland monitor rules must include a catch-all entry";
}
```

**Net change**: −1 count assertion, +2 existence assertions.

**Verify**: `nix flake check`

## Summary

| Metric | Value |
|--------|-------|
| Files modified | 4 |
| Count tests removed | 17 |
| Existence tests added | ~39 |
| Production files changed | 0 |

## Completion Log

_To be updated during implementation._
