# Hyprland Dynamic Monitor/Workspace Assignment Plan

**Status**: READY FOR IMPLEMENTATION

## Goal

Replace the static, hardcoded monitor connector names and workspace bindings in [`hyprland.nix`](../../home/dan/features/linux/hyprland.nix) with a dynamic solution that automatically distributes workspaces 1–10 across whatever monitors are attached at Hyprland startup. Fix the "Monitor DP-7 failed to set any requested modes" error.

## Context

- **Host**: thiniel — Lenovo ThinkPad X270, Intel HD Graphics 620
- **File**: [`home/dan/features/linux/hyprland.nix`](../../home/dan/features/linux/hyprland.nix)
- **Problem**: Hardcoded `DP-3`, `DP-4`, `DP-6` connector names break when using different docking stations. Stale references cause workspace assignment failures. Missing `DP-7` rule triggers Hyprland ≥0.47 mode negotiation error.
- **Solution**: Catch-all monitor rule + `exec-once` persistent daemon that reads `hyprctl monitors -j` and distributes workspaces dynamically — both at startup and on monitor hot-plug/unplug via Hyprland IPC events.

## Acceptance Criteria

1. `settings.monitor` contains exactly 2 entries: catch-all `", preferred, auto, 1"` and explicit `"eDP-1, preferred, 0x0, 1"`
2. `settings.workspace` is absent (removed entirely)
3. `settings.env` contains `"AQ_NO_MODIFIERS,1"`
4. `exec-once` launches the workspace distribution script
5. The workspace daemon:
   - Reads monitors from `hyprctl monitors -j`
   - Distributes workspaces 1–10 evenly across all monitors
   - Sets workspace 1 as default on first monitor
   - Handles 1, 2, and 3 monitor scenarios
   - Listens on Hyprland IPC socket for `monitoraddedv2` and `monitorremoved` events
   - Re-distributes workspaces on each hot-plug/unplug event (with short stabilization delay)
6. `jq` and `socat` are available at script runtime (absolute Nix store paths)
7. `nix flake check` passes
8. Unit tests in [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix) updated and pass

## Technical Analysis

### Current State

```nix
# hyprland.nix lines 73–78
monitor = [
  ", preferred, auto, 1"
  "eDP-1, preferred, 0x0, 1"
  "DP-3, preferred, 4480x0, 1, transform, 1"
  "DP-4, preferred, 1920x0, 1"
];

# hyprland.nix lines 80–91
workspace = [
  "1,monitor:eDP-1,default:true"
  "2,monitor:eDP-1"
  # ... 8 more static entries with DP-6, DP-3
];
```

### Target State

```nix
monitor = [
  ", preferred, auto, 1"
  "eDP-1, preferred, 0x0, 1"
];

env = "AQ_NO_MODIFIERS,1";

# workspace key: REMOVED entirely

exec-once = [
  "${startupScript}/bin/start"      # existing clipboard watchers
  "${workspaceScript}/bin/assign-workspaces"  # NEW: dynamic assignment
];
```

### Workspace Distribution Daemon

Written as `pkgs.writeShellScriptBin "assign-workspaces"` with absolute Nix store paths for `jq`, `hyprctl`, and `socat`. The script runs as a **persistent daemon** launched via `exec-once`:

1. Defines an `assign_workspaces` function that reads current monitors and distributes workspaces
2. Calls `assign_workspaces` once on start (initial assignment)
3. Enters a `socat` loop listening on the Hyprland IPC socket for monitor events
4. On each `monitoraddedv2` or `monitorremoved` event, calls `assign_workspaces` again (with a 1-second stabilization delay)
5. The script runs for the lifetime of the Hyprland session — Hyprland manages its lifecycle

```bash
#!/usr/bin/env bash
set -euo pipefail

HYPRCTL="${pkgs-unstable.hyprland}/bin/hyprctl"
JQ="${pkgs.jq}/bin/jq"
SOCAT="${pkgs.socat}/bin/socat"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

assign_workspaces() {
  local monitors count ws idx mon
  monitors=($("$HYPRCTL" monitors -j | "$JQ" -r '.[].name'))
  count=''${#monitors[@]}

  if [ "$count" -eq 0 ]; then
    return 1
  fi

  # Distribute workspaces 1–10 evenly across monitors
  for ws in $(seq 1 10); do
    idx=$(( (ws - 1) % count ))
    mon="''${monitors[$idx]}"
    "$HYPRCTL" dispatch moveworkspacetomonitor "$ws" "$mon"
  done

  # Set workspace 1 as active on first monitor
  "$HYPRCTL" dispatch workspace 1
}

# Initial assignment — wait for Hyprland IPC to be ready
sleep 1
assign_workspaces

# Listen for monitor hot-plug/unplug events
"$SOCAT" -U - UNIX-CONNECT:"$SOCKET" | while IFS= read -r line; do
  case "$line" in
    monitoradded*|monitorremoved*)
      sleep 1  # wait for Hyprland to finish setting up/tearing down
      assign_workspaces
      ;;
  esac
done
```

**IPC Socket**: Hyprland exposes `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock` which streams events. Relevant events:
- `monitoraddedv2>>ID,NAME,DESCRIPTION` — fired when a monitor is connected
- `monitorremoved>>NAME` — fired when a monitor is disconnected

**Distribution examples**:

| Monitors | WS 1–10 assignment |
|----------|-------------------|
| 1 monitor | All 10 on single monitor |
| 2 monitors | 1,3,5,7,9 → mon0; 2,4,6,8,10 → mon1 |
| 3 monitors | 1,4,7,10 → mon0; 2,5,8 → mon1; 3,6,9 → mon2 |

### Impact on Existing Tests

| Test | Current | After | Action |
|------|---------|-------|--------|
| [`testHyprlandMonitorCount`](../../tests/unit/hm-linux-modules-test.nix:61) | `expected = 4` | `expected = 2` | Update |
| [`testHyprlandWorkspaceCount`](../../tests/unit/hm-linux-modules-test.nix:66) | `expected = 10` | Remove test or assert `!(hyprSettings ? workspace)` | Replace |
| All other hyprland tests | Unchanged | Unchanged | No action |

### Impact on Assertions

No existing assertions in [`thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix), [`thiniel-services-invariants.nix`](../../tests/assertions/thiniel-services-invariants.nix), or [`thiniel-keyboard-invariants.nix`](../../tests/assertions/thiniel-keyboard-invariants.nix) reference `monitor` or `workspace` settings directly. No assertion changes needed.

### `exec-once` format change

Current `exec-once` is a string (line 71: `exec-once = "${startupScript}/bin/start";`). Must change to a list to support multiple entries. Hyprland/HM handles both formats — list serializes as multiple `exec-once = ...` lines.

## Validation Strategy

### Phase 0: Validation Commands

- **Syntax/eval**: `nix flake check --no-build`
- **Build**: `nix build .#nixosConfigurations.thiniel.config.system.build.toplevel --dry-run`
- **Unit tests**: `nix flake check` (runs `checks.x86_64-linux.*`)
- **Apply**: `sudo nixos-rebuild test --flake .#thiniel` (on live machine)
- **Rollback**: `sudo nixos-rebuild switch --rollback` or reboot into previous generation

### Dangerous Change Assessment

| Category | Risk | Mitigation |
|----------|------|------------|
| Display/Desktop | Hyprland may start with wrong workspace layout | Script runs post-startup; worst case = manual workspace move. Rollback via `nixos-rebuild switch --rollback` |
| Environment variable | `AQ_NO_MODIFIERS=1` changes DRM behavior | Known fix for Intel iGPU ≥0.47; revert by removing env line |

No boot, network, filesystem, auth, or secrets changes.

## Implementation Phases

### Phase 1: Red — Unit test for reduced monitor count

Write failing test: `testHyprlandMonitorCount` expects 2 instead of 4.

- [ ] Step 1.1: In [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix:61), change `testHyprlandMonitorCount.expected` from `4` to `2`
- [ ] Step 1.2: Run `nix flake check` → FAIL (monitor count is still 4)

### Phase 2: Green — Remove hardcoded DP-N monitor rules

Implement the change to make the test pass.

- [ ] Step 2.1: In [`hyprland.nix`](../../home/dan/features/linux/hyprland.nix:73), remove `"DP-3, preferred, 4480x0, 1, transform, 1"` and `"DP-4, preferred, 1920x0, 1"` from `monitor` list — keep only the catch-all and `eDP-1`
- [ ] Step 2.2: Run `nix flake check` → test `testHyprlandMonitorCount` PASSES, but `testHyprlandWorkspaceCount` may still pass (workspace list still exists)

### Phase 3: Red — Unit test for workspace removal

Write failing test: assert `workspace` key is absent from settings.

- [ ] Step 3.1: In [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix:66), replace `testHyprlandWorkspaceCount` with `testHyprlandNoStaticWorkspace`:
  ```nix
  testHyprlandNoStaticWorkspace = {
    expr = !(hyprSettings ? workspace);
    expected = true;
  };
  ```
- [ ] Step 3.2: Run `nix flake check` → FAIL (workspace key still exists)

### Phase 4: Green — Remove static workspace rules

- [ ] Step 4.1: In [`hyprland.nix`](../../home/dan/features/linux/hyprland.nix:80), delete the entire `workspace = [ ... ];` block (lines 80–91)
- [ ] Step 4.2: Run `nix flake check` → PASS

### Phase 5: Red — Unit test for AQ_NO_MODIFIERS env var

- [ ] Step 5.1: In [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix), add test:
  ```nix
  testHyprlandAqNoModifiers = {
    expr = builtins.elem "AQ_NO_MODIFIERS,1" hyprSettings.env;
    expected = true;
  };
  ```
- [ ] Step 5.2: Run `nix flake check` → FAIL (no `env` key in settings)

### Phase 6: Green — Add AQ_NO_MODIFIERS env var

- [ ] Step 6.1: In [`hyprland.nix`](../../home/dan/features/linux/hyprland.nix), add to `settings`:
  ```nix
  env = "AQ_NO_MODIFIERS,1";
  ```
- [ ] Step 6.2: Run `nix flake check` → PASS

### Phase 7: Red — Unit test for exec-once containing workspace daemon

- [ ] Step 7.1: In [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix), add tests:
  ```nix
  testHyprlandExecOnceIsList = {
    expr = builtins.isList hyprSettings.exec-once;
    expected = true;
  };

  testHyprlandExecOnceHasWorkspaceScript = {
    expr = builtins.any (cmd: lib.strings.hasInfix "assign-workspaces" cmd) hyprSettings.exec-once;
    expected = true;
  };
  ```
- [ ] Step 7.2: Run `nix flake check` → FAIL (exec-once is a string, no workspace script)

### Phase 8: Green — Create workspace daemon and wire into exec-once

- [ ] Step 8.1: In [`hyprland.nix`](../../home/dan/features/linux/hyprland.nix), add `workspaceScript` in the `let` block as a persistent daemon with IPC listener:
  ```nix
  workspaceScript = pkgs.writeShellScriptBin "assign-workspaces" ''
    set -euo pipefail

    HYPRCTL="${pkgs-unstable.hyprland}/bin/hyprctl"
    JQ="${pkgs.jq}/bin/jq"
    SOCAT="${pkgs.socat}/bin/socat"
    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

    assign_workspaces() {
      local monitors count ws idx mon
      monitors=($("$HYPRCTL" monitors -j | "$JQ" -r '.[].name'))
      count=''${#monitors[@]}

      if [ "$count" -eq 0 ]; then
        return 1
      fi

      for ws in $(seq 1 10); do
        idx=$(( (ws - 1) % count ))
        mon="''${monitors[$idx]}"
        "$HYPRCTL" dispatch moveworkspacetomonitor "$ws" "$mon"
      done

      "$HYPRCTL" dispatch workspace 1
    }

    # Initial assignment
    sleep 1
    assign_workspaces

    # Listen for monitor hot-plug/unplug events
    "$SOCAT" -U - UNIX-CONNECT:"$SOCKET" | while IFS= read -r line; do
      case "$line" in
        monitoradded*|monitorremoved*)
          sleep 1
          assign_workspaces
          ;;
      esac
    done
  '';
  ```
- [ ] Step 8.2: Change `exec-once` from string to list:
  ```nix
  exec-once = [
    "${startupScript}/bin/start"
    "${workspaceScript}/bin/assign-workspaces"
  ];
  ```
- [ ] Step 8.3: Run `nix flake check` → PASS

### Phase 9: Refactor — Verify all tests green, format, lint

- [ ] Step 9.1: Run `nix flake check` → all tests PASS
- [ ] Step 9.2: Run `nix fmt` on changed files
- [ ] Step 9.3: Run `statix check` and `deadnix` on changed files
- [ ] Step 9.4: Commit changes

### Phase 10: Apply and Verify (on live machine)

- [ ] Step 10.1: `sudo nixos-rebuild test --flake .#thiniel` — verify no build errors
- [ ] Step 10.2: Verify Hyprland starts without "Monitor DP-7 failed to set any requested modes" error
- [ ] Step 10.3: Verify workspaces are distributed across connected monitors
- [ ] Step 10.4: Test with: laptop only (1 monitor), dock with 1 external (2 monitors), dock with 2 externals (3 monitors)
- [ ] Step 10.5: Test hot-plug: connect an external monitor while Hyprland is running → verify workspaces re-distribute
- [ ] Step 10.6: Test unplug: disconnect an external monitor while Hyprland is running → verify workspaces re-distribute to remaining monitors
- [ ] Step 10.7: `sudo nixos-rebuild switch --flake .#thiniel` — make permanent

## Current Status

**Phase**: Planning complete, ready for implementation.

## Completion Log

_(Updated as phases complete)_
