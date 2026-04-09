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
    ];
  };
}
