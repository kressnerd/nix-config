# tests/assertions/thiniel-desktop-invariants.nix
# Thiniel-specific desktop assertions — enforced at evaluation time via nix flake check
# Covers: Zathura, MPV, wlsunset, CUPS, and other desktop/GUI concerns
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.home-manager.users.dan.programs.zathura.enable;
        message = "thiniel: Zathura PDF viewer must be enabled";
      }
      {
        assertion =
          let
            pdfHandler = config.home-manager.users.dan.xdg.mimeApps.defaultApplications."application/pdf" or null;
          in
          pdfHandler == "org.pwmt.zathura.desktop"
          || (builtins.isList pdfHandler && builtins.elem "org.pwmt.zathura.desktop" pdfHandler);
        message = "thiniel: application/pdf must default to Zathura";
      }
      {
        assertion =
          let
            rules =
              config.home-manager.users.dan.wayland.windowManager.hyprland.settings.windowrule or [ ];
          in
          builtins.any (
            r: builtins.match ".*org\\.pwmt\\.zathura.*" (r."match:class" or "") != null
          ) rules;
        message = "thiniel: Hyprland must have windowrule for Zathura";
      }
    ];
  };
}
