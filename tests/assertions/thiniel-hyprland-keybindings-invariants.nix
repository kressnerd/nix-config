# tests/assertions/thiniel-hyprland-keybindings-invariants.nix
# Thiniel Hyprland keybinding assertions — enforces aligned keybindings (post-migration)
# Covers: workspace switching (1–0), move-to-workspace, monitor focus, layout toggle
{ config, lib, ... }:
let
  binds = config.home-manager.users.dan.wayland.windowManager.hyprland.settings.bind or [ ];
  hasBinds = b: builtins.any (x: x == b) binds;
in
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      # ── Workspace switching: SUPER + 1–0 ────────────────────────────────────
      {
        assertion = hasBinds "$mainMod, 1, workspace, 1";
        message = "thiniel: Hyprland must bind $mainMod+1 to workspace 1";
      }
      {
        assertion = hasBinds "$mainMod, 2, workspace, 2";
        message = "thiniel: Hyprland must bind $mainMod+2 to workspace 2";
      }
      {
        assertion = hasBinds "$mainMod, 3, workspace, 3";
        message = "thiniel: Hyprland must bind $mainMod+3 to workspace 3";
      }
      {
        assertion = hasBinds "$mainMod, 4, workspace, 4";
        message = "thiniel: Hyprland must bind $mainMod+4 to workspace 4";
      }
      {
        assertion = hasBinds "$mainMod, 5, workspace, 5";
        message = "thiniel: Hyprland must bind $mainMod+5 to workspace 5";
      }
      {
        assertion = hasBinds "$mainMod, 6, workspace, 6";
        message = "thiniel: Hyprland must bind $mainMod+6 to workspace 6";
      }
      {
        assertion = hasBinds "$mainMod, 7, workspace, 7";
        message = "thiniel: Hyprland must bind $mainMod+7 to workspace 7";
      }
      {
        assertion = hasBinds "$mainMod, 8, workspace, 8";
        message = "thiniel: Hyprland must bind $mainMod+8 to workspace 8";
      }
      {
        assertion = hasBinds "$mainMod, 9, workspace, 9";
        message = "thiniel: Hyprland must bind $mainMod+9 to workspace 9";
      }
      {
        assertion = hasBinds "$mainMod, 0, workspace, 10";
        message = "thiniel: Hyprland must bind $mainMod+0 to workspace 10";
      }

      # ── Move window to workspace: SUPER SHIFT + 1–0 ─────────────────────────
      {
        assertion = hasBinds "$mainMod SHIFT, 1, movetoworkspace, 1";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+1 to movetoworkspace 1";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 2, movetoworkspace, 2";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+2 to movetoworkspace 2";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 3, movetoworkspace, 3";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+3 to movetoworkspace 3";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 4, movetoworkspace, 4";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+4 to movetoworkspace 4";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 5, movetoworkspace, 5";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+5 to movetoworkspace 5";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 6, movetoworkspace, 6";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+6 to movetoworkspace 6";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 7, movetoworkspace, 7";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+7 to movetoworkspace 7";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 8, movetoworkspace, 8";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+8 to movetoworkspace 8";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 9, movetoworkspace, 9";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+9 to movetoworkspace 9";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, 0, movetoworkspace, 10";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+0 to movetoworkspace 10";
      }

      # ── Monitor focus cycling ────────────────────────────────────────────────
      {
        assertion = hasBinds "$mainMod, Tab, focusmonitor, +1";
        message = "thiniel: Hyprland must bind $mainMod+Tab to focusmonitor +1";
      }
      {
        assertion = hasBinds "$mainMod SHIFT, Tab, focusmonitor, -1";
        message = "thiniel: Hyprland must bind $mainMod SHIFT+Tab to focusmonitor -1";
      }

      # ── Move workspace to monitor ────────────────────────────────────────────
      {
        assertion = hasBinds "$mainMod CTRL, l, movecurrentworkspacetomonitor, +1";
        message = "thiniel: Hyprland must bind $mainMod CTRL+l to movecurrentworkspacetomonitor +1";
      }
      {
        assertion = hasBinds "$mainMod CTRL, h, movecurrentworkspacetomonitor, -1";
        message = "thiniel: Hyprland must bind $mainMod CTRL+h to movecurrentworkspacetomonitor -1";
      }

      # ── Layout toggle migration ──────────────────────────────────────────────
      {
        assertion = hasBinds "$mainMod, semicolon, layoutmsg, togglesplit";
        message = "thiniel: Hyprland layout toggle must use semicolon (not S)";
      }

      # ── Negative: old workspace switching binds must NOT exist ───────────────
      {
        assertion = !(hasBinds "$mainMod, Q, workspace, 1");
        message = "thiniel: old $mainMod+Q workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, W, workspace, 2");
        message = "thiniel: old $mainMod+W workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, E, workspace, 3");
        message = "thiniel: old $mainMod+E workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, R, workspace, 4");
        message = "thiniel: old $mainMod+R workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, T, workspace, 5");
        message = "thiniel: old $mainMod+T workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, Y, workspace, 6");
        message = "thiniel: old $mainMod+Y workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, U, workspace, 7");
        message = "thiniel: old $mainMod+U workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, I, workspace, 8");
        message = "thiniel: old $mainMod+I workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, O, workspace, 9");
        message = "thiniel: old $mainMod+O workspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod, P, workspace, 10");
        message = "thiniel: old $mainMod+P workspace bind must be removed";
      }

      # ── Negative: old move-to-workspace SHIFT+letter binds must NOT exist ────
      {
        assertion = !(hasBinds "$mainMod SHIFT, Q, movetoworkspace, 1");
        message = "thiniel: old $mainMod SHIFT+Q movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, W, movetoworkspace, 2");
        message = "thiniel: old $mainMod SHIFT+W movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, E, movetoworkspace, 3");
        message = "thiniel: old $mainMod SHIFT+E movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, R, movetoworkspace, 4");
        message = "thiniel: old $mainMod SHIFT+R movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, T, movetoworkspace, 5");
        message = "thiniel: old $mainMod SHIFT+T movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, Y, movetoworkspace, 6");
        message = "thiniel: old $mainMod SHIFT+Y movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, U, movetoworkspace, 7");
        message = "thiniel: old $mainMod SHIFT+U movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, I, movetoworkspace, 8");
        message = "thiniel: old $mainMod SHIFT+I movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, O, movetoworkspace, 9");
        message = "thiniel: old $mainMod SHIFT+O movetoworkspace bind must be removed";
      }
      {
        assertion = !(hasBinds "$mainMod SHIFT, P, movetoworkspace, 10");
        message = "thiniel: old $mainMod SHIFT+P movetoworkspace bind must be removed";
      }

      # ── Negative: old layout toggle on S must NOT exist ──────────────────────
      {
        assertion = !(hasBinds "$mainMod, S, layoutmsg, togglesplit");
        message = "thiniel: old $mainMod+S layout toggle bind must be removed (moved to semicolon)";
      }
    ];
  };
}
