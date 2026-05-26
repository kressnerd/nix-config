# Hyprland ↔ AeroSpace Keybinding Alignment — Implementation Plan

**Status**: DRAFT — Pending Approval
**Owner**: Architect → Orchestrator → Code
**Affected hosts**: `thiniel` (only host importing [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix:1))

---

## 1. Business Context

The user runs two tiling window managers across platforms:

- **AeroSpace** on macOS (host `J6G6Y9JK7L`)
- **Hyprland** on NixOS (host `thiniel`)

AeroSpace is the **source of truth** for keybindings. Every Hyprland binding that has an AeroSpace equivalent must use the same physical key combination, with the modifier mapping `AeroSpace Alt ↔ Hyprland SUPER` (already in place).

Five categories of Hyprland keybindings currently diverge from AeroSpace. This plan brings them into alignment without touching Hyprland-only bindings (kill, float, pseudo, true-fullscreen, lock, power-menu, screenshots, audio, brightness).

## 2. Acceptance Criteria

1. After applying, the following Hyprland keychords behave as described:
   - [`$mainMod, 1..0`](../../home/dan/features/linux/hyprland.nix:227) → switch to workspace 1..10
   - `$mainMod SHIFT, 1..0` → move active window to workspace 1..10
   - `$mainMod, Tab` → focus next monitor (wrap-around)
   - `$mainMod SHIFT, Tab` → focus previous monitor (wrap-around)
   - `$mainMod CTRL, l` → move current workspace to next monitor (wrap-around)
   - `$mainMod CTRL, h` → move current workspace to previous monitor (wrap-around)
   - `$mainMod, semicolon` → toggle layout split direction (replaces former `$mainMod, S`)
2. All former workspace bindings on the QWERTYUIOP row are **removed** (no dual binding remains).
3. The Hyprland-only bindings listed in §3.5 are **unchanged**.
4. `nix flake check` PASSES.
5. `nixos-rebuild build --flake .#thiniel` PASSES.
6. A new assertion file [`tests/assertions/thiniel-hyprland-keybindings-invariants.nix`](../../tests/assertions/thiniel-hyprland-keybindings-invariants.nix) exists and is wired into [`tests/assertions/default.nix`](../../tests/assertions/default.nix:1), covering both presence of new bindings and absence of removed ones.
7. The Hyprland↔AeroSpace key parity is documented inside the new assertion file as a comment header (single source of truth for the mapping).

## 3. Technical Analysis

### 3.1 File Under Modification

[`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix:1) — specifically the `wayland.windowManager.hyprland.settings.bind` list (lines 196–270) and the layout-toggle line at line 206.

### 3.2 Mapping Table — Source of Truth

| AeroSpace (macOS) | Hyprland (current) | Hyprland (target) | Dispatcher |
|---|---|---|---|
| `alt-1 .. alt-0` | `$mainMod, Q..P` | `$mainMod, 1..0` | `workspace, N` |
| `alt-shift-1 .. alt-shift-0` | `$mainMod SHIFT, Q..P` | `$mainMod SHIFT, 1..0` | `movetoworkspace, N` |
| `alt-tab` | — | `$mainMod, Tab` | `focusmonitor, e+1` |
| `alt-shift-tab` | — | `$mainMod SHIFT, Tab` | `focusmonitor, e-1` |
| `alt-ctrl-l` | — | `$mainMod CTRL, l` | `movecurrentworkspacetomonitor, e+1` |
| `alt-ctrl-h` | — | `$mainMod CTRL, h` | `movecurrentworkspacetomonitor, e-1` |
| `alt-semicolon` | `$mainMod, S` | `$mainMod, semicolon` | `layoutmsg, togglesplit` |
| `alt-shift-semicolon` (service mode) | — | _not bound_ | _intentionally skipped — no Hyprland equivalent_ |

Notes on Hyprland dispatchers:

- `focusmonitor, e+1` and `movecurrentworkspacetomonitor, e+1`: the `e` prefix forces explicit numeric‑relative interpretation and wraps around when reaching the edge — matches AeroSpace `--wrap-around next`.
- `layoutmsg, togglesplit` is the existing dwindle dispatcher already used at line 206; only the trigger key changes, dispatcher payload stays identical. AeroSpace's `layout tiles horizontal vertical` is a tri-state toggle; Hyprland's `togglesplit` is the closest semantic match under the `dwindle` layout (line 99).

### 3.3 Hyprland-Only Bindings — MUST NOT CHANGE

These have no AeroSpace counterpart and remain intact:

| Key | Action |
|---|---|
| `$mainMod, Return` | Launch kitty (already aligned) |
| `$mainMod, C` | killactive |
| `$mainMod, F` | fullscreen 1 (maximize, already aligned) |
| `$mainMod SHIFT, F` | fullscreen 0 (true fullscreen) |
| `$mainMod, V` | togglefloating |
| `$mainMod, G` | pseudo |
| `$mainMod, D` | exec fuzzel (launcher, already aligned) |
| `$mainMod SHIFT, V` | clipboard history |
| `$mainMod, h/j/k/l` | movefocus (already aligned) |
| `$mainMod SHIFT, h/j/k/l` | movewindow (already aligned) |
| `$mainMod, Print` / `$mainMod SHIFT, Print` / `$mainMod ALT, Print` | screenshots |
| `$mainMod, F9` / `$mainMod SHIFT, F9` | screen recording |
| `$mainMod, backspace` | hyprlock |
| `$mainMod, Escape` | rofi-power-menu |
| `XF86Audio*`, `XF86MonBrightness*` | media keys |

### 3.4 Existing Assertion Impact

A repository-wide search confirms there are currently **no assertions that reference any of the changing Hyprland bindings** (Q/W/E/R/T/Y/U/I/O/P/S as workspace or layout triggers). Existing Hyprland assertions cover monitors, gestures, exec-once, windowrules, wlsunset binding, package consistency, and keyboard layout — none of which are touched by this change. Reference assertion files:

- [`tests/assertions/thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix:1) — monitors, env, exec-once
- [`tests/assertions/thiniel-desktop-invariants.nix`](../../tests/assertions/thiniel-desktop-invariants.nix:1) — windowrules, wlsunset bind, gesture
- [`tests/assertions/thiniel-keyboard-invariants.nix`](../../tests/assertions/thiniel-keyboard-invariants.nix:1) — kb_layout/variant/model/options

**Conclusion**: no existing assertions need updating. A new file is added (Phase 1).

### 3.5 Cross-Mode Symmetry Check (Optional Follow-Up — Out of Scope)

The AeroSpace assertion file [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1) already covers `alt-h`, `alt-tab`, `alt-ctrl-l`. It does **not** assert `alt-1`, `alt-shift-1`, `alt-semicolon`, `alt-enter`, `alt-d`, `alt-f`. Extending it for full symmetry is **out of scope for this plan**; capture as a follow-up issue if desired.

## 4. Risk & Dangerous-Change Assessment

| Category | Affected? | Notes |
|---|---|---|
| Boot | No | Pure HM/Hyprland settings change |
| Network | No | — |
| Filesystem | No | — |
| Authentication | No | — |
| Secrets | No | — |
| Session loss | **Yes (low)** | A broken Hyprland config could prevent restart of the user session. `nixos-rebuild build` catches eval errors before activation. |

**Rollback path**: `sudo nixos-rebuild --rollback switch`, or boot the previous generation from the bootloader menu.

---

## 5. Validation Strategy (Phase 0 — Before Any Code Change)

### 5.1 Per-Cycle Validation Commands

| Layer | Command | Purpose |
|---|---|---|
| Assertion eval | `nix flake check --no-build` | Verifies all `assertions` evaluate; fast feedback for Red/Green |
| Full build | `nix build .#nixosConfigurations.thiniel.config.system.build.toplevel` | Catches HM evaluation errors |
| Quality | `nix fmt && statix check && deadnix .` | Repo hygiene |

### 5.2 Final Apply

| Step | Command |
|---|---|
| Test (non-persistent) | `sudo nixos-rebuild test --flake .#thiniel` |
| Switch (persistent) | `sudo nixos-rebuild switch --flake .#thiniel` |
| Rollback | `sudo nixos-rebuild --rollback switch` |

### 5.3 Post-Apply Manual Verification (cannot be automated — keyboard input)

Run each chord once on `thiniel`:

- [ ] `SUPER+1` .. `SUPER+0` cycle through the ten workspaces.
- [ ] `SUPER+SHIFT+1` .. `SUPER+SHIFT+0` send the active window to the corresponding workspace.
- [ ] `SUPER+Tab` / `SUPER+SHIFT+Tab` move focus across monitors when ≥2 are connected.
- [ ] `SUPER+CTRL+l` / `SUPER+CTRL+h` move the current workspace across monitors.
- [ ] `SUPER+;` flips dwindle split orientation.
- [ ] None of `SUPER+Q/W/E/R/T/Y/U/I/O/P` switch workspaces anymore.
- [ ] `SUPER+S` does NOT toggle split anymore.

---

## 6. Implementation Phases

> **TDD discipline**: Each cycle is **Red → Green → Refactor**. Test is written FIRST, observed to FAIL, then implementation makes it PASS, then quality gates run. Per [TEST-FIRST-001](../../.roo/rules/13-test-first.md), one assertion per cycle. Commit after each completed cycle ([`02-commits.md`](../../.roo/rules/02-commits.md)).
>
> **Atomicity guidance**: Workspace bindings 1–10 are mechanically identical changes. The plan lists each as its own cycle to strictly honour "one change per cycle". If the Orchestrator opts to batch all ten workspace switches as a single cycle (one assertion enumerating all ten mappings via `lib.all`), that is permitted as a deviation provided the test is still written before the implementation. Document the choice when delegating.

### Phase 1 — Assertion Scaffold

| Step | Action | Verify |
|---|---|---|
| 1.1 | Create [`tests/assertions/thiniel-hyprland-keybindings-invariants.nix`](../../tests/assertions/thiniel-hyprland-keybindings-invariants.nix) with the `{ config, lib, ... }:` header, `lib.mkIf (config.networking.hostName == "thiniel")` guard, an empty `assertions = [ ]` list, and a comment header documenting the Hyprland↔AeroSpace key mapping table from §3.2. | File parses; no behavior change. |
| 1.2 | Register the new file in [`tests/assertions/default.nix`](../../tests/assertions/default.nix:1) `imports` list. | `nix flake check --no-build` PASS. |
| 1.3 | Commit: `test(thiniel): scaffold hyprland keybinding invariants`. | — |

No Red phase here — this is pure scaffolding, no assertion logic yet.

### Phase 2 — Workspace Switching (Q/W/E/R/T/Y/U/I/O/P → 1..0)

Repeat the following Red‑Green‑Commit cycle for each workspace N ∈ {1..10} mapped to key K ∈ {Q,W,E,R,T,Y,U,I,O,P} respectively (W1↔Q, W2↔W, …, W10↔P):

| Sub-Step | Action |
|---|---|
| 2.N.R | Add assertion to the new invariants file: **the `bind` list contains `"$mainMod, <digit>, workspace, <N>"` AND does NOT contain `"$mainMod, <K>, workspace, <N>"`**. Run `nix flake check --no-build` → MUST FAIL. |
| 2.N.G | In [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix:227), replace the line `"$mainMod, <K>, workspace, <N>"` with `"$mainMod, <digit>, workspace, <N>"`. The digit for N=10 is `0`. Run `nix flake check --no-build` → PASS. |
| 2.N.Q | `nix fmt && statix check && deadnix .` — clean. |
| 2.N.C | Commit: `feat(thiniel): map SUPER+<digit> to workspace <N>` (e.g., `feat(thiniel): map SUPER+1 to workspace 1`). |

Result after Phase 2: lines 227–236 contain the new digit-based bindings; old letter bindings for workspace switching are gone.

### Phase 3 — Move-To-Workspace (SHIFT row Q..P → 1..0)

Mirror Phase 2 for the `movetoworkspace` block (current lines 239–248). One Red‑Green‑Commit cycle per workspace.

| Sub-Step (per N ∈ 1..10) | Action |
|---|---|
| 3.N.R | Assert presence of `"$mainMod SHIFT, <digit>, movetoworkspace, <N>"` AND absence of `"$mainMod SHIFT, <K>, movetoworkspace, <N>"`. → FAIL. |
| 3.N.G | Replace in the bind list. → PASS. |
| 3.N.Q | Quality gates. |
| 3.N.C | Commit: `feat(thiniel): map SUPER+SHIFT+<digit> to move-to-workspace <N>`. |

### Phase 4 — Monitor Focus Cycling

Two new bindings, two cycles.

| Cycle | Red Assertion | Green Implementation | Commit |
|---|---|---|---|
| 4.1 | `bind` contains `"$mainMod, Tab, focusmonitor, e+1"` | Add line to `bind` list (place near other navigation bindings, e.g. after movewindow block) | `feat(thiniel): SUPER+Tab cycles monitor focus forward` |
| 4.2 | `bind` contains `"$mainMod SHIFT, Tab, focusmonitor, e-1"` | Add line | `feat(thiniel): SUPER+SHIFT+Tab cycles monitor focus backward` |

### Phase 5 — Move Workspace To Monitor

| Cycle | Red Assertion | Green Implementation | Commit |
|---|---|---|---|
| 5.1 | `bind` contains `"$mainMod CTRL, l, movecurrentworkspacetomonitor, e+1"` | Add line | `feat(thiniel): SUPER+CTRL+l moves workspace to next monitor` |
| 5.2 | `bind` contains `"$mainMod CTRL, h, movecurrentworkspacetomonitor, e-1"` | Add line | `feat(thiniel): SUPER+CTRL+h moves workspace to prev monitor` |

### Phase 6 — Layout Toggle Key Migration (S → semicolon)

Single cycle covering both removal of old key and addition of new key (they describe the same logical action, so they belong to one cycle).

| Sub-Step | Action |
|---|---|
| 6.R | Add assertion: **`bind` contains `"$mainMod, semicolon, layoutmsg, togglesplit"` AND does NOT contain `"$mainMod, S, layoutmsg, togglesplit"`**. → FAIL. |
| 6.G | In [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix:206), replace `"$mainMod, S, layoutmsg, togglesplit"` with `"$mainMod, semicolon, layoutmsg, togglesplit"`. → PASS. |
| 6.Q | Quality gates. |
| 6.C | Commit: `feat(thiniel): bind SUPER+semicolon to togglesplit (replaces SUPER+S)`. |

### Phase 7 — Cleanup / Negative Sweep

One assertion enumerating that none of the QWERTYUIOP/S keys remain bound under `$mainMod` or `$mainMod SHIFT` for workspace/layout actions. This is a safety net against regressions.

| Sub-Step | Action |
|---|---|
| 7.R | Add a single assertion: `builtins.all (b: builtins.match "\\$mainMod( SHIFT)?, [QWERTYUIOPS], .*" b == null) binds`. Since Phases 2/3/6 already removed these, this MUST already PASS on the first run; if it FAILS, a prior phase left a stray binding — fix before continuing. Note: this is the documented "Refactor" verification step, not a true Red cycle. |
| 7.G | If FAIL, remove the leftover line in [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix:1). If PASS, no implementation change. |
| 7.C | Commit: `test(thiniel): assert legacy hyprland workspace/layout keys are unbound`. |

### Final Phase — Apply & Verify

| Step | Action |
|---|---|
| F.1 | `nix flake check` — PASS (full check including any VM tests). |
| F.2 | `nix build .#nixosConfigurations.thiniel.config.system.build.toplevel` — PASS. |
| F.3 | `sudo nixos-rebuild test --flake .#thiniel`. |
| F.4 | Execute the manual checklist in §5.3 on the live session. |
| F.5 | `sudo nixos-rebuild switch --flake .#thiniel` after manual verification succeeds. |
| F.6 | Update plan "Current Status" and "Completion Log". |

---

## 7. Out of Scope

- AeroSpace assertion symmetry expansion (§3.5).
- `alt-shift-semicolon` (service mode) — no Hyprland equivalent.
- Any change to Hyprland-only bindings (§3.3).
- Waybar workspace indicators, fuzzel keybindings, kitty keybindings — unrelated subsystems.
- Documentation outside this plan and the in-file comment header in the new assertion file.

---

## 8. Current Status

- [ ] Phase 0: Validation Strategy (this document)
- [ ] Phase 1: Assertion scaffold
- [ ] Phase 2: Workspace switching (10 cycles)
- [ ] Phase 3: Move-to-workspace (10 cycles)
- [ ] Phase 4: Monitor focus cycling (2 cycles)
- [ ] Phase 5: Move workspace to monitor (2 cycles)
- [ ] Phase 6: Layout toggle migration (1 cycle)
- [ ] Phase 7: Negative sweep (1 cycle)
- [ ] Final Phase: Apply & verify

## 9. Completion Log

_To be filled in by Code Mode as phases complete._
