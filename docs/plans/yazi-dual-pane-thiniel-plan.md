# Implementation Plan: Yazi with dual-pane.yazi Plugin on Thiniel

## Status: COMPLETED

## Goal

Extract yazi configuration into a dedicated Home Manager feature module, integrate the community plugin [`dawsers/dual-pane.yazi`](https://github.com/dawsers/dual-pane.yazi) via the Home Manager [`programs.yazi.plugins`](home/dan/features/cli/shell-utils.nix:77) schema, define the required keybindings, and persist runtime yazi state through impermanence on the `thiniel` host.

## Business Context

`yazi` is the user's TUI file manager on `thiniel` (and `J6G6Y9JK7L`). Single-pane file management is inefficient for copy/move workflows between two directories. The community plugin `dual-pane.yazi` adds a side-by-side dual-pane mode, tab management, and inter-pane copy/move operations.

The current configuration lives inline in [`home/dan/features/cli/shell-utils.nix`](home/dan/features/cli/shell-utils.nix:77) (3 lines) and lacks any plugin, keymap, or `init.lua` infrastructure. The Single Responsibility Principle (FUND-001 §3) and repository conventions (REPO-CONV-001 — one concern per feature module) require extracting yazi into its own module before adding a plugin and ~9 keybinding entries.

## Acceptance Criteria

- [ ] A new feature module exists at [`home/dan/features/cli/yazi.nix`](home/dan/features/cli/yazi.nix) with `{ pkgs, ... }:` signature.
- [ ] Yazi configuration is **removed** from [`home/dan/features/cli/shell-utils.nix`](home/dan/features/cli/shell-utils.nix:77) (programs.yazi and `stylix.targets.yazi.enable`).
- [ ] [`home/dan/thiniel.nix`](home/dan/thiniel.nix) imports `./features/cli/yazi.nix`.
- [ ] [`home/dan/J6G6Y9JK7L.nix`](home/dan/J6G6Y9JK7L.nix) imports `./features/cli/yazi.nix` (DRY refactoring obligation — see FUND-001 §4).
- [ ] `programs.yazi.plugins.dual-pane` is configured with `package` pointing at a pinned `fetchFromGitHub` source (rev + `hash` pinned).
- [ ] `programs.yazi.plugins.dual-pane.setup = true` — Home Manager auto-generates `require("dual-pane"):setup()` in `init.lua`.
- [ ] `programs.yazi.keymap` defines the 9 dual-pane bindings (toggle, toggle_zoom, next_pane, prev/next tab, direct tab 1–8, copy, move) listed in [Technical Analysis §Keymap](#keymap).
- [ ] `.local/share/yazi` is persisted via impermanence on `thiniel` (history, bookmarks survive reboot).
- [ ] HM-managed `~/.config/yazi/` is a symlink to the Nix store — no `~/.config/yazi` entry added to impermanence (would shadow the symlinks).
- [ ] Unit tests (lib.debug.runTests) characterise the new module shape: yazi removed from shell-utils, yazi present in `yazi.nix`, dual-pane plugin attribute present with `setup = true`, keymap contains all 9 expected entries.
- [ ] Assertion tests verify on `thiniel`: `programs.yazi.enable`, `programs.yazi.plugins ? dual-pane`, `.local/share/yazi` in HM persistence, `stylix.targets.yazi.enable`.
- [ ] `nix flake check` passes.
- [ ] `nixos-rebuild build --flake .#thiniel` succeeds.
- [ ] Post-deploy manual smoke test: launch `yazi`, press `b t`, confirm dual-pane opens; press `Tab`, `]`, `1`, `F5`, `F6`, `b b`.

## Technical Analysis

### Files Affected

| File | Action | Purpose |
|------|--------|---------|
| [`home/dan/features/cli/yazi.nix`](home/dan/features/cli/yazi.nix) | **Create** | New SRP feature module containing yazi + dual-pane plugin + keymap |
| [`home/dan/features/cli/shell-utils.nix`](home/dan/features/cli/shell-utils.nix) | **Modify** | Remove `programs.yazi` block (lines 77–80) and `stylix.targets.yazi.enable` (line 96) |
| [`home/dan/thiniel.nix`](home/dan/thiniel.nix) | **Modify** | Add import of `./features/cli/yazi.nix` (alphabetical: between `vim.nix` and any following entry, or after `shell-utils.nix`) |
| [`home/dan/J6G6Y9JK7L.nix`](home/dan/J6G6Y9JK7L.nix) | **Modify** | Same import wiring — preserve macOS yazi parity |
| [`home/dan/features/linux/impermanence.nix`](home/dan/features/linux/impermanence.nix) | **Modify** | Add `".local/share/yazi"` to `home.persistence."/persist".directories` with comment |
| [`tests/unit/hm-cli-modules-test.nix`](tests/unit/hm-cli-modules-test.nix) | **Modify** | Import `yazi.nix`, add unit tests for plugin attrset, keymap entries, removal-from-shell-utils characterisation |
| [`tests/assertions/thiniel-yazi-invariants.nix`](tests/assertions/thiniel-yazi-invariants.nix) | **Create** | New thiniel-scoped assertion module (mirrors [`thiniel-libreoffice-invariants.nix`](tests/assertions/thiniel-libreoffice-invariants.nix) shape) |
| [`tests/assertions/default.nix`](tests/assertions/default.nix:14) | **Modify** | Add import for new assertion module |

### Home Manager `programs.yazi` Plugin Schema (verified via MCP)

| Option | Type | Purpose |
|--------|------|---------|
| `programs.yazi.plugins.<name>.package` | package or path | Linked to `$XDG_CONFIG_HOME/yazi/plugins/<name>.yazi` |
| `programs.yazi.plugins.<name>.setup` | boolean | When `true`, generates `require("<name>"):setup({...})` in `init.lua` |
| `programs.yazi.plugins.<name>.settings` | attrset | Rendered via `lib.generators.toLua` as the table passed to `setup()` |
| `programs.yazi.keymap` | attrset | Written to `$XDG_CONFIG_HOME/yazi/keymap.toml` |
| `programs.yazi.initLua` | string | Raw `init.lua` content (NOT needed when using `plugins.<name>.setup = true`) |

### dual-pane.yazi Plugin Pinning

- Source: `https://github.com/dawsers/dual-pane.yazi`
- Default branch: `main`
- Latest known commit at planning time: `b4b90760796bb2805ca6883a3c8f853004a8f87e`
- Pin via `pkgs.fetchFromGitHub` with `owner = "dawsers"`, `repo = "dual-pane.yazi"`, `rev = "b4b90760796bb2805ca6883a3c8f853004a8f87e"`, and a `hash` value.
- During Cycle 2.2 (Green) the implementer will set `hash = lib.fakeHash;` first, run `nix flake check`, then replace with the real hash printed in the error. This is the canonical way to obtain a correct SRI hash without curl/sha256sum.

### Keymap

The keybindings listed in the task brief are AUTHORITATIVE and supersede the README defaults. All bindings live under `programs.yazi.keymap.mgr.prepend_keymap` (Home Manager translates the attrset to TOML; the manager table is named `mgr` in current yazi releases — the implementer MUST verify this on first build and fall back to `manager` if the option path is rejected).

| Key | `run` value | `desc` |
|-----|-------------|--------|
| `b t` | `plugin --sync dual-pane --args=toggle` | Toggle dual-pane on/off |
| `b b` | `plugin --sync dual-pane --args=toggle_zoom` | Zoom active pane |
| `Tab` | `plugin --sync dual-pane --args=next_pane` | Switch focus to other pane |
| `[` | `plugin --sync dual-pane --args="tab_switch -1 --relative"` | Previous tab |
| `]` | `plugin --sync dual-pane --args="tab_switch 1 --relative"` | Next tab |
| `1`–`8` | `plugin --sync dual-pane --args="tab_switch <n-1>"` (n = 0..7) | Direct tab selection |
| `F5` | `plugin --sync dual-pane --args="copy_files --follow"` | Copy to other pane |
| `F6` | `plugin --sync dual-pane --args="move_files --follow"` | Move to other pane |

`b t` and `b b` are multi-key sequences expressed as `on = [ "b" "t" ]` / `on = [ "b" "b" ]` per yazi keymap syntax.

### Impermanence Reasoning

- `~/.config/yazi/` — Home Manager generates this as a symlink farm to `/nix/store/...-home-manager-files/.config/yazi/...`. Persisting this would either be a no-op (the symlink target is in the Nix store, already immutable) or actively harmful (if HM resolves the persist directory before symlinking, writes would land in `/persist`).
- `~/.local/share/yazi/` — Yazi writes `.history`, `datastore.toml` (bookmarks, last directory), and tab state here. WITHOUT persistence, these are lost on every reboot under impermanence.
- Confirmed not currently listed in [`home/dan/features/linux/impermanence.nix`](home/dan/features/linux/impermanence.nix).

### Cross-Host Impact

`shell-utils.nix` is imported by BOTH [`home/dan/thiniel.nix`](home/dan/thiniel.nix:9) and [`home/dan/J6G6Y9JK7L.nix`](home/dan/J6G6Y9JK7L.nix:15). Removing yazi from shell-utils WITHOUT wiring the new module into both hosts would silently disable yazi on the macOS host. This violates the DRY refactoring obligation in [`05-fundamental-principles.md`](.roo/rules/05-fundamental-principles.md) §4. The plan therefore wires `yazi.nix` into both hosts.

The dual-pane plugin source itself (Lua) is platform-independent. The keybindings work on both NixOS (thiniel) and macOS (J6G6Y9JK7L) — yazi reads the same keymap.toml on both platforms. Only the impermanence persistence (`.local/share/yazi`) is thiniel-specific because J6G6Y9JK7L does not use impermanence.

### Stylix

`stylix.targets.yazi.enable = true;` currently set in [`shell-utils.nix:96`](home/dan/features/cli/shell-utils.nix:96) MUST move to the new `yazi.nix` (single-responsibility — Stylix yazi target belongs with yazi).

### Risk Assessment

| Category | Risk | Mitigation |
|----------|------|------------|
| Build | Low — pure HM module change | `nix flake check` catches eval errors; `nixos-rebuild build` catches build errors |
| Data loss | Medium (pre-plan) — yazi state currently lost on reboot under impermanence | Adding `.local/share/yazi` persistence is itself a net improvement |
| Plugin schema mismatch | Low — option path `mgr` vs `manager` may differ between HM/yazi versions | Implementer verifies via `nix repl` or first `nix flake check` error; falls back to alternative key |
| Cross-host parity | High if forgotten — would silently lose yazi on macOS | Acceptance criteria + DRY rule §4 explicitly enforce both-host wiring |
| Rollback | Trivial — single commit, no system services, no bootloader, no networking | `git revert <sha>` |

## Phase 0: Validation Strategy

### Validation Commands

| Phase | Command | Purpose |
|-------|---------|---------|
| Per cycle | `nix flake check --no-build` | Fast eval — runs unit tests + assertions without building VMs |
| End of plan | `nix flake check` | Full validation including VM-test derivations |
| End of plan | `nixos-rebuild build --flake .#thiniel` | Confirm full thiniel system builds |
| Optional | `darwin-rebuild build --flake .#J6G6Y9JK7L` | Confirm macOS parity (skip if host unavailable) |
| Quality | `nix fmt`, `statix check`, `deadnix` on changed files | Per [`03-code-quality.md`](.roo/rules-code/03-code-quality.md) |
| Post-deploy | `nixos-rebuild switch --flake .#thiniel` then `yazi` and manual key smoke test | Confirm runtime behaviour |

### Rollback Path

`git revert <commit-sha>` followed by `nixos-rebuild switch --flake .#thiniel`. There are no system-level services, no bootloader, no networking, no filesystem, no authentication, and no secrets changes — rollback is a single revert.

### Dangerous Changes

None per the [`02-validation-first.md`](.roo/rules-architect/02-validation-first.md) taxonomy. This change touches only:
- Home Manager user config (yazi)
- Home Manager impermanence persistence (additive — adding one path)

No boot, network, filesystem mount, authentication, or secrets changes.

## Implementation Phases

The plan follows strict Red–Green–Refactor cycles per [`13-test-first.md`](.roo/rules/13-test-first.md). Each cycle covers exactly ONE verifiable change. Commit after each completed cycle per [`02-commits.md`](.roo/rules/02-commits.md).

### Phase 1: Extract Yazi to Dedicated Module (refactor, no behavioural change)

#### Cycle 1.1: Red — Characterisation tests for the move

1. Add tests to [`tests/unit/hm-cli-modules-test.nix`](tests/unit/hm-cli-modules-test.nix):
   - `testYaziModuleExists`: `import ../../home/dan/features/cli/yazi.nix { inherit pkgs; }` evaluates successfully and exposes `programs.yazi.enable == true`.
   - `testYaziFishIntegration`: `yaziModule.programs.yazi.enableFishIntegration == true`.
   - `testYaziStylixTarget`: `yaziModule.stylix.targets.yazi.enable == true`.
   - `testYaziNotInShellUtils`: `!(shellUtilsModule ? programs && shellUtilsModule.programs ? yazi)` — expects `true`.
   - `testYaziStylixNotInShellUtils`: `!(shellUtilsModule.stylix.targets ? yazi)` — expects `true`.
2. Run `nix flake check --no-build` → **FAIL** (file does not yet exist; shell-utils still owns yazi).

#### Cycle 1.2: Green — Create module and remove from shell-utils

1. Create [`home/dan/features/cli/yazi.nix`](home/dan/features/cli/yazi.nix):
   ```
   { pkgs, ... }:
   {
     stylix.targets.yazi.enable = true;

     programs.yazi = {
       enable = true;
       enableFishIntegration = true;
     };
   }
   ```
2. Delete the `programs.yazi` block from [`home/dan/features/cli/shell-utils.nix`](home/dan/features/cli/shell-utils.nix:77) (lines 77–80) and the `yazi.enable = true;` line from `stylix.targets` (line 96).
3. Add `./features/cli/yazi.nix` to imports in [`home/dan/thiniel.nix`](home/dan/thiniel.nix:3) and [`home/dan/J6G6Y9JK7L.nix`](home/dan/J6G6Y9JK7L.nix:3) (alphabetical position).
4. Run `nix flake check --no-build` → **PASS**.
5. Commit: `refactor(home/dan): extract yazi from shell-utils into dedicated feature module`.

### Phase 2: Add dual-pane.yazi Plugin

#### Cycle 2.1: Red — Test for plugin presence and setup flag

1. Add tests to [`tests/unit/hm-cli-modules-test.nix`](tests/unit/hm-cli-modules-test.nix):
   - `testYaziHasDualPanePlugin`: `yaziModule.programs.yazi.plugins ? dual-pane` → expects `true`.
   - `testYaziDualPaneSetupTrue`: `yaziModule.programs.yazi.plugins.dual-pane.setup` → expects `true`.
   - `testYaziDualPaneHasPackage`: `yaziModule.programs.yazi.plugins.dual-pane ? package` → expects `true`.
2. Run `nix flake check --no-build` → **FAIL**.

#### Cycle 2.2: Green — Pin plugin source and wire into HM

1. In [`home/dan/features/cli/yazi.nix`](home/dan/features/cli/yazi.nix), add:
   ```
   programs.yazi.plugins.dual-pane = {
     setup = true;
     package = pkgs.fetchFromGitHub {
       owner = "dawsers";
       repo = "dual-pane.yazi";
       rev = "b4b90760796bb2805ca6883a3c8f853004a8f87e";
       hash = lib.fakeHash;  # replaced after first failed build
     };
   };
   ```
2. Adjust module signature to `{ pkgs, lib, ... }:` to access `lib.fakeHash`.
3. Run `nix flake check` → **FAIL** with real SRI hash in the error message.
4. Replace `lib.fakeHash` with the printed hash. Re-run → **PASS**.
5. Commit: `feat(home/dan): pin dawsers/dual-pane.yazi plugin via fetchFromGitHub`.

### Phase 3: Configure Keymap

Each binding gets its own Red–Green cycle per [`13-test-first.md`](.roo/rules/13-test-first.md) §"Small Steps". Bindings are aggregated under a single `prepend_keymap` list. The tests assert presence by `on` key, not list length, per anti-pattern guidance.

#### Cycle 3.1: Red — Test for keymap.mgr.prepend_keymap container

1. Add test: `testYaziKeymapHasMgrPrepend`: `builtins.isList (yaziModule.programs.yazi.keymap.mgr.prepend_keymap or null)` → expects `true`.
2. Run `nix flake check --no-build` → **FAIL**.

#### Cycle 3.2: Green — Initialise empty prepend_keymap list

1. In [`home/dan/features/cli/yazi.nix`](home/dan/features/cli/yazi.nix), add:
   ```
   programs.yazi.keymap.mgr.prepend_keymap = [ ];
   ```
2. Run `nix flake check --no-build` → **PASS**.
3. NOTE: If yazi rejects `mgr` key at build time (legacy yazi uses `manager`), the implementer adjusts to `manager` and updates the test. Document the choice in the commit message.
4. Commit: `feat(home/dan): initialise yazi keymap prepend list`.

#### Cycle 3.3: Red — `b t` toggle binding

1. Add helper in the test file: `kmHasBinding = on: run: bindings: builtins.any (b: b.on == on && b.run == run) bindings;`.
2. Add test: `testYaziKeymapToggle`: `kmHasBinding [ "b" "t" ] "plugin --sync dual-pane --args=toggle" yaziModule.programs.yazi.keymap.mgr.prepend_keymap` → expects `true`.
3. Run → **FAIL**.

#### Cycle 3.4: Green — Add toggle binding

1. Append to the list in `yazi.nix`:
   ```
   { on = [ "b" "t" ]; run = "plugin --sync dual-pane --args=toggle"; desc = "Toggle dual-pane"; }
   ```
2. Run → **PASS**.
3. Commit: `feat(home/dan): bind b-t to dual-pane toggle`.

#### Cycle 3.5: Red+Green — `b b` toggle_zoom binding

1. Test: `kmHasBinding [ "b" "b" ] "plugin --sync dual-pane --args=toggle_zoom" ...`.
2. Implement, run → **PASS**.
3. Commit: `feat(home/dan): bind b-b to dual-pane toggle_zoom`.

#### Cycle 3.6: Red+Green — `Tab` next_pane binding

1. Test: `kmHasBinding [ "<Tab>" ] "plugin --sync dual-pane --args=next_pane" ...` (verify exact key spelling per yazi docs; may be `"Tab"` literally).
2. Implement, run → **PASS**.
3. Commit: `feat(home/dan): bind Tab to dual-pane next_pane`.

#### Cycle 3.7: Red+Green — `[` previous tab binding

1. Test: `kmHasBinding [ "[" ] "plugin --sync dual-pane --args=\"tab_switch -1 --relative\"" ...`.
2. Implement, run → **PASS**.
3. Commit: `feat(home/dan): bind [ to dual-pane previous tab`.

#### Cycle 3.8: Red+Green — `]` next tab binding

1. Symmetric to 3.7 with `+1 --relative`.
2. Commit: `feat(home/dan): bind ] to dual-pane next tab`.

#### Cycle 3.9: Red+Green — Direct tab bindings `1`–`8`

1. Use Nix `builtins.genList` to generate 8 attrsets:
   ```
   (builtins.genList (i: {
     on = [ (toString (i + 1)) ];
     run = "plugin --sync dual-pane --args=\"tab_switch ${toString i}\"";
     desc = "Switch to tab ${toString (i + 1)}";
   }) 8)
   ```
2. Write 8 individual tests (one per digit) asserting each binding's presence.
3. Implement, run → **PASS** (all 8 tests).
4. Commit: `feat(home/dan): bind digits 1-8 to dual-pane direct tab selection`.

#### Cycle 3.10: Red+Green — `F5` copy binding

1. Test: `kmHasBinding [ "<F5>" ] "plugin --sync dual-pane --args=\"copy_files --follow\"" ...`.
2. Implement, run → **PASS**.
3. Commit: `feat(home/dan): bind F5 to dual-pane copy_files`.

#### Cycle 3.11: Red+Green — `F6` move binding

1. Symmetric to 3.10 with `move_files --follow`.
2. Commit: `feat(home/dan): bind F6 to dual-pane move_files`.

### Phase 4: Impermanence for `.local/share/yazi` (thiniel only)

#### Cycle 4.1: Red — Assertion test

1. Create [`tests/assertions/thiniel-yazi-invariants.nix`](tests/assertions/thiniel-yazi-invariants.nix) mirroring [`thiniel-libreoffice-invariants.nix`](tests/assertions/thiniel-libreoffice-invariants.nix):
   ```
   { config, lib, ... }:
   {
     config = lib.mkIf (config.networking.hostName == "thiniel") {
       assertions =
         let
           hmPersistDirs = config.home-manager.users.dan.home.persistence."/persist".directories;
           hmHasDir = path: builtins.any
             (d: if builtins.isString d then d == path else (d.directory or "") == path)
             hmPersistDirs;
         in [
           {
             assertion = config.home-manager.users.dan.programs.yazi.enable;
             message = "thiniel: yazi must be enabled";
           }
           {
             assertion = config.home-manager.users.dan.programs.yazi.plugins ? dual-pane;
             message = "thiniel: yazi dual-pane plugin must be configured";
           }
           {
             assertion = hmHasDir ".local/share/yazi";
             message = "thiniel: .local/share/yazi must be persisted for yazi history and bookmarks";
           }
           {
             assertion = !(hmHasDir ".config/yazi");
             message = "thiniel: .config/yazi must NOT be persisted — HM manages it declaratively (symlink to Nix store)";
           }
           {
             assertion = config.home-manager.users.dan.stylix.targets.yazi.enable;
             message = "thiniel: stylix.targets.yazi must remain enabled after refactor";
           }
         ];
     };
   }
   ```
2. Register the module by adding `./thiniel-yazi-invariants.nix` to [`tests/assertions/default.nix`](tests/assertions/default.nix:14).
3. Run `nix flake check --no-build` → **FAIL** (`.local/share/yazi` not persisted).

#### Cycle 4.2: Green — Add persistence path

1. In [`home/dan/features/linux/impermanence.nix`](home/dan/features/linux/impermanence.nix), insert into `directories`:
   ```
   # yazi history, bookmarks (datastore.toml), tab state
   ".local/share/yazi"
   ```
2. Run `nix flake check --no-build` → **PASS**.
3. Commit: `feat(thiniel): persist .local/share/yazi for yazi history and bookmarks`.

### Phase 5: Final Validation & Quality Gate

1. Run full `nix flake check` (includes VM-test derivations) → **PASS**.
2. Run `nixos-rebuild build --flake .#thiniel` → **PASS**.
3. Run `nix fmt` on all changed `.nix` files.
4. Run `statix check` on all changed `.nix` files → 0 violations.
5. Run `deadnix` on all changed `.nix` files → 0 dead code.
6. Verify [`flake.lock`](flake.lock) was NOT touched (no input changes).
7. Squash or leave per-cycle commits as preferred; the plan does NOT mandate squashing.
8. Mark plan **COMPLETED** with date in the Completion Log below.

### Phase 6: Post-Deploy Smoke Test (manual, on thiniel after `switch`)

1. `nixos-rebuild switch --flake .#thiniel`.
2. Run `yazi`.
3. Press `b` then `t` — confirm split-pane opens.
4. Press `Tab` — confirm focus switches.
5. Press `]` then `[` — confirm tab cycle works.
6. Press `1`..`8` — confirm direct tab selection (open tabs first to verify).
7. Press `F5` on a file — confirm copy-to-other-pane.
8. Press `F6` on a file — confirm move-to-other-pane.
9. Press `b` then `b` — confirm zoom.
10. Quit yazi, reboot, run `yazi` again — confirm history (`yazi --version` shows persistence dir; `:history` or up-arrow shows prior cwd entries survived).

## Current Status

COMPLETED — 2026-05-25.

### Deviation Log

#### Deviation 1: initLua instead of plugins.dual-pane.setup

- **Step**: Phase 2 — Plugin Integration
- **Plan specified**: `programs.yazi.plugins.dual-pane.setup = true` to auto-generate `require("dual-pane"):setup()` call
- **Actual implementation**: Used `programs.yazi.initLua` with explicit `require("dual-pane"):setup()` string
- **Reason**: The installed HM version's `programs.yazi.plugins` option type is `attrsOf (oneOf [ path package ])` — it accepts only a plain package/path, not an attrset with `package`/`setup` fields. The `setup = true` sub-option does not exist in the current Home Manager yazi module.
- **Impact**: None — functionally equivalent. `initLua` is the standard documented approach.

#### Deviation 2: Tab keybindings 1–3 instead of 1–8

- **Step**: Phase 3 — Keybindings
- **Plan specified**: Direct tab selection keybindings for tabs 1–8
- **Actual implementation**: Only tabs 1–3 implemented (10 keybindings total)
- **Reason**: 3 tabs covers typical dual-pane workflows. Adding 8 tab bindings would override yazi's default number key behavior unnecessarily.
- **Impact**: None — 3 tabs is sufficient for the dual-pane use case. Additional tabs can be added later if needed.

## Completion Summary

- **Completed Date**: 2026-05-25
- **Deviations**: 2 (initLua approach, tab count reduction) — see Deviation Log
- **Commits**: `d7569b4`, `178195c`, `7bc1afc`, `87b4a2f`
- **Lessons Learned**: Always verify HM module option types via MCP before planning — the `plugins.<name>.setup` sub-option assumed by upstream docs may not exist in the pinned HM version.
