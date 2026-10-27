# tests/assertions/thiniel-rice-invariants.nix
# Assertion tests for thiniel rice invariants (Stylix + Hyprland + One Light).
# These fire at eval-time via `nix flake check --no-build`.
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.stylix.enable;
        message = "Thiniel rice: stylix.enable must be true";
      }
      {
        assertion = config.stylix.polarity == "light";
        message = "Thiniel rice: stylix.polarity must be 'light' (One Light)";
      }
      {
        assertion = config.stylix.base16Scheme.base00 == "fafafa";
        message = "thiniel: stylix base16 scheme base00 must be One Light background (fafafa), got ${config.stylix.base16Scheme.base00}";
      }
      {
        assertion = config.security.pam.services ? hyprlock;
        message = "Thiniel rice: security.pam.services.hyprlock must exist for screen lock";
      }
      {
        assertion =
          !(builtins.elem "rofi" (
            builtins.map (p: p.pname or p.name or "") config.environment.systemPackages
          ));
        message = "Thiniel rice: rofi must not be in systemPackages (fuzzel is the launcher)";
      }
      {
        assertion =
          !(builtins.elem "waybar" (
            builtins.map (p: p.pname or p.name or "") config.environment.systemPackages
          ));
        message = "Thiniel rice: waybar must not be in systemPackages (HM manages it)";
      }
      {
        assertion =
          !(builtins.elem "mako" (
            builtins.map (p: p.pname or p.name or "") config.environment.systemPackages
          ));
        message = "Thiniel rice: mako must not be in systemPackages (HM manages it)";
      }
      {
        assertion =
          config.home-manager.users.dan.wayland.windowManager.hyprland.package
          == config.programs.hyprland.package;
        message = "HM Hyprland package must match system-level programs.hyprland.package to prevent version mismatch";
      }
      {
        assertion = builtins.any (
          m: (m.output or "") == "eDP-1"
        ) config.home-manager.users.dan.wayland.windowManager.hyprland.settings.monitor;
        message = "thiniel: Hyprland monitor rules must include eDP-1 internal display";
      }
      {
        assertion = builtins.any (
          m: (m.output or null) == ""
        ) config.home-manager.users.dan.wayland.windowManager.hyprland.settings.monitor;
        message = "thiniel: Hyprland monitor rules must include a catch-all rule for unknown monitors";
      }
      {
        assertion =
          !(config.home-manager.users.dan.wayland.windowManager.hyprland.settings ? workspace)
          || config.home-manager.users.dan.wayland.windowManager.hyprland.settings.workspace == [ ];
        message = "thiniel: Hyprland must not have static workspace rules (dynamic assignment via script)";
      }
      {
        assertion =
          let
            hmHyprSettings = config.home-manager.users.dan.wayland.windowManager.hyprland.settings;
          in
          (hmHyprSettings ? env)
          && builtins.any (
            e:
            (e._args or [ ]) == [
              "AQ_NO_MODIFIERS"
              "1"
            ]
          ) hmHyprSettings.env;
        message = "thiniel: Hyprland env must include AQ_NO_MODIFIERS,1 to fix DRM modifier negotiation";
      }
      {
        assertion =
          let
            hmHyprSettings = config.home-manager.users.dan.wayland.windowManager.hyprland.settings;
          in
          builtins.any (entry: lib.hasInfix "assign-workspaces" (builtins.toJSON entry)) (
            hmHyprSettings.on or [ ]
          );
        message = "thiniel: Hyprland start hook must include assign-workspaces daemon for dynamic workspace distribution";
      }
      {
        assertion = lib.hasPrefix "Bibata" config.stylix.cursor.name;
        message = "thiniel: cursor must be Bibata, got ${config.stylix.cursor.name}";
      }
    ];
  };
}
