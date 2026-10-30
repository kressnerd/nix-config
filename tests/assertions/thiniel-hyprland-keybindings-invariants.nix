# tests/assertions/thiniel-hyprland-keybindings-invariants.nix
# Thiniel Hyprland keybinding assertions — enforces aligned keybindings (post-migration)
# Covers: workspace switching (1–0), move-to-workspace, monitor focus, layout toggle
{ config, lib, ... }:
let
  mainMod = "SUPER";

  settings = config.home-manager.users.dan.wayland.windowManager.hyprland.settings;
  binds = settings.bind or [ ];

  argsOf = entry: entry._args or [ ];
  exprOf = value: value.expr or "";

  hasKey =
    key: builtins.any (entry: argsOf entry != [ ] && builtins.head (argsOf entry) == key) binds;

  hasBind =
    key: dispatcher:
    builtins.any (
      entry:
      let
        args = argsOf entry;
      in
      args != [ ]
      && builtins.head args == key
      && builtins.any (value: lib.hasInfix dispatcher (exprOf value)) args
    ) binds;

  # Every chord must be claimed once. Two binds with the same key string make
  # the later definition dead or, worse, silently shift an established action.
  boundKeys = builtins.map (entry: builtins.head (argsOf entry)) (
    builtins.filter (entry: argsOf entry != [ ]) binds
  );

  keys = [
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "0"
  ];
  oldKeys = [
    "Q"
    "W"
    "E"
    "R"
    "T"
    "Y"
    "U"
    "I"
    "O"
    "P"
  ];
  nums = [
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
  ];

  workspaceSwitchAssertions = lib.imap0 (i: key: {
    assertion = hasBind "${mainMod} + ${key}" "hl.dsp.focus({ workspace = ${toString (builtins.elemAt nums i)} })";
    message = "thiniel: Hyprland must bind ${mainMod}+${key} to workspace ${toString (builtins.elemAt nums i)}";
  }) keys;

  moveToWorkspaceAssertions = lib.imap0 (i: key: {
    assertion = hasBind "${mainMod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${toString (builtins.elemAt nums i)} })";
    message = "thiniel: Hyprland must bind ${mainMod} SHIFT+${key} to move window to workspace ${toString (builtins.elemAt nums i)}";
  }) keys;

  negativeWorkspaceSwitchAssertions = lib.imap0 (_i: key: {
    assertion = !(hasKey "${mainMod} + ${key}");
    message = "thiniel: old ${mainMod}+${key} workspace bind must be removed";
  }) oldKeys;

  negativeMoveToWorkspaceAssertions = lib.imap0 (_i: key: {
    assertion = !(hasKey "${mainMod} + SHIFT + ${key}");
    message = "thiniel: old ${mainMod} SHIFT+${key} move-to-workspace bind must be removed";
  }) oldKeys;
in
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions =
      workspaceSwitchAssertions
      ++ moveToWorkspaceAssertions
      ++ [
        # ── Monitor focus cycling ────────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + Tab" ''hl.dsp.focus({ monitor = "+1" })'';
          message = "thiniel: Hyprland must bind ${mainMod}+Tab to focus monitor +1";
        }
        {
          assertion = hasBind "${mainMod} + SHIFT + Tab" ''hl.dsp.focus({ monitor = "-1" })'';
          message = "thiniel: Hyprland must bind ${mainMod} SHIFT+Tab to focus monitor -1";
        }

        # ── Move workspace to monitor ────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + CTRL + l" ''hl.dsp.workspace.move({ monitor = "+1" })'';
          message = "thiniel: Hyprland must bind ${mainMod} CTRL+l to move workspace to monitor +1";
        }
        {
          assertion = hasBind "${mainMod} + CTRL + h" ''hl.dsp.workspace.move({ monitor = "-1" })'';
          message = "thiniel: Hyprland must bind ${mainMod} CTRL+h to move workspace to monitor -1";
        }

        # ── Monitor rotation ─────────────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + CTRL + r" "hl.get_active_monitor";
          message = "thiniel: Hyprland must bind ${mainMod} CTRL+r to rotate the active monitor 90°";
        }
        {
          assertion = hasBind "${mainMod} + CTRL + r" "pkill -USR2 waybar";
          message = "thiniel: ${mainMod} CTRL+r must reload waybar — its layer surfaces keep stale geometry when rotated monitors reflow neighbours";
        }
        {
          assertion = !(hasBind "${mainMod} + CTRL + r" "pkill -USR1 waybar");
          message = "thiniel: ${mainMod} CTRL+r must not signal waybar with SIGUSR1 — waybar 0.15.0 toggles bar visibility on SIGUSR1 (reload is SIGUSR2), so that signal hides every bar until the next rotate";
        }

        # ── Layout toggle migration ──────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + semicolon" ''hl.dsp.layout("togglesplit")'';
          message = "thiniel: Hyprland layout toggle must use semicolon (not S)";
        }
      ]
      ++ negativeWorkspaceSwitchAssertions
      ++ negativeMoveToWorkspaceAssertions
      ++ [
        # ── Negative: old layout toggle on S must NOT exist ──────────────────────
        {
          assertion = !(hasKey "${mainMod} + S");
          message = "thiniel: old ${mainMod}+S layout toggle bind must be removed (moved to semicolon)";
        }

        # ── Chord uniqueness ─────────────────────────────────────────────────────
        {
          assertion = builtins.length boundKeys == builtins.length (lib.unique boundKeys);
          message = "thiniel: every Hyprland bind chord must be unique, got duplicates: ${
            builtins.toJSON (
              builtins.filter (k: builtins.length (builtins.filter (x: x == k) boundKeys) > 1) (
                lib.unique boundKeys
              )
            )
          }";
        }

        # ── Window resize and swap ───────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + ALT + h" "hl.dsp.window.resize";
          message = "thiniel: ${mainMod}+ALT+h must shrink the window horizontally";
        }
        {
          assertion = hasBind "${mainMod} + ALT + l" "hl.dsp.window.resize";
          message = "thiniel: ${mainMod}+ALT+l must grow the window horizontally";
        }
        {
          assertion = hasBind "${mainMod} + ALT + k" "hl.dsp.window.resize";
          message = "thiniel: ${mainMod}+ALT+k must shrink the window vertically";
        }
        {
          assertion = hasBind "${mainMod} + ALT + j" "hl.dsp.window.resize";
          message = "thiniel: ${mainMod}+ALT+j must grow the window vertically";
        }
        {
          assertion = hasBind "${mainMod} + SHIFT + ALT + h" "hl.dsp.window.swap";
          message = "thiniel: ${mainMod}+SHIFT+ALT+h must swap the window left";
        }
        {
          assertion = hasBind "${mainMod} + SHIFT + ALT + l" "hl.dsp.window.swap";
          message = "thiniel: ${mainMod}+SHIFT+ALT+l must swap the window right";
        }

        # ── Scratchpad ───────────────────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + grave" ''hl.dsp.workspace.toggle_special("scratchpad")'';
          message = "thiniel: ${mainMod}+grave must toggle the scratchpad";
        }
        {
          assertion = hasBind "${mainMod} + SHIFT + grave" "special:scratchpad";
          message = "thiniel: ${mainMod}+SHIFT+grave must move the focused window to the scratchpad";
        }

        # ── Window cycling ───────────────────────────────────────────────────────
        {
          assertion = hasBind "ALT + Tab" "hl.dsp.window.cycle_next";
          message = "thiniel: ALT+Tab must cycle windows";
        }
        {
          assertion = hasBind "ALT + SHIFT + Tab" "hl.dsp.window.cycle_next";
          message = "thiniel: ALT+SHIFT+Tab must cycle windows backwards";
        }

        # ── Lock, colour picker, OSD ─────────────────────────────────────────────
        {
          assertion = hasBind "${mainMod} + ALT + Escape" "hyprlock";
          message = "thiniel: ${mainMod}+ALT+Escape must lock the screen";
        }
        {
          assertion = hasBind "${mainMod} + SHIFT + C" "hyprpicker";
          message = "thiniel: ${mainMod}+SHIFT+C must copy the colour under the cursor";
        }
        {
          assertion = hasBind "XF86AudioRaiseVolume" "swayosd-client --output-volume +5";
          message = "thiniel: volume-up must go through swayosd-client so the OSD appears";
        }
        {
          assertion = hasBind "XF86AudioLowerVolume" "swayosd-client --output-volume -5";
          message = "thiniel: volume-down must go through swayosd-client so the OSD appears";
        }
        {
          assertion = hasBind "XF86MonBrightnessUp" "swayosd-client --brightness +5";
          message = "thiniel: brightness-up must go through swayosd-client so the OSD appears";
        }
        {
          assertion = hasBind "XF86MonBrightnessDown" "swayosd-client --brightness -5";
          message = "thiniel: brightness-down must go through swayosd-client so the OSD appears";
        }
        {
          assertion = hasBind "XF86AudioMute" "swayosd-client --output-volume mute-toggle";
          message = "thiniel: mute must go through swayosd-client so the OSD appears";
        }
      ];
  };
}
