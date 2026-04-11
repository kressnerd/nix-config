# tests/assertions/thiniel-keyboard-invariants.nix
# Assertion tests for thiniel Hyprland keyboard input configuration.
# These fire at eval-time via `nix flake check --no-build`.
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion =
          (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.input.kb_layout or null)
          == "us";
        message = "Thiniel keyboard: kb_layout must be 'us'";
      }
      {
        assertion =
          (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.input.kb_variant or null)
          == "altgr-intl";
        message = "Thiniel keyboard: kb_variant must be 'altgr-intl'";
      }
      {
        assertion =
          (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.input.kb_model or null)
          == "pc105";
        message = "Thiniel keyboard: kb_model must be 'pc105'";
      }
      {
        assertion =
          (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.input.kb_options or null)
          == "terminate:ctrl_alt_bksp";
        message = "Thiniel keyboard: kb_options must be 'terminate:ctrl_alt_bksp'";
      }
    ];
  };
}
