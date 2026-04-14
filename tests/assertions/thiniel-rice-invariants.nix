# tests/assertions/thiniel-rice-invariants.nix
# Assertion tests for thiniel rice invariants (Stylix + Hyprland + Catppuccin Latte).
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
        message = "Thiniel rice: stylix.polarity must be 'light' (Catppuccin Latte)";
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
          m: builtins.match ".*eDP-1.*" m != null
        ) config.home-manager.users.dan.wayland.windowManager.hyprland.settings.monitor;
        message = "thiniel: Hyprland monitor rules must include eDP-1 internal display";
      }
      {
        assertion = builtins.any (
          m: builtins.match ",.*" m != null
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
            execOnce = lib.toList (hmHyprSettings.exec-once or [ ]);
          in
          (hmHyprSettings ? exec-once)
          && builtins.any (cmd: builtins.match ".*assign-workspaces.*" cmd != null) execOnce;
        message = "thiniel: Hyprland exec-once must include assign-workspaces daemon for dynamic workspace distribution";
      }
    ];
  };
}
