{
  lib,
  ...
}:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ../../tests/assertions
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "adlerkopf";
    firewall.enable = true;
    networkmanager.enable = false;
  };

  # Placeholder until disko.nix is configured in Cycle 2
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  system.stateVersion = "25.11";
}
