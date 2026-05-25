# tests/assertions/thiniel-hyprland-keybindings-invariants.nix
# Thiniel Hyprland keybinding assertions — enforces aligned keybindings (post-migration)
# Covers: workspace switching (1–0), move-to-workspace, monitor focus, layout toggle
{ config, lib, ... }:
let
  binds = config.home-manager.users.dan.wayland.windowManager.hyprland.settings.bind or [ ];
  hasBind = b: builtins.any (x: x == b) binds;

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
    assertion = hasBind "$mainMod, ${key}, workspace, ${toString (builtins.elemAt nums i)}";
    message = "thiniel: Hyprland must bind $mainMod+${key} to workspace ${toString (builtins.elemAt nums i)}";
  }) keys;

  moveToWorkspaceAssertions = lib.imap0 (i: key: {
    assertion = hasBind "$mainMod SHIFT, ${key}, movetoworkspace, ${toString (builtins.elemAt nums i)}";
    message = "thiniel: Hyprland must bind $mainMod SHIFT+${key} to movetoworkspace ${toString (builtins.elemAt nums i)}";
  }) keys;

  negativeWorkspaceSwitchAssertions = lib.imap0 (i: key: {
    assertion = !(hasBind "$mainMod, ${key}, workspace, ${toString (builtins.elemAt nums i)}");
    message = "thiniel: old $mainMod+${key} workspace bind must be removed";
  }) oldKeys;

  negativeMoveToWorkspaceAssertions = lib.imap0 (i: key: {
    assertion =
      !(hasBind "$mainMod SHIFT, ${key}, movetoworkspace, ${toString (builtins.elemAt nums i)}");
    message = "thiniel: old $mainMod SHIFT+${key} movetoworkspace bind must be removed";
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
          assertion = hasBind "$mainMod, Tab, focusmonitor, +1";
          message = "thiniel: Hyprland must bind $mainMod+Tab to focusmonitor +1";
        }
        {
          assertion = hasBind "$mainMod SHIFT, Tab, focusmonitor, -1";
          message = "thiniel: Hyprland must bind $mainMod SHIFT+Tab to focusmonitor -1";
        }

        # ── Move workspace to monitor ────────────────────────────────────────────
        {
          assertion = hasBind "$mainMod CTRL, l, movecurrentworkspacetomonitor, +1";
          message = "thiniel: Hyprland must bind $mainMod CTRL+l to movecurrentworkspacetomonitor +1";
        }
        {
          assertion = hasBind "$mainMod CTRL, h, movecurrentworkspacetomonitor, -1";
          message = "thiniel: Hyprland must bind $mainMod CTRL+h to movecurrentworkspacetomonitor -1";
        }

        # ── Layout toggle migration ──────────────────────────────────────────────
        {
          assertion = hasBind "$mainMod, semicolon, layoutmsg, togglesplit";
          message = "thiniel: Hyprland layout toggle must use semicolon (not S)";
        }
      ]
      ++ negativeWorkspaceSwitchAssertions
      ++ negativeMoveToWorkspaceAssertions
      ++ [
        # ── Negative: old layout toggle on S must NOT exist ──────────────────────
        {
          assertion = !(hasBind "$mainMod, S, layoutmsg, togglesplit");
          message = "thiniel: old $mainMod+S layout toggle bind must be removed (moved to semicolon)";
        }
      ];
  };
}
