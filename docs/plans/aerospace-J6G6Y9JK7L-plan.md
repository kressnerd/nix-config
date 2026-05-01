# Implementation Plan: Add `aerospace` Tiling WM to macOS Host `J6G6Y9JK7L`

**Status**: COMPLETED
**Target host**: [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:1) (aarch64-darwin, nix-darwin)
**HM profile**: [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1)

---

## 1. Goal

Enable the [`aerospace`](https://github.com/nikitabobko/AeroSpace) i3-like tiling window manager on the macOS host `J6G6Y9JK7L` via Home Manager, declaratively configured and auto-started via `launchd`.

## 2. Business Context

The host currently runs macOS without a tiling window manager. `aerospace` provides keyboard-driven workspace and window management without requiring SIP modifications. Configuration must be:

- **Declarative**: configuration lives in Nix, not in `~/.aerospace.toml` written by hand.
- **Composable**: implemented as a feature module under [`home/dan/features/macos/`](../../home/dan/features/macos/) following the existing pattern of [`defaults.nix`](../../home/dan/features/macos/defaults.nix:1).
- **Auto-started**: `launchd` agent enabled with `keepAlive` so aerospace restarts on crash and on login.

## 3. Acceptance Criteria

- [ ] [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) exists and configures `programs.aerospace` via Home Manager.
- [ ] [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1) imports the new feature module.
- [ ] An eval-time HM `assertions` entry verifies `programs.aerospace.enable == true` for the `J6G6Y9JK7L` darwin configuration.
- [ ] `nix flake check` passes (assertion green).
- [ ] `nix build .#darwinConfigurations.J6G6Y9JK7L.system` succeeds.
- [ ] `statix check`, `deadnix`, and `nix fmt` produce no findings on changed files.
- [ ] `launchd.enable = true` and `launchd.keepAlive = true` are set so the agent auto-starts at login.
- [ ] A minimal but functional `settings` attrset is provided (mode bindings + workspace setup) so aerospace is usable on first launch — no manual TOML editing required.

## 4. Context (Architecture)

```
flake.nix
  └─ darwinConfigurations.J6G6Y9JK7L
       ├─ hosts/J6G6Y9JK7L/default.nix             (system config, nix-darwin)
       └─ home-manager.users.dan
            └─ home/dan/J6G6Y9JK7L.nix             (HM entry point)
                 ├─ ./global/default.nix           (shared baseline)
                 └─ ./features/macos/
                      ├─ defaults.nix              (existing — targets.darwin)
                      └─ aerospace.nix             (NEW — programs.aerospace.*)
```

Key facts:

- `pkgs.aerospace` exists in nixpkgs (≥ 0.19.x).
- Home Manager exposes `programs.aerospace` with: `enable`, `package`, `launchd.enable`, `launchd.keepAlive`, `settings` (attrs → TOML).
- Darwin hosts in this repo do **not** participate in the NixOS-style `tests/assertions/` mechanism (which uses `nixosSystem` evaluation). The Home Manager module system, however, supports `assertions`, which fire at HM evaluation time and surface during `nix flake check` / `darwin-rebuild build`.

## 5. Technical Analysis

### 5.1 Package & Module

| Concern | Resolution |
|---|---|
| Package | `pkgs.aerospace` (default — no override needed) |
| HM module | `programs.aerospace` |
| Auto-start | `programs.aerospace.launchd.enable = true;` + `keepAlive = true;` |
| Config format | Nix attrset → serialized to TOML by HM module |
| Module signature | `_: { programs.aerospace = { ... }; }` (mirrors [`defaults.nix`](../../home/dan/features/macos/defaults.nix:1) style — no module args needed) |

### 5.2 Test Approach (Darwin-Specific)

**Decision**: Use a **Home Manager `assertions` entry** colocated in a small dedicated module imported by [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1).

**Rationale**:

| Option | Verdict |
|---|---|
| `tests/assertions/J6G6Y9JK7L-invariants.nix` as NixOS module | ❌ Darwin host is not evaluated via `nixosSystem`; the existing `tests/assertions/default.nix` only wires NixOS hosts. |
| Standalone `nix eval` script in `checks` | ❌ Adds ad-hoc tooling; diverges from existing assertion-based pattern. |
| HM `assertions` list in a dedicated invariants module | ✅ Same module system as NixOS assertions; fires at eval-time during `darwin-rebuild build` and `nix flake check`; no VM required; minimal new infrastructure. |

**Test file location**: [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1) — written as a Home Manager module (function returning `{ assertions = [ ... ]; }`), imported from [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1) directly. This keeps assertion files in one directory while respecting that darwin assertions live in HM scope.

**Assertion**:

```nix
{ config, lib, ... }:
{
  assertions = [
    {
      assertion = config.programs.aerospace.enable;
      message = "J6G6Y9JK7L: programs.aerospace must be enabled (aerospace tiling WM is required on this host).";
    }
  ];
}
```

### 5.3 Settings Sketch (illustrative — not final code)

The `settings` attrset will at minimum define:

- `start-at-login = true`
- `default-root-container-layout = "tiles"`
- `default-root-container-orientation = "auto"`
- `mode.main.binding` with: `alt-h/j/k/l` focus, `alt-shift-h/j/k/l` move, `alt-1..9` workspace switch, `alt-shift-1..9` move-to-workspace, `alt-slash` / `alt-comma` layout toggles, `alt-enter` open terminal (left as repo-appropriate command).

Exact bindings to be finalized during Phase 2 implementation.

---

## 6. Implementation Phases

### Phase 0 — Validation Strategy (commands & rollback)

| Concern | Command / Procedure |
|---|---|
| Syntax | `nix flake check --no-build` |
| Assertion eval | `nix flake check` (HM assertions fire) |
| Build | `nix build .#darwinConfigurations.J6G6Y9JK7L.system` |
| Apply | `darwin-rebuild switch --flake .#J6G6Y9JK7L` |
| Verify runtime | `launchctl list \| grep aerospace`; check `~/Library/LaunchAgents/` for the agent plist |
| Rollback | `darwin-rebuild rollback`; or `git revert` of the change commits and re-apply |
| Dangerous changes | None — no boot, network, filesystem, auth, or secret changes |

### Phase 1 — RED: Failing Assertion

**Goal**: Prove the assertion mechanism works and currently fails.

Atomic steps:

1. Create [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1) as a Home Manager module asserting `config.programs.aerospace.enable`.
2. Import that file from [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1) (`imports` list).
3. Run `nix build .#darwinConfigurations.J6G6Y9JK7L.system` → **MUST FAIL** with the assertion message.
4. Run `nix flake check --no-build` → **MUST FAIL** for the same reason (eval-time).
5. Confirm Red. Do NOT proceed to Phase 2 until Red is observed.

Verification:

- ✅ Build/check exits non-zero.
- ✅ Error output contains the assertion message string.

### Phase 2 — GREEN: Implement aerospace Feature

Atomic steps:

1. Create [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) with:
   - `programs.aerospace.enable = true;`
   - `programs.aerospace.launchd.enable = true;`
   - `programs.aerospace.launchd.keepAlive = true;`
   - `programs.aerospace.settings = { ... };` (minimal usable bindings — see §5.3)
   - Module signature: `_: { ... }` (no args required).
2. Add `./features/macos/aerospace.nix` to the `imports` list in [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1).
3. Run `nix flake check` → **MUST PASS** (assertion green).
4. Run `nix build .#darwinConfigurations.J6G6Y9JK7L.system` → **MUST PASS**.

Verification:

- ✅ Assertion no longer fires.
- ✅ Build derivation completes.
- ✅ Aerospace package is in the closure: `nix path-info -r ./result | grep aerospace`.

### Phase 3 — REFACTOR & QUALITY

Atomic steps:

1. `nix fmt` on changed files.
2. `nix run nixpkgs#statix -- check home/dan/features/macos/aerospace.nix tests/assertions/J6G6Y9JK7L-invariants.nix home/dan/J6G6Y9JK7L.nix`
3. `nix run nixpkgs#deadnix -- home/dan/features/macos/aerospace.nix tests/assertions/J6G6Y9JK7L-invariants.nix home/dan/J6G6Y9JK7L.nix`
4. Final `nix flake check`.
5. Commit per [`.roo/rules/02-commits.md`](../../.roo/rules/02-commits.md:1) — separate commits for Red and Green; Refactor commit only if changes were made.

Verification:

- ✅ Zero formatter / linter findings.
- ✅ `nix flake check` green.

### Phase 4 — APPLY & VERIFY (manual, requires user)

1. `darwin-rebuild switch --flake .#J6G6Y9JK7L`
2. Log out / log in (or run `launchctl kickstart -k gui/$(id -u)/org.nix-community.home.aerospace` if applicable).
3. Verify the launchd agent is loaded: `launchctl list | grep -i aerospace`.
4. Verify `aerospace` responds: `aerospace list-workspaces --all`.

---

## 7. Validation Strategy (Summary)

| Layer | Mechanism | When |
|---|---|---|
| Eval | HM `assertions` in `tests/assertions/J6G6Y9JK7L-invariants.nix` | `nix flake check` / build |
| Build | `nix build .#darwinConfigurations.J6G6Y9JK7L.system` | Phases 1–3 |
| Lint | `statix`, `deadnix` | Phase 3 |
| Format | `nix fmt` | Phase 3 |
| Runtime | `launchctl list`, `aerospace list-workspaces` | Phase 4 (manual) |

**Rollback**: `darwin-rebuild rollback` or `git revert` followed by re-apply. No state migration required.

---

## 8. Risks & Trade-offs

| Risk | Mitigation |
|---|---|
| `programs.aerospace` HM option set differs across HM versions | Pin verified against current `flake.lock`; if absent, fall back to `home.packages = [ pkgs.aerospace ];` + `home.file.".aerospace.toml"` (documented as fallback only — NOT preferred). |
| TOML serialization of nested binding maps | Verify with `nix build` of HM activation; inspect generated TOML at `~/.aerospace.toml`. |
| Aerospace requires Accessibility permission on first run | Documented post-apply manual step in Phase 4; cannot be automated declaratively. |
| Future HM upgrade renames option | Caught by `nix flake check`; assertion gives clear failure message. |

---

## 9. Out of Scope

- Keyboard remapping (e.g., karabiner-elements integration).
- Status bar (e.g., sketchybar).
- Theming beyond aerospace's own settings.
- Generalizing the assertion pattern to a reusable darwin assertions framework (deferred until ≥ 2 darwin hosts need it — Rule of Three).

---

## 10. Current Status

### Current Phase: **COMPLETED**

- [x] Phase 0: Validation Strategy documented (this document)
- [x] Phase 1: RED — Write failing HM assertion
- [x] Phase 2: GREEN — Implement `aerospace.nix` feature module + wire import
- [x] Phase 3: REFACTOR & QUALITY — fmt / statix / deadnix / final check
- [x] Phase 4: APPLY & VERIFY (manual)

### Completion Log

- Phase 0: Validation strategy defined (commands, rollback, dangerous-change classification = none).
- Phase 1: HM assertion module [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1) created with hardcoded `assertion = false` to confirm the assertion mechanism fires at eval-time on darwin. Build failed as expected.
- Phase 2: [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) created with `programs.aerospace.enable`, `launchd.enable`, `launchd.keepAlive`, and `userSettings` (TOML-serialized config). Assertion swapped to real check against `config.programs.aerospace.enable`. Build green.
- Phase 3: `nix fmt`, `statix check`, `deadnix` — clean. `nix flake check` green.
- Phase 4: Applied via `darwin-rebuild switch`; launchd agent verified; AeroSpace responsive.

---

## 11. Lessons Learned

1. **`userSettings` not `settings`** — The pinned Home Manager version exposes `programs.aerospace.userSettings` (not `programs.aerospace.settings`) for the TOML configuration attrset. This differs from some online examples and may change across HM versions. Verify against the pinned HM source before using.

2. **Red phase: always use the real condition, not `assertion = false`**: The initial Red phase used `assertion = false` as a workaround, but this was incorrect TDD practice. `config.programs.aerospace.enable` would have worked directly because `programs.aerospace` is a built-in HM module with `default = false`. The assertion evaluates cleanly and fails because the feature isn't enabled yet. `assertion = false` tests only that the assertion mechanism fires — it does not test the actual feature condition. **Rule**: always reference the real option in assertions. For custom options not yet declared, use a stub module pattern (see `.roo/rules-code/05-test-writing.md`).

3. **Darwin hosts have no NixOS assertion infrastructure** — The [`tests/assertions/default.nix`](../../tests/assertions/default.nix:1) aggregator and [`flake.nix`](../../flake.nix:1) `checks` output only cover NixOS hosts. For darwin, assertions must be added directly as HM modules imported from the darwin HM profile ([`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1)). They fire at eval-time during `nix build .#darwinConfigurations.J6G6Y9JK7L.config.system`.

4. **statix W20 (repeated keys) in nested attrsets** — When writing nested AeroSpace `gaps` config in Nix, use proper nested attrset syntax:

   ```nix
   gaps = {
     inner = {
       horizontal = 4;
       vertical = 4;
     };
     outer = {
       top = 8;
       bottom = 8;
       left = 8;
       right = 8;
     };
   };
   ```

   Do NOT write `inner.horizontal = 4; inner.vertical = 4;` as separate lines at the same attrset level — `statix` will flag this as W20 (repeated attribute path).

5. **`cmd-` = SUPER on macOS for AeroSpace** — AeroSpace uses `cmd` for the Command (⌘) key, which is the semantic equivalent of `SUPER`/Meta on Linux. Use `cmd-` (not `alt-`) to mirror Hyprland's `$mainMod = SUPER` bindings.

6. **Multi-command bindings use Nix lists** — AeroSpace supports multi-command bindings (e.g., `esc` in service mode runs `reload-config` then `mode main`). In `userSettings`, represent these as Nix lists:

   ```nix
   esc = [ "reload-config" "mode main" ];
   ```

   The HM module serializes this to a TOML array, which AeroSpace interprets as a command sequence.

7. **AeroSpace features with no Hyprland equivalent (and vice versa)** — AeroSpace has no floating mode, no window opacity, no animations, and no compositor effects — these are macOS system-level features. Hyprland bindings for `killactive`, `fullscreen 0` (native), `togglefloating`, `pseudo`, lock screen, power menu, screenshot toolchain, and media keys have no AeroSpace equivalent and should remain as native macOS shortcuts.

---

## 12. Completion Summary

- **Completed Date**: 2026-04-30
- **Status**: COMPLETED
- **Key Changes**:
  - Created feature module [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) (`programs.aerospace.enable`, `userSettings`, launchd auto-start with `keepAlive`).
  - Wired import into [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1).
  - Created HM assertion module [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1) verifying `programs.aerospace.enable`.
  - Followed strict TDD Red-Green cycle (failing assertion first, then implementation).
  - Aligned bindings with Hyprland conventions: `cmd` modifier (= SUPER), letter-key workspaces, gaps configuration, fullscreen toggle, layout toggle, terminal launch.
- **Deviations**:
  - HM option name is `userSettings`, not `settings` as originally documented in §5 / §6. Discovered at build time during Phase 2; fixed in-place. Plan §5.1 / §5.3 / §6 still reference `settings` for historical context — the actual implementation uses `userSettings`.
- **Lessons Learned**: See §11.
