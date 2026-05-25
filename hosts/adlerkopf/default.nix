{
  lib,
  ...
}:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ./disko.nix
    ../../tests/assertions
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "adlerkopf";
    firewall.enable = true;
    networkmanager.enable = false;
  };

  system.stateVersion = "25.11";
}
