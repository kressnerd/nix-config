{ ... }:
{
  imports = [ ./nix.nix ];

  documentation.nixos.enable = false;
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
}
