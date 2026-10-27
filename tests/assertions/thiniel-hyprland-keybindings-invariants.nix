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
      ];
  };
}
