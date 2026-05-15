# Implementation Plan: AeroSpace Multi-Monitor Workspace Improvements

**Status**: PROPOSED
**Target host**: [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:1) (aarch64-darwin, nix-darwin)
**Target file**: [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1)
**HM profile**: [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1)
**Assertions module**: [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1)

---

## 1. Goal

Make all ten AeroSpace workspaces reachable via `alt-1`..`alt-0` across three hardware scenarios — MacBook standalone, MacBook + 1 external display, MacBook + 2 external displays — with graceful fallback when monitors are absent, plus first-class keybindings for cross-monitor focus, mouse-follows-focus, and manual workspace relocation.

## 2. Business Context

The host `J6G6Y9JK7L` (MacBook running nix-darwin) is used in three docking scenarios:

1. **Standalone** — laptop only.
2. **Single external** — laptop + 1 external display.
3. **Dual external** — laptop + 2 external displays (most common at desk).

The current configuration ([`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1)) uses AeroSpace's default behavior, which assigns "ghost" workspaces (e.g. `11`, `12`) to newly attached monitors. Those workspaces have no keybinding and become unreachable from the keyboard, defeating the i3-style global workspace pool.

AeroSpace exposes [`workspace-to-monitor-force-assignment`](https://nikitabobko.github.io/AeroSpace/guide#assign-workspaces-to-monitors) with **fallback arrays**, which solves this declaratively without runtime hooks. (The requested `on-monitor-detected` hook does not yet exist — see upstream issue #824 — so a static assignment with fallbacks is the correct approach.)

## 3. Acceptance Criteria

- [ ] All workspaces `1`..`10` are reachable via `alt-1`..`alt-0` in **all three** scenarios (standalone, +1 external, +2 externals).
- [ ] No workspace is auto-assigned by AeroSpace to a monitor without an explicit binding (no "ghost" workspaces).
- [ ] When an external monitor is unplugged, its workspaces fall back to the next available monitor without losing any window.
- [ ] `alt-h/j/k/l` focus traversal crosses monitor boundaries (`--boundaries all-monitors-outer-frame`).
- [ ] Mouse cursor follows focus when monitor focus changes (`on-focused-monitor-changed = ['move-mouse monitor-lazy-center']`).
- [ ] New keybindings exist for: cycle focused monitor (`focus-monitor next/prev`), move current workspace to next/prev monitor (`move-workspace-to-monitor next/prev`), focus across monitors with `--boundaries`.
- [ ] Existing keybindings (alt-hjkl focus, alt-shift-hjkl move, alt-f fullscreen, alt-d Raycast, alt-enter kitty, alt-1..0, alt-shift-1..0, mode service) remain unchanged in semantics.
- [ ] Eval-time HM assertions verify the new structure (`workspace-to-monitor-force-assignment` populated, key bindings present).
- [ ] `nix flake check` passes.
- [ ] `nix build .#darwinConfigurations.J6G6Y9JK7L.system` succeeds.
- [ ] `statix check`, `deadnix`, `nix fmt` produce no findings on changed files.

## 4. Context (Architecture)

```
flake.nix
  └─ darwinConfigurations.J6G6Y9JK7L
       ├─ hosts/J6G6Y9JK7L/default.nix
       └─ home-manager.users.dan
            └─ home/dan/J6G6Y9JK7L.nix
                 ├─ ./global/default.nix
                 ├─ ../../tests/assertions/J6G6Y9JK7L-invariants.nix  (HM assertions)
                 └─ ./features/macos/aerospace.nix                    (← THIS PLAN)
```

Validation runs at HM-eval-time (`nix flake check`) and at `darwin-rebuild build` time. There is no VM test layer for darwin hosts in this repo — assertions are the only automated gate before deployment.

## 5. Technical Analysis

### 5.1 Monitor Naming on macOS

AeroSpace monitor selectors (in priority order):

| Selector | Meaning | Stability |
|---|---|---|
| `"main"` | Monitor with macOS menu bar (user-assignable in System Settings) | Stable per-session |
| `"secondary"` | Any non-main monitor (first match) | Stable per-session |
| `"built-in"` | Internal MacBook display | Stable across reboots |
| Exact name (e.g. `"Dell U2723QE"`) | Matches `system_profiler SPDisplaysDataType` name | Hardware-dependent |
| Regex (e.g. `"/.*Dell.*/"`) | Pattern match on monitor name | Hardware-dependent |
| Index (`1`, `2`, …) | Left-to-right ordering in System Settings | Fragile (rearranging displays breaks it) |

**Decision**: Use `"main"`, `"secondary"`, and `"built-in"` exclusively. They are zero-config, hardware-agnostic, and survive monitor swaps. Exact names and indices are rejected for portability.

### 5.2 Workspace → Monitor Mapping

Proposed split (validated against the three scenarios):

| WS | Primary monitor | Fallback chain | Intent |
|----|-----------------|----------------|--------|
| 1  | `main`          | —              | Primary work (browser, IDE) |
| 2  | `main`          | —              | Primary work |
| 3  | `main`          | —              | Primary work |
| 4  | `main`          | —              | Primary work |
| 5  | `secondary`     | → `main`       | Secondary content (docs, Slack) |
| 6  | `secondary`     | → `main`       | Secondary content |
| 7  | `secondary`     | → `main`       | Secondary content |
| 8  | `built-in`      | → `secondary` → `main` | Comms / monitoring (laptop screen when docked) |
| 9  | `built-in`      | → `secondary` → `main` | Comms / monitoring |
| 10 | `built-in`      | → `secondary` → `main` | Scratch / overflow |

**Behavior per scenario**:

| Scenario | `main` | `secondary` | `built-in` | Result |
|---|---|---|---|---|
| Standalone | = `built-in` | absent | = `main` | WS 1–4 on built-in; WS 5–7 fall back to `main` (built-in); WS 8–10 land on `built-in` directly. **All 10 reachable.** |
| +1 external | external | absent | laptop | WS 1–4 on external (assuming external is set as main display in macOS); WS 5–7 fall back to `main` (external); WS 8–10 on built-in. **All 10 reachable, sensibly distributed.** |
| +2 externals | external A | external B | laptop | WS 1–4 on A; WS 5–7 on B; WS 8–10 on built-in. **All 10 reachable, three-way split.** |

**Caveat**: In the "+1 external" scenario, the `secondary` selector resolves to **nothing** (there is no second non-main monitor when only one external is attached and it is set as main). Workspaces 5–7 then fall back to `main`. This is the documented AeroSpace fallback semantic and is the correct behavior.

**Alternative considered**: Map WS 5–7 to `built-in` and WS 8–10 to `secondary`. Rejected — puts the "always-available" workspaces (5–7) on the smaller laptop display in dual-external scenarios, which is the opposite of typical productivity workflows.

### 5.3 New Keybindings

Added to `mode.main.binding`:

| Binding | Command | Purpose |
|---|---|---|
| `alt-h` / `j` / `k` / `l` | `focus --boundaries all-monitors-outer-frame left/down/up/right` | Cross-monitor vim focus (replaces existing `focus left/down/up/right`) |
| `alt-shift-h` / `j` / `k` / `l` | `move left/down/up/right` | Unchanged — moves window within workspace |
| `alt-tab` | `focus-monitor --wrap-around next` | Cycle focused monitor forward |
| `alt-shift-tab` | `focus-monitor --wrap-around prev` | Cycle focused monitor backward |
| `alt-ctrl-l` | `move-workspace-to-monitor --wrap-around next` | Push current workspace to next monitor |
| `alt-ctrl-h` | `move-workspace-to-monitor --wrap-around prev` | Push current workspace to prev monitor |

Added at top level of `userSettings`:

```nix
on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
```

**Bindings rejected**:

- `alt-` + arrow keys for monitor focus → conflicts with macOS Spaces gestures for some users; `alt-tab` is more discoverable.
- `after-startup-command` → unnecessary; `workspace-to-monitor-force-assignment` already pins workspaces at evaluation time. Using both would risk double-assignment quirks.

### 5.4 Risks and Trade-offs

| Risk | Mitigation |
|------|------------|
| User changes the macOS "main display" mid-session → workspace assignment shifts | Acceptable; AeroSpace re-evaluates assignments on monitor topology changes. Documented behavior. |
| `alt-tab` shadows the macOS app switcher | macOS app switcher is `cmd-tab`; `alt-tab` is free. Verified. |
| Force-assignment disables `move-workspace-to-monitor` for assigned workspaces | Documented upstream. The keybinding still exists for workspaces created later or for manual override; primary mechanism remains the static assignment. |
| Monitor selector `"built-in"` does not match on Mac mini / Mac Studio | Not applicable — target host is a MacBook (`J6G6Y9JK7L`). |
| Removing fallback for WS 8–10 would strand them when the laptop lid is closed | Fallback chain `built-in → secondary → main` covers clamshell mode. |

## 6. Validation Strategy (Phase 0)

This is a **nix-darwin / Home Manager configuration change**. There is no runtime "test" — validation means the configuration evaluates, builds, and the resulting TOML is well-formed.

### Validation Commands

| Command | Validates |
|---|---|
| `nix flake check` | All flake checks + HM assertions for `J6G6Y9JK7L` |
| `nix build .#darwinConfigurations.J6G6Y9JK7L.system` | Full system closure builds |
| `nix fmt` | Formatting |
| `statix check home/dan/features/macos/aerospace.nix tests/assertions/J6G6Y9JK7L-invariants.nix` | Lint |
| `deadnix home/dan/features/macos/aerospace.nix tests/assertions/J6G6Y9JK7L-invariants.nix` | Dead code |
| `darwin-rebuild build --flake .#J6G6Y9JK7L` | Equivalent to system build, run on the target |

### Affected Hosts

- **Only**: `J6G6Y9JK7L`. No other host imports [`features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1).

### Manual Acceptance (post-`darwin-rebuild switch`)

These steps are NOT part of automated validation but are the human verification of acceptance criteria. To be performed by the user after the Orchestrator delegates the apply step:

1. Standalone (close lid? no — undock all externals): press `alt-1` through `alt-0` — every workspace activates and shows on the built-in display.
2. Attach one external: repeat `alt-1`..`alt-0`. WS 1–4 on external, 5–7 on external (fallback), 8–10 on built-in.
3. Attach a second external: repeat. WS 1–4 on display A, 5–7 on display B, 8–10 on built-in.
4. With two externals attached, press `alt-tab` — focus cycles across monitors; mouse cursor jumps to the new focused monitor's center.
5. Open a window on built-in WS 8, press `alt-ctrl-h` — workspace 8 moves to the previous monitor; window goes with it.
6. Cross-monitor focus: open windows on adjacent edges of two monitors, press `alt-l` from the rightmost window of the left monitor — focus crosses to the leftmost window of the right monitor.

### Rollback Path

This change is non-destructive (no boot, network, filesystem, secrets, or auth surface):

1. `git revert <commit-sha>` of the changes to [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) and [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1).
2. `darwin-rebuild switch --flake .#J6G6Y9JK7L`.
3. Previous AeroSpace config takes effect within a few seconds of `launchd` reload.

No dangerous-change category applies (no boot, network, filesystem, auth, or secrets risk).

## 7. Implementation Phases

Each phase is one Red-Green-Refactor cycle per [`13-test-first.md`](../../.roo/rules/13-test-first.md:1). Red = failing HM assertion; Green = config change that satisfies it. After each phase, run `nix flake check`. Commit per [`02-commits.md`](../../.roo/rules/02-commits.md:1) cadence.

### Phase 1 — Force-assignment skeleton

- **Red**: Add assertion to [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1):
  ```nix
  {
    assertion = (config.programs.aerospace.userSettings.workspace-to-monitor-force-assignment or {}) != {};
    message = "aerospace: workspace-to-monitor-force-assignment must be defined";
  }
  ```
  Verify `nix flake check` FAILS.
- **Green**: Add empty-but-present `workspace-to-monitor-force-assignment = { "1" = [ "main" ]; };` block to [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) `userSettings`. Verify `nix flake check` PASSES.
- **Verify**: `nix build .#darwinConfigurations.J6G6Y9JK7L.system` succeeds.

### Phase 2 — Pin workspaces 1–4 to `main`

- **Red**: Strengthen the assertion:
  ```nix
  {
    assertion = let m = config.programs.aerospace.userSettings.workspace-to-monitor-force-assignment;
                in m ? "1" && m ? "2" && m ? "3" && m ? "4"
                   && lib.head m."1" == "main";
    message = "aerospace: workspaces 1-4 must be force-assigned to 'main'";
  }
  ```
  Verify FAIL.
- **Green**: Set `"1" = [ "main" ]; "2" = [ "main" ]; "3" = [ "main" ]; "4" = [ "main" ];`. Verify PASS.

### Phase 3 — Pin workspaces 5–7 with `secondary → main` fallback

- **Red**: Add assertion:
  ```nix
  {
    assertion = let m = config.programs.aerospace.userSettings.workspace-to-monitor-force-assignment;
                in m."5" == [ "secondary" "main" ]
                   && m."6" == [ "secondary" "main" ]
                   && m."7" == [ "secondary" "main" ];
    message = "aerospace: workspaces 5-7 must fall back secondary -> main";
  }
  ```
  Verify FAIL.
- **Green**: Add the three entries. Verify PASS.

### Phase 4 — Pin workspaces 8–10 with `built-in → secondary → main` fallback

- **Red**: Add assertion mirroring Phase 3 for WS 8, 9, 10 with chain `[ "built-in" "secondary" "main" ]`. Verify FAIL.
- **Green**: Add entries. Verify PASS.

### Phase 5 — Add `on-focused-monitor-changed` (mouse-follows-focus)

- **Red**: Add assertion:
  ```nix
  {
    assertion = (config.programs.aerospace.userSettings.on-focused-monitor-changed or []) == [ "move-mouse monitor-lazy-center" ];
    message = "aerospace: on-focused-monitor-changed must move mouse to monitor-lazy-center";
  }
  ```
  Verify FAIL.
- **Green**: Add `on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];` at `userSettings` top level. Verify PASS.

### Phase 6 — Cross-monitor focus (replace `alt-hjkl` bindings)

- **Red**: Add assertion:
  ```nix
  {
    assertion = config.programs.aerospace.userSettings.mode.main.binding."alt-l"
                == "focus --boundaries all-monitors-outer-frame right";
    message = "aerospace: alt-l must focus right across monitor boundaries";
  }
  ```
  (Add similar assertions for `alt-h/j/k`.) Verify FAIL.
- **Green**: Replace four bindings in [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1):
  ```nix
  alt-h = "focus --boundaries all-monitors-outer-frame left";
  alt-j = "focus --boundaries all-monitors-outer-frame down";
  alt-k = "focus --boundaries all-monitors-outer-frame up";
  alt-l = "focus --boundaries all-monitors-outer-frame right";
  ```
  Verify PASS.

### Phase 7 — `focus-monitor` bindings (alt-tab / alt-shift-tab)

- **Red**: Add assertions:
  ```nix
  {
    assertion = config.programs.aerospace.userSettings.mode.main.binding."alt-tab"
                == "focus-monitor --wrap-around next";
    message = "aerospace: alt-tab must cycle focused monitor forward";
  }
  {
    assertion = config.programs.aerospace.userSettings.mode.main.binding."alt-shift-tab"
                == "focus-monitor --wrap-around prev";
    message = "aerospace: alt-shift-tab must cycle focused monitor backward";
  }
  ```
  Verify FAIL.
- **Green**: Add the two bindings. Verify PASS.

### Phase 8 — `move-workspace-to-monitor` bindings (alt-ctrl-h / alt-ctrl-l)

- **Red**: Add assertions for `alt-ctrl-h` (`prev`) and `alt-ctrl-l` (`next`). Verify FAIL.
- **Green**: Add the two bindings. Verify PASS.

### Phase 9 — Quality gate & documentation

- **Refactor**: Run `nix fmt`, `statix check`, `deadnix`. Address any findings.
- **Verify**: All assertions still pass; `nix flake check` and `nix build .#darwinConfigurations.J6G6Y9JK7L.system` succeed.
- **Document**: No README change required — the feature module is self-contained. Plan file is the documentation artifact.

### Phase 10 — Apply & manual verification

Delegated by Orchestrator to the user (apply step):

1. `darwin-rebuild switch --flake .#J6G6Y9JK7L`.
2. AeroSpace `launchd` agent reloads automatically (`keepAlive = true`).
3. User performs Manual Acceptance steps from §6.
4. If a step fails: capture observed behavior, return to Architect to revise plan; otherwise mark plan COMPLETED.

## 8. Final State Preview

After all phases, [`home/dan/features/macos/aerospace.nix`](../../home/dan/features/macos/aerospace.nix:1) `userSettings` will additionally contain:

```nix
on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

workspace-to-monitor-force-assignment = {
  "1" = [ "main" ];
  "2" = [ "main" ];
  "3" = [ "main" ];
  "4" = [ "main" ];
  "5" = [ "secondary" "main" ];
  "6" = [ "secondary" "main" ];
  "7" = [ "secondary" "main" ];
  "8"  = [ "built-in" "secondary" "main" ];
  "9"  = [ "built-in" "secondary" "main" ];
  "10" = [ "built-in" "secondary" "main" ];
};
```

And `mode.main.binding` will have the four `alt-hjkl` bindings updated plus four new bindings (`alt-tab`, `alt-shift-tab`, `alt-ctrl-h`, `alt-ctrl-l`). All other existing bindings remain untouched.

## 9. Current Status

**Status**: AWAITING APPROVAL
**Completed phases**: none
**Next step**: User reviews plan; on approval, Orchestrator delegates Phase 1 to Code Mode.

## 10. Completion Log

_(populated as phases complete)_
