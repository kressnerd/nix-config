# tests/assertions/common-global-invariants.nix
# Universal NixOS module assertions for hosts/common/global/ — enforced at evaluation time via nix flake check
# No hostname guard — applies to all NixOS hosts
{ config, ... }:
{
  config = {
    assertions = [
      {
        assertion = config.time.timeZone == "Europe/Berlin";
        message = "Global invariant violated: time.timeZone must be Europe/Berlin";
      }
      {
        assertion = config.i18n.defaultLocale == "en_US.UTF-8";
        message = "Global invariant violated: i18n.defaultLocale must be en_US.UTF-8";
      }
      {
        assertion = config.networking.networkmanager.enable;
        message = "Global invariant violated: networking.networkmanager.enable must be true";
      }
      {
        assertion = builtins.elem "flakes" config.nix.settings.experimental-features;
        message = "Global invariant violated: nix flakes experimental feature must be enabled";
      }
      {
        assertion = builtins.elem "nix-command" config.nix.settings.experimental-features;
        message = "Global invariant violated: nix-command experimental feature must be enabled";
      }
    ];
  };
}
