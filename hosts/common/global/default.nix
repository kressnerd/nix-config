{ pkgs, ... }:
let
  helpers = import ../../../lib/helpers.nix;
in
{
  imports = [ ./nix.nix ];

  # A program on the device can rewrite a file the home profile renders; without
  # this, Home Manager refuses the foreign file and aborts the whole activation
  # (`Existing file '…' would be clobbered`). The command renames the rewritten
  # file beside the rendered one, on every rewrite. See the change
  # `managed-file-displacement`.
  home-manager.backupCommand = helpers.mkManagedFileDisplacement pkgs;

  documentation.nixos.enable = false;
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
}
