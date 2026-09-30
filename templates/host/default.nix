{ ... }:
{
  imports = [
    ../../hosts/common/global
    ../../hosts/common/users/dan.nix
    ./hardware.nix
  ];

  networking.hostName = "CHANGEME";
  system.stateVersion = "26.05";
}
